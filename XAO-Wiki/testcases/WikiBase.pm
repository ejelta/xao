package testcases::WikiBase;
use strict;
use XAO::Utils;
use XAO::Objects;
use Data::Dumper;

use base qw(XAO::testcases::Web::base);

###############################################################################

sub test_interface {
    my $self=shift;

    my $wiki=XAO::Objects->new(objname => 'Wiki::Base');
    $self->assert($wiki && ref $wiki,
                  "Can't get Wiki::Base object");

    my @public_methods=qw(
        build_structure
        data_structure
        parse
        parse_params_update
        render_html
        render_html_header
        render_html_link
        render_html_methods_map
        render_html_text
        retrieve
        revisions
        store
    );

    foreach my $method (@public_methods) {
        my $mcode=$wiki->can($method);
        $self->assert($mcode && ref($mcode) eq 'CODE',
                      "Expected Wiki::Base to have '$method' method");
    }
}

###############################################################################

sub test_render_html {
    my $self=shift;

    my $content=<<'EOT';
= Header 1 =
Some text with a {{curly}} in it
== Header 2 ==
Some other text, first paragraph.

Second paragraph with a [[link]] in it.
EOT

    my $wiki=XAO::Objects->new(objname => 'Wiki::Render1');

    my $html=$wiki->render_html(
        content     => $content,
    );

    my $expect='<HEADER-1><CURLY><HEADER-2><LINK>';
    $self->assert($html eq $expect,
                  "Wiki::Render1 - expected '$expect', got '$html'");
}
 
###############################################################################

