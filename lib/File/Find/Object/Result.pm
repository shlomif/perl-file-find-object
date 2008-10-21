# This program is free software, distributed under the same terms as 
# Parrot.

package File::Find::Object::Result;

use strict;
use warnings;

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(
    base
    basename
    path
    dir_components
    is_dir
));

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

=head2 $result->base()

Returns the base directory from which searching began.

=head2 $result->path()

Returns the full path of the result. As such C<< $ffo->next_obj()->path() >>
is equivalent to C<< $ffo->next() >> .

=head2 $result->is_dir()

Returns true if the result refers to a directory.

=head2 $result->dir_components()

The components of the directory part of the path starting from base() 
(also the full path if the result is a directory) as an array reference.

=head2 $result->basename()

Returns the basename of the file (if it is a file and not a directory.)
Otherwise - undef().

=head2 $result->full_components()

Returns the full components of the result with the basename if it is
a file.

=head1 SEE ALSO

L<File::Find::Object>
