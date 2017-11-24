#include <arpa/inet.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include "mininet.h"

int connectTo(const char * address, int port) {
  in_addr_t hostaddr = inet_addr(address);
  if (hostaddr == (in_addr_t)0xffffffff) {
    struct hostent * he = gethostbyname(address);
    if (!he) {
      return MININET_INVALID_ADDRESS;
    }
    struct in_addr ** list = (struct in_addr **)he->h_addr_list;
    hostaddr = list[0]->s_addr;
  }
  struct sockaddr_in server;
  memset(&server, 0, sizeof(server));
  server.sin_addr.s_addr = hostaddr;
  server.sin_family = AF_INET;
  server.sin_port = htons(port);
  int sock = socket(AF_INET, SOCK_STREAM, 0);
  if (connect(sock, (struct sockaddr*)&server, sizeof(server))) {
    close(sock);
    return MININET_CONNECTION_FAILED;
  } else {
    return sock;
  }
}

void shutDown(int sock) {
	shutdown(sock, SHUT_RDWR);
	close(sock);
}
