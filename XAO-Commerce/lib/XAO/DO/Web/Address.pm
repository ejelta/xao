package XAO::DO::Web::Address;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::Address);

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
        {
            name => 'ref_name',
            required => 1,
            style => 'text',
            maxlength => 50,
            minlength => 1,
            param => 'REF_NAME',
            text => 'Reference Name',
        },
        {
            name => 'name_line1',
            required => 1,
            style => 'text',
            maxlength => 50,
            minlength => 5,
            param => 'NAME_LINE1',
            text => 'Ship Name Line 1',
        },
        {
            name => 'name_line2',
            style => 'text',
            maxlength => 50,
            param => 'NAME_LINE2',
            text => 'Ship Name Line 2',
        },
        {
            name => 'line_1',
            required => 1,
            style => 'text',
            maxlength => 100,
            minlength => 5,
            param => 'LINE_1',
            text => 'Address (line 1)',
        },
        {
            name => 'line_2',
            style => 'text',
            maxlength => 100,
            param => 'LINE_2',
            text => 'Address (line 2)',
        },
        {
            name => 'city',
            required => 1,
            style => 'text',
            maxlength => 50,
            minlength => 2,
            param => 'CITY',
            text => 'City',
        },
        {
            name => 'state',
            required => 1,
            style => 'uscontst',
            param => 'STATE',
            text => 'State',
        },
        {
            name => 'zipcode',
            required => 1,
            style => 'text',
            maxlength => 20,
            minlength => 5,
            param => 'ZIPCODE',
            text => 'Zip-Code',
        },
        {
            name => 'phone',
            required => 1,
            style => 'usphone',
            param => 'PHONE',
            text => 'Phone',
        },
    ];
}
###############################################################################
1;
