=head1 NAME

XAO::DO::Web::Date - XAO::Web date dysplayable object

=head1 SYNOPSIS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

XXX - make real documentation!!!

=cut

###############################################################################
package XAO::DO::Web::Date;
use strict;
use POSIX qw(strftime);
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
($VERSION)=(q$Id: Date.pm,v 1.2 2002/01/04 02:13:23 am Exp $ =~ /(\d+\.\d+)/);

sub display ($;%)
{ my $self=shift;
  my $args=get_args(\@_);

  ##
  # It can be curent time or given time
  #
  my $time=$args->{gmtime} || time;

  ##
  # Checking output style
  #
  my $style=$args->{style} || '';
  my $format='';
  if(!$style)
   { $format=$args->{format};
   }
  elsif($style eq 'dateonly')
   { $format='%m/%d/%Y';
   }
  elsif($style eq 'short')
   { $format='%H:%M:%S %m/%d/%Y';
   }
  elsif($style eq 'timeonly')
   { $format='%H:%M:%S';
   }
  else
   { eprint "Unknown date style '$style'";
   }

  ##
  # Displaying according to format.
  #
  if($format)
   { $time=strftime($format,localtime($time));
   }
  else
   { $time=scalar(localtime($time));
   }
  $self->textout($time);
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
