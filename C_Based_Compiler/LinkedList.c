#include "LinkedList.h"


Parameter* BuildParamNode(char* type)
{
	Parameter* temp = (Parameter*)malloc(sizeof(Parameter));

	int len = strlen(type);
	temp->type = (char*)malloc(len + 1);
	if (temp->type == NULL) {
		printf("out of memory\n");
		exit(1);
	}

	temp->type[len] = '\0';
	strcpy(temp->type, type);

	temp->next = NULL;

	return temp;
}

Parameter* addParamToEnd(Parameter* head, Parameter* new_chain)
{
	Parameter* link = NULL;

	if (head == NULL)
		head = new_chain;
	else
	{
		for (link = head; link->next != NULL; link = link->next);
		link->next = new_chain;
	}
	return head;
}

Parameter* DeleteParamElement(Parameter* head)
{
	Parameter* temp = head->next;
	head->next = NULL;
	FreeParamList(head);

	head = temp;
	return head;
}

declarationLList* addDecToStart(declarationLList* head, char* type, int scopeId, int* paramCount, Parameter *params)
{
	declarationLList* new_head;
	new_head = BuildDecNode(type, scopeId, paramCount, params);
	new_head->next = head;

	return new_head;
}

declarationLList* BuildDecNode(char* type, int scopeId, int* paramCount, Parameter *params) {
	declarationLList* temp = (declarationLList*)malloc(sizeof(declarationLList));
	if (temp == NULL) {
		printf("out of memory\n");
		exit(1);
	}

	// add the given type to the declaration list
	int len = strlen(type);
	temp->type = (char*)malloc(len + 1);
	if (temp->type == NULL) {
		printf("out of memory\n");
		exit(1);
	}
	temp->type[len] = '\0';
	strcpy(temp->type, type);

	temp->scopeId = scopeId;

	if (paramCount)
	{
		temp->paramCount = paramCount;
	}
	else
	{
		temp->paramCount = NULL;
	}

	if (params)
	{
		temp->params = params;
	}
	else
	{
		temp->params = NULL;
	}

	temp->next = NULL;

	return temp;
}


LinkedList* addToStart(LinkedList* head, char* new_node, char* type, int scopeId, int* paramCount, Parameter *params) {

	LinkedList* new_head;
	new_head = BuildNode(new_node, type, scopeId, paramCount, params);
	new_head->next = head;
	return new_head;
}


LinkedList* addNodeToEnd(LinkedList* head, LinkedList* new_chain) {

	LinkedList* link = NULL;

	if (head == NULL)
		head = new_chain;
	else
	{
		for (link = head; link->next != NULL; link = link->next);
		link->next = new_chain;
	}
	return head;
}

LinkedList* getNode(LinkedList* head, char* id) {
	while (head != NULL) {
		if (strlen(id) == strlen(head->data) && strcmp(id, head->data) == 0) // check if the word is in the linked list 
			return head;
		head = head->next;
	}
	return NULL;
}

int isInList(LinkedList* head, char* value) {

	if (getNode(head, value))
		return 1;
	return 0;
}


declarationLList* DeleteDecElement(declarationLList* head)
{
	if(head == NULL)
	{
		return head;
	}
	declarationLList* temp = head->next;
	head->next = NULL;
	FreeDecList(head);
	head = temp;
	return head;
}


LinkedList* DeleteElement(LinkedList* head, char* value) {

	LinkedList* temp = NULL;
	while (head != NULL)
	{
		if (strlen(value) == strlen(head->data) && strcmp(value, head->data) == 0)
		{ // check if the word is in the linked list 
			temp = head->next;
			
			DeleteDecElement(head->decList);
			free(head->data);
			free(head);
			head = temp;
			return head;
		}
		head = head->next;
	}
	return head;
}

LinkedList* BuildNode(char* id, char* type, int scopeId, int* paramCount, Parameter *params)
{
	LinkedList* temp = (LinkedList*)malloc(sizeof(LinkedList));
	if (temp == NULL) {
		printf("out of memory\n");
		exit(1);
	}

	// add the given value (data \ name)
	int len = strlen(id);
	temp->data = (char*)malloc(len + 1);
	if (temp->data == NULL) {
		printf("out of memory\n");
		exit(1);
	}
	temp->data[len] = '\0';
	strcpy(temp->data, id);

	//temp->decList = decList;

	/*
	// add the given kind
	len = strlen(kind);
	temp->kind = (char*)malloc(len + 1);
	if (temp->kind == NULL) {
		printf("out of memory\n");
		exit(1);
	}
	temp->kind[len] = '\0';
	strcpy_s(temp->kind, len + 1, kind);
	*/

	// create the declaration list and add the given type
	temp->decList = BuildDecNode(type, scopeId, paramCount, params);

	temp->next = NULL;
	return temp;
}


void PrintList(LinkedList* head)
{
	while (head != NULL) {
		printf("    \"%s\"\n", head->data);
		printDecList(head->decList);
		head = head->next;
	}
	printf("\n");
}


void printParamList(Parameter* head)
{
	while (head != NULL) {
		printf("  %s", head->type);
		head = head->next;
	}
	printf("\n");
}


void printDecList(declarationLList* head)
{
	while (head != NULL) {
		printf("      scope id: %d type: %s", head->scopeId, head->type);
		if (head->paramCount)
		{
			printf(" param count: %d\n", *head->paramCount);
			if (*head->paramCount > 0)
			{
				printf("        params: ");
				printParamList(head->params);
			}	
		}
		else
			printf("\n");
		
		head = head->next;
	}
}


Parameter* FreeParamList(Parameter* head)
{
	if (head == NULL)
		return head;
	if (head->next != NULL)
		FreeParamList(head->next);
	free(head->type);
	free(head);
	head = NULL;

	return head;
}


declarationLList* FreeDecList(declarationLList* head)
{
	if (head == NULL)
		return head;
	if (head->next != NULL)
		FreeDecList(head->next);
	FreeParamList(head->params);
	free(head->paramCount);
	free(head->type);
	free(head);
	head = NULL;

	return head;
}


LinkedList* FreeList(LinkedList* head)
{
	if (head == NULL)
		return head;
	if (head->next != NULL)
		FreeList(head->next);
	FreeDecList(head->decList);
	free(head->data);
	free(head);
	head = NULL;

	return head;
}
