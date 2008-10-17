
use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    'module_name' => "File::Find::Object",
    'requires' =>
    {
        'Class::Accessor' => 0,
    },
    'license' => "perl",
);
$builder->create_build_script;
