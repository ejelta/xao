=head1 NAME

XAO::DO::ImportMap::FlatFile -- Import Map for Marcos flatfile data format

=head1 SYNOPSIS

None.

=head1 DESCRIPTION

Converts RawXML objects of Marcos flatfile data catalog into Products and Categories.

Do not forget to set MANUFACTURER and MANUFACTURER_ID !!!

=cut

###############################################################################
package XAO::DO::ImportMap::FlatFile;
use strict;
use XAO::Utils;
use XML::DOM;
use Error;
use base XAO::Objects->load(objname => 'ImportMap::Base');

use constant  MANUFACTURER    => 'FlatFile';
use constant  MANUFACTURER_ID => 'flatfile';

##
# set UPC code for given manufacturer here
#
use constant  UPC_CODE  => ''; # Should add anything ?
###############################################################################

sub xtext ($;$) {
    my $node=shift;
    my $default=shift || '';

    if($node->isa('XML::DOM::NodeList')) {
        return $default unless $node->getLength();
        $node=$node->item(0);
    }

    my $text='';
    foreach my $n ($node->getChildNodes()) {
        next unless $n->getNodeType() eq TEXT_NODE;
        $text.=$n->getNodeValue();
    }

    $text =~ s/^\s*(.*?)\s*$/$1/s;
    $text;
}

###############################################################################

sub check_category_map ($) {
    my $self=shift;
    my $cmap=shift;

    if(!scalar($cmap->keys)) {

        my %cats=(
            '_keep_original' => '',
        );

        my ($src_cat,$dst_cat)=$self->category_hash_to_array(\%cats);

        my $c=$cmap->get_new();

        for(my $i=0; $i!=@{$src_cat}; $i++) {
            $c->put(src_cat => $src_cat->[$i]);
            $c->put(dst_cat => $dst_cat->[$i]);
            $cmap->put($c);
        }
    }
}

###############################################################################

sub map_xml_categories ($$$) {
    my $self=shift;
    my $xmlcont=shift;
    my $catcont=shift;
    my $catmap=shift;

    ##
    # Preparing parser
    #
    my $parser=XML::DOM::Parser->new() ||
        throw Error::Simple "Can't create XML::DOM parser";

    ##
    # Doing two passes, first we collect categories into a hash and then
    # we translate and store them.
    #
    my %cats;
        my $doc;
    foreach my $id (@{$xmlcont->search('type','eq','category')}) {
        my $obj=$xmlcont->get($id);

        $doc=$parser->parse($obj->get('value')) ||
            throw Error::Simple ref($self)."::map_xml_categories - Can't parse category XML ($id)";

        my $catdesc=$doc->getDocumentElement();
        $catdesc->getNodeName() eq 'catdesc' ||
            throw Error::Simple "Root node is not a <catdesc> ($id)";

        my $attrmap=$catdesc->getAttributes();
        my %hash;
        foreach my $attrname (qw(id parent_id name)) {
            $hash{$attrname}=$self->xattr($attrmap,$attrname);
        }

        if(exists($cats{$hash{id}})) {
            throw Error::Simple "This category ID was already used ($id)";
        }

        $cats{$hash{id}}=\%hash;
    }
        continue {
                $doc->dispose() if $doc;
        }

    return $self->store_categories_hash($catcont,\%cats,$catmap);
}

###############################################################################

#sub map_xml_products ($$$$) { }

