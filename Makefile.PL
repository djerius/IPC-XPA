use ExtUtils::MakeMaker;
use Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'IPC::XPA',
    'VERSION_FROM' => 'XPA.pm', # finds $VERSION
    'LIBS'	=> ["-L/proj/axaf/pkgs/xpa/sparc-SunOS-5/lib -lxpa"],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '-I/proj/axaf/pkgs/xpa/include',     # e.g., '-I/usr/include/other' 
    'OBJECT'	=> 'XPA.o util.o',
);
