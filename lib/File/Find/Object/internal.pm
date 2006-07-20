# $Id$

#- Olivier Thauvin <olivier.thauvin@aerov.jussieu.fr>

# This program is free software distributed under the same terms as Parrot.

package File::Find::Object::internal;

use strict;
use warnings;

use vars qw(@ISA);
@ISA = qw(File::Find::Object);

use File::Spec;

sub new {
    my ($class, $top, $from, $index) = @_;

    my $self = {
        dir => $top->current_path($from),
        idx => $index,
    };

    bless($self, $class);

    $from->{dir} = $self->{dir};

    return $top->_father($self)->open_dir ? $self : undef;
}

1;
