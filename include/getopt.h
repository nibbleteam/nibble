#ifndef __GETOPT_H_
#define __GETOPT_H_

extern int opterr;      /* if error message should be printed */
extern int optind;      /* index into parent argv vector */
extern int optopt;      /* character checked for validity */
extern int optreset;    /* reset getopt  */
extern char *optarg;    /* argument associated with option */

int getopt(int nargc, char * const nargv[], const char *ostr);

#endif // __GETOPT_H_
