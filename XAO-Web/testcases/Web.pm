# A test for XAO::Web
#
package testcases::Web;
use strict;
use XAO::Utils;
use XAO::Web;
use XAO::Objects;

use base qw(testcases::base);

###############################################################################

sub test_all {
    my $self=shift;

    my $web=XAO::Web->new(sitename => 'test');
    $self->assert(ref($web),
                  "Can't create an instance of XAO::Web");

    my $cgi=XAO::Objects->new(objname => 'CGI', query => 'foo=bar');

    $self->catch_stdout();
    $web->execute(path => '/index.html', cgi => $cgi);
    my $text=$self->get_stdout();

    $self->assert(scalar($text =~ m/^Content-Type: text\/html/m),
                  "No Content-Type header returned");

    $self->assert(scalar($text =~ m/^Set-Cookie: .*test=INDEX/m),
                  "No Set-Cookie header returned");

    $self->assert(scalar($text =~ m/^TEST\[bar\]INDEX/m),
                  "No expected content returned");

}

###############################################################################

sub test_urlstyle_raw {
    my $self=shift;

    my $web=XAO::Web->new(sitename => 'test');
    $self->assert(ref($web),
                  "Can't create an instance of XAO::Web");

    my $cgi=XAO::Objects->new(objname => 'CGI', query => 'foo=bar');

    $self->catch_stdout();
    $web->execute(path => '/raw', cgi => $cgi);
    my $text=$self->get_stdout();
    $self->assert(scalar($text =~ m/^Content-Type: text\/html/m),
                  "No Content-Type header returned");
    $self->assert(scalar($text =~ m/^RAWFILE/m),
                  "No expected content returned");

    $self->catch_stdout();
    $web->execute(path => '/rawobj', cgi => $cgi);
    $text=$self->get_stdout();
    $self->assert(scalar($text !~ m/^Location:\s+(.*?)[\r\n\s]+/m),
                  "Should not have redirected (".($1 || '').") for /rawobj");
    $self->assert(scalar($text =~ m/^Content-Type: text\/html/m),
                  "No Content-Type header returned");
    $self->assert(scalar($text =~ m/^RAWOBJ/m),
                  "No expected content returned");

    $self->catch_stdout();
    $web->execute(path => '/filesobj', cgi => $cgi);
    $text=$self->get_stdout();
    $self->assert(scalar($text =~ m/^Location:\s+http:\/\/xao.com\/filesobj\//m),
                  "Should have redirected for /filesobj");
    $self->assert(scalar($text =~ m/^Content-Type: text\/html/m),
                  "No Content-Type header returned");
}

###############################################################################
1;
