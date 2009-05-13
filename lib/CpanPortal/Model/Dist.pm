use strict;
use warnings;

package CpanPortal::Model::Dist;
use Jifty::DBI::Schema;

use CpanPortal::Record schema {
column name =>
    type is 'varchar(255)',
    label is _('Name'),
    is mandatory,
    is distinct,
;

column bugs =>
    refers_to CpanPortal::Model::BugCollection
        by 'dist',
;
};

use Jifty::Plugin::Tag::Mixin::Model;

1;

