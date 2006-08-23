# $Id$

#- Olivier Thauvin <olivier.thauvin@aerov.jussieu.fr>

# This program is free software distributed under the same terms as Parrot.

package File::Find::Object::internal;

use strict;
use warnings;

use File::Spec;
sub _curr_file
{
    my $self = shift;

    if (@_)
    {
        $self->{_curr_file} = shift;
    }

    return $self->{_curr_file};
}

sub new {
    my ($class, $top, $from, $index) = @_;

    my $self = {
        dir => $top->current_path($from),
        idx => $index,
    };

    bless($self, $class);

    $from->{dir} = $self->{dir};

    return $top->open_dir($top->_father($self)) ? $self : undef;
}


1;
