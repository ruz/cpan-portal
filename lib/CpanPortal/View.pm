use strict;
use warnings;
use utf8;

package CpanPortal::View;
use Jifty::View::Declare -base;

template '/' => page {
    div { attr { class => 'std-block' }
        h2 {
            outs('News');
            ul {
                li { a { attr { href => "/send_news" } 'Прислать новость' } }
                li { a { attr { href => "/send_news" } 'RSS' } }
            }
        }

        ul {
            li { 'hi, there' }
            li { 'hi, there' }
            li { 'hi, there' }
        }
    }
};

template '/dist' => page {
    my ($dist) = get('dist');

    page_title is $dist->name;

    div { attr { class => 'std-block' }
        h2 { _('Description') }

        p { outs('The DBI is a database access module for the Perl programming language. It defines a set of methods, variables, and conventions that provide a consistent database interface, independent of the actual database being used.

It is important to remember that the DBI is just an interface. The DBI is a layer of "glue" between an application and one or more database driver modules. It is the driver modules which do most of the real work. The DBI provides a standard interface and framework for the drivers to operate within.') }
    }

    div { attr { class => 'std-block' }
        h2 { _('Tags') }

        my $tags = $dist->tags;

        Jifty->log->warn( $tags->build_select_query );

        ul { attr { class => 'tags' }; while ( my $t = $tags->next ) { li {$t->value} } }
    }
};





1;
