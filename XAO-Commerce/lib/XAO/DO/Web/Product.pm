package XAO::DO::Web::Product;
use strict;
use Digest::MD5 qw(md5_base64);
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::Product);

use base XAO::Objects->load(objname => 'Web::FS');

###############################################################################
sub check_mode ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    $self->SUPER::check_mode($args);
}
###############################################################################
sub form_fields {
    my $self=shift;
    return [
        # Fixed
        {
            name        => 'source_ref',
            style       => 'text',
            maxlength   => 30,
            required    => 1,
            unique      => 1,
            param       => 'SOURCE_REF',
            text        => 'Source Ref',
        },
        {
            name        => 'source_seq',
            style       => 'text',
            required    => 1,
            unique      => 1,
            minvalue    => 0,
            param       => 'SOURCE_SEQ',
            text        => 'Source Seq',
        },
        {
            name        => 'source_sku',
            style       => 'text',
            maxlength   => 30,
            required    => 1,
            unique      => 1,
            param       => 'SOURCE_SKU',
            text        => 'Source Sku',
        },
        {
            name        => 'manufacturer',
            style       => 'text',
            maxlength   => 50,
            param       => 'MANUFACTURER',
            text        => 'Manufacturer',
        },
        {
            name        => 'manufacturer_id',
            style       => 'text',
            maxlength   => 30,
            param       => 'MANUFACTURER_ID',
            text        => 'Manufacturer ID',
        },
        {
            name        => 'sku',
            style       => 'text',
            maxlength   => '30',
            required    => 1,
            unique      => 1,
            param       => 'SKU',
            text        => 'Sku',
        },
        {
            name        => 'name',
            style       => 'text',
            maxlength   => 100,
            required    => 1,
            param       => 'NAME',
            text        => 'Name',
        },
        {
            name        => 'description',
            style       => 'text',
            maxlength   => 2000,
            param       => 'DESCRIPTION',
            text        => 'Description',
        },
        {
            name        => 'thumbnail_url',
            style       => 'text',
            maxlength   => 200,
            param       => 'THUMBNAIL_URL',
            text        => 'Thumbnail URL',
        },
        {
            name        => 'image_url',
            style       => 'text',
            maxlength   => 200,
            param       => 'IMAGE_URL',
            text        => 'Image URL',
        },

        # Site Specific
        {
            name        => 'attribute',
            style       => 'text',
            maxlength   => 100,
            param       => 'ATTRIBUTE',
            text        => 'Attribute',
        },
        {
            name        => 'price',
            style       => 'text',
            param       => 'PRICE',
            text        => 'Price',
        },
        {
            name        => 'sale_price',
            style       => 'text',
            param       => 'SALE_PRICE',
            text        => 'Sale Price',
        },
        {
            name        => 'weight',
            style       => 'text',
            minvalue    => 0,
            param       => 'WEIGHT',
            text        => 'Weight',
        },
    ];
}
###############################################################################
1;
