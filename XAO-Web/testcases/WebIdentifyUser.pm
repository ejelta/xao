package testcases::WebIdentifyUser;
use strict;
use XAO::Utils;
use CGI::Cookie;
use Digest::MD5 qw(md5_base64);
use Error qw(:try);

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
        #
        # Should not destroy existing cookie even if it can't recognize
        # the user
        #
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
                    member_id   => 'm003',
                },
                text        => 'A',
            },
        },
        #
        # Should still be verified
        #
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
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        #
        # Adjusting the time and checking that verification expires, but
        # identification is still there.
        #
        t16     => {
            sub_pre => sub {
                $config->odb->fetch('/Members/m001')->put(verify_time => time - 125);
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
                    member_id   => 'm001',
                },
                text        => 'I',
            },
        },
        #
        # Checking what's passed to the templates
        #
        t20     => {
            args => {
                mode        => 'check',
                type        => 'member',
                'identified.template' => '<$CB_URI$>|<$ERRSTR$>|<$TYPE$>|<$NAME$>|<$VERIFIED$>',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => '/IdentifyUser/member||member|m001|',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/name'     => 'm001',
                    '/IdentifyUser/member/verified' => undef,
                },
            },
        },
        #
        # Checking case translation
        #
        t21     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'M001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/name'     => 'm001',
                },
                text        => 'V',
            },
        },
        t22     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/name'     => 'm001',
                },
                text        => 'V',
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
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'm001',
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                },
            },
        },
        t07     => {
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
                text        => 'I',
            },
        },
        t08     => {
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
        t09     => {
            sub_pre => sub {
                $cjar{member_key}=$cjar{member_key_1};
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => '0',
                },
                text        => 'A',
            },
        },
        t10     => {
            sub_pre => sub {
                $cjar{member_id}='m001',
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
        t05     => {
            sub_pre => sub {
                $config->put('/identify_user/member/id_cookie_type' => 'name');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'N3',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'n3',
                },
                clipboard   => {
                    '/IdentifyUser/member/id'   => 'm001',
                    '/IdentifyUser/member/name' => 'n3',
                },
                text        => 'V',
            },
        },
        t06     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'n3',
                },
                clipboard   => {
                    '/IdentifyUser/member/id'   => 'm001',
                    '/IdentifyUser/member/name' => 'n3',
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

sub test_key_list {
    my $self=shift;

    my $config=$self->siteconfig;
    $config->put(
        identify_user => {
            member => {
                list_uri            => '/Members',
                #
                id_cookie           => 'mid',
                #
                key_list_uri        => '/MemberKeys',
                key_ref_prop        => 'member_id',
                key_expire_prop     => 'expire_time',
                key_expire_mode     => 'auto',
                #
                pass_prop           => 'password',
                #
                vf_time_user_prop   => 'uvf_time',
                vf_time_prop        => 'verify_time',
                vf_expire_time      => 120,
                vf_key_cookie       => 'mkey',
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
                uvf_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
            },
        },
        MemberKeys => {
            type        => 'list',
            class       => 'Data::MemberNick',
            key         => 'member_key_id',
            key_format  => '<$AUTOINC$>',
            structure   => {
                member_id => {
                    type        => 'text',
                    maxlength   => 30,
                    index       => 1,
                },
                expire_time => {
                    type        => 'integer',
                    minvalue    => 0,
                    index       => 0,
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                    index       => 0,
                },
            },
        },
    );

    my $m_list=$config->odb->fetch('/Members');
    my $m_obj=$m_list->get_new;
    $m_obj->put(password => '12345');
    $m_list->put(m001 => $m_obj);
    $m_obj->put(password => '23456');
    $m_list->put(m002 => $m_obj);

    my %cjar;

    my %matrix=(
        t01     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002',
                password    => '12345',
            },
            results => {
                cookies     => {
                    mid         => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => 0,
                },
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
                    mid         => 'm001',
                    mkey        => '1',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '>'.(time-5),
                    '/MemberKeys/1/verify_time' => '>'.(time-5),
                    '/MemberKeys/1/expire_time' => '>'.(time+120-5),
                    '/MemberKeys/1/expire_time' => '<'.(time+120+5),
                },
            },
        },
        t03a     => {
            sub_pre => sub {
                $config->put('/identify_user/member/id_cookie_type' => 'id');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '1',
                },
                text        => 'V',
            },
        },
        t03b     => {
            cookies => {
                mkey        => 0,
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '2',
                },
                text        => 'V',
            },
        },
        t04     => {
            sub_pre => sub {
                $config->put('/identify_user/member/id_cookie_type' => 'key');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    mid         => '3',
                    mkey        => '2',
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/name'     => '3',
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => '1',
                },
            },
        },
        t05a     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '3',
                    mkey        => '2',
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/id'       => 'm001',
                    '/IdentifyUser/member/name'     => '3',
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => '1',
                },
            },
        },
        t05b    => {
            sub_post_cleanup => sub {
                my $user=$config->odb->fetch('/Members/m001');
                my $key=$config->odb->fetch('/MemberKeys/1');
                $config->clipboard->put('/IdentifyUser/member/object' => $user);
                $config->clipboard->put('/IdentifyUser/member/key_object' => $key);
                $config->clipboard->put('/IdentifyUser/member/name' => '1');
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/name'     => 1,
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => 1,
                },
                cookies     => {
                    mid     => 3,
                    mkey    => 2,
                },
            },
        },
        t06     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '3',
                    mkey        => '2',
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/id'       => 'm001',
                    '/IdentifyUser/member/name'     => '3',
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => '1',
                },
            },
        },
        t07     => {
            cookies => {
                mid         => 2,
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/id'       => 'm001',
                    '/IdentifyUser/member/name'     => '2',
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => '1',
                },
            },
        },
        t08     => {
            cookies => {
                mid         => 4,
                mkey        => 'FOO',
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '4',
                    mkey        => 'FOO',
                },
                text        => 'A',
                clipboard   => {
                    '/IdentifyUser/member/object'   => undef,
                    '/IdentifyUser/member/verified' => undef,
                },
            },
        },
        t09     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002',
                password    => '23456',
            },
            results => {
                cookies     => {
                    mid         => '4',
                    mkey        => 'FOO',
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/name'     => '4',
                },
            },
        },
        t10     => {
            cookies => {
                mid         => 1,
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '1',
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => 1,
                    '/IdentifyUser/member/name'     => 1,
                    '/IdentifyUser/member/id'       => 'm001',
                },
            },
        },
        t11     => {
            cookies => {
                mid         => 4,
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '4',
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => 1,
                    '/IdentifyUser/member/name'     => 4,
                    '/IdentifyUser/member/id'       => 'm002',
                },
            },
        },
        #
        # Logging out, but should stay identified as it was previously
        # logged in and verified.
        #
        t12     => {
            cookies => {
                mid         => 2,
            },
            args => {
                mode        => 'logout',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '2',
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => 2,
                    '/IdentifyUser/member/id'       => 'm001',
                },
            },
        },
        #
        # Checking that the other key is still verified (account from
        # another browser/computer).
        #
        t13     => {
            cookies => {
                mid         => 1,
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '1',
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => 1,
                    '/IdentifyUser/member/name'     => 1,
                    '/IdentifyUser/member/id'       => 'm001',
                },
            },
        },
        #
        # Checking that it is still identified after soft logout
        #
        t14     => {
            cookies => {
                mid         => 2,
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '2',
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => 2,
                    '/IdentifyUser/member/id'       => 'm001',
                },
            },
        },
        #
        # Checking hard logout
        #
        t15     => {
            cookies => {
                mid         => 1,
            },
            args => {
                mode        => 'logout',
                type        => 'member',
                hard_logout => 1,
            },
            results => {
                cookies     => {
                    mid         => '0',
                },
                text        => 'A',
                clipboard   => {
                    '/IdentifyUser/member/object'   => undef,
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => undef,
                    '/IdentifyUser/member/id'       => undef,
                },
                fs          => {
                    '/MemberKeys/1' => undef,
                },
            },
        },
        #
        # key '3' should still yeald verification even after hard logout
        # on 1.
        #
        t16     => {
            cookies => {
                mid         => 3,
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '3',
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => 1,
                    '/IdentifyUser/member/name'     => 3,
                    '/IdentifyUser/member/id'       => 'm001',
                },
            },
        },
        #
        # Checking timing out of sessions
        #
        t17 => {
            sub_pre => sub {
                $config->put('/identify_user/member/vf_expire_time' => 2);
                sleep(3);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '3',
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => 3,
                    '/IdentifyUser/member/id'       => 'm001',
                },
            },
        },
        #
        # Switching back to name mode and checking expiration again. It
        # should keep verification key by default and with
        # expire_mode='keep'.
        #
        t18a    => {
            sub_pre => sub {
                $config->put('/identify_user/member/id_cookie_type' => 'id');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002',
                password    => '23456',
            },
            results => {
                cookies     => {
                    mid         => 'm002',
                    mkey        => '5',
                },
                text        => 'V',
            },
        },
        t18b     => {
            sub_pre => sub {
                sleep(3);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm002',
                    mkey        => '5',
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => 'm002',
                },
            },
        },
        t18c     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm002',
                    mkey        => '5',
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => 'm002',
                },
            },
        },
        t18d   => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002',
                password    => '23456',
            },
            results => {
                cookies     => {
                    mid         => 'm002',
                    mkey        => '5',
                },
                text        => 'V',
            },
        },
        t18e => {
            sub_pre => sub {
                $config->put('/identify_user/member/expire_mode' => 'clean');
                sleep(3);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm002',
                    mkey        => '0',
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => 'm002',
                },
            },
        },
        t18f     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm002',
                    mkey        => '0',
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => 'm002',
                },
            },
        },
        t18g   => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002',
                password    => '23456',
            },
            results => {
                cookies     => {
                    mid         => 'm002',
                    mkey        => '6',
                },
                text        => 'V',
            },
        },
        #
        # In 'key' mode along with expire_mode='clean' even the
        # id_cookie should get cleared.
        #
        t19a    => {
            sub_pre => sub {
                $config->put('/identify_user/member/id_cookie_type' => 'key');
                $config->put('/identify_user/member/expire_mode' => 'clean');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                cookies     => {
                    mid         => '7',
                    mkey        => '6',
                },
                text        => 'V',
            },
        },
        t19b     => {
            sub_pre => sub {
                sleep(3);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => '0',
                    mkey        => '6',
                },
                text        => 'I',
                clipboard   => {
                    '/IdentifyUser/member/object'   => { },
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => '7',
                },
            },
        },
        t19c     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mkey        => '6',
                },
                text        => 'A',
                clipboard   => {
                    '/IdentifyUser/member/object'   => undef,
                    '/IdentifyUser/member/verified' => undef,
                    '/IdentifyUser/member/name'     => undef,
                },
            },
        },
    );

    $self->run_matrix(\%matrix,\%cjar);
}

