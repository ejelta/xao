use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'          => 'XAO::DO::FS::Glue::MySQL',
    'LIBS'          => [qw(-lmysqlclient -lm)]
);
