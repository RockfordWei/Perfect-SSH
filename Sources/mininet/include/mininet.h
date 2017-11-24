#ifndef __MININET__
#define __MININET__
#define MININET_INVALID_ADDRESS -1
#define MININET_CONNECTION_FAILED -2
extern int connectTo(const char * address, int port);
extern void shutDown(int sock);
#endif
