#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN
{
    use File::Spec;
    use lib File::Spec->catdir(File::Spec->curdir(), "t", "lib");
}

use File::Find::Object::TreeCreate;
use File::Find::Object;

use File::Path;

{
    my $tree =
    {
        'name' => "traverse-1/",
        'subs' =>
        [
            {
                'name' => "b.doc",
                'contents' => "This file was spotted in the wild.",
            },            
            {
                'name' => "a/",
            },
            {
                'name' => "foo/",
                'subs' =>
                [
                    {
                        'name' => "yet/",
                    },
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree("./t/sample-data/", $tree);
    my $ff = 
        File::Find::Object->new(
            {},
            $t->get_path("./t/sample-data/traverse-1")
        );
    my @results;
    for my $i (1 .. 6)
    {
        push @results, $ff->next();
    }
    # TEST
    is_deeply(
        \@results,
        [(map { $t->get_path("t/sample-data/traverse-1/$_") }
            ("", qw(
                a
                b.doc
                foo
                foo/yet
            ))),
         undef
        ],
        "Checking for regular, lexicographically sorted order",
    );

    rmtree($t->get_path("./t/sample-data/traverse-1"))
}
