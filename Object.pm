# $Id: Object.pm,v 1.2 2005/06/18 20:35:38 nanardon Exp $

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
        $current->_process_current and return $self->{item} = $current->current_path;
        $current = $self->{_current} || $self;
        if(!$current->movenext) {
            $current->me_die and return $self->{item} = undef;
        }
    }
}

sub item {
    my ($self) = @_;
    $self->{item}
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

__END__

=head1 NAME

File::Find::Object - A File::Find object oriented

=head1 SYNOPSIS

    use File::Find::Object;
    my $tree = File::Find::Object->new({}, @dir);

    while (my $r = $tree->next()) {
        print $r ."\n";
    }

=head1 DESCRIPTION

File::Find::Object does same job the File::Find but instead this one, works
like an object and with an iterator. As File::Find is not object oriented you
can't perform multiple search in same application. The second problem of
File::Find is its file processing, after starting its main loop, you can't
easilly wait another event an so get next result.

With File::Find::Object you get next file by calling next() functions, but
setting a callback is still possible.

=head1 FUNCTIONS

=head2 new

    my $ffo = File::Find::Object->new( { options }, @files);

Create a new File::Find::Object object. @files is the list of directory
- or files - the object should explore.

=head3 options

=over 4

=item depth

Boolean, return the directory content before the directory itself

=item nocrossfs

Boolean, don't continue on filesystem different than the parent

=item followlink

Boolean, follow symlink when they point to a directory.

You can safelly set this options, File::Find::Object does not follow the link
if detect a loop.

=item filter

Function, should point to a function returning TRUE or FALSE. This function is
call with the filename to filter, if the function return FALSE, the file is
skiped.

=item callback

Function, should point to a function calle each time a new file is return. The
function is called with the current filename as argument.

=back

=head2 next

Return the next file find by the File::Find::Object, it return undef at end.

=head2 item

Return the current filename found by the File::Find::Object object, aka the
latest value return by next().

=head1 BUGS

Currently works only on UNIX as it use '/' as separator.

=head1 SEE ALSO

L<File::Find>

=cut

