/*
  (C) 2000 Smithsonian Astrophysical Observatory.  All rights reserved.

  This program is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.
*/
char*	hash2str( HV* hash );
HV*	cdata2hash_Get( char *buf, int len, char *name, char *message );
HV *	cdata2hash_Set( char *name, char *message );
HV *	cdata2hash_Lookup( char *class, char *name, char *method );
