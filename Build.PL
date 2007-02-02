use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    'module_name' => "File::Find::Object",
    'requires' =>
    {
        'Class::Accessor' => 0,
    },
    'license' => "perl",
);
$build->create_build_script;
