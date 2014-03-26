package File::Find::Object::Base;

use strict;
use warnings;

our $VERSION = '0.2.11';

use integer;

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

