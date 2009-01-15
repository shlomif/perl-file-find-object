
use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    'module_name' => "File::Find::Object",
    'build_requires' =>
    {
        'File::Path' => 0,
        'Test::More' => 0,
    },
    'requires' =>
    {
        'base' => 0,
        'Carp' => 0,
        'Class::XSAccessor' => 0,
        'Fcntl' => 0,
        'File::Spec' => 0,
        'List::Util' => 0,
        'strict' => 0,
        'warnings' => 0,
    },
    'license' => "perl",
);
$builder->create_build_script;
