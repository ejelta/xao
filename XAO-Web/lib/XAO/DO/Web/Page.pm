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

Then, as no such static argument is found, it attempts to load an
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

For the actual site you might opt to use specific objects for header and
footer (see L<XAO::DO::Web::Header> and L<XAO::DO::Web::Footer>):

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

Even more interesting is that you can use embedding to create arguments
for embedded objects:

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

=item 4

To pass a string literally without performing any substitutions you can
use single quotes. For instance:

 <%FS
   uri="/Members/<%MEMBER_ID/f%>"
   mode="show-hash"
   fields="*"
   template='<%MEMBER_AGE/f%> -- <%MEMBER_STATUS/f%>'
 %>

If double quotes were used in this example then the parser would try to
expand <%MEMBER_AGE%> and <%MEMBER_STATUS%> variables using the current
object arguments which is not what is intended. Using single quotes it
is possible to let FS object do the expansion and therefore insert
database values in this case.

=item 5

To pass multiple nested arguments literally or to include a single quote
into the string matching pairs of {' and '} can be used:

 <%FS
   uri="/Members/<%MEMBER_ID/f%>"
   mode="show-hash"
   fields="*"
   template={'Member's age is <%MEMBER_AGE/f%>'}
 %>

=back

=head2 EMBEDDING SPECIAL CHARACTERS

Sometimes it is necessary to include various special symbols into
argument values. This can be done in the same way you would embed
special symbols into HTML tags arguments:

=over

=item *

By using &tag; construction, where tag could be "quot", "lt", "gt" and
"amp" for double quote, left angle bracket, right angle bracket and
ampersand respectfully.

=item *

By using &#NNN; construction where NNN is the decimal code for the
corresponding symbol. For example left curly bracket could be encoded as
&#123; and right curly bracket as &#125;. The above example should be
re-written as follows to make it legal:
 
 name={single &#123; inside}

=back

=head2 OUTPUT CONVERSION

As the very final step in the processing of an embedded object or
variable the parser will check if it has any flags and convert it
accordingly. This can (and should) be used to safely pass special
characters into fields, HTML documents and so on.

For instance, the following code might break if you do not use flags and
variable will contain a duoble quote character in it:

 <INPUT TYPE="TEXT" VALUE="<$VALUE$>">

Correct way to write it would be (note /f after VALUE):

 <INPUT TYPE="TEXT" VALUE="<$VALUE/f$>">

Generic format for specifying flags is:

 <%Object/x ...%> or <$VARIABLE/x$>

Where 'x' could be one of:

=over

=item f

Converts text for safe use in HTML elements attributes. Mnemonic for
remembering - (f)ield.

Will convert '123"234' into '123&quot;234'.

=item h

Converts text for safe use in HTML text. Mnemonic - (H)TML.

Will convert '123<BR>234' into '123&lt;BR&gt;234'.

=item q

Converts text for safe use in HTML query parameters. Mnemonic - (q)uery.

Will convert '123 234' into '123+234'.

Example: <A HREF="test.html?name=<$VAR/q$>">Test '<$VAR/h$>'</A>

=item s

The same as 'h' excepts that it translates empty string into
'&nbsp;'. Suitable for inserting pieces of text into table cells.

=back

It is a very good habit to use flags as much as possible and always
specify a correct conversion. Leaving output untranslated may lead to
anything from broken HTML to security violations.

=head2 LEVELS OF PARSING

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
about one page down, at the end of this chapter.

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
parser will NOT remove comments if open comment is <!--//. Here is an
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
#use Data::Dumper; #XXX - remove
use XAO::Utils;
use XAO::Cache;
use XAO::Templates;
use XAO::Objects;
use XAO::Projects qw(:all);
use XAO::PageSupport;
use Error qw(:try);

use base XAO::Objects->load(objname => 'Atom');

use vars qw($VERSION);
($VERSION)=(q$Id: Page.pm,v 1.22 2002/10/29 09:42:31 am Exp $ =~ /(\d+\.\d+)/);

##
# Prototypes
#
sub cache ($%);
sub cgi ($);
sub check_db ($);
sub dbh ($);
sub display ($%);
sub expand ($%);
sub finaltextout ($%);
sub object ($%);
sub odb ($);
sub parse ($%);
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

For security reasons it is also recommended to put all sub-templates
into /bits/ directory under templates tree or into "bits" subdirectory
of some tree inside of templates (like /admin/bits/admin-menu). Such
templates cannot be displayed from XAO::Web handler by passing their
path in URL.

=cut

sub display ($%) {
    my $self=shift;
    my $args=$self->{args}=get_args(\@_);

    ##
    # Parsing template or getting already pre-parsed template when it is
    # available.
    #
    my $page=$self->parse($args);

    ##
    # Template processing itself. Pretty simple, huh? :)
    #
    foreach my $item (@{$page}) {

        my $stop_after;
        my $itemflag;

        my $text;

        if(exists $item->{text}) {
            $text=$item->{text};
        }

        elsif(exists $item->{varname}) {
            my $varname=$item->{varname};
            $text=$args->{$varname};
            defined $text ||
                throw $self "display - undefined argument '$varname'";
            $itemflag=$item->{flag};
        }

        elsif(exists $item->{objname}) {
            my $objname=$item->{objname};

            $itemflag=$item->{flag};

            ##
            # First we're trying to substitute from arguments
            #
            $text=$args->{$objname};

            ##
            # Executing object if not.
            #
            if(!defined $text) {
                my $obj=$self->object(objname => $objname);
            
                ##
                # Preparing arguments. If argument includes object references -
                # they are expanded first.
                #
                my %objargs;
                my $ia=$item->{args};
                my $args_copy;
                foreach my $a (keys %$ia) {
                    my $v=$ia->{$a};
                    if(ref($v)) {
                        if(@$v==1 && exists($v->[0]->{text})) {
                            $v=$v->[0]->{text};
                        }
                        else {
                            if(!$args_copy) {
                                $args_copy=merge_refs($args);
                                delete $args_copy->{path};
                            }
                            $args_copy->{template}=$v;
                            $v=$self->expand($args_copy);
                        }
                    }

                    ##
                    # Decoding entities from arguments. Lt, gt, amp,
                    # quot and &#DEC; are supported.
                    #
                    $v=~s/&lt;/</sg;
                    $v=~s/&gt;/>/sg;
                    $v=~s/&quot;/"/sg;
                    $v=~s/&#(\d+);/chr($1)/sge;
                    $v=~s/&amp;/&/sg;

                    $objargs{$a}=$v;
                }

                ##
                # Executing object. For speed optimisation we call object's
                # display method directly if we're not going to do anything
                # with the text anyway. This way we avoid push/pop and at
                # least two extra memcpy's.
                #
                delete $self->{merge_args};
                if($itemflag && $itemflag ne 't') {
                    $text=$obj->expand(\%objargs);
                }
                else {
                    $obj->display(\%objargs);
                }

                ##
                # Indicator that we do not need to parse or display anything
                # after that point.
                #
                $stop_after=$self->clipboard->get('_no_more_output');

                ##
                # Was it something like SetArg object? Merging changes in then.
                #
                if($self->{merge_args}) {
                    @{$args}{keys %{$self->{merge_args}}}=values %{$self->{merge_args}};
                }
            }
        }

        ##
        # Safety conversion - q for query, h - for html, s - for nbsp'ced
        # html, f - for tag fields, t - for text as is (default).
        #
        if(defined($text) && $itemflag && $itemflag ne 't') {
            if($itemflag eq 'h') {
                $text=XAO::Utils::t2ht($text)
            }
            elsif($itemflag eq 's') {
                $text=(defined $text && length($text)) ? XAO::Utils::t2ht($text) : "&nbsp;";
            }
            elsif($itemflag eq 'q') {
                $text=XAO::Utils::t2hq($text)
            }
            elsif($itemflag eq 'f') {
                $text=XAO::Utils::t2hf($text)
            }
        }

        ##
        # Sending out the text
        #
        $self->textout($text) if defined($text);

        ##
        # Checking if this object required to stop processing
        #
        last if $stop_after;
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

=item parse ($%)

Takes template from either 'path' or 'template' and parses it. If given
the following template:

    Text <%Object a=A b="B" c={<%C/f ca={CA}%>} d='D' e={'<$E$>'}%>

It will return a reference to the array of the following structure:

    [   {   text    => 'Text ',
        },
        {   objname => 'Object',
            args    => {
                a => [
                    {   text    => 'A',
                    },
                ],
                b => [
                    {   text    => 'B',
                    },
                ],
                c => [
                    {   objname => 'C',
                        flag    => 'f',
                        args    => {
                            ca => [
                                {   text    => 'CA',
                                },
                            ],
                        },
                    },
                ],
                d => 'D',
                e => '<$E$>',
            },
        },
    ]

Templates from disk files are cached for the lifetime of the process and
are never re-parsed.

Always returns with the correct array or throws an error.

=cut

my %parsed_cache;
sub parse ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $sitename;

    ##
    # Getting template text
    #
    my $template;
    my $unparsed=$args->{unparsed};
    my $path;
    if(defined($args->{template})) {
        $template=$args->{template};
        if(ref($template)) {
            return $template;       # Pre-parsed as an argument of some upper class
        }
    }
    else {
        $path=$args->{path} ||
            throw $self "parse - no 'path' and no 'template' given to a Page object";

        $sitename=$self->{sitename} || get_current_project_name();

        if(!$unparsed && exists $parsed_cache{$sitename}->{$path}) {
            return $parsed_cache{$sitename}->{$path};
        }

        if($self->debug_check('show-path')) {
            dprint $self->{objname}."::parse - path='$path'";
        }

        $template=XAO::Templates::get(path => $path);
        defined($template) ||
            throw $self "parse - no template found (path=$path)";
    }

    ##
    # Checking if we do not need to parse that template.
    #
    if($unparsed) {
        return [ { text => $template } ];
    }

    ##
    # Parsing. If a scalar is returned it is an indicator of an error.
    #
    my $page=XAO::PageSupport::parse($template);
    ref $page ||
        throw $self "parse - $page";

    $parsed_cache{$sitename}->{$path}=$page if $path;

    return $page;
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

Or even:

 $self->object->display(template => '<%Date%>');

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

=item cache (%)

A shortcut that actually calls $self->siteconfig->cache. See the
description of cache() in L<XAO::DO::Web::Config> for more details.

=cut

sub cache ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    return $self->siteconfig->cache($args);
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

sub debug_check ($$) {
    my $self=shift;
    my $type=shift;
    return $self->clipboard->get("debug/Web/Page/$type");
}

###############################################################################

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
