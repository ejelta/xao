=head1 NAME

XAO::Utils - Utility functions widely used by XAO suite

=head1 SYNOPSIS

  use XAO::Utils (:all);    # export everything

  or

  use XAO::Utils (:none);   # do not export anything

=head1 DESCRIPTION

This is not an object, but a collection of useful utility
functions.

=cut

###############################################################################
package XAO::Utils;
use strict;
require 5.6.0;
use XAO::Errors qw(XAO::Utils);

##
# Prototypes
#
sub generate_key (;$);
sub repair_key ($);
sub set_debug ($);
sub dprint (@);
sub eprint (@);
sub t2ht ($);
sub t2hf ($);
sub t2hq ($);
sub get_args (@);
sub merge_refs (@);

use vars qw($VERSION);
($VERSION)=(q$Id: Utils.pm,v 1.2 2001/10/25 02:51:54 am Exp $ =~ /(\d+\.\d+)/);

###############################################################################
# Export control
#
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
require Exporter;
@ISA=qw(Exporter);
%EXPORT_TAGS=(
    all => \@EXPORT_OK,
    args => [qw(get_args merge_refs)],
    debug => [qw(dprint eprint)],
    html => [qw(t2ht t2hq t2hf)],
    keys => [qw(generate_key repair_key)],
    none => [],
);
@EXPORT=@{$EXPORT_TAGS{debug}};
@EXPORT_OK=(
    @{$EXPORT_TAGS{args}},
    @{$EXPORT_TAGS{debug}},
    @{$EXPORT_TAGS{html}},
    @{$EXPORT_TAGS{keys}},
);

###############################################################################

=head2 KEYS HANDLING

Utility functions in this group can be imported by using 'keys' tag:

 use XAO::Utils qw(:keys);

Here is the list of functions available:

=over

=cut

###############################################################################

=item generate_key (;$)

Generating new 8-characters random ID. Not guaranteed to be unique,
must be checked against existing database.

You can pass additional argument to add some more randomness, but it is
not required and is kept for compatibility.

Generated ID is relativelly suitable for humans - it does not contain
some letters and digits that could be easily misunderstood in writing:

=over

=item 0 (zero)

Looks the same as letter O.

=item 1 (one)

Is almost undistinguishable from capital I

=item 7

Written by american is often taken as 1 by europeans and vice versa.

=item V

Is similar to U.

=back

Examples of generated IDs are E5TUVX82, ZK845LP6 and so on. Id would
never start from digit!

=cut

sub generate_key (;$) {
    #                        1    1    2    2    3
    #              0----5----0----5----0----5----0-
    my $symbols = "2345689ABCDEFGHIJKLMNOPQRSTUWXYZ";
    my $key='';

    while(!$key || $key=~/^[0-9]+$/) {
        my $rval=pack("SSC",rand(0x10000),rand(0x10000),
                            rand(0x100)^unpack("%8C*",$_[0] || "foo"));
        for(my $i=0; $i!=8; $i++) {
            my $v=vec($rval,$i+2,4) + vec($rval,$i,1)*16;
            $key.=substr($symbols,$v,1);
        }
    }

    $key;
}

###############################################################################

=item repair_key ($)

Repairing human-entered ID. Similar letters and digits are substituted
to allowed ones.

Example:

 my $ans=<STDIN>;
 my $id=repair_key($ans);
 die "Wrong ID" unless $id;
 print "id=$id\n";

If you enter "10qwexcv" to that script it will print "IOQWEXCU".

=cut

sub repair_key ($)
{ my $key=uc($_[0]);
  $key=~s/[\r\n\s]//sg;
  return undef unless length($key) == 8;
  $key=~s/0/O/g;
  $key=~s/1/I/g;
  $key=~s/7/I/g;
  $key=~s/V/U/g;
  $key;
}

###############################################################################

=back

=head2 DEBUGGING

