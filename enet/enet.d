module enet.enet;

/** ENet public header file */

extern(C):

version(Win32)
   public import enet.win32;
else
   public import enet.unix;

public import enet.types;
public import enet.protocol;
public import enet.list;
public import enet.callbacks;

const ENET_VERSION_MAJOR = 1;
const ENET_VERSION_MINOR = 3;
const ENET_VERSION_PATCH = 3;

template ENET_VERSION_CREATE(int major, int minor, int patch)
{
   const ENET_VERSION_CREATE = (((major)<<16) | ((minor)<<8) | (patch));
}

const ENET_VERSION = ENET_VERSION_CREATE!(ENET_VERSION_MAJOR, ENET_VERSION_MINOR, ENET_VERSION_PATCH);

alias enet_uint32 ENetVersion;

enum ENetSocketType
{
	ENET_SOCKET_TYPE_STREAM   = 1,
	ENET_SOCKET_TYPE_DATAGRAM = 2
}

enum ENetSocketWait
{
	ENET_SOCKET_WAIT_NONE    = 0,
	ENET_SOCKET_WAIT_SEND    = (1 << 0),
	ENET_SOCKET_WAIT_RECEIVE = (1 << 1)
}

enum ENetSocketOption
{
	ENET_SOCKOPT_NONBLOCK  = 1,
	ENET_SOCKOPT_BROADCAST = 2,
	ENET_SOCKOPT_RCVBUF    = 3,
	ENET_SOCKOPT_SNDBUF    = 4,
	ENET_SOCKOPT_REUSEADDR = 5
}

enum
{
	ENET_HOST_ANY       = 0,            /**< specifies the default server host */
	ENET_HOST_BROADCAST = 0xFFFFFFFF,   /**< specifies a subnet-wide broadcast */

	ENET_PORT_ANY       = 0             /**< specifies that a port should be automatically chosen */
}

/**
 * Portable internet address structure. 
 *
 * The host must be specified in network byte-order, and the port must be in host 
 * byte-order. The constant ENET_HOST_ANY may be used to specify the default 
 * server host. The constant ENET_HOST_BROADCAST may be used to specify the
 * broadcast address (255.255.255.255).  This makes sense for enet_host_connect,
 * but not for enet_host_create.  Once a server responds to a broadcast, the
 * address is updated from ENET_HOST_BROADCAST to the server's actual IP address.
 */
struct ENetAddress
{
	enet_uint32 host;
	enet_uint16 port;
}

/**
 * Packet flag bit constants.
 *
 * The host must be specified in network byte-order, and the port must be in
 * host byte-order. The constant ENET_HOST_ANY may be used to specify the
 * default server host.
 
   @sa ENetPacket
*/
enum ENetPacketFlag
{
	ENET_PACKET_FLAG_RELIABLE    = (1 << 0),
	/** packet will not be sequenced with other packets
	 * not supported for reliable packets
	 */
	ENET_PACKET_FLAG_UNSEQUENCED = (1 << 1),
	/** packet will not allocate data, and user must supply it instead */
	ENET_PACKET_FLAG_NO_ALLOCATE = (1 << 2),
	/** packet will be fragmented using unreliable (instead of reliable) sends
	 * if it exceeds the MTU */
	ENET_PACKET_FLAG_UNRELIABLE_FRAGMENT = (1 << 3)
}

alias void function(ENetPacket*) ENetPacketFreeCallback;

/**
 * ENet packet structure.
 *
 * An ENet data packet that may be sent to or received from a peer. The shown 
 * fields should only be read and never modified. The data field contains the 
 * allocated data for the packet. The dataLength fields specifies the length 
 * of the allocated data.  The flags field is either 0 (specifying no flags), 
 * or a bitwise-or of any combination of the following flags:
 *
 *    ENET_PACKET_FLAG_RELIABLE - packet must be received by the target peer
 *    and resend attempts should be made until the packet is delivered
 *
 *    ENET_PACKET_FLAG_UNSEQUENCED - packet will not be sequenced with other packets 
 *    (not supported for reliable packets)
 *
 *    ENET_PACKET_FLAG_NO_ALLOCATE - packet will not allocate data, and user must supply it instead
 
   @sa ENetPacketFlag
 */
