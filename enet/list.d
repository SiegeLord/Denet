module enet.list;

/** ENet list management */

extern(C):

struct ENetListNode
{
	ENetListNode* next;
	ENetListNode* previous;
}

alias ENetListNode* ENetListIterator;

struct ENetList
{
	ENetListNode sentinel;
}

void enet_list_clear(ENetList*);

ENetListIterator enet_list_insert(ENetListIterator, void*);
void* enet_list_remove(ENetListIterator);
ENetListIterator enet_list_move(ENetListIterator, void*, void*);

size_t enet_list_size(ENetList*);

ENetListIterator enet_list_begin()(ENetList* list)
{
	return list.sentinel.next;
}

ENetListIterator enet_list_end()(ENetList* list)
{
	return &list.sentinel;
}

bool enet_list_empty()(ENetList* list)
{
	return enet_list_begin(list) == enet_list_end(list);
}

ENetListIterator enet_list_next()(ENetListIterator iterator)
{
	return iterator.next;
}

ENetListIterator enet_list_previous()(ENetListIterator iterator)
{
	return iterator.previous;
}

ENetListIterator enet_list_front()(ENetList* list)
{
	return list.sentinel.next;
}

ENetListIterator enet_list_back()(ENetList* list)
{
	return list.sentinel.previous;
}
