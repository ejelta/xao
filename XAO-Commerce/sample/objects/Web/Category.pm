package XAO::DO::Web::Category;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::Category);
use base XAO::Objects->load(objname => 'Web::Action');

###############################################################################
sub check_mode ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $mode=$args->{mode};

    if    ($mode eq 'search-keyword') { $self->search_keyword($args); }
    elsif ($mode eq 'show-path')      { $self->show_path($args); }
    elsif ($mode eq 'show-name')      { $self->show_name($args); }
    elsif ($mode eq 'show-list')      { $self->show_list($args); }
    elsif ($mode eq 'show-products')  { $self->show_products($args); }
    else {
        throw XAO::E::DO::Web::Category "check_mode - unknown mode ($mode)";
    }
}

###############################################################################

=item search-keyword => search_keyword (%)

Searches all categories for the given keyword and displays a
list of found categories. Arguments are:

 keyword        => one or more keywords separated by spaces
 header.path    => optional header
 path           => row template path
 footer.path    => optional footer
 limit          => maximum number of categories to display

=cut

sub search_keyword ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $keyword=$args->{keyword} ||
        throw XAO::E::DO::Web::Category "search_keyword - no 'keyword' given";
    my @kwlist=split(/[\s,]+/,$keyword);
    shift @kwlist unless $kwlist[0];

    ##
    # Searching and then ordering by relevance.
    #
    my $cat_list=$self->odb->fetch('/Categories');
    my $found=$cat_list->search([ 'empty', 'ne', '1' ], 'and',
                                $self->unroll_and('name', 'ws', \@kwlist));
    my $cat_rel=sub {
        my ($name,$desc)=@_;
        my $rel=0;
        my @t=($name =~ /\b($keyword)/ig);
        $rel+=10 * @t;
        @t=($desc =~ /\b($keyword)/ig);
        $rel+=10 * @t;
        foreach my $k (@kwlist) {
            @t=($name =~ /\b($k)/ig);
            $rel+=5 * @t;
            @t=($desc =~ /\b($k)/ig);
            $rel+=3 * @t;
        }
        $rel;
    };
    my @sorted=sort {
        my ($name_a,$desc_a)=$cat_list->get($a)->get('name','description');
        my ($name_b,$desc_b)=$cat_list->get($b)->get('name','description');
        &$cat_rel($name_b || '',$desc_b || '') <=> &$cat_rel($name_a || '',$desc_a || '');
    } @$found;

    my $page=$self->object;
    my $limit=$args->{limit} || 0;
    $page->display(
        path    => $args->{'header.path'},
        NUMBER  => scalar(@sorted),
        LIMIT_REACHED   => $limit && @sorted > $limit,
    ) if $args->{'header.path'};

    my $i=0;
    foreach my $id (@sorted) {
        last if $limit && $i++ >= $limit;
        $page->display(
            path            => $args->{path},
            ID              => $id,
        );
    }

    $page->display(
        path            => $args->{'footer.path'},
        NUMBER          => scalar(@sorted),
        LIMIT_REACHED   => $limit && @sorted > $limit,
    ) if $args->{'footer.path'};
}

###############################################################################
#
# Shows path for category.
# Arguments:
#  category          => category id
#  path              => path to the category element template
#  ellipsis.limit    => maximum length of path in elements
#  ellipsis.path     => path to the ellipsis template
#  ellipsis.template => ellipsis template
#
sub show_path ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $category=$args->{category};
    return unless $category;

    ##
    # Building path
    #
    my $odb=$self->odb;
    my $cat_list=$odb->fetch('/Categories');
    my @catpath=($category);
    my @catname;
    while(1) {
        my $cat=$cat_list->get($category);
        my $name;
        ($category,$name)=$cat->get('parent_id','name');
        unshift(@catname,$name);
        last unless $category;
        unshift(@catpath,$category);
    }

    ##
    # Displaying path
    #
    my $obj=$self->object;
    my $limit=$args->{'ellipsis.limit'} || 0;
    for(my $level=0; $level!=@catpath; $level++) {
        if($limit && @catpath>$limit) {
            if($level>0 && $level<@catpath-$limit+2) {
                next unless $level==1;
                $obj->display(template => $args->{'ellipsis.template'},
                              path => $args->{'ellipsis.path'});
                next;
            }
        }
        $obj->display(
            path => $args->{path},
            ID => $catpath[$level],
            LAST => ($level+1 == @catpath) ? 1 : 0,
            LEVEL => $level,
            NAME => $catname[$level],
        );
    }
}

sub show_name ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $category=$args->{category};
    return unless $category;
    my $sth=$self->dbh->prepare('SELECT name FROM categories WHERE id=?') ||
        throw XAO::E::DO::Web::Category "show_path - SQL error";
    $sth->execute($category);
    my @row=$sth->fetchrow_array();
    $self->textout(@row ? ($row[0] || 'No Name') : 'No Name');
}

