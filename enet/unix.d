module enet.unix;

/** ENet Unix header */
import tango.stdc.posix.netinet.in_;
import tango.stdc.posix.sys.select;

alias int ENetSocket;

enum
{
    ENET_SOCKET_NULL = -1
};

/**< macro that converts host to net byte-order of a 16-bit value */
uint16_t ENET_HOST_TO_NET_16()(uint16_t value)
{
	return htons(value);
}

/**< macro that converts host to net byte-order of a 32-bit value */
uint32_t ENET_HOST_TO_NET_32()(uint32_t value)
{
	return htonl(value);
}

/**< macro that converts net to host byte-order of a 16-bit value */
uint16_t ENET_NET_TO_HOST_16()(uint16_t value)
{
	return ntohs(value);
}

/**< macro that converts net to host byte-order of a 32-bit value */
uint32_t ENET_NET_TO_HOST_32()(uint32_t value)
{
	return ntohl(value);
}

struct ENetBuffer
{
	void* data;
	size_t dataLength;
}

alias fd_set ENetSocketSet;

void ENET_SOCKETSET_EMPTY()(ENetSocketSet sockset)
{
	FD_ZERO(&sockset);
}
void ENET_SOCKETSET_ADD()(ENetSocketSet sockset, ENetSocket socket)
{
	FD_SET(socket, &sockset);
}
void ENET_SOCKETSET_REMOVE()(ENetSocketSet sockset, ENetSocket socket)
{
	FD_CLR(socket, &sockset);
}
int ENET_SOCKETSET_CHECK()(ENetSocketSet sockset, ENetSocket socket)
{
	FD_ISSET(socket, &sockset);
}

