=head1 NAME

XAO::DO::Web::Page - core object of XAO::Web rendering system

=head1 SYNOPSIS

Outside web environment:

 my $page=XAO::Objects->new(objname => 'Page');
 my $date=$page->expand(template => '<%Date%>');

Inside XAO::Web template:

 <%Page path="/bits/some-path" ARG={<%SomeObject/f%>}%>

=head1 DESCRIPTION

As XAO::DO::Web::Page object (from now on just Page displayable
object) is the core object for XAO::Web web rendering engine we
will start with basics of how it works.

The goal of XAO::Web rendering engine is to produce HTML data file
that can be understood by browser and displayed to a user. It will
usually use database tables, templates and various displayable objects
to achieve that.

Every time a page is requested in someone's web browser a XAO::Web handler
gets executed, prepares site configuration, opens database connection,
determines what would be start object and/or start path and does a lot
of other useful things. If you have not read about it yet it is suggested to
do so -- see L<XAO::Web::Intro> and L<XAO::Web>.

Although XAO::Web handler can call arbitrary object with arbitrary arguments
to produce an HTML page we will assume the simplest scenario of calling
Page object with just one argument -- path to an HTML file template for
simplicity (another way to pass some template to a Page object is
to pass argument named "template" with the template text as the
value). This is the default behavior of XAO::Web handler if you
do not override it in configuration.

Let's say user asked for http://oursite.com/ and XAO::Web translated
that into the call to Page's display method with "path" argument set to
"/index.html". All template paths are treated relative to "templates"
directory in site directory or to system-wide "templates" directory if
site-specific template does not exist. Suppose templates/index.html file
in our site's home directory contains the following:

  Hello, World!

As there are no special symbols in that template Page's display method
will return exactly that text without any changes (it will also cache
pre-parsed template for re-use under mod_perl, but this is irrelevant
for now).

Now let's move to a more complex example -- suppose we want some kind of
header and footer around our text:

  <%Page path="/bits/header-template"%>

  Hello, World!

  <%Page path="/bits/footer-template"%>

Now, Page's parser sees reference to other items in that template -
these things, surrounded by <% %> signs. What it does is the following.

First it checks if there is an argument given to original Page's
display() method named 'Page' (case sensitive). In our case there is no
such argument present.

Then, as nor such static argument is found, it attempts to load an
object named 'Page' and pass whatever arguments given to that object's
display method.

I<NOTE:> it is recommended to name static
arguments in all-lowercase (for standard parameters accepted by an
object) or all-uppercase (for parameters that are to be included into
template literally) letters to distinguish them from object names where
only the first letter of every word is capitalized.

In our case Page's parser will create yet another instance of Page
displayable object and pass argument "path" with value
"/bits/header-template".  That will include the content of
templates/bits/header-template file into the output. So, if the content
of /bits/header-template file is:

  <HTML><BODY BGCOLOR="#FFFFFF">

And the content of /bits/footer-template is:

  </BODY></HTML>

Then the output produced by the original Page's display would be:

  <HTML><BODY BGCOLOR="#FFFFFF">

  Hello, World!

  </BODY></HTML>

For actual site you might opt to use specific objects for header and
footer (see L<XAO::DO::Web::Header> and
L<XAO::DO::Web::Footer>):

  <%Header title="My first XAO::Web page"%>

  Hello, World!

  <%Footer%>

Page's parser is not limited to only these simple cases, you can embed
references to variables and objects almost everywhere. In the following
example Utility object (see L<XAO::DO::Web::Utility>) is used to
build complete link to a specific page:

  <A HREF="<%Utility mode="base-url"%>/somepage.html">blah blah blah</A>

If current (configured or guessed) site URL is "http://demosite.com/"
this template would be translated into:

  <A HREF="http://demosite.com/somepage.html">blah blah blah</A>

Even more interesting is that you can use embedding to construct
arguments for embedded objects:

  <%Date gmtime={<%CgiParam param="shippingtime" default="0"%>}%>

If your page was called with "shippingtime=984695182" argument in the
query then this code would expand to (in PST timezone):

  Thu Mar 15 14:26:22 2001

As you probably noticed, in the above example argument value was in
curly brackets instead of quotes. Here are the options for passing
values for objects' arguments:

=over

=item 1

