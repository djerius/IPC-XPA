#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use IPC::XPA;

use Alien::XPA;
use Env;
use File::Which 'which';
use Action::Retry 'retry';
use Child 'child';


push @ENV, Alien::XPA->bin_dir;

bail_out( "can't find xpamb executable" )
  unless which( 'xpamb' );

# see if an xpamb instance is already running
my %res;

%res = IPC::XPA->Access( 'XPAMB:*', "gs" );

my $xpamb_already_running;

if ( keys %res ) {

    my ( $res ) = grep { defined $_->{message} } values %res;

    bail_out( "error in XPAACCESS: " . $res->{message} )
      if $res;

    $xpamb_already_running = keys %res;
}

my $child;
my $nserver = 0;

unless ( $xpamb_already_running ) {

    if ( $^O eq 'MSWin32' ) {

        require Win32::Process;
        require File::Which;

        use subs
          qw( Win32::Process::NORMAL_PRIORITY_CLASS Win32::Process::CREATE_NO_WINDOW);

        Win32::Process::Create(
            $child,
            File::Which::which( "xpamb" ),
            "xpamb",
            0,
            Win32::Process::NORMAL_PRIORITY_CLASS
              + Win32::Process::CREATE_NO_WINDOW,
            "."
        ) || die $^E;

    }
    else {

        $child = child { exec( 'xpamb' ) };
    }

    retry {
        %res = IPC::XPA->Access( 'XPAMB:*', "gs" );
        die unless %res;
    };

    bail_out( "unable to access launched xpamb: " . _extract_error( %res ) )
      unless %res;;
}

$nserver = keys %res;

# try a lookup
my @res;
ok( lives { @res = IPC::XPA->NSLookup( 'xpamb', 'ls' ) } )
  or diag $@;

# create a handle

my $xpa = IPC::XPA->Open( { verify => 'true' } );
ok( defined $xpa, 'Open' );

# send xpamb some data
my $name = "IPC::XPA";
my $data = "IPC::XPA Test Data\n";

subtest "Set -data" => sub {
    %res = $xpa->Set( 'xpamb', "-data $name", $data );

    is( keys %res, $nserver, "Set to $nserver servers" );

    my $error = _extract_error( %res );
    is( $error, '', "no error" );
};

subtest "Get -data" => sub {
    %res = $xpa->Get( 'xpamb', "-data $name" );

    is( keys %res, $nserver, "Get from $nserver servers" );

    my $error = _extract_error( %res );
    is( $error, '', "no error" );
    my $rdata = ( values %res ) [0]->{buf};

    is( $rdata, $data, "retrieved data" );
};

subtest "Set -del" => sub {
    %res = $xpa->Set( 'xpamb', "-del $name", $data );

    is( keys %res, $nserver, "Set to $nserver servers" );

    my $error = _extract_error( %res );
    is( $error, '', "no error" );

    %res = $xpa->Get( 'xpamb', "-data $name" );

    is( keys %res, $nserver, "Get from $nserver servers" );

    $error = _extract_error( %res );
    like( $error, qr/unknown xpamb entry: $name/, "deleted" );
};


END {

    # try to shut xpamb down nicely
    if ( $nserver ) {

        system( qw[ xpaset -p xpamb -exit ] );

        retry {
            die
              if qx/xpaaccess 'XPAMB:*'/ =~ 'yes';
        };
    }

    # be firm if necessary
    if ( $^O eq 'MSWin32' ) {

        use subs qw( Win32::Process::STILL_ACTIVE );

        $child->GetExitCode( my $exitcode );
        $child->Kill( 0 ) if $exitcode == Win32::Process::STILL_ACTIVE;
    }

    else {
        $child->kill( 9 ) unless $child->is_complete;
    }
}

done_testing;


sub _extract_error {

    my ( %res ) = @_;

    return
      join( ' ', map $_->{message}, grep defined $_->{message}, values %res )
}
