# (C) 2000 Smithsonian Astrophysical Observatory.  All rights reserved.
# 
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

package IPC::XPA;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

use Data::Dumper;

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.03';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined IPC::XPA macro $constname";
	}
    }
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap IPC::XPA $VERSION;

# Preloaded methods go here.

sub _flatten_mode
{
  my ( $mode ) = @_;

  return '' unless keys %$mode;

  join( ',', map { "$_=" . $mode->{$_} } keys %$mode );
}

sub Open
{
  my ( $class, $mode ) = @_;
  $class = ref($class) || $class;
  
  # _Open will bless $xpa into the IPC::XPA class, but
  # need to worry about inheritance.
  my $xpa = _Open( _flatten_mode( $mode ) );
  bless { xpa => $xpa, open => 1 }, $class;
}

sub Close
{
  my $xpa = shift;
  _Close( $xpa->{xpa} ) if $xpa->{Open};
  $xpa->{open} = 0;
}

sub DESTROY
{
  $_[0]->Close;
}


{
  my %def_attrs = ( max_servers => 1, mode => {} );
  
  sub Get
  {
    my $obj = shift;
    
    @_ == 2 || ( @_ == 3 && 'HASH' eq ref($_[2]) ) or
      croak( 'usage: IPC::XPA::Get($xpa, $template, $paramlist [,\%attrs]');
    
    my ( $template, $paramlist, $attrs ) = @_;

    my %attrs = ( %def_attrs, $attrs ? %$attrs : () );

    # if called as a class method (ref($obj) not defined)
    # create an essentially NULL pointer for pass to XPAGet
    my $xpa = ref($obj) ? $obj->{xpa} : null_XPA($obj);

    _Get($xpa, $template, $paramlist, 
	 _flatten_mode( $attrs{mode} ),
	 $attrs{max_servers} );
  }
  
}

{
  my %def_attrs = ( max_servers => 1, mode => {} );

  sub Set
  {
    my $obj = shift;

    @_ >=2 && @_ <= 4 or goto SetError;

    my $attrs;

    my $buf;
    my $template = shift;
    my $paramlist = shift;

    if ( @_ == 1 )
    {
      if ( !ref($_[0]) )
      {
	$buf = shift;
      }
      elsif ( 'HASH' eq ref($_[0]) )
      {
	$attrs = shift;
      }
      else
      {
	goto SetError;
      }
    }
    elsif ( @_ == 2 )
    {
      goto SetError 
	unless !ref($_[0]) && 'HASH' eq ref($_[1]);
      ( $buf, $attrs ) = @_;
    }

    $buf ||= '';

    my %attrs = ( %def_attrs, $attrs ? %$attrs : () );
    $attrs{len} = length($buf) unless defined $attrs{len};

    # if called as a class method (ref($obj) not defined)
    # create an essentially NULL pointer for pass to XPAGet
    my $xpa = ref($obj) ? $obj->{xpa} : nullXPA();

    return _Set($xpa, $template, $paramlist, 
		_flatten_mode( $attrs{mode} ),
		$buf, $attrs{len}, $attrs{max_servers} );

  SetError:
    croak( 'usage: IPC::XPA::Set($xpa, $template, $paramlist [, [$buf],[\%attrs]]');
  }

}


{
  my %def_attrs = ( max_servers => 1, mode => {} );
  
  sub Info
  {
    my $obj = shift;
    
    @_ == 2 || ( @_ == 3 && 'HASH' eq ref($_[2]) ) or
      croak( 'usage: IPC::XPA::Info($xpa, $template, $paramlist [,\%attrs]');
    
    my ( $template, $paramlist, $attrs ) = @_;

    my %attrs = ( %def_attrs, $attrs ? %$attrs : () );

    # if called as a class method (ref($obj) not defined)
    # create an essentially NULL pointer for pass to XPAGet
    my $xpa = ref($obj) ? $obj->{xpa} : nullXPA();

    _Info($xpa, $template, $paramlist, 
	 _flatten_mode( $attrs{mode} ),
	 $attrs{max_servers} );
  }
  
}

