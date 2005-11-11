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
use IO::File;
use Text::Aspell;
use XAO::Utils;
use XAO::Objects;
use XAO::Projects qw(get_current_project);
use base XAO::Objects->load(objname => 'Atom');

use Data::Dumper;

###############################################################################

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Aspell.pm,v 1.2 2005/11/11 21:14:36 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);

    my $checker=Text::Aspell->new;
    my $options=$args->{'options'} || { };

    my $self=$proto->SUPER::new(
        spellchecker    => $checker,
        options         => $options,
        index_id        => $args->{'index_id'},
        no_dictionary   => $args->{'no_dictionary'},
    );

    if(!$args->{'no_dictionary'}) {
        foreach my $k (keys %$options) {
            if($k eq 'master') {
                $checker->set_option(lang => $self->master_language);
                $checker->set_option($k => $self->master_filename);
            }
            elsif($k eq 'lang' && $options->{'master'}) {
                # nothing, set together with master
            }
            else {
                $checker->set_option($k => $options->{$k});
            }
        }
    }

    return $self;
}

###############################################################################

sub suggest_words ($$) {
    my ($self,$word)=@_;
    return [ map { lc } $self->{'spellchecker'}->suggest($word) ];
}

###############################################################################

sub dictionary_create ($) {
    my $self=shift;

    my $filename=$self->master_filename;
    dprint ".using filename='$filename'";

    my $lang=$self->master_language;
    my $cmd="aspell --lang $lang create master $filename";
    my $file=IO::File->new("|$cmd") ||
        die "Can't open pipe to '$cmd': $!";

    return {
        file        => $file,
        count       => 0,
    };
}

###############################################################################

sub dictionary_add ($$$$) {
    my ($self,$wh,$word,$count)=@_;

    return $wh->{'count'} unless $word=~/^[a-z]+$/i && $count>3;

    $wh->{'file'}->print($word."\n");
    $wh->{'file'}->error &&
        throw $self "Got an error writing dictionary: $!\n";

    ++$wh->{'count'};
}

###############################################################################

sub dictionary_close ($$) {
    my ($self,$wh)=@_;

    $wh->{'file'}->close;
    if($?) {
        throw $self "Error building dictionary";
    }
    else {
        dprint "Done building dictionary, words count $wh->{'count'}";
    }
}

###############################################################################

sub master_filename ($) {
    my $self=shift;

    my $filename=$self->{'options'}->{'master'} || return undef;

    my $lang=$self->master_language;
    $filename=~s/%L/$lang/g;

    if($filename=~/%I/) {
        my $index_id=$self->{'index_id'} ||
            throw $self "master_filename - need an index_id for filename '$filename'";
        $filename=~s/%I/$index_id/g;
    }

    return $filename;
}

###############################################################################

sub master_language ($) {
    my $self=shift;
    return $self->{'options'}->{'lang'} || 'en';
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
