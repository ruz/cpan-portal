use 5.008;
use strict;
use warnings;
use utf8;

package CpanPortal;

sub start {
    Jifty->web->add_javascript( qw(jquery.corner.js) );
}

1;
