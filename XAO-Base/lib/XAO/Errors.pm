=head1 NAME

XAO::Errors - throwable errors namespace support

=head1 SYNOPSIS

 package XAO::Fubar;
 use XAO::Errors qw(XAO::Fubar);

 sub foo {
    ...
    throw XAO::E::Fubar "foo - wrong arguments";
 }

=head1 DESCRIPTION

Magic module that creates error namespaces for caller's. Should be
used in situations like that. Say you create a XAO module called
XAO::DO::Data::Product and want to throw errors from it. In order for
these errors to be distinguishable you need separate namespace for
them -- that's where XAO::Errors comes to rescue.

In the bizarre case when you want more then one namespace for
errors - you can pass these namespaces into XAO::Errors and it will
make them throwable. It does not matter what to pass to XAO::Errors -
the namespace of an error or the namespace of the package, the result
would always go into XAO::E namespace.

=cut

###############################################################################
package XAO::Errors;
use strict;
use vars qw(%errors_cache);
use Error;

use vars qw($VERSION);
($VERSION)=(q$Id: Errors.pm,v 1.5 2002/01/04 02:00:15 am Exp $ =~ /(\d+\.\d+)/);

sub import {
    my $class=shift;
    my @list=@_;

    foreach my $module (@list) {
        my $em;
        if($module=~/^XAO::E((::\w+)+)$/) {
            $em=$module;
            $module='XAO' . $1;
        }
        elsif($module=~/^XAO((::\w+)+)$/) {
            $em='XAO::E' . $1;
        }
        else {
            throw Error::Simple "Can't import error module for $module";
        }

        next if $errors_cache{$em};

        eval <<END;

package $em;
use strict;
use Error;
use vars qw(\@ISA);
\@ISA=qw(Error::Simple);

sub throw {
    my \$self=shift;
    my \$text=join('',map { defined(\$_) ? \$_ : '<UNDEF>' } \@_);
    \$self->SUPER::throw('${module}::' . \$text);
}

1;
END
        throw Error::Simple $@ if $@;
        $errors_cache{$em}=1;
    }
}

###############################################################################
1;
__END__

=head1 AUTHOR

Copyright (c) 2001 XAO Inc.

Author is Andrew Maltsev <am@xao.com>.
