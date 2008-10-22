package File::Find::Object::PathComponent;

use strict;
use warnings;

use base 'File::Find::Object::Base';

use File::Spec;


sub new {
    my ($class, $top, $from, $index) = @_;

    my $self = {};
    bless $self, $class;

    $self->_dir($top->_current_components_copy());
    $self->idx($index);

    $self->_last_dir_scanned(undef);

    $from->_dir($self->_dir_copy());

    $self->_reset_actions();

    return $top->_open_dir() ? $self : undef;
}

package File::Find::Object;

use strict;
use warnings;

use base 'File::Find::Object::Base';

use File::Find::Object::Result;

__PACKAGE__->mk_accessors(qw(
    _dir_stack
    item_obj
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

# This is a variation of the Conditional-to-Inheritance refactoring - 
# we have two methods - one if _is_top is true
# and the other if it's false.
#
# This has been a common pattern in the code and should be eliminated.

sub _top_it
{
    my ($pkg, $methods) = @_;

    no strict 'refs';
    foreach my $method (@$methods)
    {
        *{$pkg."::".$method} =
            do {
                my $m = $method;
                my $top = "_top_$m";
                my $non = "_non_top_$m";
                sub {
                    my $self = shift;
                    return $self->_is_top()
                        ? $self->$top(@_)
                        : $self->$non(@_)
                        ;
                };
            };
    }

    return;
}

__PACKAGE__->_top_it([qw(
    _check_subdir_helper
    _current
    _father_components
    _me_die
    _movenext
    )]
);

__PACKAGE__->_make_copy_methods([qw(
    _current_components
    )]
);

use Carp;

our $VERSION = '0.1.1';

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
    $tree->_targets(\@targets);
    $tree->_target_index(-1);
    $tree->_reset_actions();

    $tree->_last_dir_scanned(undef);

    return $tree;
}

#sub DESTROY {
#    my ($self) = @_;
#    print STDERR join(" ", caller)."\n";
#    printf STDERR "destroy `%s'\n", $self->_dir_as_string || "--";
#}

sub _top__current
{
    my $self = shift;

    return $self;
}

sub _non_top__current
{
    my $self = shift;

    return $self->_dir_stack->[-1];
}

sub _is_top
{
    my $self = shift;

    return ! @{$self->_dir_stack()};
}

sub _current_path
{
    my $self = shift;

    return File::Spec->catfile(@{$self->_current_components_copy()});
}

sub _calc_current_item_obj {
    my $self = shift;

    my $components = $self->_current_components_copy();
    my $base = shift(@$components);
    
    my @basename = ();
    my $path = $self->_current_path();
    my $is_dir = -d $path;
    if (! $is_dir)
    {
        @basename = (basename => pop(@$components));
    }

    return File::Find::Object::Result->new(
        {
            @basename,
            path => $path,
            is_dir => $is_dir,
            dir_components => $components,
            base => $base,
        }
    );
}

sub _calc_next_obj {
    my ($self) = @_;
    while (1) {
        if ($self->_process_current())
        {
            return $self->_calc_current_item_obj();
        }
        if(!$self->_movenext) {
            if ($self->_me_die())
            {
                return undef();
            }
        }
    }
}

sub next_obj {
    my $self = shift;

    my $obj = $self->_calc_next_obj();

    return $self->item_obj($obj);
}

sub next {
    my $self = shift;

    $self->next_obj();

    return $self->item();
}

sub item {
    my $self = shift;

    return $self->item_obj() ? $self->item_obj()->path() : undef;
}

sub _father
{
    my ($self, $level) = @_;

    if (!defined($level->idx()))
    {
        return undef;
    }
    elsif ($level->idx() >= 1)
    {
        return $self->_dir_stack()->[$level->idx()-1];
    }
    else
    {
        return $self;
    }
}

sub _current_father {
    my $self = shift;

    return $self->_father($self->_current);
}

sub _non_top__movenext
{
    my $self = shift;
    if ($self->_current->_curr_file(
            shift(@{$self->_current_father->_traverse_to()})
       ))
    {
        $self->_current->_reset_actions();
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

sub _top__movenext
{
    my $self = shift;

    while ($self->_increment_target_index())
    {
        if (-e $self->_move_to_next_target())
        {
            $self->_reset_actions();
            return 1;
        }
    }

    return 0;
}

sub _top__me_die {
    return 1;
}

sub _non_top__me_die {
    my $self = shift;

    $self->_become_default();

    return 0;
}

sub _become_default
{
    my $self = shift;

    my $father = $self->_current_father;

    if ($self eq $father)
    {
        @{$self->_dir_stack()} = ();
    }
    else
    {
        while (scalar(@{$self->_dir_stack()}) != $father->idx() + 1)
        {
            $self->_pop_item();
        }
    }

    return 0;
}

sub _pop_item
{
    my $self = shift;

    pop(@{$self->_dir_stack()});

    return;
}

sub _calc_actions
{
    my $self = shift;

    my @actions = qw(_handle_callback _recurse);

    if ($self->depth())
    {
        @actions = reverse(@actions);
    }
    return @actions;
}

sub _get_real_action
{
    my $self = shift;
    my $action = shift;

    return ($self->_calc_actions())[$action];
}

sub _shift_current_action
{
    my $self = shift;

    my $action_proto = shift(@{$self->_current->_actions()});

    if (!defined($action_proto))
    {
        return;
    }
    else
    {
        return $self->_get_real_action($action_proto);
    }
}

sub _check_process_current {
    my $self = shift;

    return ($self->_current->_curr_file() && $self->_filter_wrapper());
}

# Return true if there is somthing next
sub _process_current {
    my $self = shift;

    if (!$self->_check_process_current())
    {
        return 0;
    }
    else
    {
        return $self->_process_current_actions();
    }
}

sub _handle_callback {
    my $self = shift;

    if ($self->callback()) {
        $self->callback()->($self->_current_path());
    }

    return 1;
}

sub _process_current_actions
{
    my $self = shift;

    while (my $action = $self->_shift_current_action())
    {
        my $status = $self->$action();

        if ($status ne "SKIP")
        {
            return $status;
        }
    }

    return 0;
}

sub _recurse
{
    my $self = shift;

    $self->_check_subdir() or 
        return "SKIP";

    push @{$self->_dir_stack()}, 
        File::Find::Object::PathComponent->new(
            $self,
            $self->_current(),
            scalar(@{$self->_dir_stack()})
        );

    return 0;
}

sub _filter_wrapper {
    my $self = shift;

    return defined($self->filter()) ?
        $self->filter()->($self->_current_path()) :
        1;
}

sub _check_subdir 
{
    my $self = shift;

    # If current is not a directory always return 0, because we may
    # be asked to traverse single-files.
    my @st = stat($self->_current_path());
    if (!-d _)
    {
        return 0;
    }
    else
    {
        return $self->_check_subdir_helper(\@st);
    }
}

sub _top__check_subdir_helper {
    return 1;
}

sub _find_ancestor_with_same_inode {
    my $self = shift;
    my $st = shift;

    my $ptr = $self->_current_father;

    while($ptr) {
        if ($ptr->_is_same_inode($st)) {
            return $ptr;
        }
    }
    continue {
        $ptr = $self->_father($ptr);
    }

    return;
}

sub _warn_about_loop
{
    my $self = shift;
    my $ptr = shift;

    # Don't pass strings directly to the format.
    # Instead - use %s
    # This was a security problem.
    printf(STDERR
        "Avoid loop %s => %s\n",
            $ptr->_dir_as_string(),
            $self->_current_path()
        );

    return;
}

sub _non_top__check_subdir_helper {
    my $self = shift;
    my $st = shift;

    if (-l $self->_current_path() && !$self->followlink())
    {
        return 0;
    }

    if ($st->[0] != $self->_current_father->_dev() && $self->nocrossfs())
    {
        return 0;
    }

    if (my $ptr = $self->_find_ancestor_with_same_inode($st)) {
        $self->_warn_about_loop($ptr);
        return 0;
    }

    return 1;
}

sub _current_components {
    my $self = shift;

    return
    [
        @{$self->_father_components()},
        $self->_current->_curr_file
    ];
}

sub _top__father_components {
    my $self = shift; 

    return [];
}

sub _non_top__father_components
{
    my $self = shift;

    return $self->_current_father->_dir_copy();
}

sub _open_dir {
    my $self = shift;

    return $self->_current()->_component_open_dir();
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

    return $self->_current->_traverse_to_copy();
}

sub get_current_node_files_list
{
    my $self = shift;

    $self->_current->_dir($self->_current_components_copy());

    # _open_dir can return undef if $self->_current is not a directory.
    if ($self->_open_dir())
    {
        return $self->_current->_files_copy();
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
    my $tree = File::Find::Object->new({}, @targets);

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

=head2 next_obj

Like next() only returns the result as a convenient 
L<File::Find::Object::Result> object. C<< $ff->next() >> is equivalent to
C<< $ff->next_obj()->path() >>.

=head2 item_obj

Like item() only returns the result as a convenient 
L<File::Find::Object::Result> object. C<< $ff->item() >> is equivalent to
C<< $ff->item_obj()->path() >>.

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

