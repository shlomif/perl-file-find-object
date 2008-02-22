#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

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

{
    my $test_id = "traverse-dirs-and-files";
    my $test_dir = "t/sample-data/$test_id";
    my $tree =
    {
        'name' => "$test_id/",
        'subs' =>
        [   
            {
                'name' => "a/",
                subs =>
                [
                    {
                        'name' => "b.doc",
                        'contents' => "This file was spotted in the wild.",
                    },
                ],
            },
            {
                'name' => "foo/",
                'subs' =>
                [
                    {
                        'name' => "t.door.txt",
                        'contents' => "A T Door",
                    },
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
            $t->get_path("./$test_dir/a/b.doc"),
            $t->get_path("./$test_dir/foo"),
        );
    my @results;
    for my $i (1 .. 5)
    {
        push @results, $ff->next();
    }
    # TEST
    is_deeply(
        \@results,
        [(map { $t->get_path("$test_dir/$_") }
            (qw(
                a/b.doc
                foo
                foo/t.door.txt
                foo/yet
            ))),
         undef
        ],
        "Checking that one can traverse regular files.",
    );

    rmtree($t->get_path("./$test_dir"))
}
