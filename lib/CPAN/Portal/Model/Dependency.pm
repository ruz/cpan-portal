use strict;
use warnings;

package CPAN::Portal::Model::Dependency;
use Jifty::DBI::Schema;

use CpanPortal::Record schema {
column type =>
    type is 'varchar(64)',
    label is _('Type'),
    values are {
        runtime       => _('runtime'),
        optional      => _('optional'),
        tests         => _('tests'),
        configuration => _('configuration'),
        build         => _('build'),
    },
;

column dist =>
    label is _('Distribution'),
    refers_to Cpan::Portal::Model::Dist,
    is mandatory,
;

column module =>
    label is _('Module'),
    refers_to CpanPortal::Model::Module,
    is mandatory,
;

column version =>
    type is 'varchar(32)',
    label is _('Version'),
;

#column checked_on =>
#    type is 'varchar(255)',
#    label is _('Site');
#;
#
};

1;
