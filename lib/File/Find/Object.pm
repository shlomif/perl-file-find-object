# $Id$

#- Olivier Thauvin <olivier.thauvin@aerov.jussieu.fr>

# This program is free software, distributed under the same terms as 
# Parrot.

package File::Find::Object;

use strict;
use warnings;
use File::Find::Object::internal;

our $VERSION = '0.0.3';

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
    bless($tree, $class);
}

sub _top
{
    my $self = shift;
    if (defined($self->{_top}))
    {
        return $self->{_top};
    }
    else
    {
        return $self;
    }
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

    foreach ($self->_top->{depth} ? qw/b a/ : qw/a b/) {
        if ($self->{_action}{$_}) {
            next;
        }
        $self->{_action}{$_} = 1;
        if($_ eq 'a') {
            if ($self->_top->{callback}) {
                $self->_top->{callback}->($self->current_path());
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
    my ($self) = @_;
    if ($self->{currentfile} eq '..' || $self->{currentfile} eq '.') {
        return 1;
    }
    return 0;
}

sub filter {
    my ($self) = @_;
    return defined($self->_top->{filter}) ?
        $self->_top->{filter}->($self->current_path()) :
        1;
}

sub check_subdir {
    1;
}

sub current_path {
    my ($self) = @_;
    $self->{currentfile};
}

sub open_dir {
    my ($self) = @_;
    opendir(my $handle, $self->{dir}) or return undef;
    $self->{_files} =
        [ sort { $a cmp $b } File::Spec->no_upwards(readdir($handle)) ];
    closedir($handle);
    my @st = stat($self->{dir});
    $self->{inode} = $st[1];
    $self->{dev} = $st[0];
    return 1;
}

1

__END__

=head1 NAME

File::Find::Object - An object oriented File::Find replacement

=head1 SYNOPSIS

    use File::Find::Object;
    my $tree = File::Find::Object->new({}, @dir);

    while (my $r = $tree->next()) {
        print $r ."\n";
    }

=head1 DESCRIPTION

File::Find::Object does same job as File::Find but works like an object and 
with an iterator. As File::Find is not object oriented, one cannot perform
multiple searches in the same application. The second problem of File::Find 
is its file processing: after starting its main loop, one cannot easilly wait 
for another event an so get the next result.

With File::Find::Object you can get the next file by calling the next() 
function, but setting a callback is still possible.

=head1 FUNCTIONS

=head2 new

    my $ffo = File::Find::Object->new( { options }, @files);

Create a new File::Find::Object object. @files is the list of directories
- or files - the object should explore.

=head3 options

=over 4

=item depth

Boolean - returns the directory content before the directory itself.

=item nocrossfs

Boolean - doesn't continue on filesystems different than the parent.

=item followlink

Boolean - follow symlinks when they point to a directory.

You can safely set this option to true as File::Find::Object does not follow 
the link if it detects a loop.

=item filter

Function reference - should point to a function returning TRUE or FALSE. This 
function is called with the filename to filter, if the function return FALSE, 
the file is skipped.

=item callback

Function reference - should point to a function, which would be called each 
time a new file is returned. The function is called with the current filename 
as an argument.

=back

=head2 next

Returns the next file found by the File::Find::Object. It returns undef once
the scan is completed.

=head2 item

Returns the current filename found by the File::Find::Object object, i.e: the
last value returned by next().

=head1 BUGS

Currently works only on UNIX as it uses '/' as a path separator.

=head1 SEE ALSO

L<File::Find>

=cut

