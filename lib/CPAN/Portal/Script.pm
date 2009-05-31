use 5.008003;
use strict;
use warnings;
use utf8;

=head1 NAME

CPAN::Portal::Script - 

=cut

package CPAN::Portal::Script;

use Email::Address;
use List::Compare;
use CPAN::DistnameInfo;

=head1 METHODS

=head2 new

Simple constructor that creates a hash based object and stores all
passed arguments inside it. Then L</init> is called.

=head3 options

=over 8

=item force - force sync even files are the same

=back

=cut

sub new {
    my $proto = shift;
    my $self = bless { @_ }, ref($proto) || $proto;
    $self->init();
    return $self;
}

=head2 init

Called right after constructor, changes @INC, loads RT and initilize it.

See options in description of L</new>.

=cut

sub init {
    my $self = shift;
}

sub sync_minicpan {
    my $self = shift;

    my $conf = Jifty->config->app('CPAN') || {};
    my $mirror = $conf->{'mirror'};
    my $storage = $conf->{'mini'};

    Jifty->log->debug( "Syncing files from '$mirror'\n" );

    require CPAN::Mini;
    CPAN::Mini->update_mirror(
        remote => $mirror,
        local  => $storage,
        trace  => 1,
        also_mirror => [qw(
            indices/find-ls.gz
            authors/00whois.xml
            modules/06perms.txt.gz
            modules/02packages.details.txt.gz
        )],
    );
}

my %depends_on = (
    authors       => ['authors/00whois.xml'],
    distributions => ['indices/find-ls.gz'],
    modules       => ['modules/02packages.details.txt.gz'],
    maintainers   => ['modules/06perms.txt.gz'],
);

sub sync {
    my $self = shift;
    my $type = shift;
    my $method = "sync_$type";

    return $self->$method() if $self->{'force'};

    return $self->$method()
        unless my $list = $depends_on{ $type };

    return $self->$method()
        if grep $self->is_new_file($_), @$list; 

    Jifty->log->debug( "Skip syncing $type, file(s) not changed\n" );
    return (1);
}

sub sync_authors {
    my $self = shift;

    my $authors = $self->authors;
    while ( my ($cpanid, $meta) = each %$authors ) {
        my ($user) = $self->update_author( $cpanid, $meta );
    }
    return;
}

sub sync_distributions {
    my $self = shift;

    my $dists = $self->all_distributions;
    foreach my $info ( @$dists ) {
        # XXX: it's stupid to call it multiple times,
        # but at some point we want parse versions, uploaders
        # and other info
        $self->update_dist( $info );
    }

    return (1);
}

sub sync_modules {
    my $self = shift;

    my $mods = $self->module2file;
    foreach my $module ( keys %$mods ) {
        my ($module) = $self->update_module( $module );
    }

    return (1);
}

sub sync_maintainers {
    my $self = shift;

    my $perm = $self->permissions;

    my %res;
    while ( my ($module, $maint) = each %$perm ) {
        my ($module) = $self->update_module( $module );
        next unless $module;
        
        $module->set_maintainers( @$maint );
    }
    return (1);
}

sub update_module {
    my $self = shift;
    my ($module, %rest) = @_;

    unless ( $rest{'dist'} ) {
        my $file = $self->module2file->{$module}
            or do { Jifty->log->warn("No file for module '$module'"); return };
        my $info = $self->file2distinfo( "authors/id/". $file )
            or return; # file2distinfo logs for us

        my ($dist) = $self->update_dist( $info );
        return unless $dist;

        $rest{'dist'} = $dist;
    }

    return $self->update_or_create_record(
        Module => { name => $module },
        \%rest
    );
}

sub update_author {
    my $self = shift;
    my ($cpanid, $meta) = @_;
    return $self->update_or_create_record(
        Author => { cpan => $cpanid },
        { fullname => $meta->{'fullname'}, homepage => $meta->{'homepage'} }
    );
}

sub update_dist {
    my $self = shift;
    my ($meta) = @_;
    return $self->update_or_create_record(
        Dist => { name => $meta->dist }
    );
}

sub update_or_create_record {
    my $self  = shift;
    my $model = shift;
    my $load  = shift;
    my $meta  = shift || {};

    my ($obj, $action) = $self->load_or_create_record(
        $model, $load, $meta
    );
    return wantarray? ($obj, $action) : $obj
        unless $obj;
    return wantarray? ($obj, $action) : $obj
        if $obj && $action eq 'create';

    $self->update_record( $obj => $meta );

    Jifty->log->debug("Updated $model #". $obj->id);

    return ($obj, 'update');
}

sub update_record {
    my $self = shift;
    my $obj  = shift;
    my $meta = shift || {};

    while ( my ($k, $v) = each %$meta ) {
        my $method = "set_$k";
        my ($status, $msg) = $obj->$method( $v );
        Jifty->log->error($msg) unless $status;
    }

    return $obj;
}

