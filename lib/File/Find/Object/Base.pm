# $Id: Object.pm 73 2006-09-03 20:14:23Z shlomif $

#- Olivier Thauvin <olivier.thauvin@aerov.jussieu.fr>

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

