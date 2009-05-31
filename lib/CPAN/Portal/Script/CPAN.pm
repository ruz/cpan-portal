use 5.008003;
use strict;
use warnings;
use utf8;

=head1 NAME

CPAN::Portal::Script - 

=cut

package CPAN::Portal::Script::CPAN;
use base 'CPAN::Portal::Script';

sub file_path {
    my $self = shift;
    my $res = shift;
    require File::Spec;
    $res = File::Spec->catfile( Jifty->config->app('CPAN')->{'mini'}, split /\//, $res );
    return $res;
}

1;
