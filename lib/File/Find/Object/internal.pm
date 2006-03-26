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
    opendir(my $handle, $self->{dir}) or return undef;
    $self->{_files} =
        [ sort { $a cmp $b } File::Spec->no_upwards(readdir($handle)) ];
    closedir($handle);
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
    if ($self->{currentfile} = shift(@{$self->{_files}})) {
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