struct ENetPacket
{
	size_t                   referenceCount;  /**< internal use only */
	enet_uint32              flags;           /**< bitwise-or of ENetPacketFlag constants */
	enet_uint8*              data;            /**< allocated data for packet */
	size_t                   dataLength;      /**< length of data */
	ENetPacketFreeCallback   freeCallback;    /**< function to be called when the packet is no longer in use */
}

struct ENetAcknowledgement
{
	ENetListNode acknowledgementList;
	enet_uint32  sentTime;
	ENetProtocol command;
}

struct ENetOutgoingCommand
{
	ENetListNode outgoingCommandList;
	enet_uint16  reliableSequenceNumber;
	enet_uint16  unreliableSequenceNumber;
	enet_uint32  sentTime;
	enet_uint32  roundTripTimeout;
	enet_uint32  roundTripTimeoutLimit;
	enet_uint32  fragmentOffset;
	enet_uint16  fragmentLength;
	enet_uint16  sendAttempts;
	ENetProtocol command;
	ENetPacket* packet;
}

struct ENetIncomingCommand
{
	ENetListNode     incomingCommandList;
	enet_uint16      reliableSequenceNumber;
	enet_uint16      unreliableSequenceNumber;
	ENetProtocol     command;
	enet_uint32      fragmentCount;
	enet_uint32      fragmentsRemaining;
	enet_uint32*    fragments;
	ENetPacket*     packet;
}

enum ENetPeerState
{
	ENET_PEER_STATE_DISCONNECTED                = 0,
	ENET_PEER_STATE_CONNECTING                  = 1,
	ENET_PEER_STATE_ACKNOWLEDGING_CONNECT       = 2,
	ENET_PEER_STATE_CONNECTION_PENDING          = 3,
	ENET_PEER_STATE_CONNECTION_SUCCEEDED        = 4,
	ENET_PEER_STATE_CONNECTED                   = 5,
	ENET_PEER_STATE_DISCONNECT_LATER            = 6,
	ENET_PEER_STATE_DISCONNECTING               = 7,
	ENET_PEER_STATE_ACKNOWLEDGING_DISCONNECT    = 8,
	ENET_PEER_STATE_ZOMBIE                      = 9 
}

const ENET_BUFFER_MAXIMUM = (1 + 2 * ENET_PROTOCOL_MAXIMUM_PACKET_COMMANDS);

enum
{
	ENET_HOST_RECEIVE_BUFFER_SIZE          = 256 * 1024,
	ENET_HOST_SEND_BUFFER_SIZE             = 256 * 1024,
	ENET_HOST_BANDWIDTH_THROTTLE_INTERVAL  = 1000,
	ENET_HOST_DEFAULT_MTU                  = 1400,

	ENET_PEER_DEFAULT_ROUND_TRIP_TIME      = 500,
	ENET_PEER_DEFAULT_PACKET_THROTTLE      = 32,
	ENET_PEER_PACKET_THROTTLE_SCALE        = 32,
	ENET_PEER_PACKET_THROTTLE_COUNTER      = 7, 
	ENET_PEER_PACKET_THROTTLE_ACCELERATION = 2,
	ENET_PEER_PACKET_THROTTLE_DECELERATION = 2,
	ENET_PEER_PACKET_THROTTLE_INTERVAL     = 5000,
	ENET_PEER_PACKET_LOSS_SCALE            = (1 << 16),
	ENET_PEER_PACKET_LOSS_INTERVAL         = 10000,
	ENET_PEER_WINDOW_SIZE_SCALE            = 64 * 1024,
	ENET_PEER_TIMEOUT_LIMIT                = 32,
	ENET_PEER_TIMEOUT_MINIMUM              = 5000,
	ENET_PEER_TIMEOUT_MAXIMUM              = 30000,
	ENET_PEER_PING_INTERVAL                = 500,
	ENET_PEER_UNSEQUENCED_WINDOWS          = 64,
	ENET_PEER_UNSEQUENCED_WINDOW_SIZE      = 1024,
	ENET_PEER_FREE_UNSEQUENCED_WINDOWS     = 32,
	ENET_PEER_RELIABLE_WINDOWS             = 16,
	ENET_PEER_RELIABLE_WINDOW_SIZE         = 0x1000,
	ENET_PEER_FREE_RELIABLE_WINDOWS        = 8
}

