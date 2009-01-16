use strict;
use warnings;

# We're removing this because it's no longer used, but may be used in the
# future.

sub _is_top
{
    my $self = shift;

    return ! exists($self->{_st});
}

# This function is no longer used.

sub _father
{
    my ($self, $level) = @_;

    if ($level->idx() == 0)
    {
        return undef;
    }
    else
    {
        return $self->_dir_stack()->[$level->idx()-1];
    }
}

# This code was removed to be replaced with the eval ""-ed code.

sub _check_subdir_helper_t {
    return 1;
}

sub _check_subdir_helper_d {
    my $self = shift;

    return
    !(
        (!$self->followlink() && $self->_top_is_link())
            ||
        ($self->nocrossfs() && $self->_top_stat->[0] != $self->_dev())
            ||
        ($self->_is_loop())
     )
     ;
}

