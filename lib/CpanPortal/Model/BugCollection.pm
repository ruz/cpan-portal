use 5.008;
use strict;
use warnings;
use utf8;

package CpanPortal::Model::BugCollection;
use base 'CpanPortal::Collection';

sub from {
    my $self = shift;
    my $source = shift;
    my %rest = @_;
    return $self->limit(
        %rest,
        column => 'source',
        value  => $source,
    );
}

1;