struct ENetChannel
{
	enet_uint16  outgoingReliableSequenceNumber;
	enet_uint16  outgoingUnreliableSequenceNumber;
	enet_uint16  usedReliableWindows;
	enet_uint16[ENET_PEER_RELIABLE_WINDOWS] reliableWindows;
	enet_uint16  incomingReliableSequenceNumber;
	enet_uint16  incomingUnreliableSequenceNumber;
	ENetList     incomingReliableCommands;
	ENetList     incomingUnreliableCommands;
}

/**
 * An ENet peer which data packets may be sent or received from. 
 *
 * No fields should be modified unless otherwise specified. 
 */
struct ENetPeer
{ 
	ENetListNode  dispatchList;
	ENetHost*     host;
	enet_uint16   outgoingPeerID;
	enet_uint16   incomingPeerID;
	enet_uint32   connectID;
	enet_uint8    outgoingSessionID;
	enet_uint8    incomingSessionID;
	ENetAddress   address;            /**< Internet address of the peer */
	void*         data;               /**< Application private data, may be freely modified */
	ENetPeerState state;
	ENetChannel*  channels;
	size_t        channelCount;       /**< Number of channels allocated for communication with peer */
	enet_uint32   incomingBandwidth;  /**< Downstream bandwidth of the client in bytes/second */
	enet_uint32   outgoingBandwidth;  /**< Upstream bandwidth of the client in bytes/second */
	enet_uint32   incomingBandwidthThrottleEpoch;
	enet_uint32   outgoingBandwidthThrottleEpoch;
	enet_uint32   incomingDataTotal;
	enet_uint32   outgoingDataTotal;
	enet_uint32   lastSendTime;
	enet_uint32   lastReceiveTime;
	enet_uint32   nextTimeout;
	enet_uint32   earliestTimeout;
	enet_uint32   packetLossEpoch;
	enet_uint32   packetsSent;
	enet_uint32   packetsLost;
	enet_uint32   packetLoss;          /**< mean packet loss of reliable packets as a ratio with respect to the constant ENET_PEER_PACKET_LOSS_SCALE */
	enet_uint32   packetLossVariance;
	enet_uint32   packetThrottle;
	enet_uint32   packetThrottleLimit;
	enet_uint32   packetThrottleCounter;
	enet_uint32   packetThrottleEpoch;
	enet_uint32   packetThrottleAcceleration;
	enet_uint32   packetThrottleDeceleration;
	enet_uint32   packetThrottleInterval;
	enet_uint32   lastRoundTripTime;
	enet_uint32   lowestRoundTripTime;
	enet_uint32   lastRoundTripTimeVariance;
	enet_uint32   highestRoundTripTimeVariance;
	enet_uint32   roundTripTime;            /**< mean round trip time (RTT), in milliseconds, between sending a reliable packet and receiving its acknowledgement */
	enet_uint32   roundTripTimeVariance;
	enet_uint32   mtu;
	enet_uint32   windowSize;
	enet_uint32   reliableDataInTransit;
	enet_uint16   outgoingReliableSequenceNumber;
	ENetList      acknowledgements;
	ENetList      sentReliableCommands;
	ENetList      sentUnreliableCommands;
	ENetList      outgoingReliableCommands;
	ENetList      outgoingUnreliableCommands;
	ENetList      dispatchedCommands;
	int           needsDispatch;
	enet_uint16   incomingUnsequencedGroup;
	enet_uint16   outgoingUnsequencedGroup;
	enet_uint32[ENET_PEER_UNSEQUENCED_WINDOW_SIZE / 32] unsequencedWindow; 
	enet_uint32   eventData;
}

