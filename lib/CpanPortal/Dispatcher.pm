use strict;
use warnings;
use utf8;

package CpanPortal::Dispatcher;
use Jifty::Dispatcher -base;

on 'dist/*' => run {
    my $dist = Jifty->app_class('Model::Dist')->load_by_cols( name => $1 );
    abort(404) unless $dist && $dist->id;

    set(dist => $dist);
    show('/dist');
};

1;
