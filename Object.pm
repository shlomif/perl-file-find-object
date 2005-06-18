# $Id: Object.pm,v 1.1 2005/06/18 18:21:35 nanardon Exp $

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

package File::Find::Object;

use strict;
use warnings;
use File::Find::Object::internal;

our $VERSION = '0.0.1';

sub new {
    my ($class, $options, @files) = @_;
    my $tree = {
        _father => undef,
        _current => undef,
        files => [ @files ],
        ind => -1,
        
        depth => $options->{depth},
        nocrossfs => $options->{nocrossfs},
        followlink => $options->{followlink},
        nonet => $options->{nonet},
        filter => $options->{filter},
        callback => $options->{callback},
    };
    $tree->{_top} = $tree;
    bless($tree, $class);
}

sub DESTROY {
    my ($self) = @_;
#    print STDERR join(" ", caller)."\n";
#    printf STDERR "destroy `%s'\n", $self->{dir} || "--";
}

sub next {
    my ($self) = @_;
    while (1) {
        my $current = $self->{_current} || $self;
        $current->_process_current and return $current->current_path;
        $current = $self->{_current} || $self;
        if(!$current->movenext) {
            $current->me_die and return undef;
        }
    }
}

sub movenext {
    my ($self) = @_;
    $self->{ind} > @{$self->{files}} and return;
    $self->{ind}++;
    $self->{currentfile} = ${$self->{files}}[$self->{ind}];
    $self->{_action} = {};
    1;
}

sub me_die {
    my ($self) = @_;
    1;
}

sub become_default {
    my ($self) = @_;
    $self->{_current} = undef;
}

sub set_current {
    my ($self, $current) = @_;
    $self->{_current} = $current;
}

# Return true if there is somthing next
sub _process_current {
    my ($self) = @_;
   
    $self->{currentfile} or return 0;

    $self->isdot and return 0;
    $self->filter or return 0;  

    foreach ($self->{_top}->{depth} ? qw/b a/ : qw/a b/) {
        if ($self->{_action}{$_}) {
            next;
        }
        $self->{_action}{$_} = 1;
        if($_ eq 'a') {
            if ($self->{_top}->{callback}) {
                $self->{_top}->{callback}->($self->current_path());
            }
            return 1;
        }
            
        if ($_ eq 'b') {
            $self->check_subdir or next;
            my $newtree = File::Find::Object::internal->new($self) or next;
            $self->set_current($newtree);
            return 0;
        }
    }
    0
}

sub isdot {
    0;
}

sub filter {
    my ($self) = @_;
    return defined($self->{_top}->{filter}) ?
        $self->{_top}->{filter}->($self->current_path()) :
        1;
}

sub check_subdir {
    1;
}

sub current_path {
    my ($self) = @_;
    $self->{currentfile};
}

1