/** An ENet packet compressor for compressing UDP packets before socket sends or receives.
 */
struct ENetCompressor
{
	/** Context data for the compressor. Must be non-NULL. */
	void* context;
	/** Compresses from inBuffers[0:inBufferCount-1], containing inLimit bytes, to outData, outputting at most outLimit bytes. Should return 0 on failure. */
	size_t function(void* context, in ENetBuffer* inBuffers, size_t inBufferCount, size_t inLimit, enet_uint8* outData, size_t outLimit) compress;
	/** Decompresses from inData, containing inLimit bytes, to outData, outputting at most outLimit bytes. Should return 0 on failure. */
	size_t function(void* context, in enet_uint8* inData, size_t inLimit, enet_uint8* outData, size_t outLimit) decompress;
	/** Destroys the context when compression is disabled or the host is destroyed. May be NULL. */
	void function(void* context) destroy;
}

/** Callback that computes the checksum of the data held in buffers[0:bufferCount-1] */
alias enet_uint32 function(in ENetBuffer* buffers, size_t bufferCount) ENetChecksumCallback;
 
/** An ENet host for communicating with peers.
  *
  * No fields should be modified unless otherwise stated.

    @sa enet_host_create()
    @sa enet_host_destroy()
    @sa enet_host_connect()
    @sa enet_host_service()
    @sa enet_host_flush()
    @sa enet_host_broadcast()
    @sa enet_host_compress()
    @sa enet_host_compress_with_range_coder()
    @sa enet_host_channel_limit()
    @sa enet_host_bandwidth_limit()
    @sa enet_host_bandwidth_throttle()
  */
struct ENetHost
{
	ENetSocket           socket;
	ENetAddress          address;                     /**< Internet address of the host */
	enet_uint32          incomingBandwidth;           /**< downstream bandwidth of the host */
	enet_uint32          outgoingBandwidth;           /**< upstream bandwidth of the host */
	enet_uint32          bandwidthThrottleEpoch;
	enet_uint32          mtu;
	enet_uint32          randomSeed;
	int                  recalculateBandwidthLimits;
	ENetPeer*            peers;                       /**< array of peers allocated for this host */
	size_t               peerCount;                   /**< number of peers allocated for this host */
	size_t               channelLimit;                /**< maximum number of channels allowed for connected peers */
	enet_uint32          serviceTime;
	ENetList             dispatchQueue;
	int                  continueSending;
	size_t               packetSize;
	enet_uint16          headerFlags;
	ENetProtocol[ENET_PROTOCOL_MAXIMUM_PACKET_COMMANDS] commands;
	size_t               commandCount;
	ENetBuffer[ENET_BUFFER_MAXIMUM] buffers;
	size_t               bufferCount;
	ENetChecksumCallback checksum;                    /**< callback the user can set to enable packet checksums for this host */
	ENetCompressor       compressor;
	enet_uint8[ENET_PROTOCOL_MAXIMUM_MTU][2] packetData;
	ENetAddress          receivedAddress;
	enet_uint8*          receivedData;
	size_t               receivedDataLength;
	enet_uint32          totalSentData;               /**< total data sent, user should reset to 0 as needed to prevent overflow */
	enet_uint32          totalSentPackets;            /**< total UDP packets sent, user should reset to 0 as needed to prevent overflow */
	enet_uint32          totalReceivedData;           /**< total data received, user should reset to 0 as needed to prevent overflow */
	enet_uint32          totalReceivedPackets;        /**< total UDP packets received, user should reset to 0 as needed to prevent overflow */
}

/**
 * An ENet event type, as specified in @ref ENetEvent.
 */
