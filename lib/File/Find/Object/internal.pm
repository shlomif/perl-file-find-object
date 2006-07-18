# $Id$

#- Olivier Thauvin <olivier.thauvin@aerov.jussieu.fr>

# This program is free software distributed under the same terms as Parrot.

package File::Find::Object::internal;

use strict;
use warnings;
use File::Find::Object;

use vars qw(@ISA);
@ISA = qw(File::Find::Object);

use File::Spec;

sub new {
    my ($class, $from) = @_;
    my $self = {
        _father => $from,
        _top => $from->_top,
        dir => $from->current_path,
    };

    bless($self, $class);

    $from->{dir} = $self->{dir};

    return $self->{_father}->open_dir ? $self : undef;
}

#sub DESTROY {
#    my ($self) = @_;
#}


sub me_die {
    my ($self) = @_;
    $self->{_father}->become_default;
    0
}

sub become_default {
    my ($self) = @_;
    $self->_top->{_current} = $self;
    0
}

sub set_current {
    my ($self, $current) = @_;
    $self->_top->{_current} = $current;
}

sub current_path {
    my ($self) = @_;
    my $p = $self->{_father}->{dir};
    $p =~ s!/+$!!; #!
    $p .= '/' . $self->{currentfile};
}

sub check_subdir {
    my ($self) = @_;
    my @st = stat($self->current_path());
    !-d _ and return 0;
    -l $self->current_path() && !$self->_top->{followlink} and return 0;
    $st[0] != $self->{_father}->{dev} && $self->_top->{nocrossfs} and return 0;
    my $ptr = $self; my $rc;
    while($ptr->{_father}) {
        if($ptr->{_father}->{inode} == $st[1] && $ptr->{_father}->{dev} == $st[0]) {
            $rc = 1;
            last;
        }
        $ptr = $ptr->{_father};
    }
    if ($rc) {
        printf(STDERR "Avoid loop $ptr->{_father}->{dir} => %s\n",
            $self->current_path());
        return 0;
    }
    1
}

sub movenext {
    my ($self) = @_;
    if ($self->{currentfile} = shift(@{$self->{_father}->{_files}})) {
        $self->{_action} = {};
        return 1;
    } else {
        return 0;
    }
}


1
