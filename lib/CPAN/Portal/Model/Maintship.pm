use strict;
use warnings;

package CPAN::Portal::Model::Maintship;
use Jifty::DBI::Schema;

use CPAN::Portal::Record schema {
column author =>
    label is _('Author'),
    refers_to CPAN::Portal::Model::Author,
    is mandatory,
;

column module =>
    label is _('Module'),
    refers_to CPAN::Portal::Model::Module,
    is mandatory,
;

column disabled =>
    type is 'tinyint',
    label is _('Disabled'),
    is madatory,
    default is 0,
;
};

sub enable { return shift->set_disabled(0, @_) }
sub disable { return shift->set_disabled(1, @_) }

1;