enum ENetEventType
{
	/** no event occurred within the specified time limit */
	ENET_EVENT_TYPE_NONE       = 0,  

	/** a connection request initiated by enet_host_connect has completed.  
	 * The peer field contains the peer which successfully connected. 
	 */
	ENET_EVENT_TYPE_CONNECT    = 1,  

	/** a peer has disconnected.  This event is generated on a successful 
	 * completion of a disconnect initiated by enet_pper_disconnect, if 
	 * a peer has timed out, or if a connection request intialized by 
	 * enet_host_connect has timed out.  The peer field contains the peer 
	 * which disconnected. The data field contains user supplied data 
	 * describing the disconnection, or 0, if none is available.
	 */
	ENET_EVENT_TYPE_DISCONNECT = 2,  

	/** a packet has been received from a peer.  The peer field specifies the
	 * peer which sent the packet.  The channelID field specifies the channel
	 * number upon which the packet was received.  The packet field contains
	 * the packet that was received; this packet must be destroyed with
	 * enet_packet_destroy after use.
	 */
	ENET_EVENT_TYPE_RECEIVE    = 3
}

/**
 * An ENet event as returned by enet_host_service().
   
   @sa enet_host_service
 */
struct ENetEvent 
{
	ENetEventType        type;      /**< type of the event */
	ENetPeer*            peer;      /**< peer that generated a connect, disconnect or receive event */
	enet_uint8           channelID; /**< channel on the peer that generated the event, if appropriate */
	enet_uint32          data;      /**< data associated with the event, if appropriate */
	ENetPacket*          packet;    /**< packet associated with the event, if appropriate */
}

/** ENet global functions */

/** 
  Initializes ENet globally.  Must be called prior to using any functions in
  ENet.
  @returns 0 on success, < 0 on failure
*/
int enet_initialize();

/** 
  Initializes ENet globally and supplies user-overridden callbacks. Must be called prior to using any functions in ENet. Do not use enet_initialize() if you use this variant. Make sure the ENetCallbacks structure is zeroed out so that any additional callbacks added in future versions will be properly ignored.

  @param version the constant ENET_VERSION should be supplied so ENet knows which version of ENetCallbacks struct to use
  @param inits user-overriden callbacks where any NULL callbacks will use ENet's defaults
  @returns 0 on success, < 0 on failure
*/
int enet_initialize_with_callbacks(ENetVersion ver, in ENetCallbacks* inits);

/** 
  Shuts down ENet globally.  Should be called when a program that has
  initialized ENet exits.
*/
void enet_deinitialize();

/** ENet private implementation functions */

/**
  Returns the wall-time in milliseconds.  Its initial value is unspecified
  unless otherwise set.
  */
enet_uint32 enet_time_get();
/**
  Sets the current wall-time in milliseconds.
  */
void enet_time_set(enet_uint32);

/** ENet socket functions */
ENetSocket enet_socket_create(ENetSocketType);
int        enet_socket_bind(ENetSocket, in ENetAddress*);
int        enet_socket_listen(ENetSocket, int);
ENetSocket enet_socket_accept(ENetSocket, ENetAddress*);
int        enet_socket_connect(ENetSocket, in ENetAddress*);
int        enet_socket_send(ENetSocket, in ENetAddress*, in ENetBuffer*, size_t);
int        enet_socket_receive(ENetSocket, ENetAddress*, ENetBuffer*, size_t);
int        enet_socket_wait(ENetSocket, enet_uint32*, enet_uint32);
int        enet_socket_set_option(ENetSocket, ENetSocketOption, int);
void       enet_socket_destroy(ENetSocket);
int        enet_socketset_select(ENetSocket, ENetSocketSet*, ENetSocketSet*, enet_uint32);

/** ENet address functions */
/** Attempts to resolve the host named by the parameter hostName and sets
    the host field in the address parameter if successful.
    @param address destination to store resolved address
    @param hostName host name to lookup
    @retval 0 on success
    @retval < 0 on failure
    @returns the address of the given hostName in address on success
*/
int enet_address_set_host(ENetAddress* address, in char* hostName);

