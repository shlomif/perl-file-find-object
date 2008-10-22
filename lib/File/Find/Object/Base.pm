# This program is free software, distributed under the same terms as 
# Parrot.

package File::Find::Object::Base;

use strict;
use warnings;

use base 'Class::Accessor';

use File::Spec;

__PACKAGE__->mk_accessors(qw(
    _actions
    _curr_file
    _dev
    _dir
    _files
    idx
    _inode
    _last_dir_scanned
    _open_dir_ret
    _traverse_to
));

sub _reset_actions
{
    my $self = shift;

    $self->_actions([0,1]);
}

sub _dir_copy
{
    my $self = shift;

    return [ @{$self->_dir()} ];
}

sub _dir_as_string
{
    my $self = shift;

    return File::Spec->catdir(@{$self->_dir()});
}

sub _is_same_inode
{
    my $self = shift;
    # $st is an array ref with the return of perldoc -f stat .
    my $st = shift;

    return ($self->_dev() == $st->[0] && $self->_inode() == $st->[1]);
}

sub _mystat
{
    my $self = shift;

    my @st = stat($self->_dir_as_string());
    $self->_inode($st[1]);
    $self->_dev($st[0]);

    return;
}

sub _should_scan_dir
{
    my $self = shift;

    if (defined($self->_last_dir_scanned()) &&
        ($self->_last_dir_scanned() eq $self->_dir_as_string()
       )
    )
    {
        return;
    }
    else
    {
        $self->_last_dir_scanned($self->_dir_as_string());
        return 1;
    }
}

sub _set_up_dir
{
    my $self = shift;
    my $files = shift;

    $self->_files(
        [ @$files ]
    );
    $self->_traverse_to(
        [ @$files ]
    );
    
    $self->_mystat();

    return $self->_open_dir_ret(1);
}

1;

=head1 NAME

File::Find::Object::Base - base class for File::Find::Object

=head2 DESCRIPTION

This is the base class for F::F::O classes. It only defines some accessors,
and is for File::Find::Object's internal use.

=head1 SEE ALSO

L<File::Find::Object>
