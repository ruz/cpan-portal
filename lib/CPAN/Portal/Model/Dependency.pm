use strict;
use warnings;

package CPAN::Portal::Model::Dependency;

use Cpan::Portal::Model::Dist;

use Jifty::DBI::Schema;
use CPAN::Portal::Record schema {
    column type =>
        type is 'varchar(64)',
        label is _('Type'),
        valid_values are {
            runtime       => _('runtime'),
            optional      => _('optional'),
            tests         => _('tests'),
            configuration => _('configuration'),
            build         => _('build'),
        },
    ;

    column dist =>
        type is 'int',
        label is _('Distribution'),
        refers_to Cpan::Portal::Model::Dist,
        is mandatory,
    ;

    column requires =>
        type is 'varchar(255)',
        label is _('Depends on'),
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