sub load_or_create_record {
    my $self = shift;
    my $model = shift;
    my $load = shift;
    my $meta = shift || {};

    my $desc = "$model (". join(', ', map "$_:".$load->{$_}, keys %$load ) .')';

    my $obj = Jifty->app_class('Model', $model)->new;
    $obj->load_by_cols( %$load );
    if ( my $id = $obj->id ) {
        Jifty->log->debug("Found $desc - #$id");
        return wantarray? ($obj, 'load'): $obj;
    }

    #require Carp; Carp::cluck("boo");
    my ($id, $msg) = $obj->create(
        %$load, %$meta
    );
    unless ( $id ) {
        Jifty->log->error( "Couldn't create $model: $msg" );
        return;
    }

    Jifty->log->debug("Created $desc - #$id");

    return wantarray? ($obj, 'create'): $obj;
}

{ my $cache;
sub authors {
    my $self = shift;
    $cache = $self->_authors unless $cache;
    return $cache;
} }

sub _authors {
    my $self = shift;
    my $file = 'authors/00whois.xml';
    Jifty->log->debug( "Parsing $file...\n" );

    use XML::SAX::ParserFactory;
    my $handler = CPAN2RT::UsersSAXParser->new();
    my $p = XML::SAX::ParserFactory->parser(Handler => $handler);

    my $fh = $self->open_file( $file, layers => ':raw' );
    my $res = $p->parse_file( $fh );
    close $fh;

    return $res;
}

{ my $cache;
sub permissions {
    my $self = shift;
    $cache = $self->_permissions unless $cache;
    return $cache;
} }

sub _permissions {
    my $self = shift;
    my $file = 'modules/06perms.txt';
    Jifty->log->debug( "Parsing $file...\n" );

    my $fh = $self->open_file( $file );
    $self->skip_header( $fh );

    my %res;
    while ( my $str = <$fh> ) {
        chomp $str;

        my ($module, $cpanid, $permission) = (split /\s*,\s*/, $str);
        unless ( $module && $cpanid ) {
            Jifty->log->debug( "couldn't parse '$str' from '$file'\n" );
            next;
        }

        $res{ $module } ||= [];
        push @{ $res{ $module } }, $cpanid;
    }
    close $fh;

    return \%res;
}

{ my $cache;
sub module2file {
    my $self = shift;
    $cache = $self->_module2file() unless $cache;
    return $cache;
} }

sub _module2file {
    my $self = shift;
    my $file = 'modules/02packages.details.txt';
    Jifty->log->debug( "Parsing $file...\n" );

    my $fh = $self->open_file( $file );
    $self->skip_header( $fh );

    my %res;
    while ( my $str = <$fh> ) {
        chomp $str;

        my ($module, $mver, $file) = split /\s+/, $str;
        unless ( $module && $file ) {
            Jifty->log->debug( "couldn't parse '$str'" );
            next;
        }
        $res{ $module } = $file;
    }
    close $fh;

    return \%res;
}

{ my $cache;
sub all_distributions {
    my $self = shift;
    $cache = $self->_all_distributions() unless $cache;
    return $cache;
} }

sub _all_distributions {
    my $self = shift;

    my $file = 'indices/find-ls';
    Jifty->log->debug( "Parsing $file...\n" );

    my $fh = $self->open_file( $file );

    my @res;
    while ( my $str = <$fh> ) {
        next if $str =~ /^\d+\s+0\s+l\s+1/; # skip symbolic links
        chomp $str;

        my ($mode, $file) = (split /\s+/, $str)[2, -1];
        next if index($mode, 'x') >= 0; # skip executables (dirs)
        my $info = $self->file2distinfo($file)
            or next;
        push @res, $info;
    }
    close $fh;

    return \@res;
}

{ my $cache;
sub recent_distributions {
    my $self = shift;
    $cache = $self->_recent_distributions unless $cache;
    return $cache;
} }

sub _recent_distributions {
    my $self = shift;

    my $recent = $self->recent;
    
    my @res;
    foreach my $file ( keys %$recent ) {
        my $info = $self->file2distinfo($file)
            or next;
        push @res, $info;
    }

    return \@res;
}

{ my $cache;
sub recent {
    my $self = shift;
    $cache = $self->_recent unless $cache;
    return $cache;
} }

sub _recent {
    my $self = shift;

    my $file = 'RECENT';
    Jifty->log->debug( "Parsing $file...\n" );

    my $fh = $self->open_file( $file );

    my %res;
    while ( my $str = <$fh> ) {
        chomp $str;
        $res{ $str } = 1;
    }
    close $fh;

    return \%res;
}

