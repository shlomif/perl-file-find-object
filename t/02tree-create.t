#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

BEGIN
{
    use File::Spec;
    use lib File::Spec->catdir(File::Spec->curdir(), "t", "lib");
}

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
    ok ($t->contains("./t/sample-data/h.txt", "Hello."),
        "Checking the contain method");
}
