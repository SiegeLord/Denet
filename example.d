module example;

import enet.enet;

import core.thread;
import core.memory;

import tango.core.sync.Mutex;
import tango.io.Stdout;
import tango.io.Console;
import tango.text.convert.Format;
import tango.io.stream.Lines;

__gshared bool Quit = false;
__gshared Mutex MainMutex;
__gshared const(char)[][] Messages;

ENetPeer* Connect(ENetHost* client, const(char)[] addr, ushort port)
{
	ENetAddress address;
	ENetEvent event;
	ENetPeer *peer;
	enet_address_set_host(&address, (addr ~ "\0").ptr);
	address.port = port;
	/* Initiate the connection, allocating the two channels 0 and 1. */
	peer = enet_host_connect(client, &address, 2, 0);
	if(peer is null)
	{
		Stderr("No available peers for initiating an ENet connection.").nl;
		return null;
	}

	if(enet_host_service (client, &event, 5000) > 0 && event.type == ENetEventType.ENET_EVENT_TYPE_CONNECT)
	{
		Stdout.formatln("Connected to {}:{}", addr, port).nl;
	}
	else
	{
		enet_peer_reset(peer);
		Stderr.formatln("Connected to {}:{}", addr, port).nl;
		return null;
	}
	
	return peer;
}

int Service(ENetHost* host, int num_peers, const(char)[] peer_name)
{
	struct SPeerDesc
	{
		char[] Name;
		this(char[] name)
		{
			Name = name;
		}
	}
	
	ENetEvent event;
	if(enet_host_service(host, &event, 100) > 0)
	{
		switch(event.type)
		{
			case ENetEventType.ENET_EVENT_TYPE_CONNECT:
				Stdout.formatln("{} {} connected from {}:{}.", peer_name, num_peers, event.peer.address.host, event.peer.address.port);
				auto b = new SPeerDesc(Format("{} {}", peer_name, num_peers++));
				event.peer.data = b;
				break;
			case ENetEventType.ENET_EVENT_TYPE_RECEIVE:
				Stdout.formatln("A packet of length {} containing {} was received from {} on channel {}", event.packet.dataLength, 
					(cast(char*)event.packet.data)[0..event.packet.dataLength],	(cast(SPeerDesc*)event.peer.data).Name, event.channelID);

				enet_packet_destroy(event.packet);
				break;
			case ENetEventType.ENET_EVENT_TYPE_DISCONNECT:
				Stdout.formatln("{} disconected.\n", (cast(SPeerDesc*)event.peer.data).Name);

				event.peer.data = null;
			default: {}
		}
	}
	
	return num_peers;
}

void Server()
{
	ENetHost* server;
	
	ENetAddress address;
	address.host = ENET_HOST_ANY;
	address.port = 1234;
	
	server = enet_host_create(&address,	32,	2, 0, 0);
	if(server is null)
	{
		Stderr("Failed to create a server.").nl;
	}
	scope(exit) enet_host_destroy(server);
	Stdout("Server started").nl;
	
	int num_peers = 0;
	
	while(!Quit)
	{
		num_peers = Service(server, num_peers, "Client");
	}
	
	Stdout("Server done").nl;
}

void Client(const(char)[] addr)
{
	ENetHost* client;

	client = enet_host_create (null, 1, 2, 57600 / 8, 14400 / 8);
	if(client is null)
	{
		Stderr("Failed to create a client.").nl;
		return;
	}
	scope(exit) enet_host_destroy(client);
	Stdout("Client started").nl;
	
	auto server = Connect(client, addr, 1234);
	if(server is null)
		return;
	
	int num_peers = 0;
	int served_messages = 0;
	
	while(!Quit)
	{
		num_peers = Service(client, num_peers, "Server");
		
		MainMutex.lock();
		while(served_messages < Messages.length)
		{
			auto message = Messages[served_messages];
			if(message.length > 0)
			{
				ENetPacket* packet = enet_packet_create(message.ptr, message.length, ENetPacketFlag.ENET_PACKET_FLAG_RELIABLE);
				enet_peer_send(server, 0, packet);
			}
			
			served_messages++;
		}
		MainMutex.unlock();
	}
	
	Stdout("Client done").nl;
}

extern(C)
{
	void* DMalloc(size_t size)
	{
		return GC.malloc(size);
	}
	
	void DFree(void* mem)
	{
		GC.free(mem);
	}
	
	void DNoMemory()
	{
		Stderr("Out of memory.").nl;
	}
}

int main(char[][] arg_list)
{
	bool server = false;
	const(char)[] addr;
	
	if(arg_list.length > 1)
		addr = arg_list[1];
	else
		server = true;
	
	auto d_callbacks = ENetCallbacks(&DMalloc, &DFree, &DNoMemory);
	if(enet_initialize_with_callbacks(ENET_VERSION, &d_callbacks) != 0)
	{
		Stderr("Failed to initialize enet.").nl;
		return -1;
	}
	scope(exit) enet_deinitialize();
	
	MainMutex = new Mutex;
	Thread thread;
	
	if(server)
		thread = new Thread(&Server);
	else
		thread = new Thread({Client(addr);});
	
	thread.start();
	
	foreach(line; new Lines!(char)(Cin.stream))
	{
		MainMutex.lock();
		Messages ~= line;
		MainMutex.unlock();
	}
	
	Quit = true;
	thread.join();
	
	return 0;
}
