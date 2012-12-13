module enet.protocol;

/** ENet protocol */

import enet.types;

enum
{
	ENET_PROTOCOL_MINIMUM_MTU             = 576,
	ENET_PROTOCOL_MAXIMUM_MTU             = 4096,
	ENET_PROTOCOL_MAXIMUM_PACKET_COMMANDS = 32,
	ENET_PROTOCOL_MINIMUM_WINDOW_SIZE     = 4096,
	ENET_PROTOCOL_MAXIMUM_WINDOW_SIZE     = 32768,
	ENET_PROTOCOL_MINIMUM_CHANNEL_COUNT   = 1,
	ENET_PROTOCOL_MAXIMUM_CHANNEL_COUNT   = 255,
	ENET_PROTOCOL_MAXIMUM_PEER_ID         = 0xFFF
}

enum ENetProtocolCommand
{
	ENET_PROTOCOL_COMMAND_NONE               = 0,
	ENET_PROTOCOL_COMMAND_ACKNOWLEDGE        = 1,
	ENET_PROTOCOL_COMMAND_CONNECT            = 2,
	ENET_PROTOCOL_COMMAND_VERIFY_CONNECT     = 3,
	ENET_PROTOCOL_COMMAND_DISCONNECT         = 4,
	ENET_PROTOCOL_COMMAND_PING               = 5,
	ENET_PROTOCOL_COMMAND_SEND_RELIABLE      = 6,
	ENET_PROTOCOL_COMMAND_SEND_UNRELIABLE    = 7,
	ENET_PROTOCOL_COMMAND_SEND_FRAGMENT      = 8,
	ENET_PROTOCOL_COMMAND_SEND_UNSEQUENCED   = 9,
	ENET_PROTOCOL_COMMAND_BANDWIDTH_LIMIT    = 10,
	ENET_PROTOCOL_COMMAND_THROTTLE_CONFIGURE = 11,
	ENET_PROTOCOL_COMMAND_SEND_UNRELIABLE_FRAGMENT = 12,
	ENET_PROTOCOL_COMMAND_COUNT              = 13,

	ENET_PROTOCOL_COMMAND_MASK               = 0x0F
}

enum ENetProtocolFlag
{
	ENET_PROTOCOL_COMMAND_FLAG_ACKNOWLEDGE = (1 << 7),
	ENET_PROTOCOL_COMMAND_FLAG_UNSEQUENCED = (1 << 6),

	ENET_PROTOCOL_HEADER_FLAG_COMPRESSED = (1 << 14),
	ENET_PROTOCOL_HEADER_FLAG_SENT_TIME  = (1 << 15),
	ENET_PROTOCOL_HEADER_FLAG_MASK       = ENET_PROTOCOL_HEADER_FLAG_COMPRESSED | ENET_PROTOCOL_HEADER_FLAG_SENT_TIME,

	ENET_PROTOCOL_HEADER_SESSION_MASK    = (3 << 12),
	ENET_PROTOCOL_HEADER_SESSION_SHIFT   = 12
}

struct _ENetProtocolHeader
{
align(1):
	enet_uint16 peerID;
	enet_uint16 sentTime;
}

struct ENetProtocolCommandHeader
{
align(1):
	enet_uint8 command;
	enet_uint8 channelID;
	enet_uint16 reliableSequenceNumber;
}

struct ENetProtocolAcknowledge
{
align(1):
	ENetProtocolCommandHeader header;
	enet_uint16 receivedReliableSequenceNumber;
	enet_uint16 receivedSentTime;
}

struct ENetProtocolConnect
{
align(1):
	ENetProtocolCommandHeader header;
	enet_uint16 outgoingPeerID;
	enet_uint8  incomingSessionID;
	enet_uint8  outgoingSessionID;
	enet_uint32 mtu;
	enet_uint32 windowSize;
	enet_uint32 channelCount;
	enet_uint32 incomingBandwidth;
	enet_uint32 outgoingBandwidth;
	enet_uint32 packetThrottleInterval;
	enet_uint32 packetThrottleAcceleration;
	enet_uint32 packetThrottleDeceleration;
	enet_uint32 connectID;
	enet_uint32 data;
}

struct ENetProtocolVerifyConnect
{
align(1):
	ENetProtocolCommandHeader header;
	enet_uint16 outgoingPeerID;
	enet_uint8  incomingSessionID;
	enet_uint8  outgoingSessionID;
	enet_uint32 mtu;
	enet_uint32 windowSize;
	enet_uint32 channelCount;
	enet_uint32 incomingBandwidth;
	enet_uint32 outgoingBandwidth;
	enet_uint32 packetThrottleInterval;
	enet_uint32 packetThrottleAcceleration;
	enet_uint32 packetThrottleDeceleration;
	enet_uint32 connectID;
}

struct ENetProtocolBandwidthLimit
{
align(1):
	ENetProtocolCommandHeader header;
	enet_uint32 incomingBandwidth;
	enet_uint32 outgoingBandwidth;
}

struct ENetProtocolThrottleConfigure
{
align(1):
	ENetProtocolCommandHeader header;
	enet_uint32 packetThrottleInterval;
	enet_uint32 packetThrottleAcceleration;
	enet_uint32 packetThrottleDeceleration;
}

struct ENetProtocolDisconnect
{
align(1):
	ENetProtocolCommandHeader header;
	enet_uint32 data;
}

struct ENetProtocolPing
{
align(1):
	ENetProtocolCommandHeader header;
}

struct ENetProtocolSendReliable
{
align(1):
	ENetProtocolCommandHeader header;
	enet_uint16 dataLength;
}

struct ENetProtocolSendUnreliable
{
align(1):
	ENetProtocolCommandHeader header;
	enet_uint16 unreliableSequenceNumber;
	enet_uint16 dataLength;
}

struct ENetProtocolSendUnsequenced
{
align(1):
	ENetProtocolCommandHeader header;
	enet_uint16 unsequencedGroup;
	enet_uint16 dataLength;
}

struct ENetProtocolSendFragment
{
align(1):
	ENetProtocolCommandHeader header;
	enet_uint16 startSequenceNumber;
	enet_uint16 dataLength;
	enet_uint32 fragmentCount;
	enet_uint32 fragmentNumber;
	enet_uint32 totalLength;
	enet_uint32 fragmentOffset;
}

union ENetProtocol
{
align(1):
	ENetProtocolCommandHeader header;
	ENetProtocolAcknowledge acknowledge;
	ENetProtocolConnect connect;
	ENetProtocolVerifyConnect verifyConnect;
	ENetProtocolDisconnect disconnect;
	ENetProtocolPing ping;
	ENetProtocolSendReliable sendReliable;
	ENetProtocolSendUnreliable sendUnreliable;
	ENetProtocolSendUnsequenced sendUnsequenced;
	ENetProtocolSendFragment sendFragment;
	ENetProtocolBandwidthLimit bandwidthLimit;
	ENetProtocolThrottleConfigure throttleConfigure;
}


