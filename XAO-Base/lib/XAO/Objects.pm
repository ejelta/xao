=head1 NAME

XAO::Objects - dynamic objects loader

=head1 SYNOPSIS

 use XAO::Objects;

 sub foo {
    ...
    my $page=XAO::Objects->new(objname => 'Web::Page');
 }

=head1 DESCRIPTION

Loader for XAO dynamic objects. This module is most extensively used
throughout all XAO utilities and packages.

The idea of XAO dynamic objects is to seamlessly allow multiple projects
co-exist in the same run-time environment -- for instance multiple web
sites in mod_perl environment. Using traditional Perl modules or objects
it is impossible to have different implementations of an object in the
same namespace -- once one site loads a Some::Object the code is then
re-used by all sites executing in the same instance of Apache/mod_perl.

The architecture of XAO::Web and XAO::FS requires the ability to load an
object by name and at the same time provide a pissibly different
functionality for different sites.

This is achieved by always loading XAO objects using functions of
XAO::Objects package.

Have a look at this example:

 my $dobj=XAO::Objects->new(objname => 'Web::Date');

What happens when this code is executed is that in case current site has
an extended version of Web::Date object -- this extended version will be
returned, otherwise the standard Web::Date is used. This allows for
customizations of a standard object specific to a web site without
affecting other web sites.

For creating an site specific object based on standard object the
following syntax should be used:

 package XAO::DO::Web::MyObject;
 use strict;
 use XAO::Objects;

 use base XAO::Objects->load(objname => 'Web::Page');

 sub display ($%) {
     my $self=shift;
     my $args=get_args(\@_);

     .....
 }

To extend or alter the functionality of a standard object the following
syntax should be used to avoid infinite loop in the object loader:

 package XAO::DO::Web::Date;
 use strict;
 use XAO::Objects;

 use base XAO::Objects->load(objname => 'Web::Date', baseobj => 1);

XAO::Objects is not limited to web site use only, in fact it is used in
XAO Foundation server to load database objects, in XAO::Catalogs to load
custom catalog filters and so on.

=head1 FUNCTIONS

The following functions are available. They can be
called either as 'XAO::Objects->function()' or as
'XAO::Objects::function()'. XAO::Objects never creates objects of its
own namespace, so these are functions, not methods.

=over

=cut

###############################################################################
package XAO::Objects;
use strict;
use XAO::Base qw($homedir $projectsdir);
use XAO::Utils qw(:args :debug);
use XAO::Errors qw(XAO::Objects);
use XAO::Projects;

use vars qw($VERSION);
($VERSION)=(q$Id: Objects.pm,v 1.9 2002/06/20 00:20:30 am Exp $ =~ /(\d+\.\d+)/);

##
# Prototypes
#
sub load (@);
sub new ($%);

###############################################################################

=item load

Pre-loads an object into memory for quicker access and inheritance.

On success returns class name of the loaded object, on error --
undefined value.

It is allowed to call load outside of any site context - it just would
not check site specific objects.

Arguments:

 objname  => object name (required)
 baseobj  => ignore site specific objects even if they exist (optional)
 sitename => should only be used to load Config object

=cut

use vars qw(%objref_cache);
sub load (@) {
    my $class=(scalar(@_)%2 || ref($_[1]) ? shift(@_) : 'XAO::Objects');
    my $args=get_args(\@_);
    my $objname=$args->{objname} ||
        throw XAO::E::Objects "load - no objname given";

    ##
    # Config object is a special case. When we load it we do not have
    # site configuration yet and so we have to rely on supplied site
    # name.
    #
    my $sitename;
    if($args->{baseobj}) {
        # No site name for base object
    }
    elsif($objname eq 'Config') {
        $sitename=$args->{sitename} ||
            throw XAO::E::Objects "load - no sitename given for Config object";
    }
    else {
        $sitename=XAO::Projects::get_current_project_name() ||
                  $args->{sitename} ||
                  '';
    }

    ##
    # Checking cache first
    #
    my $tref;
    if($sitename && ($tref=$objref_cache{$sitename})) {
        return $tref->{$objname} if exists $tref->{$objname};
    }
    elsif(!$sitename && ($tref=$objref_cache{'/'})) {
        return $tref->{$objname} if exists $tref->{$objname};
    }

    ##
    # Checking project directory
    #
    my $objref;
    my $system;
    if($sitename) {
        (my $objfile=$objname) =~ s/::/\//sg;
        $objfile="$projectsdir/$sitename/objects/$objfile.pm";
        if(-f $objfile && open(F,$objfile)) {
            local $/;
            my $text=<F>;
            close(F);
            $text=~s{^\s*(package\s+(XAO::DO|Symphero::Objects))::($objname\s*;)}
                    {${1}::${sitename}::${3}}m;
            $1 || throw XAO::E::Objects
                  "load - package name is not XAO::DO::$objname in $objfile";
            $2 eq 'XAO::DO' ||
                eprint "Old style package name in $objfile - change to XAO::DO::$objname";
            eval "\n#line 1 \"$objfile\"\n" . $text;
            throw XAO::E::Objects
                  "load - error loading $objname ($objfile) -- $@" if $@;
            $objref="XAO::DO::${sitename}::${objname}";
        }
        $system=0;
    }
    if(! $objref) {
        $objref="XAO::DO::${objname}";
        eval "require $objref";
        throw XAO::E::Objects
              "load - error loading $objname ($objref) -- $@" if $@;
        $system=1;
    }

    ##
    # In case no object was found.
    #
    $objref || throw XAO::E::Objects
                     "load - no object file found for sitename='$sitename', objname='$objname'";

    ##
    # Returning class name and storing into cache
    #
    $objref_cache{$sitename ? $sitename : '/'}->{$objname}=$objref;
}

