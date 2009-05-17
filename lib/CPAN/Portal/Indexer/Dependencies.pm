use 5.008;
use strict;
use warnings;
use utf8;

package CPAN::Portal::Indexer::Dependencies;
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
    
    my $meta = $self->dist_info('META.yml') or die "";
    my $deps = $meta->{'requires'} or die "";
    $_ = undef for grep $_ eq '0', values %$deps;
    $self->set_dist_info('dependencies', $deps);
    use Data::Dumper;
    warn Dumper $meta;
    
}


1;
