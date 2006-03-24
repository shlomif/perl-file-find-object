#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;

BEGIN
{
    use File::Spec;
    use lib File::Spec->catdir(File::Spec->curdir(), "t", "lib");
}

use File::Path;

use File::Find::Object::TreeCreate;

{
    my $t = File::Find::Object::TreeCreate->new();

    # TEST
    ok ($t, "TreeCreate object was initialized");

    # TEST
    is ($t->get_path("./t/file.txt"), File::Spec->catfile(File::Spec->curdir(), "t", "file.txt"));

    # TEST
    is ($t->get_path("./t/mydir/"), File::Spec->catdir(File::Spec->curdir(), "t", "mydir"));

    # TEST
    is ($t->get_path("./t/hello/there/world.jpg"), File::Spec->catfile(File::Spec->curdir(), "t", "hello", "there", "world.jpg"));

    # TEST
    is ($t->get_path("./one/two/three/four/"), File::Spec->catdir(File::Spec->curdir(), "one", "two", "three", "four"));
}

{
    my $t = File::Find::Object::TreeCreate->new();

    # TEST
    ok ($t->exist("./MANIFEST"), "Checking the exist() method");

    # TEST
    ok (!$t->exist("./BKLASDJASFDJODIJASDOJASODJ.wok"), 
        "Checking the exist() method");

    # TEST
    ok ($t->is_file("./MANIFEST"), "Checking the is_file method");

    # TEST
    ok (! $t->is_file ("./t"), "Checking the is_file method - 2");

    # TEST
    ok (! $t->is_dir("./MANIFEST"), "Checking the is_dir method - false");

    # TEST
    ok ($t->is_dir ("./t"), "Checking the is_dir method - true");
    
    # TEST
    is ($t->cat("./t/sample-data/h.txt"), "Hello.",
        "Checking the cat method");

    {
        mkdir ($t->get_path("./t/sample-data/ls-test"));
        mkdir ($t->get_path("./t/sample-data/ls-test/a"));
        open O, ">", $t->get_path("./t/sample-data/ls-test/b.txt");
        print O "Yowza";
        close(O);
        mkdir ($t->get_path("./t/sample-data/ls-test/c"));
        open O, ">", $t->get_path("./t/sample-data/ls-test/h.xls");
        print O "FooBardom!\n";
        close(O);
        # TEST
        is_deeply ($t->ls("./t/sample-data/ls-test"),
            ["a","b.txt","c","h.xls"],
            "Testing the ls method",
            );
        # Cleanup
        rmtree ($t->get_path("./t/sample-data/ls-test"));
    }
}
