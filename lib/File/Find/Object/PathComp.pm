package File::Find::Object::PathComp;

use strict;
use warnings;

use integer;

use base 'File::Find::Object::Base';

use Class::XSAccessor
	accessors => {
        (map
            { $_ => $_ }
            (qw(
                _actions
                _curr_file
                _dir
                _files
                _last_dir_scanned
                _open_dir_ret
                _stat_ret
                _traverse_to
            ))
        ) 
    },
    getters => { _inodes => '_inodes' },
    setters => { _set_inodes => '_inodes' },
    ;

use File::Spec;

__PACKAGE__->_make_copy_methods([qw(
        _dir
        _files
        _traverse_to
    )]
);

sub _dev
{
    return shift->_stat_ret->[0];
}

sub _inode
{
    return shift->_stat_ret->[1];
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

    # On MS-Windows, all inodes in stat are returned as 0, so we need to 
    # check that both inodes are not zero. This is why there's the 
    # $self->_inode() != 0 check at the end.
    return
    (   
        $self->_dev() == $st->[0]
     && $self->_inode() == $st->[1]
     && $self->_inode() != 0
    );
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

    $self->_files($self->_calc_dir_files());

    $self->_traverse_to($self->_files_copy());
    
    return $self->_open_dir_ret(1);
}

sub _calc_dir_files
{
    my $self = shift;

    my $handle;
    my @files;
    if (!opendir($handle, $self->_dir_as_string()))
    {
        # Handle this error gracefully.
    }
    else
    {
        @files = (sort { $a cmp $b } File::Spec->no_upwards(readdir($handle)));
        closedir($handle);
    }

    return \@files;
}

sub _component_open_dir
{
    my $self = shift;

    if (!$self->_should_scan_dir())
    {
        return $self->_open_dir_ret();
    }

    return $self->_set_up_dir();
}

sub _next_traverse_to
{
    my $self = shift;

    return shift(@{$self->_traverse_to()}); 
}

1;

=head1 NAME

File::Find::Object::PathComp - base class for File::Find::Object's Path Components

=head1 DESCRIPTION

This is the base class for F::F::O's path components. It only defines some 
accessors, and is for File::Find::Object's internal use.

=head1 METHODS

=head1 SEE ALSO

L<File::Find::Object>

=head1 LICENSE

Copyright (C) 2005, 2006 by Olivier Thauvin

This package is free software; you can redistribute it and/or modify it under 
the following terms:

1. The GNU General Public License Version 2.0 - 
http://www.opensource.org/licenses/gpl-license.php

2. The Artistic License Version 2.0 -
http://www.perlfoundation.org/legal/licenses/artistic-2_0.html

3. At your option - any later version of either or both of these licenses.

=cut
