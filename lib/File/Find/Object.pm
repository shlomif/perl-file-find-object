package File::Find::Object::PathComponent;

use strict;
use warnings;

use base 'File::Find::Object::Base';

use File::Spec;


sub new {
    my ($class, $top, $from, $index) = @_;

    my $self = {};
    bless $self, $class;

    $self->dir($top->_current_path($from));
    $self->idx($index);

    $self->_last_dir_scanned(undef);

    $from->dir($self->dir());

    return $top->_open_dir($top->_father($self)) ? $self : undef;
}

package File::Find::Object;

use strict;
use warnings;

use base 'File::Find::Object::Base';

__PACKAGE__->mk_accessors(qw(
    _current_idx
    _dir_stack
    item
    _targets
    _target_index
));

sub _get_options_ids
{
    my $class = shift;
    return [qw(
        callback
        depth
        filter
        followlink
        nocrossfs
    )];
}

__PACKAGE__->mk_accessors(@{__PACKAGE__->_get_options_ids()});

use Carp;

our $VERSION = '0.0.9';

sub new {
    my ($class, $options, @targets) = @_;

    my $tree = {
        
        _dir_stack => [],
    };

    bless($tree, $class);

    foreach my $opt (@{$tree->_get_options_ids()})
    {
        $tree->set($opt, $options->{$opt});
    }
    $tree->_targets([ @targets ]);
    $tree->_target_index(-1);
    $tree->_current_idx(-1);

    $tree->_last_dir_scanned(undef);

    return $tree;
}

sub DESTROY {
    my ($self) = @_;
#    print STDERR join(" ", caller)."\n";
#    printf STDERR "destroy `%s'\n", $self->dir() || "--";
}

sub _current
{
    my $self = shift;

    my $dir_stack = $self->_dir_stack();

    if ($self->_current_idx < 0)
    {
        return $self;
    }
    else
    {
        return $dir_stack->[$self->_current_idx];
    }
}

sub next {
    my ($self) = @_;
    while (1) {
        my $current = $self->_current();
        if ($self->_process_current($current))
        {
            return $self->item($self->_current_path($current));
        }
        $current = $self->_current();
        if(!$self->_movenext) {
            if ($self->_me_die($current))
            {
                return $self->item(undef);
            }
        }
    }
}

sub _father
{
    my ($self, $current) = @_;

    if (!defined($current))
    {
        require Data::Dumper;
        print Data::Dumper->new([$self],['$self'])->Dump();
        confess "Current is undef";
    }

    if (!defined($current->idx()))
    {
        return undef;
    }
    elsif ($current->idx() >= 1)
    {
        return $self->_dir_stack()->[$current->idx()-1];
    }
    else
    {
        return $self;
    }
}

sub _movenext_with_current
{
    my $self = shift;
    if ($self->_current->_curr_file(
            shift(@{$self->_father($self->_current)->_traverse_to()})
       ))
    {
        $self->_current->_action({});
        return 1;
    } else {
        return 0;
    }
}

sub _increment_target_index
{
    my $self = shift;
    $self->_target_index( $self->_target_index() + 1 );

    return ($self->_target_index() < scalar(@{$self->_targets()}));
}

sub _calc_next_target
{
    my $self = shift;

    my $target = $self->_targets()->[$self->_target_index()];

    return defined($target) ? File::Spec->canonpath($target) : undef;
}

sub _move_to_next_target
{
    my $self = shift; 

    return $self->_curr_file($self->_calc_next_target());
}

sub _movenext_wo_current
{
    my $self = shift;

    while ($self->_increment_target_index())
    {
        if (-e $self->_move_to_next_target())
        {
            $self->_action({});

            return 1;
        }
    }

    return 0;
}

sub _movenext {
    my ($self) = @_;
    if (@{$self->_dir_stack()})
    {
        return $self->_movenext_with_current();
    }
    else
    {
        return $self->_movenext_wo_current();
    }
}

sub _me_die {
    my ($self, $current) = @_;

    if ($self eq $current)
    {
        return 1;
    }

    $self->_become_default($self->_father($current));
    return 0;
}

sub _become_default
{
    my ($self, $current) = @_;

    if ($self eq $current)
    {
        @{$self->_dir_stack()} = ();
        $self->_current_idx(-1);
    }
    else
    {
        while (scalar(@{$self->_dir_stack()}) != $current->idx() + 1)
        {
            pop(@{$self->_dir_stack()});
            $self->_current_idx($self->_current_idx()-1);
        }
    }

    return 0;
}

# Return true if there is somthing next
sub _process_current {
    my ($self, $current) = @_;
   
    $current->_curr_file() or return 0;

    $self->_filter_wrapper($current) or return 0;  

    foreach my $action ($self->depth() ? qw(b a) : qw(a b))
    {
        if ($current->_action->{$action}) {
            next;
        }
        $current->_action->{$action} = 1;
        if($action eq 'a') {
            if ($self->callback()) {
                $self->callback()->($self->_current_path($current));
            }
            return 1;
        }
            
        if ($action eq 'b') {
            my $status = $self->_recurse($current);
            
            if ($status eq "SKIP")
            {
                next;
            }
            else
            {
                $self->_current_idx($self->_current_idx()+1);
                return $status;
            }
        }
    }
    return 0;
}

