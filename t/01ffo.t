#!/usr/bin/perl

# $Id$

use strict;
use warnings;
use Test::More tests => 3;

use_ok('File::Find::Object', "Can use main NBackup::Tree");

mkdir('t/dir');
mkdir('t/dir/a');
mkdir('t/dir/b');

open(my $h, ">", 't/dir/file');
close($h);

# symlink does not exists everywhere (windows)
# if it failed, this does not matter
eval {
    symlink('.', 't/dir/link');
};

my (@res1, @res2);
my $tree = File::Find::Object->new(
    {
        callback => sub {
            push(@res1, $_[0]);
        }
    },
    't/dir'
);

ok($tree, "Can get tree object");

while (my $r = $tree->next()) {
    push(@res2, $r);
}

ok(scalar(@res1) == scalar(@res2), "Get same result from callback and next");
