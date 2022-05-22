#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


typedef struct Parameter
{
	char* type;
	struct Parameter *next;
} Parameter;

typedef struct declarationLList
{
	int scopeId;
	char* type;
	int* paramCount;
	Parameter *params;
	struct declarationLList* next;
} declarationLList;

typedef struct LinkedList
{
	char* data;
	declarationLList* decList;
	struct LinkedList* next;
} LinkedList;

Parameter* BuildParamNode(char* type); // create new node to the param list
Parameter* addParamToEnd(Parameter* head, Parameter* new_chain); //add a new parameter to the end of the parameter list
void printParamList(Parameter* head);
Parameter* FreeParamList(Parameter*); //free all the values at the declaration list
Parameter* DeleteParamElement(Parameter*); // delete a element at the linked list

void printDecList(declarationLList* head);
declarationLList* addDecToStart(declarationLList* head, char* type, int scopeId, int* paramCount, Parameter *params); //add a new value to the start of the declaration list
declarationLList* BuildDecNode(char* type, int scopeId, int* paramCount, Parameter *params); // create new node to the declaration list
declarationLList* FreeDecList(declarationLList*); //free all the values at the declaration list
declarationLList* DeleteDecElement(declarationLList*); // delete a element at the declaration list

void PrintList(LinkedList*); // print the values in the linked list
LinkedList* BuildNode(char* id, char* type, int scopeId, int* paramCount, Parameter *params); // create new node to the linked list
LinkedList* addToStart(LinkedList* head, char* new_node, char* type, int scopeId, int* paramCount, Parameter *params); //add a new value to the start of the linked list
LinkedList* addNodeToEnd(LinkedList* head, LinkedList* new_chain); //add a new value to the end of the linked list
LinkedList* FreeList(LinkedList*); //free all the values at the linked list
LinkedList* DeleteElement(LinkedList*, char*); // delete a element at the linked list
LinkedList* getNode(LinkedList*, char*); // find a node with the value in list
int isInList(LinkedList*, char*); // check if a certain value is in the linked list