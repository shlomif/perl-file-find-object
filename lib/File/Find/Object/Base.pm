# This program is free software, distributed under the same terms as 
# Parrot.

package File::Find::Object::Base;

use strict;
use warnings;

# TODO :
# _last_dir_scanned should be defined only for ::PathComp , but we should
# add a regression test to test it.
#

use Class::XSAccessor
	accessors => {
        (map
            { $_ => $_ }
            (qw(
                _last_dir_scanned
            ))
        ) 
    }
    ;

use File::Spec;

# Create a _copy method that does a flat copy of an array returned by
# a method as a reference.

sub _make_copy_methods
{
    my ($pkg, $methods) = @_;

    no strict 'refs';
    foreach my $method (@$methods)
    {
        *{$pkg."::".$method."_copy"} =
            do {
                my $m = $method;
                sub {
                    my $self = shift;
                    return [ @{$self->$m(@_)} ];
                };
            };
    }
    return;
}

1;

=head1 NAME

File::Find::Object::Base - base class for File::Find::Object

=head1 DESCRIPTION

This is the base class for F::F::O classes. It only defines some accessors,
and is for File::Find::Object's internal use.

=head1 METHODS

=head1 SEE ALSO

L<File::Find::Object>
