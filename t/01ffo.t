#!/usr/bin/perl

# $Id$

use strict;
use warnings;

use Test::More tests => 4;

use File::Path qw(rmtree);

# TEST
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
my $symlink_created = ($@ eq "");

my (@res1, @res2);
my $tree = File::Find::Object->new(
    {
        callback => sub {
            push(@res1, $_[0]);
        },
        followlink => 1,
    },
    't/dir'
);

my @warnings;

local $SIG{__WARN__} = sub { my $w = shift; push @warnings, $w; };

# TEST
ok($tree, "Can get tree object");

while (my $r = $tree->next()) {
    push(@res2, $r);
}

# TEST
ok(scalar(@res1) == scalar(@res2), "Get same result from callback and next");

# TEST
ok (
    ($symlink_created ? scalar($warnings[0] =~ m{Avoid loop}) : 1),
    "Avoid loop warning",
);

# Cleanup
rmtree('t/dir', 0, 1);
