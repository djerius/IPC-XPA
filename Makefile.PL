use ExtUtils::MakeMaker;
use Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'IPC::XPA',
    'VERSION_FROM' => 'XPA.pm', # finds $VERSION
    'LIBS'	=> ["-L/soft/saord/lib -lxpa"],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '-I/soft/saord/include',     # e.g., '-I/usr/include/other' 
    'OBJECT'	=> 'XPA.o util.o',
    'PREREQ_PM' => { Test::More => 0 },
);
