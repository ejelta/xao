##
# This is object loader.
#
package Symphero::Objects;
use strict;
use Symphero::Defaults qw($homedir $projectsdir);
use Symphero::Utils;
use Symphero::SiteConfig;

##
# Prototypes
#
sub load (%);
sub new ($%);

##
# Module version.
#
use vars qw($VERSION);
($VERSION)=(q$Id: Objects.pm,v 1.1 2001/10/23 00:45:09 am Exp $ =~ /(\d+\.\d+)/);

##
# Loads object into memory.
#
# It first looks into site directory for object package, then into
# Symphero objects directory. If found - loads and creates object,
# otherwise returns undef.
#
# It's assumed that standard objects are in Symphero::Objects::
# namespace and site overriden objects are in sitename::Objects::
# namespace.
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
my %objref_cache;
sub load (%) {
    my $class=(scalar(@_)%2 || ref($_[1]) ? shift(@_) : 'Symphero::Objects');
    my $args=get_args(\@_);
    my $objname=$args->{objname};
    $objname || throw Symphero::Errors::Objects
                      "${class}::load - no objname given";
    my $baseobj=$args->{baseobj};

    ##
    # Config object is a special case. When we load it we do not have
    # site configuration yet and so we have to rely on supplied site
    # name.
    my $sitename;
    if($objname eq 'Config') {
        $sitename=$args->{sitename};
        $sitename || $baseobj ||
            throw Symphero::Errors::Objects "load - no sitename given for Config object";
    }
    else {
        my $siteconfig=get_site_config();
        $sitename=$siteconfig ? $siteconfig->sitename() : '';
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
    if(!$baseobj && $sitename) {
        (my $objfile=$objname) =~ s/::/\//sg;
        $objfile="$projectsdir/$sitename/objects/$objfile.pm";
        if(open(F,$objfile)) {
            local $/;
            my $text=<F>;
            close(F);
            if($text =~ s{(package\s+Symphero::Objects)::($objname\s*;)}
                         {${1}::${sitename}::$2}) {
                eval "\n# line 1 \"$objfile\"\n" . $text;
                throw Symphero::Errors::Objects
                    "Error loading $objname ($objfile) -- $@" if $@;
                $objref="Symphero::Objects::${sitename}::${objname}";
            }
            else {
                throw Symphero::Errors::Objects
                    "Package name is not Symphero::Objects::$objname in $objfile";
            }
        }
        $system=0;
    }
    if(! $objref) {
        $objref="Symphero::Objects::${objname}";
        eval "require $objref";
        throw Symphero::Errors::Objects "Error loading $objname ($objref) -- $@" if $@;
        $system=1;
    }

    ##
    # In case no object was found.
    #
    $objref || throw Symphero::Errors::Objects
                     "No object file found for sitename='$sitename', objname='$objname'";

    ##
    # Returning class name and storing into cache
    #
    $objref_cache{$system ? '/' : $sitename}->{$objname}=$objref;
}

##
# Creates instance of named object. There is just one required argument
# - 'objname', everything else is passed into object's constructor
# unmodified.
#
sub new ($%)
{ my $class=shift;
  my $args=get_args(\@_);

  ##
  # Looking up what is real object reference for that objname.
  #
  my $objref=$class->load($args);
  return undef unless $objref;

  ##
  # Creating instance of that object
  #
  my $obj=eval $objref.'->new($args)';
  $obj || throw Symphero::Errors::Objects
                "Error creating instance of $objref -- $@";
  $obj;
}

##
# Error to be thrown from Symphero::Objects
##
package Symphero::Errors::Objects;
use Error;
use vars qw(@ISA);
@ISA=qw(Error::Simple);

sub throw ($$) {
    my $self=shift;
    my $text=shift;
    $self->SUPER::throw("Symphero::Objects::" . $text);
}

##
# That's it
#
1;