sub file2distinfo {
    my $self = shift;
    my $file = shift;

    # we're only interested in files in authors/id/ dir
    return unless rindex($file, "authors/id/", 0) == 0;
    return unless $file =~ /\.(bz2|zip|tgz|tar\.gz)$/i;

    my $info = CPAN::DistnameInfo->new( $file );
    my $dist = $info->dist;
    unless ( $dist ) {
        Jifty->log->debug( "Couldn't parse distribution name from '$file'\n" );
        return;
    }

    return $info;
}

sub parse_email_address {
    my $self = shift;
    my $string = shift;
    return undef unless defined $string && length $string;
    return undef if uc($string) eq 'CENSORED';

    my $address = (grep defined, Email::Address->parse( $string || '' ))[0];
    return undef unless defined $address;
    return $address->address;
}

sub is_new_file {
    my $self = shift;
    my $file = shift;
    return exists $self->recent->{ $file };
}

sub open_file {
    my $self = shift;
    my $file = $self->file_path(shift);
    my %opts = @_;

    my $layers = $opts{'layers'} || ':utf8';
    unless ( -e $file ) {
        if ( -e "$file.gz" ) {
            $file .= '.gz';
        }
        elsif ( -e "$file.bz2" ) {
            $file .= '.bz2';
        }
        else {
            return if $opts{'missing_ok'};
            die "couldn't find file '$file' or '$file.gz'";
        }
    }
    my $fh;
    if ( $file =~ /\.bz2$/ ) {
        open $fh, "-|$layers", 'bunzip2', '-dkc', $file
            or die "Couldn't open gunzip for '$file': $!";
    }
    elsif ( $file =~ /\.gz$/ ) {
        open $fh, "-|$layers", 'gunzip', '-dc', $file
            or die "Couldn't open gunzip for '$file': $!";
    }
    else {
        open $fh, "<$layers", $file
            or die "Couldn't open '$file': $!";
    }
    return $fh;
}

sub fetch_file {
    my $self  = shift;
    my $url   = shift;
    my $file  = shift;
    my $tries = shift || 3;

    require LWP::UserAgent;
    my $ua = new LWP::UserAgent;
    $ua->timeout( 10 );

    my $store = $self->file_path( $file );
    $self->backup_file( $store );

    Jifty->log->debug( "Fetching '$url' -> '$file'" );
    my $response = $ua->get( $url, ':content_file' => $store );
    unless ( $response->is_success ) {
        print STDERR "Request to '$url' failed. Server response:\n". $response->status_line ."\n";
        return $self->fetch_file( $url, $file, $tries) if --$tries;

        print STDERR "Failed several attempts to fetch '$url'\n";
        return undef;
    }
    Jifty->log->debug( "Fetched '$file' -> '$store'\n" );

    my $mtime = $response->header('Last-Modified');
    if ( $mtime ) {
        require HTTP::Date;
        $mtime = HTTP::Date::str2time( $mtime );
        utime $mtime, $mtime, $store if $mtime;
        Jifty->log->debug( "Last modified: $mtime\n" );
    }
    return 1;
}

sub backup_file {
    my $self = shift;
    my $old = shift;
    return unless -e $old;

    my ($name, $ext) = split /\./, $old, 2;
    my $new = $ext? "$name.old.$ext" : "$name.old";
    return rename $old, $new;
}

sub file_path {
    my $self = shift;
    require File::Spec;
    return File::Spec->catfile( grep defined && length, map split( /\//, $_), @_ );
}

sub skip_header {
    my $self = shift;
    my $fh = shift;
    while ( my $str = <$fh> ) {
        return if $str =~ /^\s*$/;
    }
}

1;

package CPAN2RT::UsersSAXParser;
use base qw(XML::SAX::Base);

sub start_document {
    my ($self, $doc) = @_;
    $self->{'res'} = {};
}

sub start_element {
    my ($self, $el) = @_;
    my $name = $el->{LocalName};
    return if $name ne 'cpanid' && !$self->{inside};

    if ( $name eq 'cpanid' ) {
        $self->{inside} = 1;
        $self->{tmp} = [];
        return;
    } else {
        $self->{inside_prop} = 1;
    }

    push @{ $self->{'tmp'} }, $name, '';
}

sub characters {
    my ($self, $el) = @_;
    $self->{'tmp'}[-1] .= $el->{Data} if $self->{inside_prop};
}

sub end_element {
    my ($self, $el) = @_;
    $self->{inside_prop} = 0;

    my $name = $el->{LocalName};

    if ( $name eq 'cpanid' ) {
        $self->{inside} = 0;
        my %rec = map Encode::decode_utf8($_), @{ delete $self->{'tmp'} };
        $self->{'res'}{ delete $rec{'id'} } = \%rec;
    }
}

sub end_document {
    my ($self) = @_;
    return $self->{'res'};
}

1;
