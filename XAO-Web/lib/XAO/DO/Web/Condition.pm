=head1 NAME

XAO::DO::Web::Condition - allows to check various conditions

=head1 SYNOPSIS

 Only useful in XAO::Web context.

=head1 DESCRIPTION

Example usage would be:

 <%Condition NAME1.value="<%CgiParam param=test%>"
             NAME1.path="/bits/test-is-set"
             NAME2.cgiparam="foo"
             NAME2.path="/bits/foo-is-set"
             NAME3.siteconfig="product_list"
             NAME3.template="product_list exists in siteconfig"
             default.objname="Error"
             default.template="No required parameter set"
 %>

Which means to execute /bits/test-is-set if CGI has `test'
parameter, otherwise execute /bits/foo-is-set if `foo' parameter
is set and finally, if there is no foo and no test - execute
/bits/nothing-set. For `foo' shortcut is used, because most of the
time you will check for CGI parameters anyway.

Default object to be substituted is Page. Another object may be
specified with objname. All arguments after NAMEx. are just passed
into object without any processing.

NAME1 and NAME2 may be anything, they sorted alphabetycally before
checking. So, usually if there is only one check and default - then
something meaningful is used for the name. For multiple choices just
numbers are better for names.

Condition checked in perl style - '0' and empty string is false.

Hides itself from object it executes - makes parent and parent_args
pointing to Condition's parent.

Supports the following conditions:

=over

=item value

Just constant value, usually substituted in template itself.

=item cgiparam

Parameter in CGI.

=item arg

Parent object argument.

=item siteconf

Site configuration parameter.

=item cookie

Cookie value.

=back

All values are treated as booleans only, no comparision is implemented
yet.

=cut

###############################################################################
package XAO::DO::Web::Condition;
use strict;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

sub display ($;%)
{ my $self=shift;
  my %args=%{get_args(\@_) || {}};
  my $config=$self->siteconfig;

  ##
  # First going through the list of conditions and checking them.
  #
  my $name;
  foreach my $a (sort keys %args)
   { next unless $a =~ /^(\w+)\.(number|value|arg|cgiparam|siteconf|siteconfig|cookie)$/;
     if($2 eq 'cgiparam')
      { my $param=$args{$a};
        my $cname=$1;
        if($param =~ /\s*(.*?)\s*=\s*(.*?)\s*$/)
         { my $pval=$config->cgi->param($1);
           if(defined($pval) && $pval eq $2)
            { $name=$cname;
              last;
            }
         }
        else
         { if($config->cgi->param($param))
            { $name=$cname;
              last;
            }
         }
      }
     elsif($2 eq 'arg')
      { if($self->{parent} && $self->{parent}->{args}->{$args{$a}})
         { $name=$1;
           last;
         }
      }
     elsif($2 eq 'siteconf' || $2 eq 'siteconfig')
      { if($config->get($args{$a}))
         { $name=$1;
           last;
         }
      }
     elsif($2 eq 'cookie')
      {  if($config->cgi->cookie($args{$a}))
          { $name=$1;
             last;
          }    
      }
     elsif($2 eq 'number')
      { if(($args{$a} || 0)+0)
         { $name=$1;
           last;
         }    
      }
     elsif($args{$a})	# value
      { $name=$1;
        last;
      }
   }
  $name="default" unless defined $name;

    ##
    # Building object arguments now.
    #
    my %objargs;
    foreach my $a (keys %args) {
        if($self->{parent} && $self->{parent}->{args}
                           && $a =~ /^$name\.pass\.(.*)$/) {
            $objargs{$1}=$self->{parent}->{args}->{$1};
        }
        elsif($a eq "$name.pass") {
            # See below
        }
        elsif($a =~ /^$name\.(\w.*)$/) {
            $objargs{$1}=$args{$a};
        }
    }
    return unless %objargs;

    ##
    # Now getting object and executing it.
    #
    my $obj=$self->object(objname=>$objargs{objname} || "Page");
    delete $objargs{objname};

    ##
    # If we were asked to pass complete set of arguments then merging.
    #
    if($args{"$name.pass"} && $self->{parent} && $self->{parent}->{args}) {
        my %aaa=%{$self->{parent}->{args}};
        delete $aaa{path};
        delete $aaa{template};
        $obj->display($self->merge_args(
                                oldargs => \%aaa,
                                newargs => \%objargs
                     ));
    }
    else {
        $obj->display(\%objargs);
    }
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
