=head1 NAME

XAO::DO::Web::Styler - Simple styler object

=head1 SYNOPSIS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

Styler allows to define style templates and then use them in the web
pages. It also includes formatting capabilities for various commonly
used values.

XXX - make real documentation!!

=cut

###############################################################################
package XAO::DO::Web::Styler;
use strict;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
($VERSION)=(q$Id: Styler.pm,v 1.2 2002/01/04 02:13:23 am Exp $ =~ /(\d+\.\d+)/);

sub display ($;%)
{ my $self=shift;
  my $args=get_args(\@_);

  ##
  # Special formatting for special fields.
  #
  # number => 1,234,456,789
  #
  my $template="<%NUMBER%>" if defined($args->{number});
  my $number=int($args->{number} || 0);
  1 while $number=~s/(\d)(\d{3}($|,))/$1,$2/;

  ##
  # dollars => $1'234.78
  #
  $template="<%DOLLARS%>" if defined($args->{dollars}) || defined($args->{dollar});
  my $dollars=sprintf("%.2f",$args->{dollars} || $args->{dollar} || 0);
  1 while $dollars=~s/(\d)(\d{3}($|,|\.))/$1,$2/;
  $dollars='$'.$dollars;

  ##
  # real => 1'234.78
  #
  $template="<%REAL%>" if defined($args->{real});
  my $real=sprintf("%.2f",$args->{real} || 0);
  1 while $real=~s/(\d)(\d{3}($|,|\.))/$1,$2/;

  ##
  # Percents
  #
  my $percent=0;
  if(defined($args->{percent}))
   { $template="<%PERCENT%>";
     if(defined($args->{total}))
      { $percent=$args->{total} ? $args->{percent}/$args->{total} : 0;
      }
     else
      { $percent=$args->{percent};
      }
   }

  ##
  # Displaying what we've got and any additional arguments
  #
  my $path=$args->{style};
  my $text=$args->{text};
  if($path)
   { $path="/bits/styler/$path";
     $template=undef;
   }
  else
   { $template=$text unless $template;
     $path=undef;
   }
  delete $args->{path};
  delete $args->{template};
  $self->SUPER::display( path => $path
                       , template => $template
                       , TEXT => $text
                       , NUMBER => $number
                       , DOLLARS => $dollars
                       , REAL => $real
                       , PERCENT => sprintf('%.2f%%',$percent*100)
                       , %{$args});
}

###############################################################################
1;
__END__

=head1 METHODS

No publicly available methods except overriden display().

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2000-2001 XAO, Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.

=cut