You can surround value with double quotes: name="value". This is
recommended for short strings that do not include any " characters.

=item 2

You can surround value with matching curly brackets. Curly brackets
inside are allowed and counted so that these expansions would work:

 name={Some text with " symbols}

 name={Multiple
       Lines}

 name={something <%Foo bar={test}%> alsdj}

The interim brackets in the last example would be left untouched by the
parser. Although this example won't work because of unmatched brackets:

 name={single { inside}

See below for various ways to include special symbols inside of
arguments.

=item 3

Just like for HTML files if the value does not include any spaces or
special symbols quotes can be left out:

 number=123

But it is not recommended to use that method and it is not guaranteed
that this will remain legal in future versions. Kept mostly for
compatibility with already deployed code.

=back

Sometimes it is necessary to include various special symbols into
argument values. This can be done in the same way you would embed
special symbols into HTML tags arguments:

=over

=item *

By using &tag; construct, where tag could be "quot", "lt", "gt" and
"amp" for double quote, left angle bracket, right angle bracket and
ampersand respectfully.

=item *

By using &#NNN; construct where NNN is the decimal code for the
corresponding symbol. For example left curly bracket could be encoded as
&#123; and right curly bracket as &#125;. The above example should be
re-written as follows to make it legal:
 
 name={single &#123; inside}

=back

Arguments can include as many level of embedding as you like, but you
must remember:

=over

=item 1

That all embedded arguments are expanded from the deepest
level up to the top before executing main object.

=item 2

That undefined references to either non-existing object or non-existing
variable produce a run-time error and the page is not shown.

=item 3

All embedded arguments are processed in the same arguments space that
the template one level up from them.

=back

As a test of how you understood everything above please attempt to
predict what would be printed by the following example (after reading
L<XAO::DO::Web::SetArg> or guessing its meaning). The answer is
about one page down, at the end of description chapter.

 <%SetArg name="V1" value="{}"%>
 <%SetArg name="V2" value={""}%>
 <%Page template={<%V1%><%V2%>
 <%Page template={<%SetArg name="V2" value="[]" override%><%V2%>}%>
 <%V2%><%V1%>}
 %>

In most cases it is not recommended to make complex inline templates
though, it is usually better to move sub-templates into a separate file
and include it by passing path into Page. Usually it is also more time
efficient because templates with known paths are cached in parsed state
first time they used while inlined templates are parsed every time.

It is usually good idea to make templates as simple as possible and move
most of the logic inside of objects. To comment what you're doing in
various parts of template you can use normal HTML-style comments. They
are removed from the output completely, so you can include any amounts
of text inside of comments -- it won't impact the size of final HTML
file. Here is an example:

 <!-- Header section -->
 <%Header title="demosite.com"%>
 <%Page path="/bits/menu"%>

 <!-- Main part -->
 <%Page path="/bits/body"%>

 <!-- Footer -->
 <%Footer%>

One exception is JavaScript code which is usually put into comments. The
parser would NOT remove comments if open comment is <!--//. Here is an
example of JavaScript code:

 <SCRIPT LANGUAGE="JAVASCRIPT"><!--//
 function foo ()
 { alert("bar");
 }
 //-->
 </SCRIPT>

=head2 NOTE FOR HARD-BOILED HACKERS

If you do not like something in the parser behavior you can define
site-specific Page object and refine or replace any methods of system
Page object. Your new object would then be used by all system and
site-specific objects B<for your site> and won't impact any other sites
installed on the same host. But this is mentioned here merely as a
theoretical possibility, not as a good thing to do.

=head2 TEST OUTPUT

The output of the test above would be:

 {}""
 []
 ""{}

In fact first two SetArg's would add two empty lines in front because
they have carriage returns after them, but this is only significant if
your HTML code is space-sensitive.

=head1 METHODS

Publicly accessible methods of Page (and therefor of all objects derived
from Page unless overwritten) are:

=over

=cut

###############################################################################
package XAO::DO::Web::Page;
use strict;
use XAO::Utils;
use XAO::Cache;
use XAO::Templates;
use XAO::Objects;
use XAO::Projects qw(:all);
use XAO::PageSupport;
use Error qw(:try);

use base XAO::Objects->load(objname => 'Atom');

use vars qw($VERSION);
($VERSION)=(q$Id: Page.pm,v 1.13 2002/02/20 01:03:29 am Exp $ =~ /(\d+\.\d+)/);

##
# Prototypes
#
sub cache ($%);
sub cgi ($);
sub check_db ($);
sub dbh ($);
sub display ($%);
sub editable ();
sub expand ($%);
sub finaltextout ($%);
sub object ($%);
sub odb ($);
sub parse ($%);
sub parse_args ($);
sub siteconfig ($);
sub textout ($%);

###############################################################################

=item display (%)

Displays given template to the current output buffer. The system uses
buffers to collect all text displayed by various objects in a rather
optimal way using XAO::PageSupport (see L<XAO::PageSupport>)
module. In XAO::Web handler the global buffer is initialized and after all
displayable objects have worked their way it retrieves whatever was
accumulated in that buffer and displays it.

This way you do not have to think about where your output goes as long
as you do not "print" anything by yourself - you should always call
either display() or textout() to print any piece of text.

Display() accepts the following arguments:

=over

=item path => 'path/to/the/template'

Gives Page a path to the template that should be processed and
displayed.

=item template => 'template text'

Provides Page with the actual template text.

=item unparsed => 1

If set it does not parse template, just displays it literally.

=back

Any other argument given is passed into template unmodified as a
variable. Remember that it is recommended to pass variables using
all-capital names for better visual recognition.

Example:

 $obj->display(path => "/bits/left-menu", ITEM => "main");

For security reasons is also recommended to put all sub-templates into
/bits/ directory under templates tree or into "bits" subdirectory of
some tree inside of templates (like /admin/bits/admin-menu). Such
templates cannot be displayed from XAO::Web handler by passing their path in
URL.

=cut

sub display ($%) {
    my $self=shift;
    my $args=$self->{args}=get_args(\@_);

    ##
    # Parsing template
    #
    my $page=$self->parse(path      => $args->{path},
                          template  => $args->{template});
    $page || return;

    ##
    # Template processing itself. Pretty simple, huh? :)
    #
    foreach my $item (@{$page}) {
        my $text=$item->{text};

        ##
        # <%End%> is special kind of object, processing stops where it is
        # found. Suitable to cut off carriage return at the end of template
        # and to put comments inside template.
        #
        last if !defined($text) && $item->{objname} eq 'End';

        ##
        # Trying to substitute from args if possible.
        #
        $text=$args->{$item->{objname}} unless defined($text);

        ##
        # Executing object if not.
        #
        my $itemflag=$item->{flag};
        if(!defined($text)) {
            my $obj;
        try {
            $obj=$self->object(objname => $item->{objname});
        }
        catch XAO::E::Objects with {
            my $e=shift;
            if($args->{path}) {
                eprint "Object loading error while processing path='$args->{path}'";
            }
            else {
                eprint "Object loading error";
            }
            $e->throw;
        };

        ##
        # Preparing arguments. If argument includes object references -
        # they are expanded first.
        #
        my $objargs=$item->{args};
        foreach my $a (keys %{$objargs})
         { next unless $objargs->{$a} =~ /<\%.*\%>/s;
           my %newargs=%{$args};
           $newargs{template}=$objargs->{$a};
           delete $newargs{path};
           $objargs->{$a}=$self->expand(%newargs);
         }

        ##
        # Now decoding entities from arguments. Lt, gt, amp, quot and
        # &#DEC; are supported.
        #
        map
         { my $v=$objargs->{$_};
           $v=~s/&lt;/</sg;
           $v=~s/&gt;/>/sg;
           $v=~s/&quot;/"/sg;
           $v=~s/&#(\d+);/chr($1)/sge;
           $v=~s/&amp;/&/sg;
           $objargs->{$_}=$v;
         } keys %{$objargs};

        ##
        # Executing object. For speed optimisation we call object's
        # display method directly if we're not going to do anything with
        # the text anyway. This way we avoid push/pop and two extra
        # memcpy's.
        #
        delete $self->{merge_args};
        if($itemflag && $itemflag ne 't')
         { $text=$obj->expand($objargs);
         }
        else
         { $obj->display($objargs);
         }

        ##
        # Was it something like SetArg object? Merging changes in then.
        #
        if($self->{merge_args})
         { @{$args}{keys %{$self->{merge_args}}}=values %{$self->{merge_args}};
         }
      }

     ##
     # Safety conversion - q for query, h - for html, s - for nbsp'ced
     # html, f - for tag fields, t - for text as is (default).
     #
     if(defined($text) && $itemflag && $itemflag ne 't')
      { if($itemflag eq 'h')
         { $text=XAO::Utils::t2ht($text)
         }
        elsif($itemflag eq 's')
         { $text=(defined $text && length($text)) ? XAO::Utils::t2ht($text) : "&nbsp;";
         }
        elsif($itemflag eq 'q')
         { $text=XAO::Utils::t2hq($text)
         }
        elsif($itemflag eq 'f')
         { $text=XAO::Utils::t2hf($text)
         }
      }

     ##
     # Sending out the text
     #
     $self->textout($text) if defined($text);

     ##
     # Checking if this object required to stop processing
     #
     last if $self->clipboard->get('_no_more_output');
   }
}

###############################################################################

=item expand (%)

Returns a string corresponding to the expanded template. Accepts exactly
the same arguments as display(). Here is an example:

 my $str=$obj->expand(template => '<%Date%>');

=cut

sub expand ($%) {
    my $self=shift;

    ##
    # First it prepares a place in stack for new text (push) and after
    # display it calls pop to get back whatever was written. The sole
    # reason for all this is speed optimization - XAO::PageSupport is
    # implemented in C in quite optimal way.
    #
    XAO::PageSupport::push();
    $self->display(@_);
    XAO::PageSupport::pop();
}

###############################################################################

=item object (%)

Creates new displayable object correctly tied to the current one. You
should always get a reference to a displayable object by calling this
method, not by using XAO::Objects' new() method. Currently most
of the objects would work fine even if you do not, but this is not
guaranteed.

Possible arguments are (the same as for XAO::Objects' new method):

=over

=item objname => 'ObjectName'

The name of an object you want to have an instance of. Default is
'Page'. All objects are assumed to be in XAO::DO::Web namespace,
prepending them with 'Web::' is optional.

=item baseobj => 1

If present then site specific object is ignored and system object is
loaded.

=back

Example of getting Page object:

 sub display ($%) {
     my $self=shift;
     my $obj=$self->object;
     $obj->display(template => '<%Date%>');
 }

Getting FilloutForm object:

 sub display ($%) {
     my $self=shift;
     my $ff=$self->object(objname => 'FilloutForm');
     $ff->setup(...);
     ...
  }

Object() method always returns object reference or throws an exception
-- meaning that under normal circumstances you do not need to worry
about returned object correctness. If you get past the call to object()
method then you have valid object reference on hands.

=cut

sub object ($%) {
    my $self=shift;
    my $args=get_args(@_);

    my $objname=$args->{objname} || 'Page';
    $objname='Web::' . $objname unless substr($objname,0,5) eq 'Web::';

    XAO::Objects->new(
        objname => $objname,
        parent => $self,
    );
}

###############################################################################

=item textout ($)

Displays a piece of text literally, without any changes.

It used to be called as textout(text => "text") which is still
supported for compatibility, but is not recommended any more. Call it
with single argument -- text to be displayed.

Example:

 $obj->textout("Text to be displayed");

This method is the only place where text is actually gets displayed. You
can override it if you really need some other output strategy for you
object. Although it is not recommended to do so.

=cut

sub textout ($%) {
    my $self=shift;
    return unless @_;
    if(@_ == 1) {
        XAO::PageSupport::addtext($_[0]);
    }
    else {
        my %args=@_;
        XAO::PageSupport::addtext($args{text});
    }
}

###############################################################################

=item finaltextout ($)

Displays some text and stops processing templates on all levels. No more
objects should be called in this session and no more text should be
printed.

Used in Redirect object to break execution immediately for example.

Accepts the same arguments as textout() method.

=cut

sub finaltextout ($%) {
    my $self=shift;
    $self->textout(@_);
    $self->clipboard->put(_no_more_output => 1);
}

###############################################################################

=item dbh ()

Returns current database handler or throws an error if it is not
available.

Example:

 sub display ($%)
     my $self=shift;
     my $dbh=$self->dbh;

     # if you got this far - you have valid DB handler on hands
 }

=cut

sub dbh ($) {
    my $self=shift;
    return $self->{dbh} if $self->{dbh};
    $self->{dbh}=$self->siteconfig->dbh;
    return $self->{dbh} if $self->{dbh};
    throw $self "dbh - no database connection";
}

###############################################################################

=item odb ()

Returns current object database handler or throws an error if it is not
available.

Example:

 sub display ($%) {
     my $self=shift;
     my $odb=$self->odb;

     # ... if you got this far - you have valid DB handler on hands
 }

=cut

sub odb ($) {
    my $self=shift;
    return $self->{odb} if $self->{odb};

    $self->{odb}=$self->siteconfig->odb;
    return $self->{odb} if $self->{odb};

    throw $self "odb - requires object database connection";
}

###############################################################################

=item cgi ()

Returns CGI object reference (see L<CGI>) or throws an error if it is
not available.

=cut

sub cgi ($) {
    my $self=shift;
    $self->siteconfig->cgi;
}

###############################################################################

=item clipboard ()

Returns clipboard object, which inherets XAO::SimpleHash methods. Use
this object to pass data between various objects that work together to
produce a page. Clipboard is cleaned before starting every new session.

=cut

sub clipboard ($) {
    my $self=shift;
    $self->siteconfig->clipboard;
}

###############################################################################

=item siteconfig ()

Returns site configuration reference. Be careful with your changes to
configuration, try not to change configuration -- use clipboard to pass
data between objects. See L<XAO::Projects> for more details.

=cut

sub siteconfig ($) {
    my $self=shift;
    return $self->{siteconfig} if $self->{siteconfig};
    $self->{siteconfig}=$self->{sitename} ? get_project($self->{sitename})
                                          : get_current_project();
}

###############################################################################

=item base_url (%)

Returns base_url for secure or normal connection. Depends on parameter
"secure" if it is set, or current state if it is not.

Examples:

 # Returns secure url in secure mode and normal
 # url in normal mode.
 #
 my $url=$self->base_url; 

 # Return secure url no matter what
 #
 my $url=$self->base_url(secure => 1);

 # Return normal url no matter what
 #
 my $url=$self->base_url(secure => 0);

=cut

sub base_url ($;%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $url;
    my $secure=$args->{secure};
    $secure=$self->is_secure unless defined $secure;
    if($secure) {
        $url=$self->siteconfig->get('base_url_secure');
        if(!$url) {
            $url=$self->siteconfig->get('base_url');
            $url=~s/^http:/https:/i;
        }
    } else {
        $url=$self->siteconfig->get('base_url');
    }
    $url;
}

###############################################################################

=item is_secure ()

Returns 1 if the current the current connection is a secure one or 0
otherwise.

=cut

sub is_secure ($) {
    my $self=shift;
    return $self->cgi->https() ? 1 : 0;
}

###############################################################################

=item pageurl (%)

Returns full URL of current page without parameters. Accepts the same
arguments as base_url() method.

=cut

sub pageurl ($;%) {
    my $self=shift;
    my $url=$self->base_url(@_);
    my $url_path=$self->clipboard->get('pagedesc')->{fullpath};
    $url_path="/".$url_path unless $url_path=~ /^\//;
    $url.$url_path;
}

###############################################################################

=item merge_args (%)

This is an utility method that joins together arguments from `newargs'
hash with `oldargs' hash (newargs override objargs). Useful to pass
arguments to sub-objects.

Does not modify any argument hashes, creates new one instead and
returns reference to it.

Example -- setting new path and leaving all other arguments untouched:

 sub display ($%) {
     my $self=shift;
     my $args=get_args(\@_);
     my $obj=$self->object;
     $obj->display($self->merge_args(oldargs => $args,
                                     newargs => { path => '/bits/new-path' }
                                    ));
 }

=cut

sub merge_args ($%) {
    my $self=shift;
    eprint ref($self)."::merge_args - obsolete, use XAO::Utils::merge_refs";
    my $args=get_args(\@_);
    my $oldargs=$args->{oldargs};
    my $newargs=$args->{newargs};
    my %a;
    map {
        $a{$_}=$oldargs->{$_}
    } keys %{$oldargs} if $oldargs;
    map {
        $a{$_}=$newargs->{$_} if defined($newargs->{$_})
    } keys %{$newargs} if $newargs;
    \%a;
}

###############################################################################
# Parses given template and returns reference to array of the following
# structure:
#  [ { text => text }
#  , { text => text }
#  , { objname => object name
#    , args => { object args }
#    , objtext => unparsed object text
#    , flag => text (h, q, f or t)
#    }
#  , { text => text }
#  ]
#
### my %parsed_cache;
sub parse ($%) {
    my ($self,%args)=@_;
    my $classname=ref $self || $self;
    if(! keys %args) {
        eprint "$classname : No arguments given";
        return undef;
    }

    ##
    # Getting template text
    #
    my $template;
    if(defined($args{template})) {
        $template=$args{template};
    }
    else {
        my $path=$args{path} ||
            throw $self "parse - No path given to a Page object";

        if($self->debug_check('show-path')) {
            dprint $self->{objname}."::parse - path='$path'";
        }

        #XXX# return $parsed_cache{$path} if exists($parsed_cache{$path});

        $template=XAO::Templates::get(path => $path);
        defined($template) ||
            throw $self "parse - no template found (path=$path)";
    }

    ##
    # Checking if we do not need to parse that template.
    #
    if($self->{args}->{unparsed}) {
        return [ { text => $template } ];
    }

    ##
    # Parsing
    #
    my @page;
    $template=~s/<!--(?!\/\/).*?-->//sg;
    my @parts=split('(<%|%>|"|{|})',$template);
    my $in_object=0;
    my $in_quotes=0;
    my $in_brackets=0;
    my $objtext;
    for(my $pnum=0; $pnum!=@parts; $pnum++) {
        my $part=$parts[$pnum];
        if($in_object) {
            if($in_brackets) {
                $objtext.=$part;
                if($part eq '{') {
                    $in_brackets++;
                }
                elsif($part eq '}') {
                    $in_brackets--;
                }
            }
            elsif($part eq '"') {
                $objtext.='"';
                if($in_quotes) {
                    $in_quotes=0;
                }
                else {
                    $in_quotes=1;
                }
            }
            elsif($in_quotes) {
                $objtext.=$part;
            }
            elsif($part eq '{') {
                $in_brackets++;
                $objtext.='{';
            }
            elsif($part eq '<%') {
                $in_object++;
                $objtext.=$part;
            }
            elsif($part eq '%>') {
                $in_object--;
                if(!$in_object) {
                    push(@page,{ objtext => $objtext });
                }
                else {
                    $objtext.=$part;
                }
            }
            else {
                $objtext.=$part;
            }
        }
        else {
            if($part eq '<%') {
                $in_object++;
                $objtext='';
            }
            else {
                push(@page,{ text => $part });
            }
        }
    }

    $in_object && throw $self 'display - not closed object in template';

    foreach my $item (@page) {
        next unless defined($item->{objtext});
        if($item->{objtext} !~ /^\s*(\w[\w\.:]*)(\/(\w+))?\s*(.*)$/s) {
            $item->{text}='<%';	# <%%> is just a funny way to embed <%
            delete $item->{objtext};
            next;
        }
        $item->{objname}=$1;
        $item->{flag}=$3 ? $item->{flag}=lc(substr($3,0,1)) : 't';
        $item->{args}=parse_args($4);
    }

    ##
    # Document structure
    #
    ## for(my $i=0; $i!=@page; $i++)
    ##  { dprint "$i) ",join(",",%{$page[$i]}),"\n";
    ##    if($page[$i]->{args})
    ##     { my $args=$page[$i]->{args};
    ##       foreach my $a (sort keys %{$args})
    ##        { dprint "   $a => $args->{$a}\n";
    ##        }
    ##     }
    ##  }

    ## XXX - Cache have to be much more elaborate, the same template can
    ## be parsed into different things and we can't cache it without
    ## content checks. Need to check if hashing by complete content is
    ## faster then just re-parsing.
    ## ##
    ## # Storing into the cache if possible
    ## #
    ## $parsed_cache{$args{path}}=\@page unless defined($args{template});

    \@page;
}

##
# States for argument parser.
#
my $SPACE=0;
my $GOT_NAME=1;
my $GOT_EQUAL=2;
my $AFTER_EQUAL=3;
my $GOT_QUOTE=4;
my $GOT_LCB=5;

##
# Pretty hairy subroutine - parsing arguments and values from text
# string into hash reference.
#
# Example:
#  $parse_args('a b=bb c="c c&quot;c" d={dd&#125; {" 123}}');
#
# will return:
#  { a => 'on',
#    b => 'bb',
#    c => 'c c"c',
#    d => 'dd} {" 123}'
#  }
#
sub parse_args ($)
{ my $str=$_[0];
  return {} unless defined($str);
  my @tokens=split(/("|=|{|}|\s)/s,$str.' ');
  my %args;

  my $state=$SPACE;
  my $name='';
  my $value='';
  my $level=0;
  foreach my $token (@tokens)
   { if($state == $SPACE)
      { $value='';
        if($token =~ /^[a-z][\w.]*$/i)
         { $name=$token;
           $state=$GOT_NAME;
         }
        elsif($token eq '' || $token =~ /\s+/)
         {
         }
        else
         { eprint "Wrong argument name - $token";
           return {};
         }
      }
     elsif($state == $GOT_NAME)
      { if($token eq '=')
         { $state=$GOT_EQUAL;
         }
        elsif($token =~ /\s+/)
         { $args{$name}='on';
           $state=$SPACE;
         }
        else
         { eprint "Syntax error 1 in arguments, token='$token'";
           return {};
         }
      }
     elsif($state == $GOT_EQUAL)
      { if($token eq '')
         { $state=$AFTER_EQUAL;
         }
        else
         { $args{$name}=$token;
           $state=$SPACE;
         }
      }
     elsif($state == $AFTER_EQUAL)
      { if($token =~ /\s+/)
         { $args{$name}='';
           $state=$SPACE;
         }
        elsif($token eq '"')
         { $state=$GOT_QUOTE;
         }
        elsif($token eq '{')
         { $state=$GOT_LCB;
           $level++;
         }
        else
         { eprint "Syntax error 2 in arguments, token='$token'";
           return {};
         }
      }
     elsif($state == $GOT_QUOTE)
      { if($token eq '"')
         { $args{$name}=$value;
           $state=$SPACE;
         }
        else
         { $value.=$token;
         }
      }
     elsif($state == $GOT_LCB)
      { if($token eq '{')
         { $level++;
           $value.=$token;
         }
        elsif($token eq '}')
         { $level--;
           if($level)
            { $value.=$token;
            }
           else
            { $args{$name}=$value;
              $state=$SPACE;
            }
         }
        else
         { $value.=$token;
         }
      }
     else
      { eprint "Wow, got into unknown state!";
      }
   }
  if($state != $SPACE)
   { eprint "Syntax error in arguments, quote was not closed";
     return {};
   }
  \%args;
} 

##
# This is overriden in all editable objects. Default is "not editable".
# XXX - unused.
#
sub editable () {
    eprint "editable - should not be used any more";
    return 0;
}

###############################################################################

=item cache (%)

Creates or retrieves a cache for use in various Page based
objects. Arguments are directly passed to XAO::Cache's new() method (see
L<XAO::Cache>) except for 'name' argument which is used to identify the
requested cache.

If a cache with that name was already initialized before it is not
re-created, but previously created version is returned instead.

Example:

 my $cache=$self->cache(
     name        => 'fubar',
     retrieve    => \&real_retrieve,
     coords      => ['foo','bar'],
     expire      => 60
 );

=cut

sub cache ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $name=$args->{name} ||
        throw $self "cache - no 'name' argument";

    my $cache_list=$self->siteconfig->get('cache_list');
    if(! $cache_list) {
        $cache_list={};
        $self->siteconfig->put(cache_list => $cache_list);
    }

    my $cache=$cache_list->{$name};
    if(! $cache) {
        $cache=XAO::Cache->new($args);
        $cache_list->{$name}=$cache;
    }

    return $cache;
}

sub debug_check ($$) {
    my $self=shift;
    my $type=shift;
    return $self->clipboard->get("debug/Web/Page/$type");
}

sub debug_set ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    foreach my $type (keys %$args) {
        $self->clipboard->put("debug/Web/Page/$type",$args->{$type} ? 1 : 0);
    }
}

###############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2000-2002 XAO, Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::Objects>,
L<XAO::Projects>,
L<XAO::Templates>.

=cut
