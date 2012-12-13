module enet.callbacks;

/** ENet callbacks */

extern(C):

struct ENetCallbacks
{
	void* function(size_t size) malloc;
	void function(void* memory) free;
	void function() no_memory;
}

/** ENet internal callbacks */
void* enet_malloc(size_t);
void  enet_free(void*);