###############################################################################

=item show-list => show_list (%)

Displays the list of all categories for which given category is the parent.
Arguments are:

 category       => category ID
 header.path    => optional header
 path           => path that is displayed for all categories
 footer         => optional footer

=cut

sub show_list ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $category=$args->{category};

    my $cat_list=$self->odb->fetch('/Categories');
    my $list=$cat_list->search([ 'empty', 'ne', 1 ], 'and',
                               [ 'parent_id', 'eq', $category ],
                               { orderby => 'name' });

    my $page=$self->object;
    $page->display(
        path    => $args->{'header.path'},
        NUMBER  => scalar(@$list),
    ) if $args->{'header.path'};

    foreach my $id (@$list) {
        my $cat=$cat_list->get($id);
        my ($name,$description,$thumbnail)=$cat->get(qw(name description thumbnail_url));
        $page->display(
            path            => $args->{path},
            ID              => $id,
            NAME            => $name || 'No Name',
            DESCRIPTION     => $description || '',
            THUMBNAIL_URL   => $thumbnail || '',
        );
    }

    $page->display(
        path    => $args->{'footer.path'},
        NUMBER  => scalar(@$list),
    ) if $args->{'footer.path'};
}
################################################################################
sub show_products ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $category=$args->{category} || 0;
    my $join_similar=$args->{join_similar} ? 1 : 0;

    ##
    # Searching for products in the given category. That's easy.
    #
    my $prod_list=$self->odb->fetch('/Products');
    my $list=$prod_list->search('Categories/prod_cat_id', 'eq', $category,
                                { orderby => 'name' });

    ##
    # Calculating navigation parameters
    #
    my $start_item=$args->{start_item} || 0;
    my $items_per_page=$args->{items_per_page} || 0;
    my $total_items=scalar(@$list);
    my $page_items=$total_items-$start_item;
    $page_items=$items_per_page if $items_per_page && $page_items > $items_per_page;
    $page_items=0 if $page_items<0;
    my $limit_reached=($page_items != $total_items) ? 1 : 0;

    ##
    # Displaying 'nothing' template if it is given and we did not get
    # any products.
    #
    my $page=$self->object;
    if($args->{'nothing.path'} && !$total_items) {
        $page->display(
            path => $args->{'nothing.path'},
            CATEGORY => $category,
        );
        return;
    }

    ##
    # Displaying products list
    #
    $page->display(
        path => $args->{'header.path'},
        ITEMS_PER_PAGE  => $items_per_page,
        LIMIT_REACHED   => $limit_reached,
        PAGE_ITEMS      => $page_items,
        START_ITEM      => $start_item,
        TOTAL_ITEMS     => $total_items,
    ) if $args->{'header.path'};

    my @fl=qw(name price thumbnail_url);
    my $count=0;
    foreach my $id ($items_per_page ? @{$list}[$start_item..($start_item+$page_items-1)]
                                    : @$list) {
        my ($name,$price,$thumbnail_url, $manufacturer, $manufacturer_id, $sku, $description)=
            $prod_list->get($id)->get(qw(name price thumbnail_url manufacturer manufacturer_id sku description));
        $page->display(
            path            => $args->{path},
            #
            CATEGORY        => $category,
            CATEGORY_NAME   => $args->{CATEGORY_NAME} || '',
            ID              => $id,
            NAME            => $name || 'No name',
            PRICE           => $price || 0,
            THUMBNAIL_URL   => $thumbnail_url || '',
            #
            ITEMS_PER_PAGE  => $items_per_page,
            LIMIT_REACHED   => $limit_reached,
            PAGE_ITEMS      => $page_items,
            START_ITEM      => $start_item,
            TOTAL_ITEMS     => $total_items,
            MANUFACTURER    => $manufacturer,
            MANUFACTURER_ID => $manufacturer_id,
            SKU             => $sku,
            DESCRIPTION     => $description,
            COUNT           => ++$count,
            MATCH_NUMBER    => '',
        );
    }

    $page->display(
        path => $args->{'footer.path'},
        ITEMS_PER_PAGE  => $items_per_page,
        LIMIT_REACHED   => $limit_reached,
        PAGE_ITEMS      => $page_items,
        START_ITEM      => $start_item,
        TOTAL_ITEMS     => $total_items,
    ) if $args->{'footer.path'};
}

###############################################################################

=item unroll_and ($$$)

Creates 'AND' condition for keywords search. Takes field name, operation
and reference to an array with keywords.

=cut

sub unroll_and ($$$) {
    my $self=shift;
    my ($name,$op,$list)=@_;
    my $cond;
    foreach my $kw (@$list) {
        if ($cond) { $cond = [ [ $name, $op, $kw ], 'and', $cond ]; }
        else       { $cond = [$name, $op, $kw]; }
    }
    $cond;
}
###############################################################################
1;
