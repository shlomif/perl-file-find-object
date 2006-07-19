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
    my ($class, $from, $index) = @_;
    my $self = {
        _top => $from->_top,
        dir => $from->current_path,
        idx => $index,
    };

    bless($self, $class);

    $from->{dir} = $self->{dir};

    return $self->_father->open_dir ? $self : undef;
}

#sub DESTROY {
#    my ($self) = @_;
#}


sub me_die {
    my ($self) = @_;
    $self->_father()->become_default;
    0
}

sub become_default {
    my ($self) = @_;
    while (scalar(@{$self->_top->_dir_stack()}) != $self->{idx} + 1)
    {
        pop(@{$self->_top->_dir_stack()});
    }
    return 0;
}


sub current_path {
    my ($self) = @_;
    my $p = $self->_father->{dir};
    $p =~ s!/+$!!; #!
    $p .= '/' . $self->{currentfile};
}

sub check_subdir {
    my ($self) = @_;
    my @st = stat($self->current_path());
    !-d _ and return 0;
    -l $self->current_path() && !$self->_top->{followlink} and return 0;
    $st[0] != $self->_father->{dev} && $self->_top->{nocrossfs} and return 0;
    my $ptr = $self; my $rc;
    while($ptr->_father) {
        if($ptr->_father->{inode} == $st[1] && $ptr->_father->{dev} == $st[0]) {
            $rc = 1;
            last;
        }
        $ptr = $ptr->_father;
    }
    if ($rc) {
        printf(STDERR "Avoid loop " . $ptr->_father->{dir} . " => %s\n",
            $self->current_path());
        return 0;
    }
    1
}

1;
