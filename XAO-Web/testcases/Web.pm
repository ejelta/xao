# A test for XAO::Web
#
package testcases::Web;
use strict;
use XAO::Utils;
use XAO::Web;
use CGI;

use base qw(testcases::base);

sub test_all {
    my $self=shift;

    my $web=XAO::Web->new(sitename => 'test');
    $self->assert(ref($web),
                  "Can't create an instance of XAO::Web");

    my $cgi=CGI->new('foo=bar');

    $self->catch_stdout();
    $web->execute(path => '/index.html', cgi => $cgi);
    my $text=$self->get_stdout();
    #dprint "text='$text'";

    $self->assert(scalar($text =~ m/^Content-Type: text\/html/m),
                  "No Content-Type header returned");

    $self->assert(scalar($text =~ m/^Set-Cookie: .*test=INDEX/m),
                  "No Set-Cookie header returned");

    $self->assert(scalar($text =~ m/^TEST\[bar\]INDEX/m),
                  "No expected content returned");

}

1;