sub test_storage {
    my $self=shift;

    my $wiki=XAO::Objects->new(objname => 'Wiki::Base');
    $self->assert($wiki && ref $wiki,
                  "Can't get Wiki::Base object");

    my %ds=$wiki->data_structure;
    $self->assert(scalar(%ds),
                  "Wiki::Base::data_structure failed");
    $self->assert($ds{'Wiki'} && $ds{'Wiki'}->{'class'} eq 'Data::Wiki',
                  "Expected to have /Wiki in the structure definition");
    $self->assert($ds{'Wiki'}->{'structure'}->{'Revisions'} && $ds{'Wiki'}->{'structure'}->{'Revisions'}->{'class'} eq 'Data::WikiRevision',
                  "Expected to have /Wiki/Revisions in the structure definition");
                
    $wiki->build_structure;

    my $odb=$self->siteconfig->odb;
    $self->assert($odb->fetch('/')->exists('Wiki'),
                  "No /Wiki in the database after build_structure");

    my $content=<<EOT;
= Header Text =
Some text with a [[link]].
EOT

    my $now=time-2;     # to see if the store method takes it or assigns its own

    my $member_id='foo';
    my $comment='Initial Comment';

    $odb->transact_begin;
    my $wiki_id=$wiki->store(
        content         => $content,
        edit_comment    => $comment,
        edit_member_id  => $member_id,
        edit_time       => $now,
    );
    $odb->transact_commit if $odb->transact_active;
    $self->assert($wiki_id,
                  "Failed to store original wiki content");

    my $wiki_list=$odb->fetch('/Wiki');
    $self->assert($wiki_list->exists($wiki_id),
                  "No record in the database after successsful store ($wiki_id)");

    my ($db_content,$db_edit_time,$db_member_id,$db_comment,$db_create_time,$db_create_member_id)=$wiki->retrieve(
        wiki_id     => $wiki_id,
        fields      => [ qw(content edit_time edit_member_id edit_comment create_time create_member_id) ],
    );
    $self->assert($db_content,
                  "Got no content from the database (wiki_id=$wiki_id)");
    $self->assert($db_content eq $content,
                  "Content in the database differs from stored");
    $self->assert($db_edit_time,
                  "Got no edit_time from the database (wiki_id=$wiki_id)");
    $self->assert($db_edit_time eq $now,
                  "Edit_time in the database ($db_edit_time) differs from stored ($now)");
    $self->assert($db_member_id,
                  "Got no edit_member_id from the database (wiki_id=$wiki_id)");
    $self->assert($db_member_id eq $member_id,
                  "Edit_member_id in the database ($db_member_id) differs from stored ($member_id)");
    $self->assert($db_comment eq $comment,
                  "Edit_comment in the database ($db_comment) differs from stored ($comment)");
    $self->assert($db_create_time,
                  "Got no edit_time from the database (wiki_id=$wiki_id)");
    $self->assert($db_create_time eq $now,
                  "Edit_time in the database ($db_create_time) differs from stored ($now)");
    $self->assert($db_create_member_id,
                  "Got no create_member_id from the database (wiki_id=$wiki_id)");
    $self->assert($db_create_member_id eq $member_id,
                  "Create_member_id in the database ($db_create_member_id) differs from stored ($member_id)");

    my $revdata=$wiki->revisions(
        wiki_id     => $wiki_id,
    );
    $self->assert($revdata && ref($revdata) eq 'ARRAY',
                  "Revisions() method returned not an array");
    $self->assert(@$revdata == 0,
                  "Revisions() list is not empty after the first store()");

    $odb->transact_begin;
    my $new_wiki_id=$wiki->store(
        wiki_id         => $wiki_id,
        content         => $content,
        edit_comment    => 'New Comment',
        edit_time       => $now,
        edit_member_id  => $member_id,
    );
    $odb->transact_commit;

    $self->assert($new_wiki_id eq $wiki_id,
                  "Overwriting storage returned a wrong wiki_id ($new_wiki_id)");
    $revdata=$wiki->revisions(
        wiki_id     => $wiki_id,
    );
    $self->assert(@$revdata == 0,
                  "Revisions() list is not empty after storing identical content");

    my $new_content='New Content';
    my $new_member_id='bar';
    my $new_now=time;
    my $new_comment='Very New Comment';

    $odb->transact_begin;
    $new_wiki_id=$wiki->store(
        wiki_id         => $wiki_id,
        content         => $new_content,
        edit_comment    => $new_comment,
        edit_time       => $new_now,
        edit_member_id  => $new_member_id,
    );
    $odb->transact_commit;

    $self->assert($new_wiki_id eq $wiki_id,
                  "Overwriting storage returned a wrong wiki_id ($new_wiki_id)");

    ($db_content,$db_edit_time,$db_member_id,$db_comment)=$wiki->retrieve(
        wiki_id     => $wiki_id,
        fields      => [ qw(content edit_time edit_member_id edit_comment) ],
    );

    $self->assert($db_content,
                  "Got no content from the database (wiki_id=$wiki_id)");
    $self->assert($db_content eq $new_content,
                  "Content in the database differs from stored");
    $self->assert($db_edit_time,
                  "Got no edit_time from the database (wiki_id=$wiki_id)");
    $self->assert($db_edit_time eq $new_now,
                  "Edit_time in the database ($db_edit_time) differs from stored ($new_now)");
    $self->assert($db_member_id,
                  "Got no edit_member_id from the database (wiki_id=$wiki_id)");
    $self->assert($db_member_id eq $new_member_id,
                  "Edit_member_id in the database ($db_member_id) differs from stored ($new_member_id)");
    $self->assert($db_comment eq $new_comment,
                  "Edit_comment in the database ($db_comment) differs from stored ($new_comment)");

    $revdata=$wiki->revisions(
        wiki_id     => $wiki_id,
        fields      => 'revision_id,content',
    );
    $self->assert($revdata && ref($revdata) eq 'ARRAY',
                  "Revisions() method returned not an array");
    $self->assert($revdata->[0] && ref($revdata->[0]) eq 'ARRAY',
                  "Revisions() method returned not an array of arrays");
    $self->assert(@$revdata == 1,
                  "Revisions() list does not contain one element after override (".scalar(@$revdata).")");
    $self->assert($revdata->[0]->[1] eq $content,
                  "Returned revision content differs from stored");

    ($db_content,$db_edit_time,$db_member_id,$db_comment)=$wiki->retrieve(
        wiki_id     => $wiki_id,
        revision_id => $revdata->[0]->[0],
        fields      => [ qw(content edit_time edit_member_id edit_comment) ],
    );
    $self->assert($db_content,
                  "Got no content from the database (wiki_id=$wiki_id)");
    $self->assert($db_content eq $content,
                  "Content in the database differs from stored");
    $self->assert($db_edit_time,
                  "Got no edit_time from the database (wiki_id=$wiki_id)");
    $self->assert($db_edit_time eq $now,
                  "Edit_time in the database ($db_edit_time) differs from stored ($now)");
    $self->assert($db_member_id,
                  "Got no edit_member_id from the database (wiki_id=$wiki_id)");
    $self->assert($db_member_id eq $member_id,
                  "Edit_member_id in the database ($db_member_id) differs from stored ($member_id)");
    $self->assert($db_comment eq $comment,
                  "Edit_comment in the database ($db_comment) differs from stored ($comment)");
}