/** Gives the printable form of the ip address specified in the address parameter.
    @param address    address printed
    @param hostName   destination for name, must not be NULL
    @param nameLength maximum length of hostName.
    @returns the null-terminated name of the host in hostName on success
    @retval 0 on success
    @retval < 0 on failure
*/
int enet_address_get_host_ip(in ENetAddress* address, char* hostName, size_t nameLength);

/** Attempts to do a reverse lookup of the host field in the address parameter.
    @param address    address used for reverse lookup
    @param hostName   destination for name, must not be NULL
    @param nameLength maximum length of hostName.
    @returns the null-terminated name of the host in hostName on success
    @retval 0 on success
    @retval < 0 on failure
*/
int enet_address_get_host(in ENetAddress* address, char* hostName, size_t nameLength);

/** @} */

ENetPacket*  enet_packet_create(in void*, size_t, enet_uint32);
void         enet_packet_destroy(ENetPacket*);
int          enet_packet_resize (ENetPacket*, size_t);
enet_uint32  enet_crc32(in ENetBuffer*, size_t);
                
ENetHost*  enet_host_create(in ENetAddress*, size_t, size_t, enet_uint32, enet_uint32);
void       enet_host_destroy(ENetHost*);
ENetPeer*  enet_host_connect(ENetHost*, in ENetAddress*, size_t, enet_uint32);
int        enet_host_check_events(ENetHost*, ENetEvent*);
int        enet_host_service(ENetHost*, ENetEvent*, enet_uint32);
void       enet_host_flush(ENetHost*);
void       enet_host_broadcast(ENetHost*, enet_uint8, ENetPacket*);
void       enet_host_compress(ENetHost*, in ENetCompressor*);
int        enet_host_compress_with_range_coder(ENetHost* host);
void       enet_host_channel_limit(ENetHost*, size_t);
void       enet_host_bandwidth_limit(ENetHost*, enet_uint32, enet_uint32);
void       enet_host_bandwidth_throttle(ENetHost*);

int                 enet_peer_send(ENetPeer*, enet_uint8, ENetPacket*);
ENetPacket*         enet_peer_receive(ENetPeer*, enet_uint8* channelID);
void                enet_peer_ping(ENetPeer*);
void                enet_peer_reset(ENetPeer*);
void                enet_peer_disconnect(ENetPeer*, enet_uint32);
void                enet_peer_disconnect_now(ENetPeer*, enet_uint32);
void                enet_peer_disconnect_later(ENetPeer*, enet_uint32);
void                enet_peer_throttle_configure(ENetPeer*, enet_uint32, enet_uint32, enet_uint32);
int                 enet_peer_throttle(ENetPeer*, enet_uint32);
void                enet_peer_reset_queues(ENetPeer*);
void                enet_peer_setup_outgoing_command(ENetPeer*, ENetOutgoingCommand*);
ENetOutgoingCommand* enet_peer_queue_outgoing_command(ENetPeer*, in ENetProtocol*, ENetPacket*, enet_uint32, enet_uint16);
ENetIncomingCommand* enet_peer_queue_incoming_command(ENetPeer*, in ENetProtocol*, ENetPacket*, enet_uint32);
ENetAcknowledgement* enet_peer_queue_acknowledgement(ENetPeer*, in ENetProtocol*, enet_uint16);
void                enet_peer_dispatch_incoming_unreliable_commands(ENetPeer*, ENetChannel*);
void                enet_peer_dispatch_incoming_reliable_commands(ENetPeer*, ENetChannel*);

void* enet_range_coder_create();
void   enet_range_coder_destroy(void*);
size_t enet_range_coder_compress(void*, in ENetBuffer*, size_t, size_t, enet_uint8*, size_t);
size_t enet_range_coder_decompress(void*, in enet_uint8*, size_t, enet_uint8*, size_t);
   
size_t enet_protocol_command_size(enet_uint8);
