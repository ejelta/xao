package testcases::WebIdentifyUser;
use strict;
use XAO::Utils;
use CGI::Cookie;
use Digest::MD5 qw(md5_base64);

use Data::Dumper;

use base qw(testcases::base);

###############################################################################

sub test_no_vf_key {
    my $self=shift;

    my $config=$self->siteconfig;
    $config->put(
        identify_user => {
            member => {
                list_uri        => '/Members',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
            },
        },
    );

    $self->assert($config->get('/identify_user/member/list_uri') eq '/Members',
                  "Can't get configuration parameter");

    my $odb=$config->odb;
    $odb->fetch('/')->build_structure(
        Members => {
            type        => 'list',
            class       => 'Data::Member1',
            key         => 'member_id',
            structure   => {
                password => {
                    type        => 'text',
                    maxlength   => 100,
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
            },
        },
    );

    my $m_list=$config->odb->fetch('/Members');
    my $m_obj=$m_list->get_new;
    $m_obj->put(
        password    => '12345',
        verify_time => 0,
    );
    $m_list->put(m001 => $m_obj);

    my %cjar;

    my %matrix=(
        t01     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12346',
            },
            results => {
                cookies     => {
                    member_id   => undef,
                },
                text        => 'A',
            },
        },

        t02     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },

        t03     => {
            sub_pre => sub {
                $m_list->get('m001')->put(password => 'qqqqq');
                $config->put('/identify_user/member/pass_encrypt','plaintext');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'A',
            },
        },

        t10     => {
            sub_pre => sub {
                $m_list->get('m001')->put(password => md5_base64('12345'));
                $config->put('/identify_user/member/pass_encrypt','md5');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },

        t11     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'A',
            },
        },

        t12     => {
            sub_pre => sub {
                delete $cjar{member_id};
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm003',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => undef,
                },
                text        => 'A',
            },
        },

        t13     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => undef,
                },
                text        => 'A',
            },
        },

        t14     => {
            cookies => {
                member_id   => 'm003',
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => undef,
                },
                text        => 'A',
            },
        },

        t15     => {
            cookies => {
                member_id   => 'm001',
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => undef,
                },
                text        => 'V',
            },
        },

        t16     => {
            sub_pre => sub {
                $config->odb->fetch('/Members/m001')->put(verify_time => time - 1111);
            },
            cookies => {
                member_id   => 'm001',
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => undef,
                },
                text        => 'I',
            },
        },

        t20     => {
            args => {
                mode        => 'check',
                type        => 'member',
                'identified.template' => '<$CB_URI$>|<$ERRSTR$>|<$TYPE$>|<$NAME$>|<$VERIFIED$>',
            },
            cookies => {
                member_id   => 'm001',
            },
            results => {
                cookies     => {
                    member_id   => undef,
                },
                text        => '/IdentifyUser/member||member|m001|',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/name'     => 'm001',
                    '/IdentifyUser/member/verified' => undef,
                },
            },
        },
    );

    $self->run_matrix(\%matrix,\%cjar);
}

###############################################################################

