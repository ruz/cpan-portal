use 5.008003;
use strict;
use warnings;
use utf8;

=head1 NAME

CpanPortal::Script - 

=cut

package CpanPortal::Script::CPAN;
use base 'CpanPortal::Script';

sub file_path {
    my $self = shift;
    my $res = shift;
    require File::Spec;
    $res = File::Spec->catfile( Jifty->config->app('CPAN')->{'mini'}, split /\//, $res );
    return $res;
}

1;
