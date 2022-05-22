
#include <math.h>
#include "LinkedList.c"

#define REDECLARATION_ERROR 2
#define LONGEST_TERM 255


typedef struct HashTableElement
{
	int key;
	LinkedList* chain;
} HashTableElement;


typedef struct HashTable
{
	HashTableElement* hashTable;
	int hashFunction;
	int tableSize;
	int cellsTaken;
	int numOfElements;
} HashTable;
int improvedHashFunction(char* str); // hash function - A function that returns for the string str n length characters the stack value calculated according to a formula
int hash(char* str, HashTable* ht); /* The function receives a string and a hash table in which you want to save the string.
															The function calculates and returns an index where we store the string.*/
HashTable* initTable(int tableSize); //Which accepts the table size
int insert(HashTable* ht, char* id, char* type, int scopeId, int* paramCount, Parameter *params); // The function gets a table and a string, and puts the string into the table.
int deleteStr(HashTable* ht, char* str); // The function checks if the str is in a hash if it then deletes it
int search(HashTable* ht, char* str); //The function gets a string and a table and checks if the string exists in the table.
LinkedList** place(HashTable* ht, char* str); //The function returns the place of the string in the hash table
void printHashTabe(HashTable* ht); // The function prints all the words in hash table
HashTable* freeHashTable(HashTable*); // The function free all the elements in hash table