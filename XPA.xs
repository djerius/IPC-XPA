/*
  (C) 2000 Smithsonian Astrophysical Observatory.  All rights reserved.

  This program is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.
*/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <xpa.h>
#include "util.h"
#ifdef __cplusplus
}
#endif

#define X_MAXSERVERS "max_servers"
#define L_MAXSERVERS strlen(X_MAXSERVERS)

#define X_MODE     "mode"
#define L_MODE	   strlen(X_MODE)

typedef XPA IPC_XPA;

MODULE = IPC::XPA		PACKAGE = IPC::XPA		

IPC_XPA
_Open(mode)
	char* mode
	CODE:
		RETVAL = XPAOpen(mode);
	OUTPUT:
	RETVAL


void 
_Close(xpa)
	IPC_XPA	xpa
	CODE:
	XPAClose(xpa);

void
_Get(xpa, xtemplate, paramlist, mode, max_servers )
	IPC_XPA	xpa
	char*	xtemplate
	char*	paramlist
	char*   mode
	int     max_servers
	PREINIT:
		char **bufs;
		int *lens;
		char **names;
		char **messages;
		int i;
		int ns;
	PPCODE:
		/* allocate return arrays */
		New( 0, bufs, max_servers, char *);
		New( 0, lens, max_servers, int);
		New( 0, names, max_servers, char *);
		New( 0, messages, max_servers, char *);
		/* send request to server */
		ns = XPAGet(xpa, xtemplate, paramlist, mode, bufs, lens,
		    	names, messages, max_servers);
		/* convert result into something Perlish */
		for ( i = 0 ; i < ns ; i++ )
		{
  		  /* push a reference to the hash onto the stack */
		  XPUSHs( sv_2mortal(newRV_noinc((SV*)
				    cdata2hash_Get(bufs[i],lens[i],names[i],
					       messages[i] ))) );
		  free( names[i] );
		  free( messages[i] );
		}
		/* free up memory that's no longer needed */
		Safefree( bufs );
		Safefree( lens );
		Safefree( names );
		Safefree( messages );
	

#undef NMARGS
#define NMARGS 3
void
_Set(xpa, xtemplate, paramlist, mode, buf, len, max_servers )
	IPC_XPA	xpa
	char*	xtemplate
	char*	paramlist
	char*   mode
	char*	buf
	long	len
	int     max_servers
	PREINIT:
		char **bufs;
		int   *lens;
		char **names;
		char **messages;
		int i;
		int ns;
		int n = 1;
	PPCODE:
		/* allocate return arrays */
		New( 0, names, max_servers, char *);
		New( 0, messages, max_servers, char *);
		/* send request to server */
		ns = XPASet(xpa, xtemplate, paramlist, mode, buf, len,
		    	names, messages, max_servers);
		/* convert result into something Perlish */
		for ( i = 0 ; i < ns ; i++ )
		{
  		  /* Now, push a reference to the hash onto the stack */
		  XPUSHs( sv_2mortal(newRV_noinc((SV*)
				    cdata2hash_Set(names[i], messages[i] ))) );
		  free( names[i] );
		  free( messages[i] );
		}
		/* free up memory that's no longer needed */
		Safefree( names );
		Safefree( messages );
	

void
_Info(xpa, xtemplate, paramlist, mode, max_servers )
	IPC_XPA	xpa
	char*	xtemplate
	char*	paramlist
	char*	mode
	int	max_servers
	PREINIT:
		char **names;
		char **messages;
		int i;
		int ns;
	PPCODE:
		/* allocate return arrays */
		New( 0, names, max_servers, char *);
		New( 0, messages, max_servers, char *);
		/* send request to server */
		ns = XPAInfo(xpa, xtemplate, paramlist, mode,
		    	names, messages, max_servers);
		/* convert result into something Perlish */
		for ( i = 0 ; i < ns ; i++ )
		{
  		  /* Now, push a reference to the hash onto the stack */
		  XPUSHs( sv_2mortal(newRV_noinc((SV*)
				    cdata2hash_Set(names[i], messages[i] ))) );
		  free( names[i] );
		  free( messages[i] );
		}
		/* free up memory that's no longer needed */
		Safefree( names );
		Safefree( messages );

void
_NSLookup(tname, ttype)
	char*	tname
	char*	ttype
	PREINIT:
		char **xclasses;
		char **names;
		char **methods;
		int i;
		int ns;
	PPCODE:
		ns = XPANSLookup(tname, ttype, &xclasses, &names, &methods);
		/* convert result into something Perlish */
		for ( i = 0 ; i < ns ; i++ )
		{
  		  /* Now, push a reference to the hash onto the stack */
		  XPUSHs( sv_2mortal(newRV_noinc((SV*)
				    cdata2hash_Lookup(xclasses[i],
						      names[i],
						      methods[i] ))) );
		  free( xclasses[i] );
		  free( names[i] );
		  free( methods[i] );
		}
		free( xclasses );
		free( names );
		free( methods );

int
_Access (tname, ttype)
	char *tname
	char *ttype
	CODE:
		RETVAL = XPAAccess( tname, ttype );
	OUTPUT:
		RETVAL