###############################################################################

sub test_parse {
    my $self=shift;

    my $wiki=XAO::Objects->new(objname => 'Wiki::Foo');
    $self->assert($wiki->isa('XAO::DO::Wiki::Base'),
                  "Expected Wiki::Foo to be based on Wiki::Base");

    my %tests=(
        t001        => {
            template    => "blah\n==some header==\nafter",
            expect      => [
                {   type        => 'header',
                    content     => 'some header',
                },
            ],
        },
        t002        => {
            template    => "blah\n==  some header  ==\nafter",
            expect      => [
                {   type        => 'header',
                    content     => 'some header',
                },
            ],
        },
        t003        => {
            template    => "blah\n===some header==\nafter",
            expect_not  => [
                {   type        => 'header',
                    content     => 'some header',
                },
            ],
        },
        #
        # Strange, but this is how Wikipedia parses it, so keeping ourselves compatible
        #
        t004        => {
            template    => "blah\n==some header== xxx\nafter",
            expect      => [
                {   type        => 'header',
                    content     => 'some header',
                },
            ],
        },
        t010        => {
            template    => "blah\n===    some   subheader===  \nafter",
            expect      => [
                {   type        => 'header',
                    level       => 3,
                    content     => 'some   subheader',
                },
            ],
        },
        t011        => {
            template    => "blah\nxxx ===    some   subheader===  \nafter",
            expect_not      => [
                {   type        => 'subheader',
                    content     => 'some   subheader',
                },
            ],
        },
        t012        => {
            template    => "\x{263a}",
            expect      => [
                {   type        => 'text',
                    content     => "<p>\x{263a}\n</p>\n",
                },
            ],
        },
        t013        => {
            template    => "Bold smiley -- '''\x{263a}'''",
            expect      => [
                {   type        => 'text',
                    content     => "<p>Bold smiley -- <b>\x{263a}</b>\n</p>\n",
                },
            ],
        },
        t020        => {
            template    => '{{}}',
            expect_not  => [
                {   type        => 'curly',
                },
            ],
        },
        t021        => {
            template    => '{{something}}',
            expect      => [
                {   type        => 'curly',
                    opcode      => 'something',
                    content     => '',
                },
            ],
        },
        t022        => {
            template    => "{{\n values\n| some=thing\n| other=that\n}}",
            expect      => [
                {   type        => 'curly',
                    opcode      => 'values',
                    content     => '| some=thing | other=that',
                },
            ],
        },
        t023        => {
            template    => "[[link | label]] some text",
            expect      => [
                {   type        => 'link',
                    link        => 'link',
                    label       => 'label',
                },
            ],
        },
        t024        => {
            template    => "some text [[ multi-word link ]]",
            expect      => [
                {   type        => 'link',
                    link        => 'multi-word link',
                    label       => '',
                },
            ],
        },
        t025        => {
            template    => "some text [[ multi-word link | comment1 | comment2]] postfix",
            expect      => [
                {   type        => 'link',
                    link        => 'multi-word link',
                    label       => 'comment1 | comment2',
                },
            ],
        },
        #
        t030        => {
            template    => "blah {{fubar}} blah",
            expect      => [
                {   type        => 'fubar',
                    content     => '',
                },
            ],
        },
        t031        => {
            template    => "{{first}}{{last}}",
            expect      => [
                {   type        => 'curly',
                    opcode      => 'first',
                },
                {   type        => 'curly',
                    opcode      => 'last',
                },
            ],
        },
        t032        => {
            template    => "{{last}}{{first}}",
            expect      => [
                {   type        => 'curly',
                    opcode      => 'first',
                },
                {   type        => 'curly',
                    opcode      => 'last',
                },
            ],
        },
        t033        => {
            template    => "{{last}}{{verylast}}{{first}}",
            expect      => [
                {   type        => 'curly',
                    opcode      => 'first',
                },
                {   type        => 'curly',
                    opcode      => 'last',
                },
                {   type        => 'curly',
                    opcode      => 'verylast',
                },
            ],
        },
    );

    $self->run_parse_tests($wiki,\%tests);
}