###############################################################################

=item new (%)

Creates an instance of named object. There is just one required
argument - 'objname', everything else is passed into object's
constructor unmodified.

See also recycle() method description for the algorithm of object
recycling that in many circumstances can significantly improve
performance.

=cut

my %recyclables;
sub new ($%) {
    my $class=(scalar(@_)%2 || ref($_[1]) ? shift(@_) : 'XAO::Objects');
    my $args=get_args(\@_);

    my $objname=$args->{objname} ||
        throw XAO::E::Objects "new - no 'objname' given";

    ##
    # Checking if we have a recycled object to return
    #
    if(exists $recyclables{$objname}) {
        my $sitename=$args->{sitename} ||
                     XAO::Projects::get_current_project_name();
        my $odesc=$recyclables{$objname}->{$sitename};
        if($odesc && $odesc->{recyclable} && @{$odesc->{pool}}) {
            # dprint "Returning recycled object";
            return shift @{$odesc->{pool}};
        }
    }

    ##
    # Looking up what is real object reference for that objname.
    #
    my $objref=$class->load($args) ||
        throw XAO::E::Objects "new - can't load object ($args->{objname})";

    ##
    # Creating instance of that object
    #
    my $obj=$objref->new($args) ||
        throw XAO::E::Objects "new - error creating instance of $objref ($@)";

    $obj;
}

###############################################################################

=item recycle ($)

In some circumstances XAO dynamic objects are created and destroyed
very frequently -- for instance if a table on a web page is built and
every line of that table has several Date fields and Web::Date object is
referenced from templates to display the date.

In that case significant amount of time is spent in BEGIN/END blocks
and in allocating/de-allocating object support structures in the Perl
itself. According to profiling information up to 20% of all execution
time is spent on that on tight loop jobs like the one above.

To address this problem there is a possibility to "recycle" the same
object without actually destroying it/re-instantiating it. This works
in the following way - when you're through with the object you got from
XAO::Objects->new() method call XAO::Objects->recycle() on it instead of
just letting it die on going out of existance scope.

Even if this technique is used in just one place -- Web::Page's
display() method it still drastically improves performance as this is
the place where most calls to new() are coming from anyway. So even for
existing code the performance is significantly improved without any
modifications.

Recycle() function does not recycle objects unles it knows they are
recyclable. It checks it once and remembers results by checking if an
object has a recycle() method and that this method returns a reference
to the object. If you want to make your object based on a recyclable
object non-recyclable just override recycle() method and return undef
from it.

Web::Page is a recyclable object and therefore all standard Web objects
are recyclable as well.

B<NOTE:> Current implementation always assumes that the object was
created for the same project that is current at the time you call
recycle(). If that's not true - do not recycle.

=cut

sub recycle ($$) {
    my $class=scalar(@_)==2 ? shift : 'XAO::Objects';
    my $obj=shift;

    my $objname=$obj->{objname} || return;
    my $sitename=XAO::Projects::get_current_project_name() || '';

    my $odesc=$recyclables{$objname}->{$sitename};

    if(!$odesc) {
        my $rc=$obj->can('recycle') && $obj->recycle;
        if($rc) {
            $odesc={ recyclable => 1,
                     pool => [ $obj ],
                   };
            #dprint "Recycling $objname ($obj) for $sitename for the first time";
        }
        else {
            $odesc={ recyclable => 0 };
            #dprint "Non-recyclable object $objname for $sitename";
        }
        $recyclables{$objname}->{$sitename}=$odesc;
        return;
    }
    elsif($odesc->{recyclable}) {
        return unless $obj->recycle;
        my $ra=$odesc->{pool};
        return if @$ra>=10;
        push @$ra,$obj;
        #dprint "Recycling $objname ($obj) for $sitename";
        return;
    }
    else {
        return;
    }
}

###############################################################################

1;
__END__

=back

=head1 AUTHOR

Copyright (c) 2000-2002 XAO Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Have a look at: L<XAO::Web>, L<XAO::Utils>, L<XAO::FS>.
