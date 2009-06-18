package File::Find::Object::Result;

use strict;
use warnings;

use integer;

use Class::XSAccessor
    accessors => {
        (map { $_ => $_ } (qw(
        base
        basename
        is_dir
        is_file
        is_link
        path
        dir_components
        stat_ret
        )))
    }
    ;

use Fcntl qw(:mode);

sub new
{
    my $class = shift;
    my $self = shift;

    bless $self, $class;

    return $self;
}

sub full_components
{
    my $self = shift;

    return
    [ 
        @{$self->dir_components()},
        ($self->is_dir() ? () : $self->basename()),
    ];
}

1;

=head1 NAME

File::Find::Object::Result - a result class for File::Find::Object

=head1 DESCRIPTION

This is a class returning a single L<File::Find::Object> result as returned
by its next_obj() method.

=head1 METHODS

=head2 File::Find::Object::Result->new({%args});

Initializes a new object from %args. For internal use.

=head2 $result->base()

Returns the base directory from which searching began.

=head2 $result->path()

Returns the full path of the result. As such C<< $ffo->next_obj()->path() >>
is equivalent to C<< $ffo->next() >> .

=head2 $result->is_dir()

Returns true if the result refers to a directory.

=head2 $result->is_file()

Returns true if the result refers to a plain file (equivalent to the Perl
C<-f> operator).

=head2 $result->is_link()

Returns true if the result is a symbolic link.

=head2 $result->dir_components()

The components of the directory part of the path starting from base() 
(also the full path if the result is a directory) as an array reference.

=head2 $result->basename()

Returns the basename of the file (if it is a file and not a directory.)
Otherwise - undef().

=head2 $result->full_components()

Returns the full components of the result with the basename if it is
a file.

=head2 $result->stat_ret()

The return value of L<perlfunc/stat> for the result, placed
inside an array reference. This is calculated by L<File::Find::Object> and 
kept here for convenience and for internal use.

=head1 SEE ALSO

L<File::Find::Object>

=head1 LICENSE

Copyright (C) 2005, 2006 by Olivier Thauvin

This package is free software; you can redistribute it and/or modify it under 
the following terms:

1. The GNU General Public License Version 2.0 - 
http://www.opensource.org/licenses/gpl-license.php

2. The Artistic License Version 2.0 -
http://www.perlfoundation.org/legal/licenses/artistic-2_0.html

3. At your option - any later version of either or both of these licenses.

=cut

