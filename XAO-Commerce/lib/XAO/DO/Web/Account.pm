package XAO::DO::Web::Account;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::Account);

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
            name     => 'first_name',
            required => 1,
            style    => 'text',
            param    => 'FIRST_NAME',
            text     => 'First Name',
        },
        {
            name     => 'middle_name',
            style    => 'text',
            param    => 'MIDDLE_NAME',
            text     => 'Middle Name',
        },
        {
            name     => 'last_name',
            required => 1,
            style    => 'text',
            param    => 'LAST_NAME',
            text     => 'Last Name',
        },
        {
            name     => 'email',
            required => 1,
            unique   => 1,
            style    => 'email',
            param    => 'EMAIL',
            text     => 'Email',
        },
        {
            name        => 'password',
            style       => 'password',
            required    => 1,
            size        => 30,
            minlength   => 5,
            maxlength   => 50,
            param       => 'PASSWORD',
            text        => 'Password',
            pair        => 'password2',
        },
        {
            name        => 'password2',
            style       => 'password',
            required    => 1,
            size        => 30,
            minlength   => 5,
            maxlength   => 50,
            param       => 'PASSWORD2',
            text        => 'Password (re-type)',
        },
    ];
}
###############################################################################
1;
