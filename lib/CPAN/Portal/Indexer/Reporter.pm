use 5.008;
use strict;
use warnings;

package CPAN::Portal::Indexer::Reporter;

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
        my ($notes, $info) = @_;
        update_dependencies($info);

    };
}

sub update_dependencies {
    my $info = shift;

    my $meta = $info->dist_info('META.yml') or die "No META.yml";

    my %deps = ();
    $deps{'runtime'}    = $meta->{'requires'} or die "";
    $deps{'build'}      = $meta->{'build_requires'};
    $deps{'configure'}  = $meta->{'configure_requires'};
    $deps{'recommends'} = $meta->{'recommends'};

    my $dist = Jifty->app_class('Model::Dist')->new;
    $dist->load_or_create(
        name => $meta->{'name'},
    );
    die "can not load or create dist '". $meta->{'name'} ."'"
        unless $dist;

    my ($status, @msgs) = $dist->set_dependencies( %deps );
    print ($status? "Success:": "Failed:") ."\n". join("\n", map "\t$_", @msgs) ."\n";
    return 1;
}

sub final_words { 1 }

1;
