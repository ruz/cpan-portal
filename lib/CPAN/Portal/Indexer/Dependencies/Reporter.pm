use 5.008;
use strict;
use warnings;

package CPAN::Portal::Indexer::Dependencies::Reporter;

BEGIN {
    require Jifty::Util;
    my $root = Jifty::Util->app_root;
    unshift @INC, "$root/lib" if $root;

    use Jifty::Everything;
    Jifty->new;
}

sub get_reporter {
    my( $class, $notes ) = @_;
    return $notes->{'reporter'} = sub {
        my( $notes, $info ) = @_;
        use Data::Dumper;
        warn Dumper( [$notes, $info]);
    };
}

sub final_words { 1 }

1;
