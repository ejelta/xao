package testcases::Page;
use strict;
use Encode;
use XAO::Objects;
use XAO::Utils;
use Error qw(:try);
use XAO::Errors qw(XAO::DO::Web::Page XAO::DO::Web::MyPage);

use base qw(XAO::testcases::Web::base);

###############################################################################

sub test_cgi_param_charsets {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $cgi=$page->cgi;
    $self->assert(ref($cgi),
                  "Can't get page->cgi");

    $self->assert($cgi->isa('XAO::DO::CGI'),
                  "Expected CGI to be XAO::DO::CGI, got ".ref($cgi));

    $self->assert($cgi->get_param_charset eq 'UTF-8',
                  "Expected cgi->get_param_charset to return 'UTF-8', got '".($cgi->get_param_charset || '<UNDEF>')."'");

    my $ucode=$cgi->param('ucode');
    $self->assert($ucode ne '',
                  "Expected to have a ucode param from base.pm");

    $self->assert(Encode::is_utf8($ucode),
                  "Expected ucode to be perl UTF-8");

    my %tests=(
        t1  => {
            name        => 'ucode',
            expect      => 'unicode',
        },
        t2  => {
            name        => 'foo',
            expect      => 'unicode',
        },
        t3  => {
            name        => 'ucode',
            expect      => 'data',
            no_charset  => 1,
        },
        t4  => {
            name        => 'foo',
            expect      => 'data',
            no_charset  => 1,
        },
    );

    foreach my $tname (keys %tests) {
        my $test=$tests{$tname};
        my $template="<\%Unicode name='$test->{name}'%>";

        my $got;
        if($test->{'no_charset'}) {
            my $c=$page->cgi->set_param_charset(undef);
            $got=$page->expand(template => $template);
            $page->cgi->set_param_charset($c);
        }
        else {
            $got=$page->expand(template => $template);
        }

        my $expect=$test->{'expect'};
        $self->assert($got eq $expect,
                      "Test $tname - expected '$expect', got '$got'");
    }
}

###############################################################################

