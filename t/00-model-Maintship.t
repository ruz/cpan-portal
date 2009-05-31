#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the Maintship model.

=cut

use Jifty::Test tests => 11;

# Make sure we can load the model
use_ok('CPAN::Portal::Model::Maintship');

# Grab a system user
my $system_user = CPAN::Portal::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = CPAN::Portal::Model::Maintship->new(current_user => $system_user);
my ($id) = $o->create();
ok($id, "Maintship create returned success");
ok($o->id, "New Maintship has valid id set");
is($o->id, $id, "Create returned the right id");

# And another
$o->create();
ok($o->id, "Maintship create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection =  CPAN::Portal::Model::MaintshipCollection->new(current_user => $system_user);
$collection->unlimit;
is($collection->count, 2, "Finds two records");

# Searches in specific
$collection->limit(column => 'id', value => $o->id);
is($collection->count, 1, "Finds one record with specific id");

# Delete one of them
$o->delete;
$collection->redo_search;
is($collection->count, 0, "Deleted row is gone");

# And the other one is still there
$collection->unlimit;
is($collection->count, 1, "Still one left");