Utility functions in this group are imported by default, their tag name is
`debug'. In the rare event when you need everything but debug functions
you can say:

 use XAO::Utils qw(:all !:debug);

Here is the list of functions available:

=over

=cut

###############################################################################

my $debug_flag=0;

###############################################################################

=item dprint (@)

Prints all arguments just like normal "print" does but 1) it prints them
to STDERR and 2) only if you called set_debug(1) somewhere above. Useful
for printing various debug messages and then looking at them in
S<"tail -f apache/logs/error_log">.

Once you debugged your program you just turn off set_debug() somewhere at
the top and all output goes away.

Example:

 @arr=parse_my_stuff();
 dprint "Got Array: ",join(",",@arr);

B<Note:> Debugging status is global. In case of mod_perl environment
with multiple sites under the same Apache server you enable or disable
debugging for all sites at once.

=cut

sub dprint (@) {
    return unless $debug_flag;
    my $str=join("",map { defined($_) ? $_ : "<UNDEF>" } @_);
    chomp $str;
    print STDERR $str,"\n";
}

###############################################################################

=item eprint (@)

Prints all arguments to STDERR like dprint() does but
unconditionally. Great for reporting minor problems to the server log.

=cut

sub eprint (@) {
    my $str=join("",map { defined($_) ? $_ : "<UNDEF>" } @_);
    chomp $str;
    print STDERR "*ERROR: ",$str,"\n";
}

###############################################################################

=item set_debug ($)

Turns debug flag on or off. The flag is global for all packages that
use XAO::Utils!

Example:

 use XAO::Utils;

 XAO::Utils::set_debug(1);
 dprint "dprint will now work!";

=cut

sub set_debug ($) {
    $debug_flag=$_[0];
}

###############################################################################

=back

=head2 HTML ENCODING

Utility functions in this group can be imported by using 'html' tag:

 use XAO::Utils qw(:html);

Here is the list of functions available:

=over

=cut

###############################################################################

=item t2hf ($)

Escapes text to be be included in HTML tags arguments. Can be used for
XAO::Web object arguments as well.

 " ->> &quot;

All symbols from 0x0 to 0x1f and from 0x80 to 0x9f are substituted with
their codes in &#NNN; format.

=cut

sub t2hf ($) {
    my $text=t2ht($_[0]);
    $text=~s/"/&quot;/sg;
    $text=~s/([\x00-\x1f\x80-\x9f<>])/'&#'.ord($1).';'/sge;
    $text;
}

###############################################################################

=item t2hq ($)

Escapes text to be be included into URL parameters.

All symbols from 0x0 to 0x1f and from 0x80 to 0xff as well as the
symbols from [&?<>"=%#+] are substituted to %XX hexadecimal codes
interpreted by all standard CGI tools.

=cut

sub t2hq ($) {
    my $text=shift;
    $text=~s/([\x00-\x20\x80-\xff\&\?<>"=%#+])/"%".unpack("H2",$1)/sge;
    $text;
}

###############################################################################

=item t2ht ($)

Escapes text to look the same in HTML.

 & ->> &amp;
 > ->> &gt;
 < ->> &lt;

=cut

sub t2ht ($) {
    my $text=shift;
    $text=~s/&/&amp;/sg;
    $text=~s/</&lt;/sg;
    $text=~s/>/&gt;/sg;
    $text;
}

###############################################################################

=back

=head2 ARGUMENTS HANDLING

Utility functions in this group are imported by default, their tag name is
`args'. For example if you need everything but them you can say:

 use XAO::Utils qw(:all !:args);

Here is the list of functions available:

=over

=cut

###############################################################################

=item get_args ($)

Probably one of the most used functions throughout XAO
tools. Understands arguments in the variety of formats and always
returns a hash reference as the result.

Undrestands arrays, array references and hash references.

Should be used as follows:

 use XAO::Utils;

 sub my_method ($%) {
     my $self=shift;
     my $args=get_args(\@_);

     if($args->{mode} eq 'fubar') {
         ...
 }

Now my_method could be called in either way:

 $self->my_method(mode => 'fubar');

 $self->my_method( { mode => 'fubar' } );

 sub other_method ($%) {
     my $self=shift;
     my $args=get_args(\@_);

     if(some condition) {

        return $self->my_method($args);
     }
     ...

 sub debug_my_method ($%) {
     my $self=shift;
     dprint "will call my_method with our arguments";
     $self->my_method(@_);
 }

Note, that in the above examples you could also use "get_args(@_)"
instead of "get_args(\@_)". That's fine and that would work, but
slower.

=cut

sub get_args (@) {
    my $arr=ref($_[0]) eq "ARRAY" ? $_[0] : \@_;
    my $args;
    if(@{$arr} == 1) {
        $args=$arr->[0];
        ref($args) eq "HASH" ||
            throw XAO::E::Utils "XAO::Utils::get_args - not a HASH in arguments ($arr->[0])";
    }
    elsif(! (scalar(@{$arr}) % 2)) {
        my %a=@{$arr};
        $args=\%a;
    }
    else {
        throw XAO::E::Utils "XAO::Utils::get_args - unparsable arguments";
    }
    $args={} unless $args;
    $args;
}

###############################################################################

=item merge_refs (@)

Combines together multiple hash references into one without altering
original hashes. Can be used in situations when you want to pass along
slightly modified hash reference like that:

 sub some_wrapper (%) {
     my $args=get_args(\@_);
     real_method(merge_args($args,{ objname => 'Fubar' }));
 }

Any number of hash references can be passed, first has lowest priority.

=cut

sub merge_refs (@) {
    my %hash;
    foreach my $ref (@_) {
        next unless defined $ref;
        @hash{keys %$ref}=values %$ref;
    }
    \%hash;
}

###############################################################################
1;
__END__

=back

=head1 EXPORTS

eprint(), dprint().

=head1 AUTHORS

XAO, Inc.: Andrew Maltsev, <am@xao.com>, Bil Drury <bild@xao.com>.

=head1 SEE ALSO

Have a look at L<XAO::Base> for overview.

=cut
