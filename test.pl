# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use strict;
use vars qw( $use_PDL $max_tests $test $loaded @res %res $verbose);

BEGIN { $| = 1; 
	$verbose = 0;
	$max_tests = 9;

	eval 'require PDL; PDL::import();';
	$use_PDL = ! $@;
	$max_tests++ if $use_PDL;

	print "1..$max_tests\n"; 
      }
END {print "not ok 1\n" unless $loaded;}

use IPC::XPA;
$test = 1;
$loaded = 1;
print "ok $test\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use Data::Dumper;
use constant XPASERVER => 'ds9';

$test++;
# check connectivity

# set connect to -1 on failure so all of the remaining tests fail
print "\n$test: Access\n" if $verbose;
my $connect = IPC::XPA->Access( XPASERVER, "gs" ) || -1;
print "Unable to connect to server `", XPASERVER, "'; most tests will fail.\n" 
  if $connect < 1;
print 'not ' unless $connect > 0;
print "ok $test\n";

my %attr = ( max_servers => ($connect > 0 ? $connect : 0 ) );

# try a lookup
$test++;
print "\n$test: NSLookup\n" if $verbose;
@res = IPC::XPA->NSLookup( 'ds9', 'ls' );
print Dumper(\@res) if $verbose;
print 'not ' unless @res == $connect;
print "ok $test\n";

# create a new XPA handle
$test++;
print "\n$test: Open\n" if $verbose;
my $xpa = IPC::XPA->Open( { verify => 'true' } );
print 'not ' unless defined $xpa;
print "ok $test\n";


# grab ds9 version
$test++;
print "\n$test: Get version\n" if $verbose;
%res = $xpa->Get( 'ds9', 'version', \%attr );
print Dumper(\%res) if $verbose;
_chk_message( $connect, %res );
print "ok $test\n";

# make sure version(s) of ds9 are current enough.
while( my ( $server, $res ) = each %res )
{
  my $version;
  unless ( ($version) = $res->{buf} =~ /\b([1-9.]+)\b/ )
  {
    warn( "unable to parse version string for server `$server': $res->{buf}\n" );
    next;
  }
  warn( "DS9 version $version has not been tested with this module.\n",
	  "Some of the tests may fail.\n" )
    if $version lt '1.9.4';
}


$test++;
print "\n$test: Get 1\n" if $verbose;
%res = $xpa->Get( 'ds9', '-help quit', \%attr );
print Dumper(\%res) if $verbose;
_chk_message( $connect, %res );
print "ok $test\n";

$test++;
print "\n$test: Get 2\n" if $verbose;
my %res = $xpa->Get( 'ds9', '-help quit',
		     { mode => { ack => 'true' }, %attr });
print Dumper(\%res) if $verbose;
_chk_message( $connect, %res );
print "ok $test\n";

$test++;
print "\n$test: Set 1\n" if $verbose;
%res = $xpa->Set( 'ds9', 'mode crosshair', \%attr );
print Dumper(\%res) if $verbose;
_chk_message( $connect, %res );
print "ok $test\n";

$test++;
print "\n$test: Set 2\n" if $verbose;
%res = $xpa->Set( 'ds9', 'mode crosshair',
		     { mode => { ack => 'true' }, %attr });
print Dumper(\%res) if $verbose;
_chk_message( $connect, %res );
print "ok $test\n";

$test++;
print "\n$test: Set 3\n" if $verbose;
%res = IPC::XPA->Set( 'ds9', 'mode pointer',
		     { mode => { ack => 'true' }, %attr });
print Dumper(\%res) if $verbose;
_chk_message( $connect, %res );
print "ok $test\n";

if ( $use_PDL )
{
  my $k = zeroes(double(), 100,100)->rvals;
  
  $test++;
  print "\n$test: array\n" if $verbose;
  %res = $xpa->Set( 'ds9', 'array [dim=100,bitpix=-64]', 
		    ${$k->get_dataref}, \%attr);
  print Dumper(\%res) if $verbose;
  _chk_message( $connect, %res );
  print "ok $test\n";
}

sub _chk_message
{
  my ( $connect, %res ) = @_;
  if ( keys %res != $connect )
  {
    print 'not ';
  }
  else
  {
    print 'not ' if grep { defined $_->{message} } values %res;
  }
}
