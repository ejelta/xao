package testcases::WebFS;
use strict;
use XAO::Projects;

use base qw(testcases::base);

sub test_all {
    my $self=shift;

    my $odb=XAO::Objects->new(objname => 'Web::Page')->odb;
    $self->assert(ref($odb),
                  "Can't load database handler database");
    my $root=$odb->fetch('/');
    $root->put('project' => 'foo');
    $root->build_structure(
        List => {
            type        => 'list',
            class       => 'Data::Product',
            key         => 'product_id',
            structure   => {
                text => {
                    type        => 'text',
                    maxlength   => 50,
                },
                num => {
                    type        => 'integer',
                },
            },
        },
    );
    my $list=$root->get('List');
    my $l1=$list->get_new();
    $l1->put(text => 'ttt');
    $l1->put(num => 123);
    $list->put(l1 => $l1);
    $l1->put(text => 'kkk');
    $l1->put(num => 321);
    $list->put(l2 => $l1);

    my %matrix=(
        t1 => {
            template => '<%FS uri="/project"%>',
            expect   => 'foo',
        },
        t2 => {
            template => '<%FS base.database="/" uri="project"%>',
            expect  => 'foo',
        },
        t3 => {
            template => '<%FS base.database="/project"%>',
            expect  => 'foo',
        },
        t4 => {
            template => '<%FS base.database="/List/l1" uri="num"%>',
            expect  => '123',
        },
        t5 => {
            template => '<%FS mode="show-list"' .
                            ' base.database="/"' .
                            ' base.clipboard="fs_cache/test_fs"' .
                            ' uri="List"' .
                            ' fields="*"' .
                            ' header.path="/bits/WebFS/list-header"' .
                            ' path="/bits/WebFS/list-row"' .
                        '%>',
            expect => '[2]{l1-2-ttt-123}{l2-2-kkk-321}',
        },
        t6 => {
            template => '<%FS mode="show-list"' .
                            ' base.clipboard="fs_cache/test_fs"' .
                            ' uri="List"' .
                            ' fields="*"' .
                            ' path="/bits/WebFS/list-row"' .
                            ' footer.path="/bits/WebFS/list-header"' .
                        '%>',
            expect => '{l1-2-ttt-123}{l2-2-kkk-321}[2]',
        },
        t7 => {
            template => '<%FS mode="show-hash"' .
                            ' base.clipboard="fs_cache/test_fs"' .
                            ' uri="List/l2"' .
                            ' fields="*"' .
                            ' path="/bits/WebFS/hash"' .
                        '%>',
            expect => '{l2-kkk-321}',
        },
    );

    foreach my $tn (sort keys %matrix) {
        my $page=XAO::Objects->new(objname => 'Web::Page');
        my $got=$page->expand(template => $matrix{$tn}->{template});
        my $expect=$matrix{$tn}->{expect};
        $self->assert($got eq $expect,
                      "Test '$tn' failed: got '$got', expected '$expect'");
    }
}

1;
