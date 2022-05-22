#include "HashTable.h"



int improvedHashFunction(char* str) {
	int sum = 0;
	for (unsigned int i = 0, len = strlen(str); i < len; i++) { 
		sum += (int)(pow(31.0, (len - i - 1.0)) * str[i]); // the hashing formula we implemented
	}
	return sum;
}


int insert(HashTable* ht, char* id, char* type, int scopeId, int* paramCount, Parameter *params) {
	if (ht == NULL || id == NULL || ht->hashTable == NULL) // check if the id is in the hash table
		return 0;

	int hashing = hash(id, ht);
	if (search(ht, id) == 1)
	{
		LinkedList* lnode = getNode(ht->hashTable[hashing].chain, id);
		if(lnode->decList->scopeId == scopeId)
		{
			return REDECLARATION_ERROR;
		}
		lnode->decList = addDecToStart(lnode->decList, type, scopeId, paramCount, params);
	}
	else
	{
		if (ht->hashTable[hashing].chain == NULL)
			++ht->cellsTaken;
		ht->hashTable[hashing].chain = addToStart(ht->hashTable[hashing].chain, id, type, scopeId, paramCount, params);

		++ht->numOfElements;
	}
	return 1;
}

LinkedList** place(HashTable* ht, char* str) {
	return &(ht->hashTable[hash(str, ht)].chain);
}

HashTable* initTable(int tableSize)
{
	HashTable* new_hash_table = (HashTable*)malloc(sizeof(HashTable)); 
	if (new_hash_table == NULL)
	{
		printf("out of memory\n");
		return NULL;
	}
	new_hash_table->tableSize = tableSize;
	new_hash_table->hashTable = (HashTableElement*)malloc(tableSize * sizeof(HashTableElement));
	if (new_hash_table->hashTable == NULL)
	{
		free(new_hash_table);
		printf("out of memory\n");
		return NULL;
	}
	for (int i = 0; i < tableSize; ++i)
		new_hash_table->hashTable[i].chain = NULL;
	new_hash_table->hashFunction = 3;
	new_hash_table->cellsTaken = 0;
	new_hash_table->numOfElements = 0;

	return new_hash_table;
}


int hash(char* str, HashTable* ht)
{
	//𝑖𝑛𝑑𝑒𝑥 = | ℎ𝑎𝑠ℎ𝐹𝑢𝑛𝑐𝑡𝑖𝑜𝑛(𝑠𝑡𝑟) | (𝑚𝑜𝑑 𝑡𝑎𝑏𝑙𝑒𝑆𝑖𝑧𝑒)

	int index;

	switch (ht->hashFunction)
	{
	case 3:
		index = improvedHashFunction(str);
		break;
	default:
		printf("Error: No such hash function - default index set to 0\n");
		freeHashTable(ht);
		return 0;
	}
	index = abs(index) % ht->tableSize;

	return index;
}

int deleteStr(HashTable* ht, char* str)
{
	if (ht == NULL || str == NULL || ht->hashTable == NULL) //check if ht or str are NULL
		return 0;
	if (search(ht, str))
	{
		*place(ht, str) = DeleteElement(*place(ht, str), str);
		--ht->numOfElements;
		if (*place(ht, str) == NULL)
			--ht->cellsTaken;
		return 1;
	}
	return 0;
}

int search(HashTable* ht, char* str)
{
	if (ht == NULL || str == NULL || ht->hashTable == NULL || !isInList(ht->hashTable[hash(str, ht)].chain, str))
		return 0;
	return 1;
}

void printHashTabe(HashTable* ht)
{
	if (ht)
	{
		printf("Number of elements: %d\n", ht->numOfElements);
		printf("Number of cells taken: %d\n", ht->cellsTaken);
		for (int i = 0, counter = 0; i < ht->tableSize; ++i) // loop for printing each cell of the hash table , counter is for numbering the occupied cells
		{
			if (ht->hashTable[i].chain != NULL) 
			{
				printf("%d. \n", ++counter);
				PrintList(ht->hashTable[i].chain);
				printf("\n");
			}
		}
	}
}

HashTable* freeHashTable(HashTable* ht)
{
	if (ht != NULL && ht->hashTable != NULL)
		for (int i = 0; i < ht->tableSize; ++i)
			ht->hashTable[i].chain = FreeList(ht->hashTable[i].chain);
	if (ht != NULL)
	{
		if (ht->hashTable != NULL)
			free(ht->hashTable);
		ht->hashTable = NULL;
		free(ht);
		ht = NULL;
	}
	return ht;
}
