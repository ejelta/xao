use ExtUtils::MakeMaker;

$Verbose=1;
$CC='c++';

WriteMakefile(
    NAME    => 'XAO::Wiki::WParser::wparser',
    SKIP    => [qw(all static static_lib dynamic dynamic_lib)],
    clean   => {'FILES' => 'libwparser$(LIB_EXT) testparser'},
    CC      => $CC,
);

$O_LIB="s_string.o wparser.o";

$O_TEST="s_string.o wparser.o test.o";

sub MY::top_targets {
    return <<'EOT';
all :: static testparser

pure_all :: static

static :: libwparser$(LIB_EXT)

libwparser$(LIB_EXT): s_string.o wparser.o
	$(AR) cr libwparser$(LIB_EXT) s_string.o wparser.o
	$(RANLIB) libwparser$(LIB_EXT)

testparser: s_string.o wparser.o test.o
	$(CC) -o $@ s_string.o wparser.o test.o

EOT
}
