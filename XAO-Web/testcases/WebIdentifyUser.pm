package testcases::WebIdentifyUser;
use strict;
use XAO::Utils;
use CGI::Cookie;
use POSIX qw(mktime);
use Digest::MD5 qw(md5_base64);
use Error qw(:try);

use Data::Dumper;

use base qw(XAO::testcases::Web::base);

###############################################################################

sub test_fail_blocking {
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
                fail_max_count  => 3,                   # how many times allowed to fail
                fail_expire     => 2,                   # when to auto-expire failed status
                fail_time_prop  => 'failure_time',      # time of login failure
                fail_count_prop => 'failure_count',     # how many times failed
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
                    charset     => 'latin1',
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                verify_key => {
                    type        => 'text',
                    maxlength   => 20,
                    charset     => 'latin1',
                },
                failure_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                failure_count => {
                    type        => 'integer',
                    minvalue    => 0,
                    maxvalue    => 100,
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
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 1,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => undef,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        t03     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 2,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => undef,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        t04     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 3,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => undef,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        t05     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 4,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => 1,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        t06     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 4,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => 1,
                    '/IdentifyUser/member/fail_locked'              => 1,
                },
                text        => 'A',
            },
        },
        t07     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_locked'              => 1,
                },
                text        => 'A',
            },
        },
        # Success after failures expire
        t08     => {
            sub_pre => sub { sleep(4) },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'V',
            },
        },
        # Failing again, to see if counter drops to zero after success
        t09     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 1,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => undef,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        # Success after single failure
        t10     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'V',
            },
        },
        # failures, then success at the last moment
        t11     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 1,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => undef,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        t12     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 2,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => undef,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        t13     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => 'WRONG',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_count'               => 3,
                    '/IdentifyUser/member/fail_max_count'           => 3,
                    '/IdentifyUser/member/fail_max_count_reached'   => undef,
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'A',
            },
        },
        t14     => {
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/fail_locked'              => undef,
                },
                text        => 'V',
            },
        },
    );

    $self->run_matrix(\%matrix,\%cjar);
}

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
            key_charset => 'latin1',
            structure   => {
                password => {
                    type        => 'text',
                    maxlength   => 100,
                    charset     => 'latin1',
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
                    charset     => 'latin1',
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                verify_key => {
                    type        => 'text',
                    maxlength   => 20,
                    charset     => 'latin1',
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
                    member_key  => undef,
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
                    member_id   => undef,
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
                    member_id   => undef,
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
                            charset     => 'latin1',
                        },
                    },
                },
                password => {
                    type        => 'text',
                    maxlength   => 100,
                    charset     => 'latin1',
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                verify_key => {
                    type        => 'text',
                    maxlength   => 20,
                    charset     => 'latin1',
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
                username    => 'N3',        # Will break if collation is case-sensitive
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
                    charset     => 'latin1',
                },
                password => {
                    type        => 'text',
                    maxlength   => 100,
                    charset     => 'latin1',
                },
                verify_time => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                verify_key => {
                    type        => 'text',
                    maxlength   => 20,
                    charset     => 'latin1',
                },
                acc_type => {
                    type        => 'text',
                    charset     => 'latin1',
                    maxlength   => 10,
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
        acc_type    => 'web',
    );
    $m_list->put(m001 => $m_obj);

    $m_obj->put(
        email       => 'two@bar.org',
        password    => '12345',
        verify_time => 0,
        acc_type    => 'foo',
    );
    $m_list->put(m002foo => $m_obj);

    $m_obj->put(
        email       => 'two@bar.org',
        password    => '12345',
        verify_time => 0,
        acc_type    => 'web',
    );
    $m_list->put(m002web => $m_obj);

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
        t06     => {
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop' => undef);
                $config->put('/identify_user/member/alt_user_prop' => 'email');
            },
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
        #
        # Multiple user props
        #
        t10a    => {            # by email, single email, returning name
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
            },
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
        t10b     => {
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
        #
        t11a    => {            # by id, single email, returning name
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
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
        t11b     => {
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
        t12a    => {            # by email, single email, returning id
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'id');
            },
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
        t12b     => {
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
        t13a    => {            # by id, single email, returning id
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
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
                    member_id   => 'm001',
                },
                text        => 'V',
            },
        },
        t13b     => {
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
        t15a    => {            # by email, multi-email, no qualifier
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'two@bar.org',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm001',
                },
                text        => 'A',     # because this email is listed twice
            },
            ignore_stderr => 1,
        },
        #
        t16a    => {            # by id, multi-email, no qualifier
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002web',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'V',
            },
        },
        t16b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'V',
            },
        },
        #
        t17a    => {            # by id, multi-email, no qualifier
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002foo',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm002foo',
                },
                text        => 'V',
            },
        },
        t17b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm002foo',
                },
                text        => 'V',
            },
        },
        #
        t18a    => {            # by email, multi-email, with qualifier
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => [ 'acc_type','eq','web' ]);
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'TWO@bar.org',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'two@bar.org',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id   => 'two@bar.org',
                },
                text        => 'V',
            },
        },
        t18b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'two@bar.org',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id   => 'two@bar.org',
                },
                text        => 'V',
            },
        },
        #
        t19a    => {            # by email, multi-email, with qualifier
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'id');
                $config->put('/identify_user/member/user_condition' => [ 'acc_type','eq','web' ]);
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'two@BAR.ORG',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'two@bar.org',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'V',
            },
        },
        t19b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'two@bar.org',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'V',
            },
        },
        #
        t20a    => {            # by id, multi-email, with qualifier
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => [ 'acc_type','eq','web' ]);
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002web',
                password    => '12345',
            },
            results => {
                cookies     => {
                    member_id   => 'm002web',
                },
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'm002web',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                text        => 'V',
            },
        },
        t20b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'm002web',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'V',
            },
        },
        #
        t21a    => {            # by id, multi-email, with qualifier
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => [ 'acc_type','eq','web' ]);
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002foo',
                password    => '12345',
            },
            results => {
                text        => 'A',     # condition is not satisfied
            },
        },
        t21b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'I',     # identification from previous login
            },
        },
        #
        t22a    => {            # by id, multi-email, complex condition
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => [ [ 'email','ne','' ],'and', [ 'acc_type','ne','foo' ] ]);
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'two@bar.org',
                password    => '12345',
            },
            results => {
                text        => 'V',
            },
        },
        #
        t23a    => {            # by email, multi-email, multi-condition
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => {
                    email       => [ 'acc_type','eq','web' ],
                    member_id   => undef,
                });
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'two@BAR.ORG',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'two@bar.org',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id                       => 'two@bar.org',
                },
                text        => 'V',
            },
        },
        t23b     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'two@bar.org',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id                       => 'two@bar.org',
                },
                text        => 'V',     # identification from previous login
            },
        },
        t23c    => {            # failure
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => {
                    email       => [ 'acc_type','eq','web' ],
                    member_id   => undef,
                });
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002foo',
                password    => 'BADPW',
            },
            results => {
                text        => 'A',
            },
        },
        t23d    => {            # by id#1, multi-email, multi-condition
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => {
                    email       => [ 'acc_type','eq','web' ],
                    member_id   => undef,
                });
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002web',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'm002web',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'V',
            },
        },
        t23e     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'm002web',
                    '/IdentifyUser/member/id'       => 'm002web',
                },
                cookies     => {
                    member_id   => 'm002web',
                },
                text        => 'V',     # identification from previous login
            },
        },
        t23f    => {            # failure
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => {
                    email       => [ 'acc_type','eq','web' ],
                    member_id   => undef,
                });
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002foo',
                password    => 'BADPW',
            },
            results => {
                text        => 'A',
            },
        },
        t23g    => {            # by id#2, multi-email, multi-condition
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => {
                    email       => [ 'acc_type','eq','web' ],
                    member_id   => undef,
                });
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002foo',
                password    => '12345',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'm002foo',
                    '/IdentifyUser/member/id'       => 'm002foo',
                },
                cookies     => {
                    member_id   => 'm002foo',
                },
                text        => 'V',
            },
        },
        t23h     => {
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                clipboard   => {
                    '/IdentifyUser/member/name'     => 'm002foo',
                    '/IdentifyUser/member/id'       => 'm002foo',
                },
                cookies     => {
                    member_id   => 'm002foo',
                },
                text        => 'V',     # identification from previous login
            },
        },
        t23i    => {            # failure
            sub_pre => sub {
                $config->put('/identify_user/member/user_prop'      => [ 'email','member_id' ]);
                $config->put('/identify_user/member/alt_user_prop'  => undef);
                $config->put('/identify_user/member/id_cookie_type' => 'name');
                $config->put('/identify_user/member/user_condition' => {
                    email       => [ 'acc_type','eq','web' ],
                    member_id   => undef,
                });
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002foo',
                password    => 'BADPW',
            },
            results => {
                text        => 'A',
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
                vf_key_cookie       => 'mkey',
                vf_time_user_prop   => 'uvf_time',
                vf_time_prop        => 'verify_time',
                vf_expire_time      => 120,
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
                    charset     => 'latin1',
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
                    charset     => 'latin1',
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
    my %cjar_a;
    my %cjar_b;

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
                    mkey        => 1,       # ++mkey
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/1/verify_time' => '~NOW',
                    '/MemberKeys/1/expire_time' => '~NOW+120',
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
                    mkey        => 1,
                },
                text        => 'V',
            },
        },
        t03b     => {
            cookies => {
                mkey        => undef,
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
                    mkey        => 2,       # ++mkey
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
                    mid         => 3,       # ++mkey
                    mkey        => 2,       # from the previous test
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/cookie_value' => '3',
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/verified'     => 1,
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
                    mid         => 3,       # from the previous test
                    mkey        => 2,       # from the previous test
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/id'           => 'm001',
                    '/IdentifyUser/member/cookie_value' => '3',
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/verified'     => 1,
                },
            },
        },
        t05b    => {            # second call in the same session
            sub_post_cleanup => sub {
                my $user=$config->odb->fetch('/Members/m001');
                my $key=$config->odb->fetch('/MemberKeys/3');
                $config->clipboard->put('/IdentifyUser/member/object' => $user);
                $config->clipboard->put('/IdentifyUser/member/key_object' => $key);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/verified'     => 1,
                },
                cookies     => {
                    mid     => 3,       # from the previous test
                    mkey    => 2,       # from the previous test
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
                    mid         => 3,   # from the previous test
                    mkey        => 2,   # from the previous test
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/id'           => 'm001',
                    '/IdentifyUser/member/cookie_value' => '3',     # mkey
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/verified'     => 1,
                },
            },
        },
        t07     => {
            cookies => {
                mid         => 2,
                mkey        => 123,
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                text        => 'V',
                cookies     => {
                    mid         => 2,
                    mkey        => 123, # from what's given
                },
                clipboard   => {
                    '/IdentifyUser/member/id'           => 'm001',
                    '/IdentifyUser/member/cookie_value' => '2',
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/verified'     => 1,
                },
            },
        },
        t08     => {        # Providing invalid key
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
        t09     => {        # Second user login
            cookies => {
                mid         => 7,
                mkey        => 'FOO',
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm002',
                password    => '23456',
            },
            results => {
                cookies     => {
                    mid         => 4,
                    mkey        => 'FOO',   # Not changed because id_cookie_type==key
                },
                text        => 'V',
                clipboard   => {
                    '/IdentifyUser/member/cookie_value' => '4',
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
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/cookie_value' => 1,
                    '/IdentifyUser/member/id'           => 'm001',
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
                    mid         => undef,
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
                    mkey        => undef,
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
                    mkey        => undef,
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
                    mid         => undef,
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
        #
        # Checking extended expiration
        #
        t20a => {       # Non-extended login
            sub_pre => sub {
                $config->odb->fetch('/MemberKeys')->get_new->add_placeholder(
                    name        => 'extended',
                    type        => 'integer',
                    minvalue    => 0,
                    maxvalue    => 1,
                );

                $config->put('/identify_user/member/id_cookie_type'     => 'id');
                $config->put('/identify_user/member/vf_expire_time'     => 2);
                $config->put('/identify_user/member/vf_expire_ext_time' => 6);
                $config->put('/identify_user/member/key_expire_ext_prop'=> 'extended');
                $config->put('/identify_user/member/expire_mode'        => 'keep');
            },
            cookie_jar => \%cjar_a,
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
                extended    => 0,
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '8',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/8/verify_time' => '~NOW',
                    '/MemberKeys/8/expire_time' => '~NOW+2',
                    '/MemberKeys/8/extended'    => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t20b => {       # Extended login
            cookie_jar => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
                extended    => 1,
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '9',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/9/verify_time' => '~NOW',
                    '/MemberKeys/9/expire_time' => '~NOW+6',
                    '/MemberKeys/9/extended'    => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 1,
                },
            },
        },
        t21a => {       # Make sure 'extended' is still OFF after 'check'ing.
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '8',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/8/verify_time' => '~NOW',
                    '/MemberKeys/8/expire_time' => '~NOW+2',
                    '/MemberKeys/8/extended'    => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t21b => {       # Make sure 'extended' is still ON after 'check'ing.
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
                sleep(1);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '9',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/9/verify_time' => '~NOW',
                    '/MemberKeys/9/expire_time' => '~NOW+6',
                    '/MemberKeys/9/extended'    => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 1,
                },
            },
        },
        t22a => {       # Timing out non-extended key
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
                sleep(3);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-3',
                    '/MemberKeys/8/verify_time' => '~NOW-3',
                    '/MemberKeys/8/expire_time' => '~NOW-1',
                    '/MemberKeys/8/extended'    => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t22b => {       # Extended should not time out in 3 seconds
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '9',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/9/verify_time' => '~NOW',
                    '/MemberKeys/9/expire_time' => '~NOW+6',
                    '/MemberKeys/9/extended'    => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 1,
                },
            },
        },
        t23a => {       # No change, just rechecking non-extended key
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '8',     # depends on expire_mode=keep
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',  # from t22b
                    '/MemberKeys/8/verify_time' => '~NOW-3',
                    '/MemberKeys/8/expire_time' => '~NOW-1',
                    '/MemberKeys/8/extended'    => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t23b => {       # Expiring extended key
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
                sleep(7);
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '9',
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',
                    '/MemberKeys/9/verify_time' => '~NOW-7',
                    '/MemberKeys/9/expire_time' => '~NOW-1',
                    '/MemberKeys/9/extended'    => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 1,
                },
            },
        },
        t24a => {       # No change, just rechecking non-extended key
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '8',
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',  # from t22b
                    '/MemberKeys/8/verify_time' => '~NOW-10',
                    '/MemberKeys/8/expire_time' => '~NOW-8',
                    '/MemberKeys/8/extended'    => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t24b => {       # No change, just rechecking
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '9',
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',
                    '/MemberKeys/9/verify_time' => '~NOW-7',
                    '/MemberKeys/9/expire_time' => '~NOW-1',
                    '/MemberKeys/9/extended'    => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 1,
                },
            },
        },
        t25a => {       # "Soft" logout
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'logout',    # Default is "soft" logout, going to identified state
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => undef,
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',  # from t22b
                    '/MemberKeys/8/verify_time' => 0,
                    '/MemberKeys/8/expire_time' => '~NOW-8',
                    '/MemberKeys/8/extended'    => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t25b => {       # No change, just rechecking
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'logout',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => undef,
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',
                    '/MemberKeys/9/verify_time' => 0,
                    '/MemberKeys/9/expire_time' => '~NOW-1',
                    '/MemberKeys/9/extended'    => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t26a => {       # Checking after logging out
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => undef,
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',  # from t22b
                    '/MemberKeys/8/verify_time' => 0,
                    '/MemberKeys/8/expire_time' => '~NOW-8',
                    '/MemberKeys/8/extended'    => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t26b => {       # No change, just rechecking
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => undef,
                },
                text        => 'I',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',
                    '/MemberKeys/9/verify_time' => 0,
                    '/MemberKeys/9/expire_time' => '~NOW-1',
                    '/MemberKeys/9/extended'    => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t27a => {       # Hard logout
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'logout',
                type        => 'member',
                hard_logout => 1,
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',  # from t22a
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t27b => {       # No change, just rechecking
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'logout',
                type        => 'member',
                hard_logout => 1,
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t28a => {       # Check after hard logout
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',  # from t22a
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t28b => {       # No change, just rechecking
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW-7',
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t29a => {       # Login after hard logout
            sub_pre => sub {
            },
            cookie_jar => \%cjar_a,
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
                extended    => 0,
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '10',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/10/verify_time'=> '~NOW',
                    '/MemberKeys/10/expire_time'=> '~NOW+2',
                    '/MemberKeys/10/extended'   => 0,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 0,
                },
            },
        },
        t29b => {       # Extended login
            cookie_jar => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'login',
                type        => 'member',
                username    => 'm001',
                password    => '12345',
                extended    => 1,
            },
            results => {
                cookies     => {
                    mid         => 'm001',
                    mkey        => '11',
                },
                text        => 'V',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',
                    '/MemberKeys/11/verify_time'=> '~NOW',
                    '/MemberKeys/11/expire_time'=> '~NOW+6',
                    '/MemberKeys/11/extended'   => 1,
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => { },
                    '/IdentifyUser/member/key_object'   => { },
                    '/IdentifyUser/member/verified'     => 1,
                    '/IdentifyUser/member/name'         => 'm001',
                    '/IdentifyUser/member/extended'     => 1,
                },
            },
        },
        t30a => {       # Hard logout
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'logout',
                type        => 'member',
                hard_logout => 1,
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',  # from t29a
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t30b => {       # No change, just rechecking
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'logout',
                type        => 'member',
                hard_logout => 1,
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',  # from t29b
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t31a => {       # Check after hard logout
            cookie_jar      => \%cjar_a,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',  # from t29a
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
                },
            },
        },
        t31b => {       # No change, just rechecking
            cookie_jar      => \%cjar_b,
            sub_pre => sub {
            },
            args => {
                mode        => 'check',
                type        => 'member',
            },
            results => {
                cookies     => {
                    mid         => undef,
                    mkey        => undef,
                },
                text        => 'A',
                fs => {
                    '/Members/m001/uvf_time'    => '~NOW',  # from t29b
                },
                clipboard   => {
                    '/IdentifyUser/member/object'       => undef,
                    '/IdentifyUser/member/key_object'   => undef,
                    '/IdentifyUser/member/verified'     => undef,
                    '/IdentifyUser/member/name'         => undef,
                    '/IdentifyUser/member/extended'     => undef,
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

        my $rcjar=$tdata->{'cookie_jar'} || merge_refs($cjar,$tdata->{'cookies'});
        my $wcjar=$tdata->{'cookie_jar'} || $cjar;

        my $cenv='';
        foreach my $cname (keys %$rcjar) {
            next unless defined $rcjar->{$cname};
            $cenv.='; ' if length($cenv);
            $cenv.="$cname=$rcjar->{$cname}";
            $wcjar->{$cname}=$rcjar->{$cname};
        }

        ### dprint "..cookies: $cenv";

        $ENV{'HTTP_COOKIE'}=$cenv;

        $config->embedded('web')->cleanup;
        $config->embedded('web')->enable_special_access;
        $config->embedded('web')->cgi(CGI->new('foo=bar&bar=foo'));
        $config->embedded('web')->disable_special_access;

        if($tdata->{sub_post_cleanup}) {
            &{$tdata->{sub_post_cleanup}}();
        }

        $self->catch_stderr() if $tdata->{'ignore_stderr'};

        my $iu=XAO::Objects->new(objname => 'Web::IdentifyUser');
        my $got=$iu->expand({
            'anonymous.template'    => 'A',
            'identified.template'   => 'I',
            'verified.template'     => 'V',
        },$tdata->{args});

        if($tdata->{'ignore_stderr'}) {
            my $stderr=$self->get_stderr();
            dprint "IGNORED(OK-STDERR): $stderr";
        }

        my $results=$tdata->{results};
        if(exists $results->{text}) {
            $self->assert($got eq $results->{text},
                          "$tname - expected '$results->{text}', got '$got'");
        }

        foreach my $cd (@{$config->cookies}) {
            next unless defined $cd;

            my $expires_text=$cd->expires;

            $self->assert($expires_text =~ /(\d{2})\W+([a-z]{3})\W+(\d{4})\W+(\d{2})\W+(\d{2})\W+(\d{2})/i,
                "Invalid cookie expiration '".$expires_text." for name '".$cd->name."' value '".$cd->value."'");

            my $midx=index('janfebmaraprmayjunjulaugsepoctnovdev',lc($2));
            $self->assert($midx>=0,
                "Invalid month '$2' in cookie '".$cd->name."' expiration '".$expires_text."'");

            my $expires=mktime($6,$5,$4,$1,$midx/3,$3-1900);

            ### dprint "...cookie name='".$cd->name."' value='".$cd->value." expires=".$expires_text." (".localtime($expires)." - ".($expires<=time ? 'EXPIRED' : 'ACTIVE').")";

            if($expires <= time) {
                $wcjar->{$cd->name}=undef;
            }
            else {
                $wcjar->{$cd->name}=$cd->value;
            }
        }

        if(exists $results->{cookies}) {
            foreach my $cname (keys %{$results->{cookies}}) {
                my $expect=$results->{cookies}->{$cname};
                if(defined $expect) {
                    $self->assert(defined($wcjar->{$cname}),
                                  "$tname - cookie=$cname, expected $expect, got nothing");
                    $self->assert($wcjar->{$cname} eq $expect,
                                  "$tname - cookie=$cname, expected $expect, got $wcjar->{$cname}");
                }
                else {
                    $self->assert(!defined($wcjar->{$cname}),
                                  "$tname - cookie=$cname, expected nothing, got ".($wcjar->{$cname} || ''));
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

        my $parseval=sub($) {
            my $t=shift;
            if   ($t=~/^NOW\+(\d+)$/) { return time+$1; }
            elsif($t=~/^NOW-(\d+)$/)  { return time-$1; }
            elsif($t=~/^NOW$/)        { return time; }
            elsif($t=~/^\d+$/)        { return $t; }
            else { $self->assert(0,"Unparsable constant '$t'"); }
        };

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
                elsif($expect =~ /^>(.*)$/) {
                    my $val=$parseval->($1);
                    $self->assert($got>$val,
                                  "$tname - fs=$uri, expected $expect ($val), got $got");
                }
                elsif($expect =~ /^<(.*)$/) {
                    my $val=$parseval->($1);
                    $self->assert($got=~/^[\d\.]+$/ && $got<$val,
                                  "$tname - fs=$uri, expected $expect ($val), got $got");
                }
                elsif($expect =~ /^~(.*)$/) {
                    my $val=$parseval->($1);
                    $self->assert($got=~/^[\d\.]+$/ && $got>=$val-2 && $got<=$val+2,
                                  "$tname - fs=$uri, expected $expect ($val+/-2), got $got");
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
