use 5.008;
use strict;
use warnings;
use utf8;

=head1 NAME

CpanPortal::Script - 

=cut

package CpanPortal::Script::RT;
use base 'CpanPortal::Script';

sub sync {
    my $self = shift;

    return $self->sync_counters unless $self->{'dist'};
    return $self->sync_bugs;
}

sub sync_counters {
    my $self = shift;

    $self->fetch_file(
        'http://rt.cpan.org/Public/bugs-per-dist.tsv',
        'bugs-per-dist.tsv'
    ) if $self->{'sync'};

    my $new = $self->parse_counters( $self->open_file('bugs-per-dist.tsv') );
    my $old = $self->parse_counters(
        $self->open_file('bugs-per-dist.old.tsv', missing_ok => 1)
    );

    while ( my ($dist, $values) = each %$new ) {
        next if !$self->{'force'} &&
            join(',', @$values) eq join(',', @{ $old->{$dist} || [] });
        
        $dist = $self->load_or_create_record(
            Dist => { name => $dist }
        ) or next;

        $self->update_or_create_record(
            BugsCounter => {
                dist => $dist->id,
            }, {
                new      => $values->[0],
                open     => $values->[1],
                stalled  => $values->[2],
                resolved => $values->[3],
                rejected => $values->[4],
            },
        );
    }
}

sub sync_bugs {
    my $self = shift;

    my $dist = $self->{'dist'} or die "No dist :)";
    my $file = $dist.'-bugs.tsv';

    $self->fetch_file(
        'http://rt.cpan.org/Public/Dist/bugs.tsv?Dist='. $dist, # XXX: uri escaping
        $file
    );

    my $new = $self->parse_bugs( $self->open_file($file) );

    $dist = $self->load_or_create_record(
        Dist => { name => $dist }
    ) or return 0;

# XXX: handle situation when bug has been moved

    my $bugs = $dist->bugs;
    $bugs->from('rt.cpan.org');

    while ( my $bug = $bugs->next ) {
        if ( my $meta = delete $new->{ $bug->ticket } ) {
            delete @{ $meta }{'source', 'ticket'};
            $self->update_record( $bug => $meta );
        }
        else {
# XXX: inactive
            my ($status, $msg) = $bug->set_status('inactive');
            Jifty->log->error("Couldn't set status: $msg")
                unless $status;
        }
    }

    foreach my $meta ( values %$new ) {
        my ($source, $ticket) = delete @{ $meta }{'source', 'ticket'};
        $self->load_or_create_record(
            Bug => {
                dist   => $dist->id,
                source => $source,
                ticket => $ticket,
            },
            $meta
        );
    }
}

sub parse_bugs {
    my $self = shift;
    my $fh   = shift or return [];
    
    my %res = ();
    while ( my $str = <$fh> ) {
        next if $str =~ /^\s*#/ || $str =~ /^\s*$/;
        chomp $str;

        my %bug = (source => 'rt.cpan.org');
        @bug{qw(url ticket summary status)} = split /\t/, $str;

        $res{ $bug{'ticket'} } = \%bug;
    }

    return \%res;
}

sub parse_counters {
    my $self = shift;
    my $fh   = shift or return {};
    
    my %res = ();
    while ( my $str = <$fh> ) {
        next if $str =~ /^\s*#/ || $str =~ /^\s*$/;

        chomp $str;
        my ($dist, @numbers) = split /\t/, $str;
        $res{ $dist } = \@numbers;
    }

    return \%res;
}

sub file_path {
    my $self = shift;
    return $self->SUPER::file_path('var/rt', @_);
}

1;
