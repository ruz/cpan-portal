use 5.008;
use strict;
use warnings;
use utf8;

package CpanPortal::View::Page;
use base 'Jifty::Plugin::ViewDeclarePage::Page';
use Jifty::View::Declare::Helpers;

sub render_page {
    my $self = shift;
    div { attr { id => 'mainWrapper' } div { attr { id => 'siteWrapper' }
        div { attr { id => 'top' };
            div { attr { id => 'logo' };
                a { attr { href => '/' }
                    img { attr { src => '/static/images/logo.png', alt => 'cpan::portal' } }
                }
            }
            div { attr { id => 'top-links' };
                $self->render_navigation;
            }
#            $self->render_salutation;
        }
        div { attr { id => 'content' };
            $self->instrument_content;
            $self->render_jifty_page_detritus;
        }
    } };
    return '';
}

sub render_navigation {
    Jifty->web->navigation->render_as_menu;
    return '';
}

sub render_title_inpage {
    my $self = shift;
    my $title = shift;

    if ( length $title ) {
        h1 { attr { class => 'title' }; outs($title) };
    }

#    Jifty->web->page_navigation->render_as_menu;

    Jifty->web->render_messages;

    return '';
}

sub render_content {
    my $self = shift;

    local *sidebar::add = sub {
        shift;
        my %args = ('name', @_);
        my $list = $self->_sidebar || [];
        push @$list, \%args;
        $self->_sidebar( $list );
        return '';
    };

    Template::Declare->new_buffer_frame;
    $self->SUPER::render_content( @_ );
    my $content = Template::Declare->end_buffer_frame->data;

    div { attr { id => 'wrapper' } div { attr { id => 'left-column' }
        outs_raw( $content );
    } }

    div { attr { id => 'rightMainCol' }
    };

    return '';
}

1;
