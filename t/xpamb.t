#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use IPC::XPA;

use Alien::XPA;
use Env;
use File::Which 'which';
use Action::Retry 'retry';


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

unless ( $xpamb_already_running ) {
    exec( 'xpamb' ) if !fork;

    retry {
        %res = IPC::XPA->Access( 'XPAMB:*', "gs" );
        die unless %res;
    };
    bail_out( "unable to access launched xpamb: " . _extract_error( %res ) )
      unless %res;;
}

my $nserver = keys %res;

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
    system( qw[ xpaset -p xpamb -exit ] )
      unless $xpamb_already_running;
}


done_testing;


sub _extract_error {

    my ( %res ) = @_;

    return
      join( ' ', map $_->{message}, grep defined $_->{message}, values %res )
}
