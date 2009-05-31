use strict;
use warnings;

package CPAN::Portal::Model::Dist;

use Jifty::DBI::Schema;
use CPAN::Portal::Record schema {
    column name =>
        type is 'varchar(255)',
        label is _('Name'),
        is mandatory,
        is distinct,
    ;

    column bugs =>
        refers_to CPAN::Portal::Model::BugCollection
            by 'dist',
    ;

    column dependencies =>
        refers_to CPAN::Portal::Model::DependencyCollection
            by 'dist',
    ;
};

use Jifty::Plugin::Tag::Mixin::Model;

sub load_or_create {
    my $self = shift;
    my %args = (@_);

    $self->load_by_cols(%args);
    return $self if $self->id;

    return $self->create(%args);
}

sub set_dependencies {
    my $self = shift;
    my %args = (
        runtime => { },
        @_
    );

    my %current;
    $current{ $_->type }{ $_->requires } = $_
        foreach @{ $self->dependencies };

    my ($success, @msgs) = (1, ());
    foreach my $type ( grep $args{$_}, keys %args ) {
        while ( my ($requires, $version) = each %{ $args{$type} } ) {
            print "x $type, $requires, $version\n\n";
            if ( my $has = delete $current{$type}{$requires} ) {
                # has, let's check the version
                next if ($has->version||'') eq ($version||'');

                my ($status, $msg) = $has->set_version( $version );
                $success = 0 unless $status;
                push @msgs, $msg if $msg;
            }
            else {
                my $new = Jifty->app_class('Model::Dependency')->new;
                my ($id, $msg) = $new->create(
                    type => $type, dist => $self->id, requires => $requires, version => $version,
                );

                $success = 0 unless $id;
                push @msgs, $msg if $msg;
            }
        }
    }

    # everything that is still in %current should be dropped
    foreach my $dep ( map { values %$_ } values %current ) {
        my ($status, $msg) = $dep->delete;
        $success = 0 unless $status;
        push @msgs, $msg if $msg;
    }

    unless ( @msgs ) {
        push @msgs, ($success? _('No changes') : _("Couldn't update some dependencies"));
    }
    return wantarray? ($success, @msgs) : $success;
}

1;