sub map_xml_products ($$$$) {
    my $self=shift;
    my $catalog=shift || throw Error::Simple ref($self)."::map_xml_products - no catalog given";;
    my $prefix=shift || throw Error::Simple ref($self)."::map_xml_products - no prefix given";;
    my $xmlcont=shift || throw Error::Simple ref($self)."::map_xml_products - no RawXML container given";
    my $prodcont=shift || throw Error::Simple ref($self)."::map_xml_products - no Products container given";;
    my $catmap=shift || throw Error::Simple ref($self)."::map_xml_products - no category map given";;

    ##
    # Preparing parser
    #
    my $parser=XML::DOM::Parser->new() || throw Error::Simple "Can't create XML::DOM parser";

    my $source_ref=$catalog->container_key || 'unknown';
    my $source_seq=$catalog->get('source_seq') || 0;
    $catalog->put(source_seq => ++$source_seq);

    my $doc;
    foreach my $objid (@{$xmlcont->search('type','eq','product')}) {
        my $obj=$xmlcont->get($objid);

        $doc=$parser->parse($obj->get('value')) ||
            throw Error::Simple "Can't parse product XML ($objid)";

        my $pdesc=$doc->getDocumentElement();
        $pdesc->getNodeName() eq 'product' ||
            throw Error::Simple "Root node is not a <product> ($objid)";

        ##
        # Scanning categories
        #
        my %cats;
        foreach my $node ($pdesc->getElementsByTagName('category')) {
            my $attrmap=$node->getAttributes();
            my $id=$self->xattr($attrmap,'id');
            if(!$id) {
                eprint "No category ID is in one of the categories at $objid";
            }
            else {
                my $list=$catmap->{$id};
                if(!$list) {
                    eprint "Unknown category used in $objid";
                }
                else {
                    @cats{@{$list}}=@{$list};
                }
            }
        }
        my @cats=keys %cats;        # making category IDs unique
        undef %cats;
        if(!@cats) {
            eprint "Product $objid does not belong to any known category, skipping it";
            next;
        }

        ##
        # Loading product description
        #
        my $attrmap=$pdesc->getAttributes();
        my $id=$self->xattr($attrmap,'sku');
        unless($id) { eprint "No product ID at $objid"; next; }
        my %product=(
            sku                 => $self->xattr($attrmap,'sku'),
            name                => $self->xattr($attrmap,'name'),
            description         => $self->xattr($attrmap,'description'),
            image_url           => $self->xattr($attrmap,'image_url'),
            thumbnail_url       => $self->xattr($attrmap,'thumbnail_url'),
            source_sku          => $id,
            source_seq          => $source_seq,
            manufacturer        => MANUFACTURER,
            manufacturer_id     => MANUFACTURER_ID,
            attribute           => $self->xattr($attrmap,'attribute'),
            price               => $self->xattr($attrmap,'price'),
            sale_price          => $self->xattr($attrmap,'sale-price'),
            weight              => $self->xattr($attrmap,'weight'),
        );

        ##
        # Looking for matching SKU and taking suggestion for product ID. If there
        # is no SKU then we ignore this product.
        #
        my $product_id=$self->product_id(\%product);
        if(!$product{sku}) {
            dprint "Skipping product without known SKU - (id=$id)";
            next;
        }

        ##
        # Looking for existing product with the same SKU. Ignoring
        # suggested ID if found.
        #
        my $pobj;
        my $existing;
        my $product_ids=$prodcont->search('sku','eq',$product{sku});
        if(@{$product_ids}) {
            $product_id=$product_ids->[0];
        }

        ##
        # Filling data into this detached object
        #
        $pobj=$prodcont->get_new();
        foreach my $fn (keys %product) {
            next if $fn eq 'categories';
            my $maxl=$pobj->describe($fn)->{maxlength};
            my $value=$maxl ? substr($product{$fn},0,$maxl) : $product{$fn};
            $pobj->put($fn => $value);
        }

        ##
        # Storing and reloading to get attached product reference.
        #
        if($product_id && $prodcont->exists($product_id)) {
            my $curr_id=$prodcont->get($product_id)->get('source_sku');
            if($id ne $curr_id) {
                eprint "Cannot override products, current source_sku=$curr_id, new=$id, id=$product_id";
                $product_id=undef;
            }
        }
        if($product_id) {
            $prodcont->put($product_id => $pobj);
        }
        else {
            $product_id=$prodcont->put($pobj);
        }
        $pobj=$prodcont->get($product_id);

        ##
        # Now storing/updating categories
        #
        my $prod_cats=$pobj->get('Categories');
        $prod_cats->destroy();
        my $cat_obj=$prod_cats->get_new();
        foreach my $cat (@cats) {
            $prod_cats->put($cat => $cat_obj);
        }
    }
        continue {
                $doc->dispose() if $doc;
    }
}

###############################################################################

1;

__END__

=head1 AUTHORS

Copyright (c) 2001 XAO Inc.

Andrew Maltsev <am@xao.com>
