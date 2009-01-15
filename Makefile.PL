# $Id$

use ExtUtils::MakeMaker;

sub MY::postamble {
    <<MAKECHANGELOG;
.PHONY: ChangeLog

ChangeLog:
	cvs2cl -W 400 -I ChangeLog --accum -U ../common/username
	rm -f *.bak

MAKECHANGELOG
}

WriteMakefile(
    NAME	 => 'File::Find::Object',
    VERSION_FROM => 'lib/File/Find/Object.pm',
    PREREQ_PM =>
    {
        'base' => 0,
        'Carp' => 0,
        'Class::XSAccessor' => 0,
        'Fcntl' => 0,
        'File::Path' => 0,
        'File::Spec' => 0,
        'List::Util' => 0,
        'strict' => 0,
        'warnings' => 0,   'Test::More' => 0,
    },
    PL_FILES => {},
);