sub test_vf_key_simple {
    my $self=shift;

    my $config=$self->siteconfig;
    $config->put(
        identify_user => {
            member => {
                list_uri        => '/Members',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
                vf_key_cookie   => 'member_key',
                vf_key_prop     => 'verify_key',
            },
        },
    );

    $self->assert($config->get('/identify_user/member/list_uri') eq '/Members',
                  "Can't get configuration parameter");

    my $odb=$config->odb;
    $odb->fetch('/')->build_structure(
        Members => {
            type        => 'list',
            class       => 'Data::Member1',
            key         => 'member_id',
            structure   => {
                password => {
                    type        => 'text',
                    maxlength   => 100,
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                verify_key => {
                    type        => 'text',
                    maxlength   => 20,
                },
            },
        },
    );

    my $m_list=$config->odb->fetch('/Members');
    my $m_obj=$m_list->get_new;
    $m_obj->put(
        password    => '12345',
        verify_time => 0,
    );
    $m_list->put(m001 => $m_obj);

    my %cjar;

    my %matrix=(
        t01     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        t02     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        t03     => {
            sub_pre => sub {
                $cjar{member_key_1}=$cjar{member_key};
                delete $cjar{member_key};
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'I',
            },
        },
        t04     => {
            sub_pre => sub {
                $cjar{member_key}='1234';
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'I',
            },
        },
        t05     => {
            sub_pre => sub {
                $cjar{member_key}=$cjar{member_key_1};
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        t06     => {
            args => {
                mode        => 'logout',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                    member_key  => 0,
                },
                text        => 'I',
            },
        },
        t07     => {
            args => {
                mode        => 'logout',
                type        => 'member',
                hard_logout => 1,
            },
            results => {
                cookies     => {
                    member_id   => 0,
                },
                text        => 'A',
            },
        },
    );

    $self->run_matrix(\%matrix,\%cjar);
}

###############################################################################

sub test_user_prop_list {
    my $self=shift;

    my $config=$self->siteconfig;
    $config->put(
        identify_user => {
            member => {
                list_uri        => '/Members',
                user_prop       => 'Nicknames/nickname',
                id_cookie_type  => 'name',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
                vf_key_cookie   => 'member_key',
                vf_key_prop     => 'verify_key',
            },
        },
    );

    $self->assert($config->get('/identify_user/member/list_uri') eq '/Members',
                  "Can't get configuration parameter");

    my $odb=$config->odb;
    $odb->fetch('/')->build_structure(
        Members => {
            type        => 'list',
            class       => 'Data::Member1',
            key         => 'member_id',
            structure   => {
                Nicknames => {
                    type        => 'list',
                    class       => 'Data::MemberNick',
                    key         => 'nickname_id',
                    structure   => {
                        nickname => {
                            type        => 'text',
                            maxlength   => '50',
                            index       => 1,
                            unique      => 1,
                        },
                    },
                },
                password => {
                    type        => 'text',
                    maxlength   => 100,
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                verify_key => {
                    type        => 'text',
                    maxlength   => 20,
                },
            },
        },
    );

    my $m_list=$config->odb->fetch('/Members');
    my $m_obj=$m_list->get_new;
    $m_obj->put(
        password    => '12345',
        verify_time => 0,
    );
    $m_list->put(m001 => $m_obj);
    my $n_list=$m_list->get('m001')->get('Nicknames');
    my $n_obj=$n_list->get_new;
    $n_obj->put(nickname    => 'n1');
    $n_list->put(id1 => $n_obj);
    $n_obj->put(nickname    => 'n2');
    $n_list->put(id2 => $n_obj);
    $n_obj->put(nickname    => 'n3');
    $n_list->put(id3 => $n_obj);

    my %cjar;

    my %matrix=(
        t01     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'n1',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'n1',
                },
                text        => 'V',
            },
        },
        t02     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'n4',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'n1',
                },
                text        => 'A',
            },
        },
        t03     => {
            sub_pre => sub {
                $config->put('/identify_user/member/id_cookie_type' => 'id');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'n2',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001/id2',
                },
                text        => 'V',
            },
        },
        t04     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001/id2',
                },
                text        => 'V',
            },
        },
    );

    $self->run_matrix(\%matrix,\%cjar);
}

###############################################################################

