package XAO::Errors;
use strict;
use vars qw(%errors_cache);
use Error;

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

1;
