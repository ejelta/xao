=head1 NAME

XAO::DO::Config - Base object for all configurations

=head1 SYNOPSIS

Useful in tandem with XAO::Projects to describe contexts.

 use XAO::Projects qw(:all);

 my $config=XAO::Objects->new(objname => 'Config',
                              sitename => 'test');

 create_project(name => 'test',
                object => $config,
                set_current => 1);

 my $webconfig=XAO::Objects->new(objname => 'Web::Config');
 my $fsconfig=XAO::Objects->new(objname => 'FS::Config');

 $config->embed(web => $webconfig,
                fs => $fsconfig);

 # Now we have web and fs methods on the config itself:
 #
 my $cgi=$config->cgi;
 my $odb=$config->odb;

=head1 DESCRIPTION

This object provides storage for project specific configuration
variables and clipboard mechanism.

It can ``embed'' other configuration objects that describe specific
parts of the system -- such as database, web or something else. This is
done by using method embed() -- see below.

=head1 METHODS

XAO::DO::Config provides the following methods:

=over

=cut

###############################################################################
package XAO::DO::Config;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Config);

###############################################################################

=item embed (%)

This method allows to embed other configuration objects into
Config. After embedding certain methods of embedded object become
available as Config methods. For example, if you embed Web::Config into
Config and Web::Config provides a method called cgi(), then you will be
able to call that method on Config:

 my $config=XAO::Objects->new(objname => 'Config');
 my $webconfig=XAO::Objects->new(objname => 'Web::Config');

 $config->embed('Web::Config' => $webconfig);

 my $cgi=$config->cgi();

In order to support that hte object being embedded must have a method
embeddable_methods() that returns an array of method names to be
embedded.

 sub embeddable_methods ($) {
     my $self=shift;
     return qw(cgi add_cookie del_cookie);
 }

The idea behind embedding is to allow easy access to arbitrary context
description objects (Configs). For example XAO::FS would provide its own
config that creates and caches its database handler. Some other database
module might provide its own config if for some reason XAO::FS can't be
used.

=cut

sub embed ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    foreach my $name (keys %$args) {

        throw XAO::E::DO::Config "embed - object with that name was already embedded before"
            if $self->{$name};

        my $obj=$args->{$name};
        $obj->can('embeddable_methods') ||
            throw XAO::E::DO::Config
                  "embed - object ($name) does not have embeddable_methods() method";

        ##
        # Building perl code for proxy methods definitions
        #
        my @list=$obj->embeddable_methods();
        my $code='';
        foreach my $mn (@list) {
            $obj->can($mn) ||
                throw XAO::E::DO::Config
                      "embed - object ($name) doesn't have embeddable method $mn()";

            $self->{_methods}->{$mn} &&
                throw XAO::E::DO::Config
                      "embed - method with such name ($mn) already exists, can't be embedded from $name";

            $self->{_methods}->{$mn}=$obj;

            $code.="sub $mn { shift->{_methods}->{$mn}->$mn(\@_); }\n"
        }

        ##
        # Now a bit of black magic, evaluating the code in the current
        # package context to add appropriate proxy methods.
        #
        eval $code;
        throw XAO::E::DO::Config "embed - internal error" if $@;

        ##
        # This is not required, but we're keeping that information just
        # in case.
        #
        $self->{$name}->{obj}=$obj;
        $self->{$name}->{methods}=\@list;
    }
}

###############################################################################

=item init (%)

Suggested method name for project specific Config implementation
initialization. This method would normally be called by various handlers
after creating configuration and making it current.

=cut

###############################################################################

=item new (%)

Creates new instance of abstract Config.

=cut

sub new ($%) {
    my $proto=shift;
    bless {},ref($proto) || $proto;
}

###############################################################################
1;
__END__

=back

=head1 AUTHOR

Copyright (c) 2001 XAO Inc.

Author is Andrew Maltsev <am@xao.com>.