sub test_user_prop_hash {
    my $self=shift;

    my $config=$self->siteconfig;
    $config->put(
        identify_user => {
            member => {
                list_uri        => '/Members',
                user_prop       => 'email',
                id_cookie       => 'member_id',
                pass_prop       => 'password',
                vf_time_prop    => 'verify_time',
                vf_expire_time  => 120,
                vf_key_cookie   => 'member_key',
                vf_key_prop     => 'verify_key',
            },
        },
    );

    $self->assert($config->get('/identify_user/member/list_uri') eq '/Members',
                  "Can't get configuration parameter");

    my $odb=$config->odb;
    $odb->fetch('/')->build_structure(
        Members => {
            type        => 'list',
            class       => 'Data::Member1',
            key         => 'member_id',
            structure   => {
                email => {
                    type        => 'text',
                    maxlength   => 100,
                    unique      => 1,
                },
                password => {
                    type        => 'text',
                    maxlength   => 100,
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                verify_key => {
                    type        => 'text',
                    maxlength   => 20,
                },
            },
        },
    );

    my $m_list=$config->odb->fetch('/Members');
    my $m_obj=$m_list->get_new;
    $m_obj->put(
        email       => 'foo@bar.org',
        password    => '12345',
        verify_time => 0,
    );
    $m_list->put(m001 => $m_obj);

    my %cjar;

    my %matrix=(
        t01     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => undef,
                },
                text        => 'A',
            },
        },
        t02     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'foo@bar.org',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'foo@bar.org',
                },
                text        => 'V',
            },
        },
        t03     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'foo@bar.org',
                },
                text        => 'V',
            },
        },
        t04     => {
            sub_pre => sub {
                $config->put('/identify_user/member/id_cookie_type' => 'id');
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'foo@bar.org',
                },
                text        => 'A',
            },
        },
        t05     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'foo@bar.org',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
    );

    $self->run_matrix(\%matrix,\%cjar);
}

###############################################################################

sub run_matrix {
    my ($self,$matrix,$cjar)=@_;

    my $config=$self->siteconfig;
    my $odb=$config->odb;

    foreach my $tname (sort keys %$matrix) {
        dprint "TEST $tname";
        my $tdata=$matrix->{$tname};

        if($tdata->{sub_pre}) {
            &{$tdata->{sub_pre}}();
        }

        my $chash=merge_refs($cjar,$tdata->{cookies});
        my $cenv='';
        foreach my $cname (keys %$chash) {
            $cenv.='; ' if length($cenv);
            $cenv.="$cname=$chash->{$cname}";
            dprint "CENV: $cenv";
        }
        $ENV{HTTP_COOKIE}=$cenv;
        $config->embedded('web')->cleanup;
        $config->embedded('web')->enable_special_access;
        $config->embedded('web')->cgi(CGI->new('foo=bar&bar=foo'));
        $config->embedded('web')->disable_special_access;

        my $iu=XAO::Objects->new(objname => 'Web::IdentifyUser');
        my $got=$iu->expand({
            'anonymous.template'    => 'A',
            'identified.template'   => 'I',
            'verified.template'     => 'V',
        },$tdata->{args});

        my $results=$tdata->{results};
        if(exists $results->{text}) {
            $self->assert($got eq $results->{text},
                          "$tname - expected '$results->{text}', got '$got'");
        }

        foreach my $cd (@{$config->cookies}) {
            $cjar->{$cd->name}=$cd->value;
        }

        if(exists $results->{cookies}) {
            foreach my $cname (keys %{$results->{cookies}}) {
                my $expect=$results->{cookies}->{$cname};
                if(defined $expect) {
                    $self->assert(defined($cjar->{$cname}),
                                  "$tname - cookie=$cname, expected $expect, got nothing");
                    $self->assert($cjar->{$cname} eq $expect,
                                  "$tname - cookie=$cname, expected $expect, got $cjar->{$cname}");
                }
                else {
                    $self->assert(!defined($cjar->{$cname}),
                                  "$tname - cookie=$cname, expected nothing, got ".($cjar->{$cname} || ''));
                }
            }
        }

        if(exists $results->{clipboard}) {
            my $cb=$config->clipboard;
            foreach my $cname (keys %{$results->{clipboard}}) {
                my $expect=$results->{clipboard}->{$cname};
                my $got=$cb->get($cname);
                if(defined $expect) {
                    $self->assert(defined($got),
                                  "$tname - clipboard=$cname, expected $expect, got nothing");
                    if(ref($expect)) {
                        $self->assert(ref($got),
                                      "$tname - clipboard=$cname, expected a ref, got $got");
                    }
                    else {
                        $self->assert($got eq $expect,
                                      "$tname - clipboard=$cname, expected $expect, got $got");
                    }
                }
                else {
                    $self->assert(!defined($got),
                                  "$tname - clipboard=$cname, expected nothing, got ".($got || ''));
                }
            }
        }
    }
}

###############################################################################
1;
