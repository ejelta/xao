package testcases::utils;
use strict;

use base qw(testcases::base);

sub test_t2x {
    my $self=shift;

    use XAO::Utils qw(:html);

    my $str;
    my $got;
    $str='\'"!@#$%^&*()_-=[]\<>?';
    $got=t2ht($str);
    $self->assert($got eq '\'"!@#$%^&amp;*()_-=[]\&lt;&gt;?',
                  "Wrong value from t2ht ($got)");

    $got=t2hq($str);
    $self->assert($got eq '\'%22!@%23$%25^%26*()_-%3d[]\%3c%3e%3f',
                  "Wrong value from t2hq ($got)");

    $got=t2hf($str);
    $self->assert($got eq '\'&quot;!@#$%^&amp;*()_-=[]\&lt;&gt;?',
                  "Wrong value from t2hf ($got)");
}

1;
__END__

##
# Arguments
#
my $args=get_args(a => 1, b => 2);
tprint "get_args(%a)", $args->{a} == 1 && $args->{b} == 2;
$args=get_args([a => 2, b => 3]);
tprint "get_args(\@_)", $args->{a} == 2 && $args->{b} == 3;
$args=get_args({a => 3, b => 4});
tprint "get_args(\%a)", $args->{a} == 3 && $args->{b} == 4;

##
# merge_args
#
if(1) {
    my %a=(aa => 1, bb => '');
    my %b=(bb => 2, cc => undef);
    my %c=(cc => 3, dd => 3);
    my $r=merge_refs(\%a,\%b,\%c);
    tprint "merge_refs()",
           $a{aa} == 1 && $a{bb} eq '' &&
           $b{bb} == 2 && !defined($b{cc}) &&
           $c{cc} == 3 && $c{dd} == 3 &&
           $r->{aa} == 1 && $r->{bb} == 2 && $r->{cc} == 3 && $r->{dd} == 3 &&
           scalar(keys %$r) == 4;
}

##
# ID
#
my $key=generate_key();
tprint 'generate_key()', $key =~ /^[0-9A-Z]{8}/;
$key=repair_key('01V34567');
tprint 'repair_key()', $key eq 'OIU3456I';

##########################################################################
load_module "Symphero::SimpleHash";
my $sh=new Symphero::SimpleHash(a => 1, b => 2);
tprint "get(..)", $sh->get('a') == 1;
tprint "defined('a')", $sh->defined('a');
tprint "defined('A')", ! $sh->defined('A');
$sh->put(c => 3);
tprint "put(..)", $sh->get('c') == 3;
$sh->fill({ a => 11, d => 4});
tprint 'fill(\%)', $sh->get('a') == 11 && $sh->get('d') == 4;
$sh->fill(b => 22, c => 33);
tprint 'fill(%)', $sh->get('b') == 22 && $sh->get('c') == 33;
$sh->fill([d => 44], [e => 55]);
tprint 'fill([],[],..)', $sh->get('d') == 44 && $sh->get('e') == 55;
${$sh->getref('a')}++;
tprint 'getref(..)', $sh->get('a')==12;
tprint 'values()', join(',',sort $sh->values) eq '12,22,33,44,55';
tprint 'keys()', join(',',sort $sh->keys) eq 'a,b,c,d,e';
$sh->delete('a');
tprint 'delete(..)', ! $sh->contains(12);
tprint 'contains(..)', $sh->contains(22) eq 'b';

tprint 'put(URI)',
       $sh->put('/test/foo/bar' => 123) == 123;
tprint 'get(URI1)',
       ref($sh->get('test/foo')) == 'HASH';
tprint 'exists(URI)',
       $sh->exists('//test//foo///bar');
tprint 'get(test)',
       $sh->get('test')->{foo}->{bar} == 123;
$sh->put('test/foo/bar' => undef);
tprint 'exists(URI)',
       $sh->exists('//test//foo///bar');
tprint 'defined(URI)',
       ! $sh->defined('//test//foo///bar');
$sh->put('test//foo/aaa' => 'AAA');
tprint 'get(aaa)',
       $sh->get('test/foo/aaa') eq 'AAA';
$sh->delete('test/foo');
tprint '!exists(URI)',
       ! $sh->exists('//test//foo');
tprint '!exists(URI)',
       ! $sh->exists('//test//foo/bar');

##########################################################################
load_module "Symphero::MultiValueHash";
tprint "UNIMPLEMENTED TESTS", 1;

##########################################################################
load_module "Symphero::MultiValueDB";
tprint "UNIMPLEMENTED TESTS", 1;

1;
1;
