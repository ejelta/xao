# Handler for /products/* urls
#
package XAO::DO::Web::AutoProduct;
use XAO::Utils;
use base XAO::Objects->load(objname => 'Web::Page');

###############################################################################
sub display ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $mode=$args->{mode} || 'product';

    my $path=$args->{path};
    my $id=0;
    $id=uc($1) if $path =~ /^(\w+)\./;

    if($mode eq 'product') {
        $self->object->display(path => '/bits/product/page-template',
                               ID => $id);
    }
    elsif($mode eq 'image') {
        my $image_url=$self->odb->fetch("/Products/$id/image_url");
        $self->object->display(
            path      => '/bits/product/page-image',
            ID        => $id,
            IMAGE_URL => $image_url || '',
        );
    }
    else {
        $self->throw("Unknown mode '$mode'");
    }
}
###############################################################################
1;
