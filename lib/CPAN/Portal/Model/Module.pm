use strict;
use warnings;

package CPAN::Portal::Model::Module;
use Jifty::DBI::Schema;

use Scalar::Util qw(blessed);

use CPAN::Portal::Record schema {
# 2008-12-29 longest module has 96 characters
column name =>
    type is 'varchar(127)',
    label is _('Name'),
    is mandatory,
    is distinct
;

column dist =>
    label is _('Distribution'),
    refers_to CPAN::Portal::Model::Dist,
    is mandatory,
;

column maintship =>
    refers_to CPAN::Portal::Model::MaintshipCollection
        by 'module',
;


column maintainers =>
    refers_to CPAN::Portal::Model::AuthorCollection
        by tisql => 'maintainers.id = .maintship.author',
;

};

sub set_maintainers {
    my $self = shift;
    my @new = @_;

    my $aclass = Jifty->app_class('Model::Author');

    @new = 
        map $_->id, grep defined,
        map blessed($_)? $_ : $aclass->load_or_create($_),
        @new;
    my @old = map $_->author_id, @{ $self->maintship };

    my $mclass = Jifty->app_class('Model::Maintship');

    my $set = List::Compare->new( '--unsorted', \@old, \@new );
    foreach ( $set->get_unique ) {
        my $maint = $mclass->load_by_cols(
            module => $self->id, author => $_
        );
        unless ( $maint ) {
            Jifty->log->error("Strange! No more maint record");
        }
        my ($status, $msg) = $maint->disable;
        Jifty->log->error("Couldn't disable $msg");
    }
    foreach my $author ( $set->get_complement ) {
        my $maint = $mclass->load_by_cols(
            module => $self->id, author => $author
        );
        unless ( $maint ) {
            my ($id, $msg) = $mclass->create( 
                module => $self, author => $author
            );
            Jifty->log->error("Strange! $msg")
                unless $id;
        } else {   
            my ($status, $msg) = $maint->enable;
            Jifty->log->error("Strange! $msg")
                unless $status;
        }
    }

}

# Your model-specific methods go here.

1;
