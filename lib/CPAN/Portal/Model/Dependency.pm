use strict;
use warnings;

package CPAN::Portal::Model::Dependency;
use Jifty::DBI::Schema;

use CpanPortal::Record schema {
column type =>
    type is 'varchar(64)',
    label is _('Type'),
    values are {
        runtime       => '',
        optional      => '',
        tests         => '',
        configuration => '',
        build         => '',
    },
;

column dist =>
    type is 'varchar(64)',
    label is _('CPAN ID'),
    is mandatory,
    is distinct;

column module =>
    type is 'varchar(255)',
    label is _('Full name');

column version =>
    type is 'varchar(255)',
    label is _('Site');

column listed_in =>
    type is 'varchar(255)',
    label is _('Site');

column checked_on =>
    type is 'varchar(255)',
    label is _('Site');
};

1;
