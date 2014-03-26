
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
        'Carp' => 0,
        'Class::XSAccessor' => 0,
        'Fcntl' => 0,
        'File::Spec' => 0,
        'List::Util' => 0,
        'parent' => 0,
        'perl' => '5.008',
        'strict' => 0,
        'warnings' => 0,
    },
    configure_requires =>
    {
        'Module::Build' => 0.36,
    },
    'license' => "artistic_2",
    meta_merge => {
        resources => {
            homepage => "http://www.shlomifish.org/open-source/projects/File-Find-Object/",
            repository => "https://bitbucket.org/shlomif/perl-file-find-object",
        },
        keywords =>
        [
            "alternative-to-core",
            "directories",
            "directory",
            "directory-traversal",
            "directory-tree",
            "directory-trees",
            "file",
            "file-find",
            "find",
            "instance",
            "instantiated",
            "instantiation",
            "iterative",
            "object",
            "object-oriented",
            "oop",
            "prune",
            "traversal",
            "traverse",
            "tree",
        ]
    },
);
$builder->create_build_script;
