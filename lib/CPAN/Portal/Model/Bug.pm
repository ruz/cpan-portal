use strict;
use warnings;

package CpanPortal::Model::Bug;
use Jifty::DBI::Schema;

use CpanPortal::Record schema {
column dist =>
    label is _('Distribution'),
    refers_to CpanPortal::Model::Dist,
    is mandatory,
;

column source =>
    label is _('Source'),
    type is 'varchar(32)',
    is mandatory,
;

column url =>
    label is _('URL'),
    type is 'varchar(32)',
    is mandatory,
;

column ticket =>
    label is _('Summary'),
    type is 'varchar(32)',
;

column summary =>
    label is _('Summary'),
    type is 'text',
;

column status =>
    label is _('Status'),
    type is 'varchar(32)',
;

};

# Your model-specific methods go here.

1;

