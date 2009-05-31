use 5.008;
use strict;
use warnings;
use utf8;

=head1 NAME

CPAN::Portal::Script - 

=cut

package CPAN::Portal::Script::Forum;
use base 'CPAN::Portal::Script';

sub sync {
    my $self = shift;
    return $self->sync_tags;
}

sub sync_tags {
    my $self = shift;

    $self->fetch_file(
        'http://www.cpanforum.com/module_tags.csv.bz2',
        'module_tags.csv.bz2'
    ) if $self->{'sync'};

    my $new = $self->parse_tags( $self->open_file('module_tags.csv') );
    while ( my ($dist, $tags) = each %$new ) {
        $dist = $self->load_or_create_record(
            Dist => { name => $dist }
        ) or next;

        foreach my $tag ( @$tags ) {
            my ($status, $msg) = $dist->add_tag( $tag, exist_ok => 1 );
            Jifty->log->error("Couldn't add tag: $msg")
                unless $status;
        }
    }
}

sub parse_tags {
    my $self = shift;
    my $fh   = shift or return {};

    use Text::CSV;
    my $csv = new Text::CSV;

    my %res = ();
    while ( my $row = $csv->getline( $fh ) ) {
        $res{ shift @$row } = $row;
    }
    return \%res;
}

sub file_path {
    my $self = shift;
    return $self->SUPER::file_path('var/forum', @_);
}

1;
