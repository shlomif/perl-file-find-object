# $Id: internal.pm,v 1.4 2005/06/19 14:24:00 nanardon Exp $

#- Olivier Thauvin <olivier.thauvin@aerov.jussieu.fr>

#- This program is free software; you can redistribute it and/or modify
#- it under the terms of the GNU General Public License as published by
#- the Free Software Foundation; either version 2, or (at your option)
#- any later version.
#-
#- This program is distributed in the hope that it will be useful,
#- but WITHOUT ANY WARRANTY; without even the implied warranty of
#- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#- GNU General Public License for more details.
#-
#- You should have received a copy of the GNU General Public License
#- along with this program; if not, write to the Free Software
#- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package File::Find::Object::internal;

use strict;
use warnings;
use File::Find::Object;

use vars qw(@ISA);
@ISA = qw(File::Find::Object);

sub new {
    my ($class, $from) = @_;
    my $self = {
        _father => $from,
        _top => $from->{_top},
        dir => $from->current_path,
    };

    bless($self, $class);

    return $self->open_dir ? $self : undef;
}

#sub DESTROY {
#    my ($self) = @_;
#}

sub open_dir {
    my ($self) = @_;
    opendir($self->{_handle}, $self->{dir}) or return undef;
    my @st = stat($self->{dir});
    $self->{inode} = $st[1];
    $self->{dev} = $st[0];
    1
}

sub me_die {
    my ($self) = @_;
    $self->{_father}->become_default;
    0
}

sub become_default {
    my ($self) = @_;
    $self->{_top}->{_current} = $self;
    0
}

sub set_current {
    my ($self, $current) = @_;
    $self->{_top}->{_current} = $current;
}

sub current_path {
    my ($self) = @_;
    my $p = $self->{dir};
    $p =~ s!/+$!!; #!
    $p .= '/' . $self->{currentfile};
}

sub check_subdir {
    my ($self) = @_;
    my @st = stat($self->current_path());
    !-d _ and return 0;
    -l $self->current_path() && !$self->{_top}->{followlink} and return 0;
    $st[0] != $self->{dev} && $self->{_top}->{nocrossfs} and return 0;
    my $ptr = $self; my $rc;
    while($ptr->{_father}) {
        if($ptr->{inode} == $st[1] && $ptr->{dev} == $st[0]) {
            $rc = 1;
            last;
        }
        $ptr = $ptr->{_father};
    }
    if ($rc) {
        printf(STDERR "Avoid loop $ptr->{dir} => %s\n",
            $self->current_path());
        return 0;
    }
    1
}

sub movenext {
    my ($self) = @_;
    my $h = $self->{_handle};
    if ($self->{currentfile} = readdir($h)) {
        $self->{_action} = {};
        return 1;
    } else {
        return 0;
    }
}

sub isdot {
    my ($self) = @_;
    if ($self->{currentfile} eq '..' || $self->{currentfile} eq '.') {
        return 1;
    }
    return 0;
}

1