# this is a class method
sub Access
{
  my $class = shift;
  @_ == 2 ||
    croak( 'usage: IPC::XPA::Access->($name, $type)');
  _Access( @_ );
}

# this is a class method
sub NSLookup
{
  my $class = shift;
  @_ == 2 ||
    croak( 'usage: IPC::XPA::NSLookup->($template, $type)');
  _NSLookup( @_ );
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

IPC::XPA - Interface to the XPA messaging system

=head1 SYNOPSIS

  use IPC::XPA;

  $xpa = IPC::XPA->Open();
  $xpa = IPC::XPA->Open(\%mode);
  $xpa = IPC::XPA->nullXPA;


  @res = $xpa->Get( $template, $paramlist );
  @res = $xpa->Get( $template, $paramlist, \%attrs );

  @res = $xpa->Set( $template, $paramlist );
  @res = $xpa->Set( $template, $paramlist, $buf );
  @res = $xpa->Set( $template, $paramlist, $buf, \%attrs );
  @res = $xpa->Set( $template, $paramlist, \%attrs );

  @res = $xpa->Info( $template, $paramlist );
  @res = $xpa->Info( $template, $paramlist, \%attrs );
  
  $nservers = IPC::XPA->Access( $name, $type );

  @res = IPC::XPA->NSLookup( $template, $type );

=head1 DESCRIPTION

This class provides access to the XPA messaging system library, C<xpa>,
developed by the Smithsonian Astrophysical Observatory's High Energy
Astrophysics R&D Group.  The library provides simple inter-process
communication via calls to the C<xpa> library as well as via supplied
user land programs.

The method descriptions below do not duplicate the contents of the
documentation provided with the C<xpa> library.

Currently, only the client side routines are accessible.

=head1 METHODS

Unless otherwise specified, the following methods are simple wrappers
around the similarly named XPA routines (just prefix the Perl
routines with C<XPA>).


=head2 Class Methods

=over 8

=item nullXPA

	$xpa = XPA::IPC->nullXPA;

This creates an xpa object which is equivalent to a NULL XPA handle as
far as the underlying XPA routines are concerned.  It can be used to
create a default XPA object, as it it guaranteed to succeed (the
B<Open()> method may fail).


=item Open

	$xpa = XPA::IPC->Open();
	$xpa = XPA::IPC->Open( \%mode );

This creates an XPA object.  C<mode> is a hash
containing mode keywords and values, which will be translated into the
string form used by B<XPAOpen()>.  The object will be destroyed when
it goes out of scope; the B<XPAClose()> routine will automatically be called.
It returns B<undef> upon failure.

For example,

	$xpa = XPA::IPC->Open( { verify => 'true' } );


=item Close

	$xpa->Close;

Close the XPA object.  This is usually not necessary, as it will
automatically be closed upon destruction.

=item Access

	$ns = XPA::IPC->Access( $name, $type )

Returns the number of public access points that match the specified name
and access type.  See the XPA docs for more information.

=item NSLookup

	@res = XPA::IPC->NSLookup( $template, $type )

This calls the XPANSLookup routine.  It returns the results of the
lookup as a list of references to hashes, one per match.  The hashes
have the keys C<name>, C<class>, C<method>.  For example,

	use Data::Dumper;
	@res = XPA::IPC->NSLookup( 'ds9', 'ls' );
	print Dumper(\@res);

results in

	$VAR1 = [
	          {
	            'method' => '838e2ab4:46529',
	            'name' => 'ds9',
	            'class' => 'DS9'
	          }
	        ];

See the XPA docs for more information the C<template> and C<type>
specification.

=item Set

The B<Set> instance method (see L<Instance Methods>) can also be
called as a class method, which is equivalent to calling
B<XPASet()> with a C<NULL> handle to the B<xpa> object.

For example,

	@res = IPC::XPA->Set( $template, $paramlist );

=item Get

The B<Get> instance method (see L<Instance Methods>) can also be
called as a class method, which is equivalent to calling
B<XPAGet()> with a C<NULL> handle to the B<xpa> object.

For example,

	@res = IPC::XPA->Get( $template, $paramlist );


=item Info

The B<Info> instance method (see L<Instance Methods>) can also be
called as a class method, which is equivalent to calling
B<XPAInfo()> with a C<NULL> handle to the B<xpa> object.

For example,

	@res = IPC::XPA->Info( $template, $paramlist );


=back

=head2 Instance Methods

=over 8

=item Set

	@res = $xpa->Set( $template, $paramlist );
	@res = $xpa->Set( $template, $paramlist, $buf );
	@res = $xpa->Set( $template, $paramlist, $buf, \%attrs );
	@res = $xpa->Set( $template, $paramlist, \%attrs );

Send data to the XPA server(s) specified by B<$template>.  B<$xpa> is
a reference to an XPA object created by C<Open()>. B<$paramlist> specifies the command
to be performed.  If additional information is to be sent, the B<$buf>
parameter should be specified.  The B<%attrs> hash specifies optional
parameters and values to be sent.  The following are available:

=over 8

=item max_servers

The maximum number of servers to which the request should be sent. This
defaults to C<1>.

=item len

The number of bytes in the buffer to be sent.  If not set, the entire
contents will be sent.

=item mode

The value of this is a hash containing mode keywords and values, which
will be translated into the string form used by B<XPASet()>.

=back

It returns a list of references to hashes, one per server.  The hashes
will contain the key C<name>, indicating the server's name.  If there
was an error, the hash will also contain the key C<message>.  See
the B<XPASet> documentation for more information on the C<name> and
C<message> values.

For example,

	@res = $xpa->Set( 'ds9', 'mode crosshair' );

	use Data::Dumper;
	@res = $xpa->Set( 'ds9', 'array [dim=100,bitpix=-64]', $buf, 
			  { mode => { ack => false } });
	print Dumper \@res, "\n";

The latter might result in:

	$VAR1 = [
	          {
	            'name' => 'DS9:ds9 838e2ab4:46529'
	          }
	        ];

=item Get

	@res = $xpa->Get( $template, $paramlist );
	@res = $xpa->Get( $template, $paramlist, \%attrs );

Retrieve data from the servers specified by the B<$template>
parameter.  B<$xpa> is a reference to an XPA object created by
C<Open()>.  The B<$paramlist> indicates which data to return.  The
B<%attrs> hash specifies optional parameters and values to be sent.
The following are available:

=over 8

=item max_servers

The maximum number of servers to which the request should be sent. This
defaults to C<1>.

=item mode

The value of this is a hash containing mode keywords and values, which
will be translated into the string form used by B<XPAGet()>

=back

It returns a list of references to hashes, one per server.  The hashes
will contain the key C<name>, indicating the server's name, and C<buf>
which will contain the returned data.  If there
was an error, the hash will also contain the key C<message>.  See
the B<XPAGet> documentation for more information on the C<name> and
C<message> values.

For example,

	use Data::Dumper;
	@res = $xpa->Get( 'ds9', '-help quit' );
	print Dumper(\@res);

might result in

	$VAR1 = [
	          {
	            'name' => 'DS9:ds9 838e2ab4:46529',
	            'buf' => 'quit:	-- exit application
	'
	          }
	        ];

=item Info

	@res = $xpa->Info( $template, $paramlist);
	@res = $xpa->Info( $template, $paramlist, \%attrs );

Send a short message (in B<$paramlist>) to the servers specified in
the B<$template> parameter.  B<$xpa> is a reference to an XPA object
created by C<Open()>. The B<%attrs> hash specifies optional parameters
and values to be sent.  The following are available:

=over 8

=item max_servers

The maximum number of servers to which the request should be sent. This
defaults to C<1>.

=item mode

The value of this is a hash containing mode keywords and values, which
will be translated into the string form used by B<XPAGet()>

=back

It returns a list of references to hashes, one per server.  The hashes
will contain the key C<name>, indicating the server's name.  If there
was an error or the server replied with a message, the hash will also
contain the key C<message>.  See the B<XPAGet> documentation for more
information on the C<name> and C<message> values.

=back

=head1 The XPA Library

The XPA library is available at C<http://hea-www.harvard.edu/RD/xpa/>.

=head1 AUTHOR

Diab Jerius ( djerius@cfa.harvard.edu )

=head1 SEE ALSO

perl(1).

=cut
