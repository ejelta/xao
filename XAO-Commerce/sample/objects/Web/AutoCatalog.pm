# Handler for /catalog/* urls
#
package XAO::DO::Web::AutoCatalog;
use XAO::Utils;
use base XAO::Objects->load(objname => 'Web::Page');

###############################################################################
sub display ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $path = $args->{path};
    my $id   = $path;
    $id      =~ s/^(\w+)\.html/$1/;
    my $category=0;
    $category=uc($1) if $path =~ /^(\w+)\./;

    $self->object->display(
        path     => '/bits/catalog/page-template',
        CATEGORY => $category,
    );
}
###############################################################################
1;