sub test_pass {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $template_simple=<<'EOT';
<%Page
  template={'<%SetArg name='FOO' value='IN'%><$FOO$>'}
  pass
%><%End%>
EOT

    my $template_star=<<'EOT';
<%Page
  template={'<%SetArg name='FOO' value='IN'%><$FOO$>'}
  pass='*'
%><%End%>
EOT

    my $template_map=<<'EOT';
<%Page
  template={'<%SetArg name='VAR' value='DEFAULT'%><$VAR$>'}
  pass="VAR=<$VARNAME$>"
%><%End%>
EOT

    my $template_map2=<<'EOT';
<%Page
  template={'<%SetArg name='VAR' value='DEFAULT'
             %><%SetArg name='VAR.ONE' value='DEFAULT.ONE'
             %><%SetArg name='VAR.TWO' value='DEFAULT.TWO'
             %><%SetArg name='OUTSIDE' value='DEFAULT-OUTSIDE'
             %><$VAR$>/<$VAR.ONE$>/<$VAR.TWO$>/<$OUTSIDE$>'}
  pass="<$PASS$>"
%><%End%>
EOT

    my %tests=(
###        t01 => {
###            args        => {
###                template    => $template_simple,
###            },
###            expect      => 'IN',
###        },
###        t02 => {
###            args        => {
###                template    => $template_simple,
###                FOO         => 'OUT',
###            },
###            expect      => 'OUT',
###        },
###        t03 => {
###            args        => {
###                template    => $template_star,
###            },
###            expect      => 'IN',
###        },
###        t04 => {
###            args        => {
###                template    => $template_star,
###                FOO         => 'OUT',
###            },
###            expect      => 'OUT',
###        },
###        t10 => {
###            args        => {
###                template    => $template_map,
###                FOO         => 'FOOVALUE',
###                BAR         => 'BARVALUE',
###                VARNAME     => 'FOO',
###            },
###            expect      => 'FOOVALUE',
###        },
###        t11 => {
###            args        => {
###                template    => $template_map,
###                FOO         => 'FOOVALUE',
###                BAR         => 'BARVALUE',
###                VARNAME     => 'BAR',
###            },
###            expect      => 'BARVALUE',
###        },
###        t12 => {
###            args        => {
###                template    => $template_map,
###                FOO         => 'FOOVALUE',
###                BAR         => 'BARVALUE',
###                VARNAME     => 'NONEXIST',
###            },
###            expect      => 'DEFAULT',
###        },
        t20 => {
            args        => {
                template    => $template_map2,
                'PASS'      => 'VAR=FOO;VAR.*=BAR.*',
                'FOO'       => 'FOOVALUE',
                'FOO.ONE'   => 'FOO.ONEVALUE',
                'FOO.TWO'   => 'FOO.TWOVALUE',
                'BAR'       => 'BARVALUE',
                'BAR.ONE'   => 'BAR.ONEVALUE',
                'BAR.TWO'   => 'BAR.TWOVALUE',
            },
            expect      => 'FOOVALUE/BAR.ONEVALUE/BAR.TWOVALUE/DEFAULT-OUTSIDE',
        },
        t21 => {
            args        => {
                template    => $template_map2,
                'PASS'      => 'VAR = FOO ; VAR.*=BAR.* ;*',        # * after
                'FOO'       => 'FOOVALUE',
                'FOO.ONE'   => 'FOO.ONEVALUE',
                'FOO.TWO'   => 'FOO.TWOVALUE',
                'BAR'       => 'BARVALUE',
                'BAR.ONE'   => 'BAR.ONEVALUE',
                'BAR.TWO'   => 'BAR.TWOVALUE',
            },
            expect      => 'FOOVALUE/BAR.ONEVALUE/BAR.TWOVALUE/DEFAULT-OUTSIDE',
        },
        t22 => {
            args        => {
                template    => $template_map2,
                'PASS'      => '*;  VAR = FOO ;VAR.*=  BAR.* ; ;',        # * before
                'FOO'       => 'FOOVALUE',
                'FOO.ONE'   => 'FOO.ONEVALUE',
                'FOO.TWO'   => 'FOO.TWOVALUE',
                'BAR'       => 'BARVALUE',
                'BAR.ONE'   => 'BAR.ONEVALUE',
                'BAR.TWO'   => 'BAR.TWOVALUE',
                'OUTSIDE'   => 'OUT-VALUE',
            },
            expect      => 'FOOVALUE/BAR.ONEVALUE/BAR.TWOVALUE/OUT-VALUE',
        },
        t23 => {
            args        => {
                template    => $template_map2,
                'PASS'      => '*; VAR=FOO; !OUTSIDE;',
                'FOO'       => 'FOOVALUE',
                'VAR.ONE'   => 'FOO.ONEVALUE',
                'OUTSIDE'   => 'OUT-VALUE',
            },
            expect      => 'FOOVALUE/FOO.ONEVALUE/DEFAULT.TWO/DEFAULT-OUTSIDE',
        },
        t24 => {
            args        => {
                template    => $template_map2,
                'PASS'      => '*; VAR=FOO; !OUTSIDE; !VAR.*',
                'FOO'       => 'FOOVALUE',
                'VAR.ONE'   => 'FOO.ONEVALUE',
                'VAR.TWO'   => 'FOO.TWOVALUE',
                'OUTSIDE'   => 'OUT-VALUE',
            },
            expect      => 'FOOVALUE/DEFAULT.ONE/DEFAULT.TWO/DEFAULT-OUTSIDE',
        },
        t25 => {
            args        => {
                template    => $template_map2,
                'PASS'      => '*; VAR.*=FOO.*; !VAR.T*',
                'FOO'       => 'FOOVALUE',
                'VAR.ONE'   => 'FOO.ONEVALUE',
                'VAR.TWO'   => 'FOO.TWOVALUE',
                'OUTSIDE'   => 'OUT-VALUE',
            },
            expect      => 'DEFAULT/FOO.ONEVALUE/DEFAULT.TWO/OUT-VALUE',
        },
    );

    foreach my $tname (keys %tests) {
        my $args=$tests{$tname}->{'args'};

        my $got=$page->expand($args);
        my $expect=$tests{$tname}->{'expect'};

        $self->assert($got eq $expect,
                      "In test '$tname' expected '$expect', got '$got'");
    }
}

###############################################################################

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

    my $str='\'"!@#$%^&*()_-=[]\\<>? ';
    my %ttt=(
        '<$TEST$>'      => $str,
        '<$TEST/h$>'    => '\'"!@#$%^&amp;*()_-=[]\\&lt;&gt;? ',
        '<$TEST/f$>'    => '\'&quot;!@#$%^&amp;*()_-=[]\\&lt;&gt;? ',
        '<$TEST/q$>'    => '\'%22!@%23$%25^%26*()_-%3d[]\\%3c%3e%3f%20',
        '<$TEST/u$>'    => '\'%22!@%23$%25^%26*()_-%3d[]\\%3c%3e%3f%20',
        '<$TEST/j$>'    => '\\\'\\"!@#$%^&*()_-=[]\\\\<>? ',
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

###############################################################################
1;
