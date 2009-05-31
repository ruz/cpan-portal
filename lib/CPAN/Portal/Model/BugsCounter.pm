use strict;
use warnings;

package CPAN::Portal::Model::BugsCounter;
use Jifty::DBI::Schema;

use CPAN::Portal::Record schema {
column dist =>
    label is _('Distribution'),
    refers_to CPAN::Portal::Model::Dist,
    is mandatory,
    is distinct,
;

column new =>
    label is _('New'),
    type is 'integer',
    is mandatory,
    default is 0,
;

column open =>
    label is _('New'),
    type is 'integer',
    is mandatory,
    default is 0,
;

column stalled =>
    label is _('New'),
    type is 'integer',
    is mandatory,
    default is 0,
;

column resolved =>
    label is _('New'),
    type is 'integer',
    is mandatory,
    default is 0,
;

column rejected =>
    label is _('New'),
    type is 'integer',
    is mandatory,
    default is 0,
;

};

# Your model-specific methods go here.

1;
