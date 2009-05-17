use strict;
use warnings;

package CpanPortal::Model::Author;
use Jifty::DBI::Schema;

use CpanPortal::Record schema {
column cpan =>
    type is 'varchar(64)',
    label is _('CPAN ID'),
    is mandatory,
    is distinct;

column fullname =>
    type is 'varchar(255)',
    label is _('Full name');

column homepage =>
    type is 'varchar(255)',
    label is _('Site');



};

sub load_or_create {
    my $class = shift;
    my $cpanid = shift;

    my $self;
    if ( blessed $class ) {
        ($self, $class) = ($class, undef);
    } else {
        $self = $class->new;
    }

    $self->load_by_cols( cpan => $cpanid );
    if ( my $id = $self->id ) {
        return (!wantarray || $class)? $self : ($self, "Loaded author $cpanid #$id");
    }

    return $self->create( cpan => $cpanid )
        unless $class;
    
    my ($id, $msg) = $self->create( cpan => $cpanid );
    return $self if $id;

    Jifty->log->error("Couldn't create author '$cpanid': $msg");
    return;
}


1;
