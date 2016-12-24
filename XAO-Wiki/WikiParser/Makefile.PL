use 5.008006;
use ExtUtils::MakeMaker;

$CC='c++';

WriteMakefile(
    NAME                => 'XAO::WikiParser',
    VERSION_FROM        => 'WikiParser.pm',
    PREREQ_PM           => {},
    LIBS                => [''], # e.g., '-lm'
    DEFINE              => '', # e.g., '-DHAVE_SOMETHING'
    INC                 => '-I.', # e.g., '-I. -I/usr/include/other'
    MYEXTLIB            => 'wparser/libwparser$(LIB_EXT) -lstdc++',
    CC                  => $CC,
    LD                  => '$(CC)',
    'XSOPT'             => '-C++',
    #'TYPEMAPS'          => ['perlobject.map' ],
);

sub MY::postamble {
    return <<'EOT';
$(MYEXTLIB): wparser/Makefile
	cd wparser && $(MAKE) $(PASSTHRU)
EOT
}
