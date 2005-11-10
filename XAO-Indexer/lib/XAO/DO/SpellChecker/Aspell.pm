=head1 NAME

XAO::DO::SpellChecker::Aspell -- Text::Aspell based spellchecker

=head1 SYNOPSIS



=head1 DESCRIPTION

Provides indexer functionality that can (and for some methods MUST) be
overriden by objects derived from it.

Methods are:

=over

=cut

###############################################################################
package XAO::DO::SpellChecker::Aspell;
use strict;
use Text::Aspell;
use XAO::Utils;
use XAO::Objects;
use XAO::Projects qw(get_current_project);
use base XAO::Objects->load(objname => 'Atom');

use Data::Dumper;

###############################################################################

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Aspell.pm,v 1.1 2005/11/10 10:32:34 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);

    my $checker=Text::Aspell->new;
    my $options=$args->{'options'} || { };
    foreach my $k (keys %$options) {
        $checker->set_option($k => $options->{$k});
    }

    return $proto->SUPER::new(
        spellchecker    => $checker,
        options         => $options,
    );
}

###############################################################################

sub suggest_words ($$) {
    my ($self,$word)=@_;
    return [ map { lc } $self->{'spellchecker'}->suggest($word) ];
}

###############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Indexer>,
L<XAO::DO::Indexer::Base>,
L<XAO::DO::Data::Index>.

=cut
