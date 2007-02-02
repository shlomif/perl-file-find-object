# This program is free software, distributed under the same terms as 
# Parrot.

package File::Find::Object::Base;

use strict;
use warnings;

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(
    _action
    _curr_file
    dev
    dir
    _files
    idx
    inode
    _last_dir_scanned
    _open_dir_ret
    _traverse_to
));

1;

=head1 NAME

File::Find::Object::Base - base class for File::Find::Object

=head2 DESCRIPTION

This is the base class for F::F::O classes. It only defines some accessors,
and is for File::Find::Object's internal use.

=head1 SEE ALSO

L<File::Find::Object>