###############################################################################

sub run_matrix {
    my ($self,$matrix,$cjar)=@_;

    my $config=$self->siteconfig;

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
            $cjar->{$cname}=$chash->{$cname};
        }
        $ENV{HTTP_COOKIE}=$cenv;
        $config->embedded('web')->cleanup;
        $config->embedded('web')->enable_special_access;
        $config->embedded('web')->cgi(CGI->new('foo=bar&bar=foo'));
        $config->embedded('web')->disable_special_access;

        if($tdata->{sub_post_cleanup}) {
            &{$tdata->{sub_post_cleanup}}();
        }

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
            next unless defined $cd;
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

        if(exists $results->{fs}) {
            my $odb=$config->odb;
            foreach my $uri (keys %{$results->{fs}}) {
                my $expect=$results->{fs}->{$uri};
                my $got;
                try {
                    $got=$odb->fetch($uri);
                }
                otherwise {
                    my $e=shift;
                    dprint "IGNORED(OK): $e";
                };
                if(!defined($expect)) {
                    $self->assert(!defined($got),
                                  "$tname - fs=$uri, expected nothing, got ".($got || ''));
                }
                elsif(!defined $got) {
                    $self->assert(0,
                                  "$tname - fs=$uri, expected $expect, got nothing");
                }
                elsif($expect =~ /^>(\d+)$/) {
                    $self->assert($got>$1,
                                  "$tname - fs=$uri, expected $expect, got $got");
                }
                elsif($expect =~ /^<(\d+)$/) {
                    my $val=$1;
                    $self->assert($got=~/^[\d\.]+$/ && $got<$val,
                                  "$tname - fs=$uri, expected $expect, got $got");
                }
                else {
                    $self->assert($got eq $expect,
                                  "$tname - fs=$uri, expected $expect, got $got");
                }
            }
        }
    }
}

###############################################################################
1;