sub _recurse
{
    my ($self, $current) = @_;

    $self->_check_subdir($current) or 
        return "SKIP";


    push @{$self->_dir_stack()}, 
        File::Find::Object::PathComponent->new(
            $self,
            $current,
            scalar(@{$self->_dir_stack()})
        );

    return 0;
}

sub _filter_wrapper {
    my ($self, $current) = @_;
    return defined($self->filter()) ?
        $self->filter()->($self->_current_path($current)) :
        1;
}

sub _check_subdir 
{
    my ($self, $current) = @_;

    # If current is not a directory always return 0, because we may
    # be asked to traverse single-files.
    my @st = stat($self->_current_path($current));
    if (!-d _)
    {
        return 0;
    }

    if ($self eq $current)
    {
        return 1;
    }
    if (-l $self->_current_path($current) && !$self->followlink())
    {
        return 0;
    }
    if ($st[0] != $self->_father($current)->dev() && $self->nocrossfs())
    {
        return 0;
    }
    my $ptr = $current; my $rc;
    while($self->_father($ptr)) {
        if($self->_father($ptr)->inode() == $st[1] && $self->_father($ptr) == $st[0]) {
            $rc = 1;
            last;
        }
        $ptr = $self->_father($ptr);
    }
    if ($rc) {
        printf(STDERR "Avoid loop " . $self->_father($ptr)->dir() . " => %s\n",
            $self->_current_path($current));
        return 0;
    }
    return 1;
}

sub _current_path {
    my ($self, $current) = @_;

    if ($self eq $current)
    {
        return $self->_curr_file;
    }

    my $p = $self->_father($current)->dir();
    
    return File::Spec->catfile($p, $current->_curr_file);
}

sub _open_dir {
    my ($self, $current) = @_;

    if (defined($current->_last_dir_scanned()) &&
        ($current->_last_dir_scanned() eq $current->dir()
       )
    )
    {
        return $current->_open_dir_ret();
    }

    $current->_last_dir_scanned($current->dir());

    my $handle;
    if (!opendir($handle, $current->dir()))
    {
        return $current->_open_dir_ret(undef);
    }
    my @files = (sort { $a cmp $b } File::Spec->no_upwards(readdir($handle)));
    closedir($handle);

    $current->_files(
        [ @files ]
    );
    $current->_traverse_to(
        [ @files ]
    );

    
    my @st = stat($current->dir());
    $current->inode($st[1]);
    $current->dev($st[0]);


    return $current->_open_dir_ret(1);
}

sub set_traverse_to
{
    my ($self, $children) = @_;

    # Make sure we scan the current directory for sub-items first.
    $self->get_current_node_files_list();

    $self->_current->_traverse_to([@$children]);
}

sub get_traverse_to
{
    my $self = shift;

    return [ @{$self->_current->_traverse_to()} ];
}

sub get_current_node_files_list
{
    my $self = shift;

    # Remming out because it doesn't work.
    # $self->_father($self->_current)->dir($self->_current->dir());

    $self->_current->dir($self->_current_path($self->_current()));

    # _open_dir can return undef if $self->_current is not a directory.
    if ($self->_open_dir($self->_current))
    {
        return [ @{$self->_current->_files()}];
    }
    else
    {
        return [];
    }
}

sub prune
{
    my $self = shift;

    return $self->set_traverse_to([]);
}

1;

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
for another event and so get the next result.

With File::Find::Object you can get the next file by calling the next() 
function, but setting a callback is still possible.

=head1 FUNCTIONS

=head2 new

    my $ffo = File::Find::Object->new( { options }, @targets);

Create a new File::Find::Object object. C<@targets> is the list of 
directories or files which the object should explore.

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

=head2 $ff->set_traverse_to([@children])

Sets the children to traverse to from the current node. Useful for pruning
items to traverse.

=head2 $ff->prune()

Prunes the current directory. Equivalent to $ff->set_traverse_to([]).

=head2 [@children] = $ff->get_traverse_to()

Retrieves the children that will be traversed to.

=head2 [@files] = $ff->get_current_node_files_list()

Gets all the files that appear in the current directory. This value is
constant for every node, and is useful to use as the basis of the argument
for C<set_traverse_to()>.

=head1 BUGS

No bugs are known, but it doesn't mean there aren't any.

=head1 SEE ALSO

There's an article about this module in the Perl Advent Calendar of 2006:
L<http://perladvent.pm.org/2006/2/>.

L<File::Find> is the core module for traversing files in perl, which has
several limitations.

L<File::Next>, L<File::Find::Iterator>, L<File::Walker> and the unmaintained
L<File::FTS> are alternatives to this module.

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

