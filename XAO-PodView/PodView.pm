=head1 NAME

XAO::DO::Web::PodView - POD files viewer for XAO::Web

=head1 SYNOPSIS

 <%PodView module="XAO::Web"%>

=head1 DESCRIPTION

This displayable object for XAO::Web parses pod documentation inside
installed perl modules and displays it. How it will look depends on a
set of templates you provide and can theoretically vary from HTML to
PostScript to XML as no specific HTML code is included in the module
itself.

You can use this object to view documentation for all Perl modules
installed in your system.

Default templates allow you to put the followin into your templates to
display this manual pages for example:

 <%PodView module="XAO::DO::Web::PodView"%>

Alternatively you can give it a path to the file that would contain
pod documentation after being processed by XAO::Page. This way you can
even create and display dynamic POD documents.

 <%PodView path="/bits/example.pod"%>

By default it assumes that the output is "html" and uses appropriate
=begin, =for and =end blocks. If you want to change that feel free to
pass "format" argument:

 <%PodView module="IO::File" format="ps"%>

That will also change directory prefix for all templates internally used
by PodView object -- you will need to provide them. And B<please, please,
please> -- if you are a PostScript guru who can create a set of templates
that will produce nice looking PostScript document -- do a favor for the
Perl community and share it, mail it to me (am@xao.com) and I'll
make sure it will be included in the next release with correct
acknowledgements.

The following templates are shipped with the PodView object and should
be modified if you want. Remember, that you do not need to modify them
in system directory - just copy them to your site and modify them there.
You should actually only alter templates that you need, not all of them!

 bits/podview/html/command-back-bullet  =back
 bits/podview/html/command-back-number  =back
 bits/podview/html/command-back-text    =back
 bits/podview/html/command-head1        =head1
 bits/podview/html/command-head2        =head2
 bits/podview/html/command-item-bullet  =item
 bits/podview/html/command-item-number  =item
 bits/podview/html/command-item-text    =item
 bits/podview/html/command-over-bullet  =over
 bits/podview/html/command-over-number  =over
 bits/podview/html/command-over-text    =over
 bits/podview/html/command-unknown      unknown commands
 bits/podview/html/embed-bold           B<text>
 bits/podview/html/embed-code           C<text>
 bits/podview/html/embed-escape         E<text>
 bits/podview/html/embed-file           F<text>
 bits/podview/html/embed-italic         I<text>
 bits/podview/html/embed-link-man       L<system manpage>
 bits/podview/html/embed-link-pod       L<perl module>
 bits/podview/html/embed-link-url       L<http://site.com/>
 bits/podview/html/embed-nbsp           S<text>
 bits/podview/html/embed-unknown        unknown<text>
 bits/podview/html/pod-start            start of the document
 bits/podview/html/pod-stop             end of the document
 bits/podview/html/textblock-start      start of text paragraphs
 bits/podview/html/textblock-stop       end of paragraphs
 bits/podview/html/textblock-text       paragraph body
 bits/podview/html/verbatim-start       start of verbatim paragraph
 bits/podview/html/verbatim-stop        stop of verbatim paragraph
 bits/podview/html/verbatim-text        verbatim paragraph body

A little explanation is required for start and stop for textblock and
verbatim. PodView calls 'start' before a set of continous textblock or
verbatim paragraphs and 'stop' after it.

Normally start and stop for textblock are empty with <P> and </P>
included in textblock-body. For verbatim mode start contains <PRE> and
stop contains </PRE>. That means in effect that empty line between two
verbatim paragraphs would not break verbatim mode as it happens with all
pod processors I looked at.

And at the same time if you do want to treat verbatim paragraphs one by
one - you're free to do so by altering templates.

=head1 METHODS

No publicly available methods except overriden display().

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2001 XAO Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.

=cut

###############################################################################
package XAO::DO::Web::PodView;
use strict;
use IO::File;
use IO::String;
use XAO::Utils;
use XAO::Objects;

use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
$VERSION='1.02';

##
# Loading and displaying perl module documentation.
#
sub display ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    ##
    # Creating parser
    #
    my $parser=XAO::Objects->new(objname => 'Web::PodView::Parser',
                                 dispobj => $self->object(),
                                 format => $args->{format} || 'html');

    ##
    # Input handler
    #
    my $ih;

  ##
  # Do we have path to pod document?
  #
  if($args->{path} || $args->{template})
   { my $text=$self->object->expand($args);
     $ih=IO::String->new($text);
   }

  ##
  # Finding file for the given module
  #
  if(!$ih && $args->{module})
   { my $file=$parser->find_module_file($args->{module});
     if(!$file)
      { $self->object->display(path => $args->{error}) if $args->{error};
        return;
      }
     $ih=IO::File->new;
     if(!$ih->open($file))
      { $self->object->display(path => $args->{error}) if $args->{error};
        return;
      }
   }

  ##
  # No input?? Too bad.
  #
  if(!$ih)
   { $self->object->display(path => $args->{error}) if $args->{error};
     return;
   }

  ##
  # Parsing
  #
  my $oh=IO::String->new();
  $parser->parse_from_filehandle($ih,$oh);
}

###############################################################################
1;
