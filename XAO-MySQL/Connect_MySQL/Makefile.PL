use 5.008006;
use ExtUtils::MakeMaker;

my $mysql_libs=`mysql_config --libs`;
chomp $mysql_libs;
$mysql_libs=~s/'//g;
my $mysql_cflags=`mysql_config --cflags`;
chomp $mysql_cflags;
$mysql_cflags=~s/'//g;

WriteMakefile(
    NAME            => 'XAO::DO::FS::Glue::Connect_MySQL',
    VERSION_FROM    => 'Connect_MySQL.pm',
    INC             => $mysql_cflags,
    LIBS            => $mysql_libs,
);
