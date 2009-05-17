use strict;
use warnings;

package CpanPortal::Model::Maintship;
use Jifty::DBI::Schema;

use CpanPortal::Record schema {
column author =>
    label is _('Author'),
    refers_to CpanPortal::Model::Author,
    is mandatory,
;

column module =>
    label is _('Module'),
    refers_to CpanPortal::Model::Module,
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

