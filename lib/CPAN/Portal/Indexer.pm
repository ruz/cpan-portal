use 5.008;
use strict;
use warnings;
use utf8;

package CPAN::Portal::Indexer;
use base 'MyCPAN::Indexer';

sub examine_dist_steps {
    return (
        #    method                error message                  fatal
        [ 'unpack_dist',        "Could not unpack distribtion!",     1 ],
        [ 'find_dist_dir',      "Did not find distro directory!",    1 ],
        [ 'parse_meta_files',   "Could not parse META.yml!",         1 ],
        [ 'find_dependencies',  "Could not find dependencies",       1 ],
    );
}

sub find_dependencies {
    my $self = shift;
}

1;
