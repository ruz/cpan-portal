use strict;
use warnings;

package CPAN::Portal::Model::WorkQueue;
use Jifty::DBI::Schema;

use CPAN::Portal::Record schema {
column type =>
    type is 'varchar(32)',
    is mandatory,
;

column argument =>
    type is 'blob',
    is mandatory,
;

};

# Your model-specific methods go here.

1;

