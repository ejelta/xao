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
use XAO::Utils qw(:args fround);
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

###############################################################################

use vars qw($VERSION);
($VERSION)=(q$Id: Styler.pm,v 1.9 2003/10/03 04:33:09 am Exp $ =~ /(\d+\.\d+)/);

sub separate_thousands ($);

###############################################################################

sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    ##
    # Special formatting for special fields.
    #
    # number => 1,234,456,789
    #
    my $template="<%NUMBER%>" if defined($args->{number});
    my $number=int($args->{number} || 0);
    $number=separate_thousands($number);

    ##
    # dollars => $1'234.78
    #
    $template="<%DOLLARS%>" if defined($args->{dollars}) || defined($args->{dollar});
    my $dollars=$args->{format}
                  ? sprintf($args->{format},$args->{dollars} || $args->{dollar} || 0)
                  : sprintf('%.2f',fround($args->{dollars} || $args->{dollar} || 0,100));
    $dollars='$' . separate_thousands($dollars);

    ##
    # real => 1'234.78
    #
    $template='<$REAL$>' if defined($args->{real});
    my $real=$args->{format}
             ? sprintf($args->{format},$args->{real} || 0)
             : sprintf("%.2f",$args->{real} || 0);
    $real=separate_thousands($real);         

    ##
    # Percents
    #
    my $percent=0;
    if(defined($args->{percent})) {
        $template='<$PERCENT$>';
        if(defined($args->{total})) {
            $percent=$args->{total} ? $args->{percent}/$args->{total} : 0;
        }
        else {
            $percent=$args->{percent};
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
                       , PERCENT => sprintf($args->{format} || '%.2f%%',
                                            $percent*100)
                       , %{$args});
}

############################## PRIVATE ########################################

sub separate_thousands ($) {
    my $value=shift;

    return $value unless $value =~ /^(\d+)(\.\d+)?$/;

    my ($i,$f)=($1,$2);

    1 while $i=~s/(\d)(\d{3}($|,))/$1,$2/;

    $i.=$f if defined $f;

    return $i;
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
