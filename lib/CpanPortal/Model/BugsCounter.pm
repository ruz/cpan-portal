use strict;
use warnings;

package CpanPortal::Model::BugsCounter;
use Jifty::DBI::Schema;

use CpanPortal::Record schema {
column dist =>
    label is _('Distribution'),
    refers_to CpanPortal::Model::Dist,
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
