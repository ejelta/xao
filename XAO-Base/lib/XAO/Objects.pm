=head1 NAME

XAO::Objects - dynamic objects loader

=head1 SYNOPSIS

 use XAO::Objects;

 sub foo {
    ...
    my $page=XAO::Objects->new(objname => 'Web::Page');
 }

=head1 DESCRIPTION

XXX - provide real description ASAP. For now code is the only description.

=cut

###############################################################################
package XAO::Objects;
use strict;
use XAO::Base qw($homedir $projectsdir);
use XAO::Utils qw(:args :debug);
use XAO::Errors qw(XAO::Objects);
use XAO::Projects;

##
# Prototypes
#
sub load (%);
sub new ($%);

##
# Module version.
#
use vars qw($VERSION);
($VERSION)=(q$Id: Objects.pm,v 1.4 2001/11/10 00:30:30 am Exp $ =~ /(\d+\.\d+)/);

##
# Loads object into memory.
#
# It first looks into site directory for object package, then into XAO
# objects directory. If found - loads and creates object, otherwise
# returns undef.
#
# It's assumed that standard objects are in XAO::DO:: namespace and site
# overriden objects are in XAO::DO::sitename:: namespace.
#
# On success returns class name of the loaded object.
#
# It is allowed to call load outside of any site context - it just would
# not check site specific objects.
#
# Arguments:
#  objname => object name (required)
#  baseobj => ignore site specific objects even if they exist (optional).
#  sitename => should only be used to load Config object.
#
use vars qw(%objref_cache);
sub load (%) {
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
        $sitename=XAO::Projects::get_current_project_name() || '';
    }

    ##
    # Checking cache first
    #
    return $objref_cache{$sitename}->{$objname}
        if $sitename &&
           exists($objref_cache{$sitename}) &&
           exists($objref_cache{$sitename}->{$objname});
    return $objref_cache{'/'}->{$objname}
        if exists($objref_cache{'/'}) &&
           exists($objref_cache{'/'}->{$objname});

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
            eval "\n# line 1 \"$objfile\"\n" . $text;
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
    $objref_cache{$system ? '/' : $sitename}->{$objname}=$objref;
}

##
# Creates an instance of named object. There is just one required
# argument - 'objname', everything else is passed into object's
# constructor unmodified.
#
sub new ($%) {
    my $class=(scalar(@_)%2 || ref($_[1]) ? shift(@_) : 'XAO::Objects');
    my $args=get_args(\@_);

    ##
    # Looking up what is real object reference for that objname.
    #
    my $objref=$class->load($args) ||
        throw XAO::E::Objects "new - can't load object ($args->{objname})";

    ##
    # Creating instance of that object
    #
    my $obj=eval $objref.'->new($args)' ||
        throw XAO::E::Objects "new - error creating instance of $objref ($@)";

    $obj;
}

###############################################################################
1;
__END__

=head1 AUTHOR

Copyright (c) 2001 XAO Inc.

Author is Andrew Maltsev <am@xao.com>.
