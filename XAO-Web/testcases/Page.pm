package testcases::Page;
use strict;
use Encode;
use XAO::Objects;
use XAO::Utils;
use Error qw(:try);
use XAO::Errors qw(XAO::DO::Web::Page XAO::DO::Web::MyPage);

use base qw(testcases::base);

sub test_unicode_transparency {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    ##
    # Explanation: This is probably going to change in the future, but
    # for right now we assume that the template engine operates on
    # bytes, not characters. Thus we expect bytes back even when we
    # supply unicode.
    #
    # TODO: The better way is probably to define an encoding for input/output
    # text somewhere and always convert from that encoding to UTF and
    # back whenever we cross the border between templates and perl code.
    #
    my %tests=(
        t1  => {
            template    => "unicode - \x{263a} - ttt",
            expect      => Encode::encode('utf8',"unicode - \x{263a} - ttt"),
        },
        t2  => {
            template    => Encode::encode('utf8',"unicode - \x{263a} - ttt"),
            expect      => Encode::encode('utf8',"unicode - \x{263a} - ttt"),
        },
        t3  => {
            template    => Encode::encode('ucs2',"unicode - \x{263a} - ttt"),
            expect      => Encode::encode('ucs2',"unicode - \x{263a} - ttt"),
        },
        t4 => {
            template    => "8bit - \x90\x91\x92",
            expect      => "8bit - \x90\x91\x92",
        },
        t5 => {
            template    => '<%SetArg name="A" value="<$BAR/f$>"%>foo<$A$>',
            BAR         => "<\x{263a}>",
            expect      => Encode::encode('utf8',"foo<\x{263a}>"),
        },
    );

    foreach my $test (keys %tests) {
        my $template=$tests{$test}->{'template'};
        my $got=$page->expand($tests{$test});
        my $expect=$tests{$test}->{'expect'};
        ### dprint "length(template=$template)=".length($template);
        ### dprint "length(got=$got)=".length($got);
        ### dprint "length(expect=$expect)=".length($expect);
        $self->assert($got eq $expect,
                      "Test $test - expected '$expect', got '$got'");
    }
}

sub test_expand {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $str='\'"!@#$%^&*()_-=[]\<>? ';
    my %ttt=(
        '<%TEST%>'      => $str,
        '<%TEST/h%>'    => '\'"!@#$%^&amp;*()_-=[]\&lt;&gt;? ',
        '<%TEST/f%>'    => '\'&quot;!@#$%^&amp;*()_-=[]\&lt;&gt;? ',
        '<%TEST/q%>'    => '\'%22!@%23$%25^%26*()_-%3d[]\%3c%3e%3f%20',
        '<%TEST/u%>'    => '\'%22!@%23$%25^%26*()_-%3d[]\%3c%3e%3f%20',
    );
    foreach my $template (keys %ttt) {
        my $got=$page->expand(template => $template,
                              TEST => $str);
        $self->assert($got eq $ttt{$template},
                      "Wrong value for $template ('$got' ne '$ttt{$template}'");
    }

    my $got=$page->expand(path => '/system.txt',
                          TEST => 'TEST<>?');
    $self->assert($got eq 'system:[[TEST<>?][TEST&lt;&gt;?]]',
                  "Got wrong value for /system.txt: $got");

    $got=$page->expand(path => '/local.txt',
                       TEST => 'TEST<>?');
    $self->assert($got eq 'system:[[TEST<>?]{TEST&lt;&gt;?}]',
                  "Got wrong value for /local.txt: $got");

    my %matrix=(
        '123' => {
            template => q(<%Page
                            template={'<%Page template="<%TEST%>"%>'}
                            TEST='123'
                          %>),
        },
        '1234' => {
            template => q(<%Page
                            template={'<%Page template="<$TEST$>"%>'}
                            TEST='1234'
                          %>),
        },
    );
    foreach my $expect (keys %matrix) {
        my $args=$matrix{$expect};
        my $got=$page->expand($args);
        $self->assert($got eq $expect,
                      "Expected '$expect', got '$got'");
    }
}

sub test_fs {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $odb=$page->odb;
    $self->assert(ref($odb),
                  "Can't get database reference from Page");
}

sub test_web {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $cgi=$page->cgi;
    $self->assert(ref($cgi),
                  "Can't get CGI reference from Page");
}

sub test_end {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $got=$page->expand(template => 'AAA<%End%>BBB');
    my $expect='AAA';
    $self->assert($got eq $expect,
                  "<%End%> does not work, got '$got' instead of '$expect'");
}

sub test_throw {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::MyPage');
    $self->assert(ref($page),
                  "Can't load MyPage object");

    my $error='';
    try {
        $page->throw("test - test error");
        $error="not really throwed an error";
    }
    catch XAO::E::DO::Web::MyPage with {
        # Ok!
    }
    catch XAO::E::DO::Web::Page with {
        $error="caught E...Page instead of E...MyPage";
    }
    otherwise {
        my $e=shift;
        $error="cought some unknown error ($e) instead of expected E...MyPage";
    };

    $self->assert(!$error,
                  "Page::throw error - $error");
}

sub test_cache {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::MyPage');
    $self->assert(ref($page),
                  "Can't load MyPage object");

    my $cache_val=123;
    my $cache_sub=sub { return $cache_val++ };

    my $cache=$page->cache(
        name        => 'test',
        retrieve    => $cache_sub,
        coords      => 'name',
        expire      => 60,
    );
    $self->assert(ref($cache),
                  "Can't load Cache object");

    my $got=$cache->get(name => 'foo');
    $self->assert($got == 123,
                  "Wrong value from cache, expected 123, got $got");

    $got=$cache->get(name => 'foo');
    $self->assert($got == 123,
                  "Wrong value from cache, expected 123, got $got");

    my $page1=XAO::Objects->new(objname => 'Web::MyPage');
    $self->assert(ref($page),
                  "Can't load MyPage object");

     my $cache1=$page1->cache(
        name        => 'test',
        retrieve    => $cache_sub,
        coords      => 'name',
        expire      => 60,
    );
    $self->assert(ref($cache1),
                  "Can't load Cache object (Page1)");

    $got=$cache1->get(name => 'foo');
    $self->assert($got == 123,
                  "Wrong value from cache, expected 123, got $got");
}

1;