###############################################################################

sub run_parse_tests ($$$) {
    my ($self,$wiki,$tests)=@_;

    eval 'use Data::Compare';
    if($@) {
        print STDERR "\n" .
                     "Perl extension Data::Compare is not available, skipping tests\n" .
        return;
    }

    ##
    # For each test checking that we get _at least_ the blocks listed in
    # 'expect' in the same order. There may be other blocks in parser
    # response too.
    #
    foreach my $tid (sort keys %$tests) {
        my $tdata=$tests->{$tid};

        my $rc=$wiki->parse(
            content     => $tdata->{'template'},
        );
        $self->assert(!$rc->{'error'},
                      "Got a parsing error ($rc->{'errstr'}) for test $tid");
        $self->assert(!$rc->{'errstr'},
                      "Got no error, but an unexpected error message ($rc->{'errstr'}) for test $tid");

        my $got=$rc->{'elements'};

        my $got_pos=0;
        my $expect=$tdata->{'expect'} || [ ];
        for(my $i=0; $i<@$expect; ++$i) {
            my $eblock=$expect->[$i];
            my $found;
            for(my $j=$got_pos; $j<@$got; ++$j) {
                $found=1;
                foreach my $k (keys %$eblock) {
                    if(!defined $got->[$j]->{$k} || $got->[$j]->{$k} ne $eblock->{$k}) {
                        $found=0;
                        last;
                    }
                }
                if($found) {
                    $got_pos=$j;
                    last;
                }
            }
            if(!$found) {
                print STDERR Dumper($got);
                $self->assert($found,
                              "Can't find expected block (#=$i, type='$eblock->{'type'}', content='$eblock->{'content'}') for test $tid");
            }
        }

        my $exnot=$tdata->{'expect_not'} || [ ];
        for(my $i=0; $i<@$exnot; ++$i) {
            my $eblock=$exnot->[$i];
            my $found;
            for(my $j=0; $j<@$got; ++$j) {
                $found=1;
                foreach my $k (keys %$eblock) {
                    if(!defined $got->[$j]->{$k} || $got->[$j]->{$k} ne $eblock->{$k}) {
                        $found=0;
                        last;
                    }
                }
                if($found) {
                    print STDERR Dumper($got);
                    $self->assert(!$found,
                                  "Found unexpected block (#=$i, type='$eblock->{'type'}', content='$eblock->{'content'}') for test $tid");
                }
            }
        }
    }
}

###############################################################################
1;
