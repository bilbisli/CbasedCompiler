%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "lex.yy.c"
#include "HashTable.c"

#define NO_ERRORS 0
#define SYMBOL_TABLE_SIZE 3000
#define ANSI_COLOR_RED "\033[1;31m"
#define ANSI_COLOR_RESET "\033[0m"

int yylex();
int yyerror(const char *s);


typedef struct ThreeAddCode
{
	char *var;
	char *code;
	char* trueLabel;
	char* falseLabel;
	char* next;
	
} ThreeAddCode;

typedef struct node	
{
	char* type;
	char *token;
	struct node *left;
	struct node *right;
	ThreeAddCode *threeAddCode;


} node;

typedef struct IdNode
{
	char* id;
	struct IdNode *next;
} IdNode;

typedef struct Scope
{
	int id;
	struct Scope *previous;
	IdNode *declarations;
} Scope;

typedef struct Program
{
	int scopeCount;
	int varCount;
	int labelCount;
	int isSemanticsOk;
	node *tree;
	Scope *scopeStack;
	HashTable *symbolTable;
	HashTable *tableCopy;
} Program;


node *mknode(char *token, node *left, node *right);
int is_leaf(node *checked_node);
void print_tabs(int tabs);
int is_connecting_node(node* check_node);
void printtree(node *tree, int tabs);
Program* startProgram(node* tree);
Program* mkprogram(node* tree);
int checkSemantics(Program* prog);
IdNode* mkIdNode(const char* id);
IdNode* addIdNodeToStart(IdNode* head, const char* id);
Scope* addScopeToStart(Program *prog, Scope* s);
Scope* DeleteScopeElement(HashTable *ht, Scope* head);
Scope* FreeScopes(HashTable *ht, Scope* head);
IdNode* FreeIdList(HashTable* ht, IdNode* head);
void DeleteIdFromHashTable(HashTable*, char*);
void recursiveSemanticCheck(Program *prog, node* tree);
int checkAddScope(Program *prog, node *tree);
void printIdList(IdNode* idNode);
void printScopes(Scope*);
char* checkTypeConversion(HashTable*, node*, node*);
char* checkCond(HashTable*, node*);
char* freshVar(Program*);
char* freshLabel(Program*);
ThreeAddCode* mkThreeAddCode(char*,char*);
void generate3Ac(Program*, node*);
void emit(char* codeString);
int relop(char* token);
void print3AddCode(node* tree);
int getBytes(char* type);
char* prependStr(char* dest, const char* src);


void print3AddCode(node* tree)
{
	if (!tree)
	{
		return;
	}

	if (tree->threeAddCode && tree->threeAddCode->code && !is_connecting_node(tree))
	{
		printf("%s", tree->threeAddCode->code);
	}
	else
	{
		if (tree->left)
		{
			print3AddCode(tree->left);
		}
		if (tree->right)
		{
			print3AddCode(tree->right);
		}

	}
	
}

int getBytes(char* type)
{
	if (strcmp(type, "INT") == 0)
	{
		return 4;
	}
	else if (strcmp(type, "REAL") == 0 
		|| (strcmp(type, "INT_PTR") == 0)
		|| (strcmp(type, "REAL_PTR") == 0)
		|| (strcmp(type, "CHAR_PTR") == 0))
	{
		return 8;
	}
	else if (strcmp(type, "CHAR") == 0)
	{
		return 1;
	}
}

int relop(char* token)
{
	return 	((strcmp(token, ">") == 0) 
			|| (strcmp(token, "<") == 0) 
			|| (strcmp(token, "=>") == 0) 
			|| (strcmp(token, "=<") == 0) 
			|| (strcmp(token, "!=") == 0) 
			|| (strcmp(token, "==") == 0));
}

char* prependStr(char* dest, const char* src)
{
	int len = strlen(src);

	memmove(dest + len, dest, strlen(dest) + 1);
	memcpy(dest, src, len);

	return dest;
}


// void createLabels(Program* prog, node* tree)
// {
// 	createLabels(prog, tree->left);
// 	createLabels(prog, tree->right);
// 	if (tree->left && strcmp(tree->left->token, "IF") == 0)
// 	{
		
// 		next = 


// 		tree->threeAddCode->trueLabel = freshLabel(prog);
// 		tree->threeAddCode->falseLabel = freshLabel(prog);

// 	}
// 		// || (strcmp(tree->token, "ELSE-IF") == 0)
// 		// || 
// 		// )
	

// }


void generate3Ac(Program* prog, node* tree)
{
	if (tree)
	{
		// printf("%s\n", tree->token);
		// if (!((strcmp(tree->token, "") == 0) || strcmp(tree->token, "\n") == 0))
		// {
		// 	printf("%s\n", tree->token);
		// }
		// if (tree->left)
		// 	generate3Ac(prog, tree->left);
		// if (tree->right)
		// 	generate3Ac(prog, tree->right);
	}
	else
	{
		return;
	}

	if (strcmp(tree->token, "CODE") == 0)
	{
		generate3Ac(prog, tree->left);

		// char* next = freshLabel(prog);
		int sizeCode = strlen(tree->left->threeAddCode->code) + 1;
		char *chainCode = (char*)malloc(sizeof(char) * sizeCode);

		snprintf(chainCode, sizeCode, "%s", tree->left->threeAddCode->code);
		tree->threeAddCode = mkThreeAddCode("", chainCode);
		// tree->threeAddCode->next = next;
		// tree->left->threeAddCode->next = next;

		///////////////////////////////////////////

		// generate3Ac(prog, tree->left);

		// char* next = freshLabel(prog);
		// int sizeCode = strlen(tree->left->threeAddCode->code) + strlen(next) + strlen("\n:") + 1;
		// char *chainCode = (char*)malloc(sizeof(char) * sizeCode);

		// snprintf(chainCode, sizeCode, "%s%s:", tree->left->threeAddCode->code, next);
		// tree->threeAddCode = mkThreeAddCode("", chainCode);
		// tree->threeAddCode->next = next;
		// tree->left->threeAddCode->next = next;

		///////////////////////////////////////////
	}
	
	else if (strcmp(tree->token, "BLOCK") == 0)
	{
		// inherit to children
		if (tree->threeAddCode)
		{
			if (!tree->left->left->threeAddCode)
			{
				tree->left->left->threeAddCode = mkThreeAddCode("", "");
			}
			tree->left->left->threeAddCode->falseLabel = tree->threeAddCode->falseLabel;
			tree->left->left->threeAddCode->trueLabel = tree->threeAddCode->trueLabel;
			tree->left->left->threeAddCode->next = tree->threeAddCode->next;
		}

		generate3Ac(prog, tree->left->left);

		

		if (tree->left->left)
		{
			// char* next = freshLabel(prog);
			char* chainCode = NULL;
			int sizeCode = strlen(tree->left->left->threeAddCode->code) + 1;
			chainCode = (char*)malloc(sizeof(char) * sizeCode);
		
			snprintf(chainCode, sizeCode, "%s", tree->left->left->threeAddCode->code);
			tree->threeAddCode = mkThreeAddCode("", chainCode);

			// tree->threeAddCode->next = next;
		}



		//////////////////////////////////////////

		// generate3Ac(prog, tree->left->left);

		// char* next = freshLabel(prog);
		// char* chainCode = NULL;

		// if (tree->left->left)
		// {
		// 	int sizeCode = strlen(tree->left->left->threeAddCode->code) + strlen(next) + strlen("\n:") + 1;
		// 	chainCode = (char*)malloc(sizeof(char) * sizeCode);
		// 	tree->left->left->threeAddCode->next = next;
		// 	snprintf(chainCode, sizeCode, "%s\n%s:", tree->left->left->threeAddCode->code, next);
		// }
		// else
		// {
		// 	chainCode = (char*)malloc(sizeof(char) * (strlen(next) + 1));
		// 	snprintf(chainCode, strlen(next) + 1, "%s:", next);
		// }

		// tree->threeAddCode = mkThreeAddCode("", chainCode);
		// tree->threeAddCode->next = next;

		//////////////////////////////////////////////

	}

	else if (strcmp(tree->token, "IF") == 0)
	{




		///////////////////////////////////////////////////


		// false label will be to the end of the if (to next statement after if)
		char *falseLabel = NULL;
		int inheritanceFlag = 0;

		
		if (tree->threeAddCode && tree->threeAddCode->next)
		{
			inheritanceFlag = 1;
			falseLabel = tree->threeAddCode->next;
		}
		else
		{
			falseLabel = freshLabel(prog);
		}
		
		// inherit false label to code sub tree (for the case of chained if\if-else\loops streight after the if statement)
		if (!tree->left->right->left->threeAddCode)
		{
			tree->left->right->left->threeAddCode = mkThreeAddCode("", "");
		}
		tree->left->right->left->threeAddCode->falseLabel = falseLabel;
		// tree->left->right->left->threeAddCode->next = falseLabel;
		
		
		// recursive call with the true code node (NOTE: new labels will be created here only under the if statement)
		generate3Ac(prog, tree->left->right->left);
		
		ThreeAddCode *trueCode = tree->left->right->left->threeAddCode;

		// true label will lead to the code within the if statement
		char *trueLabel = freshLabel(prog);
		
		// inherit false and true labels to condition sub tree
		if (!tree->left->left->left->threeAddCode)
		{
			tree->left->left->left->threeAddCode = mkThreeAddCode("", "");
		}
		tree->left->left->left->threeAddCode->falseLabel = falseLabel;
		tree->left->left->left->threeAddCode->trueLabel = trueLabel;
		tree->left->left->left->threeAddCode->next = falseLabel;

		// recursive call with the condition node
		generate3Ac(prog, tree->left->left->left);

		ThreeAddCode *cond = tree->left->left->left->threeAddCode;

		// create if code with true label to code within the 'if' (NOTE: false labels will be handled appropriatly within condtion sub tree)
		char *chainCode = NULL;
		int codeSize = strlen(cond->code) + strlen(trueLabel) + strlen(trueCode->code) + strlen("\n:") + 1;
		if (!inheritanceFlag)
		{
			codeSize += strlen(falseLabel) + strlen("\n:");
		}
		
		chainCode = (char*)malloc(sizeof(char) * codeSize);
		snprintf(chainCode, codeSize, "%s\n%s:%s", cond->code, trueLabel, trueCode->code);
		if (!inheritanceFlag)
		{
			strcat(chainCode, "\n");
			strcat(chainCode, falseLabel);
			strcat(chainCode, ":");
		}
		if (inheritanceFlag)
		{
			tree->threeAddCode->code = strdup(chainCode);
		}
		else
		{
			tree->threeAddCode = mkThreeAddCode("", chainCode);
		}
		
		free(chainCode);
	}

	else if (strcmp(tree->token, "IF-ELSE") == 0)
	{



		printf("innnnnnnn\n");



		///////////////////////////////////////////////////


		
		// true label will lead to the code within the if statement
		char *trueLabel = freshLabel(prog);
		// false label will be to the end of the if (to the start of the else)
		char *falseLabel = freshLabel(prog);
		// next label will be to the end of the else (to next statement after else)
		char *nextLabel = NULL;
		
		int inheritanceFlag = 0;
		if (tree->threeAddCode && tree->threeAddCode->next)
		{
			inheritanceFlag = 1;
			nextLabel = tree->threeAddCode->next;
		}
		else
		{
			nextLabel = freshLabel(prog);
		}
		
		// inherit false label to true code sub tree
		if (!tree->left->right->left->threeAddCode)
		{
			tree->left->right->left->threeAddCode = mkThreeAddCode("", "");
		}
		tree->left->right->left->threeAddCode->falseLabel = nextLabel;
		// tree->left->right->left->threeAddCode->next = nextLabel;
		
		
		// recursive call with the true code node (NOTE: new labels will be created here only under the if statement)
		generate3Ac(prog, tree->left->right->left);

		
		ThreeAddCode *trueCode = tree->left->right->left->threeAddCode;


		// inherit false label to false code sub tree (for the case of chained if\if-else\loops streight after the if statement)
		if (!tree->left->right->right->threeAddCode)
		{
			tree->left->right->right->threeAddCode = mkThreeAddCode("", "");
		}
		tree->left->right->right->threeAddCode->falseLabel = nextLabel;
		// tree->left->right->right->threeAddCode->next = nextLabel;
		
		
		// recursive call with the true code node (NOTE: new labels will be created here only under the if statement)
		generate3Ac(prog, tree->left->right->right);
		
		
		ThreeAddCode *falseCode = tree->left->right->right->threeAddCode;
		
		// inherit false and true labels to condition sub tree
		if (!tree->left->left->left->threeAddCode)
		{
			tree->left->left->left->threeAddCode = mkThreeAddCode("", "");
		}
		tree->left->left->left->threeAddCode->falseLabel = falseLabel;
		tree->left->left->left->threeAddCode->trueLabel = trueLabel;
		tree->left->left->left->threeAddCode->next = falseLabel;

		// recursive call with the condition node
		generate3Ac(prog, tree->left->left->left);
		

		ThreeAddCode *cond = tree->left->left->left->threeAddCode;

		// create if code with true label to code within the 'if' (NOTE: false labels will be handled appropriatly within condtion sub tree)
		char *chainCode = NULL;
		int codeSize = strlen(cond->code) 
					+ strlen(trueLabel)
					+ strlen(trueCode->code) 
					+ strlen(falseCode->code)
					+ strlen(falseLabel)
					+ strlen(nextLabel)
					+ strlen("\n\tgoto ")
					+ strlen("\n:") * 2
					// + strlen("\n")
					+ 1;
		if (!inheritanceFlag)
		{
			codeSize += strlen(nextLabel) + strlen("\n:");
		}
		
		
		chainCode = (char*)malloc(sizeof(char) * codeSize);
		snprintf(chainCode, codeSize, "%s\n%s:%s\n\tgoto %s\n%s:%s", cond->code, trueLabel, trueCode->code, nextLabel, falseLabel, falseCode->code);
		
		if (!inheritanceFlag)
		{
			strcat(chainCode, "\n");
			strcat(chainCode, nextLabel);
			strcat(chainCode, ":");
		}
		if (inheritanceFlag)
		{
			tree->threeAddCode->code = strdup(chainCode);
		}
		else
		{
			tree->threeAddCode = mkThreeAddCode("", chainCode);
		}
		
		free(chainCode);



		///////////////////////////////////////////////////

	}

	else if (strcmp(tree->token, "FOR") == 0)
	{

		// init call
		generate3Ac(prog, tree->left->left->left);
		ThreeAddCode *init = tree->left->left->left->threeAddCode;

		// false label will be to the end of the while (to next statement after while)
		char *falseLabel = NULL;
		int inheritanceFlag = 0;

		
		if (tree->threeAddCode && tree->threeAddCode->next)
		{
			inheritanceFlag = 1;
			falseLabel = tree->threeAddCode->next;
		}
		else
		{
			falseLabel = freshLabel(prog);
		}
		
		// inherit false label to code sub tree (for the case of chained if\if-else\loops streight after the if statement)
		if (!tree->left->right->right->right->threeAddCode)
		{
			tree->left->right->right->right->threeAddCode = mkThreeAddCode("", "");
		}
		tree->left->right->right->right->threeAddCode->falseLabel = falseLabel;
		// tree->left->right->left->threeAddCode->next = falseLabel;
		
		
		// recursive call with the true code node (NOTE: new labels will be created here only under the if statement)
		generate3Ac(prog, tree->left->right->right->right);
		
		ThreeAddCode *trueCode = tree->left->right->right->right->threeAddCode;

		// label to the conditon (goes here after every iteration)
		char *startCondLabel = freshLabel(prog);

		// true label will lead to the code within the if statement
		char *trueLabel = freshLabel(prog);

		// inherit false and true labels to condition sub tree
		if (!tree->left->right->left->left->threeAddCode)
		{
			tree->left->right->left->left->threeAddCode = mkThreeAddCode("", "");
		}
		tree->left->right->left->left->threeAddCode->falseLabel = falseLabel;
		tree->left->right->left->left->threeAddCode->trueLabel = trueLabel;
		tree->left->right->left->left->threeAddCode->next = falseLabel;

		// recursive call with the condition node
		generate3Ac(prog, tree->left->right->left->left);

		ThreeAddCode *cond = tree->left->right->left->left->threeAddCode;

		// recursive call with the update node
		generate3Ac(prog, tree->left->right->right->left->left);
		
		ThreeAddCode *update = tree->left->right->right->left->left->threeAddCode;

		// create if code with true label to code within the 'if' (NOTE: false labels will be handled appropriatly within condtion sub tree)
		char *chainCode = NULL;
		int codeSize = strlen(cond->code)
					+ strlen(init->code)
					+ strlen(startCondLabel) * 2
					+ strlen(trueLabel) 
					+ strlen(trueCode->code)
					+ strlen(update->code)
					+ strlen("\n:\n:\n\tgoto ") + 1;
		
		if (!inheritanceFlag)
		{
			codeSize += strlen(falseLabel) + strlen("\n:");
		}
		
		chainCode = (char*)malloc(sizeof(char) * codeSize);
		snprintf(chainCode, codeSize, "%s\n%s:%s\n%s:%s%s\n\tgoto %s", init->code, startCondLabel, cond->code, trueLabel, trueCode->code, update->code, startCondLabel);
		if (!inheritanceFlag)
		{
			strcat(chainCode, "\n");
			strcat(chainCode, falseLabel);
			strcat(chainCode, ":");
		}
		if (inheritanceFlag)
		{
			tree->threeAddCode->code = strdup(chainCode);
		}
		else
		{
			tree->threeAddCode = mkThreeAddCode("", chainCode);
		}

		free(chainCode);
	}

	else if (strcmp(tree->token, "WHILE") == 0)
	{



		// false label will be to the end of the while (to next statement after while)
		char *falseLabel = NULL;
		int inheritanceFlag = 0;

		
		if (tree->threeAddCode && tree->threeAddCode->next)
		{
			inheritanceFlag = 1;
			falseLabel = tree->threeAddCode->next;
		}
		else
		{
			falseLabel = freshLabel(prog);
		}
		
		// inherit false label to code sub tree (for the case of chained if\if-else\loops streight after the if statement)
		if (!tree->left->right->left->threeAddCode)
		{
			tree->left->right->left->threeAddCode = mkThreeAddCode("", "");
		}
		tree->left->right->left->threeAddCode->falseLabel = falseLabel;
		// tree->left->right->left->threeAddCode->next = falseLabel;
		
		
		// recursive call with the true code node (NOTE: new labels will be created here only under the if statement)
		generate3Ac(prog, tree->left->right->left);
		
		ThreeAddCode *trueCode = tree->left->right->left->threeAddCode;

		// label to the conditon (goes here after every iteration)
		char *startCondLabel = freshLabel(prog);

		// true label will lead to the code within the if statement
		char *trueLabel = freshLabel(prog);

		// inherit false and true labels to condition sub tree
		if (!tree->left->left->left->threeAddCode)
		{
			tree->left->left->left->threeAddCode = mkThreeAddCode("", "");
		}
		tree->left->left->left->threeAddCode->falseLabel = falseLabel;
		tree->left->left->left->threeAddCode->trueLabel = trueLabel;
		tree->left->left->left->threeAddCode->next = falseLabel;

		// recursive call with the condition node
		generate3Ac(prog, tree->left->left->left);

		ThreeAddCode *cond = tree->left->left->left->threeAddCode;

		// create if code with true label to code within the 'if' (NOTE: false labels will be handled appropriatly within condtion sub tree)
		char *chainCode = NULL;
		int codeSize = strlen(cond->code) 
					+ strlen(startCondLabel) * 2
					+ strlen(trueLabel) 
					+ strlen(trueCode->code) 
					+ strlen("\n:\n:\n\tgoto ") + 1;
		if (!inheritanceFlag)
		{
			codeSize += strlen(falseLabel) + strlen("\n:");
		}
		
		chainCode = (char*)malloc(sizeof(char) * codeSize);
		snprintf(chainCode, codeSize, "\n%s:%s\n%s:%s\n\tgoto %s", startCondLabel, cond->code, trueLabel, trueCode->code, startCondLabel);
		if (!inheritanceFlag)
		{
			strcat(chainCode, "\n");
			strcat(chainCode, falseLabel);
			strcat(chainCode, ":");
		}
		if (inheritanceFlag)
		{
			tree->threeAddCode->code = strdup(chainCode);
		}
		else
		{
			tree->threeAddCode = mkThreeAddCode("", chainCode);
		}

		
		free(chainCode);

	}

	else if (strcmp(tree->token, "DO-WHILE") == 0)
	{

		// false label will be to the end of the while (to next statement after while)
		char *falseLabel = NULL;
		// int inheritanceFlag = 0;
		// label to the conditon (goes here after every iteration)

		
		if (tree->threeAddCode && tree->threeAddCode->next)
		{
			// inheritanceFlag = 1;
			falseLabel = tree->threeAddCode->next;
		}
		else
		{
			falseLabel = freshLabel(prog);
		}
		
		// inherit false label to code sub tree (for the case of chained if\if-else\loops streight after the if statement)
		if (!tree->left->left->left->threeAddCode)
		{
			tree->left->left->left->threeAddCode = mkThreeAddCode("", "");
		}
		tree->left->left->left->threeAddCode->falseLabel = falseLabel;
		// tree->left->right->left->threeAddCode->next = falseLabel;
		
		// recursive call with the true code node (NOTE: new labels will be created here only under the if statement)
		generate3Ac(prog, tree->left->left->left);
		
		ThreeAddCode *trueCode = tree->left->left->left->threeAddCode;

		// true label will lead to the code within the if statement
		char *trueLabel = freshLabel(prog);

		// inherit false and true labels to condition sub tree
		if (!tree->left->right->left->threeAddCode)
		{
			tree->left->right->left->threeAddCode = mkThreeAddCode("", "");
		}
		// tree->left->right->left->threeAddCode->falseLabel = falseLabel;
		tree->left->right->left->threeAddCode->trueLabel = trueLabel;
		// tree->left->right->left->threeAddCode->next = falseLabel;

		// recursive call with the condition node
		generate3Ac(prog, tree->left->right->left);

		ThreeAddCode *cond = tree->left->right->left->threeAddCode;

		// create if code with true label to code within the 'if' (NOTE: false labels will be handled appropriatly within condtion sub tree)
		char *chainCode = NULL;
		int codeSize = strlen(cond->code) 
					+ strlen(trueLabel) 
					+ strlen(trueCode->code) 
					+ strlen("\n:") + 1;
		// if (!inheritanceFlag)
		// {
		// 	codeSize += strlen(falseLabel) + strlen("\n:");
		// }
		
		chainCode = (char*)malloc(sizeof(char) * codeSize);
		snprintf(chainCode, codeSize, "\n%s:%s%s", trueLabel, trueCode->code, cond->code);
		// if (!inheritanceFlag)
		// {
		// 	strcat(chainCode, "\n");
		// 	strcat(chainCode, falseLabel);
		// 	strcat(chainCode, ":");
		// }
		if (tree->threeAddCode)
		{
			tree->threeAddCode->code = strdup(chainCode);
		}
		else
		{
			tree->threeAddCode = mkThreeAddCode("", chainCode);
		}

		
		free(chainCode);

	}

	else if (strcmp(tree->token, "FUNC") == 0)
	{
		// body
		generate3Ac(prog, tree->left->right->left);

		// return
		generate3Ac(prog, tree->left->right->left->right);

		
		char* funcName = tree->left->left->left->left->left->token;
		
		if (tree->left->right->left->left)
		{
			char* bodyCode = tree->left->right->left->threeAddCode->code;

			int sizeCode = strlen(":\n\tBeginFunc\n\n\tEndFunc") + strlen(funcName) + strlen(bodyCode) + 1;
			char* chainCode = (char*)malloc(sizeof(char) * sizeCode);
			

			snprintf(chainCode, sizeCode, "\n%s:\n\tBeginFunc%s\n\tEndFunc", funcName, bodyCode);
			tree->threeAddCode = mkThreeAddCode(funcName, chainCode);
			free(chainCode);
		}
		else
		{
			int sizeCode = strlen(":\n\tBeginFunc\n\tEndFunc") + strlen(funcName) + 1;
			char* chainCode = (char*)malloc(sizeof(char) * sizeCode);

			snprintf(chainCode, sizeCode, "\n%s:\n\tBeginFunc\n\tEndFunc", funcName);
			tree->threeAddCode = mkThreeAddCode(funcName, chainCode);
			free(chainCode);
		}

	}



	else if (strcmp(tree->token, "VAR") == 0)
	{

		generate3Ac(prog, tree->left);
		tree->threeAddCode = tree->left->threeAddCode;
	
	}

	else if (strcmp(tree->token, "STRING") == 0)
	{
		generate3Ac(prog, tree->left);
		tree->threeAddCode = tree->left->threeAddCode;
	}

	

	else if (strcmp(tree->token, "()") == 0)
	{
		// inherit to children
		if (tree->threeAddCode)
		{
			if(!tree->left->threeAddCode)
			{
				tree->left->threeAddCode = mkThreeAddCode("", "");
			}
			tree->left->threeAddCode->falseLabel = tree->threeAddCode->falseLabel;
			tree->left->threeAddCode->trueLabel = tree->threeAddCode->trueLabel;
			tree->left->threeAddCode->next = tree->threeAddCode->next;
		}

		generate3Ac(prog, tree->left);

		if (!tree->threeAddCode)
		{
			tree->threeAddCode = mkThreeAddCode(tree->left->threeAddCode->var, tree->left->threeAddCode->code);
		}
		else
		{
			tree->threeAddCode->var = tree->left->threeAddCode->var;
			tree->threeAddCode->code = tree->left->threeAddCode->code;
		}
		tree->threeAddCode->falseLabel = tree->left->threeAddCode->falseLabel;
		tree->threeAddCode->trueLabel = tree->left->threeAddCode->trueLabel;
		tree->threeAddCode->next = tree->threeAddCode->next;

	}

	else if (strcmp(tree->token, "||") == 0)
	{


		///////////////////////////////////////////////////////////////////////////

		char *chainCode = NULL;
		char *trueLabel = NULL;
		// false label will jump to the right sub tree to keep checking if that side is true
		char* falseLabel = freshLabel(prog);
		char *var = "";

		
		// for the case that the 'or' is within an if/if-else/loop statement
		if (tree->threeAddCode && tree->threeAddCode->trueLabel)
		{

			// true label will jump to the true code based on the statement containing the 'or' condition
			trueLabel = tree->threeAddCode->trueLabel;
			
			// for the case of simple left value
			int leftSimpleFlag = 0;

			if (tree->left->left->threeAddCode 
					&& tree->left->left->threeAddCode->var
					&& strcmp(tree->left->left->token, "") != 0
					&& (
						place(prog->tableCopy, tree->left->left->threeAddCode->var)
						|| strcmp(tree->left->left->threeAddCode->var, "true") == 0
						|| strcmp(tree->left->left->threeAddCode->var, "false") == 0
						)
				)
			{
				leftSimpleFlag = 1;
			}

			// inherit true label to left sub tree (so that if in any step on the way we know it is true we can jump to the true label)
			if (!tree->left->left->threeAddCode)
			{
				tree->left->left->threeAddCode = mkThreeAddCode("", "");
			}
			tree->left->left->threeAddCode->trueLabel = trueLabel;
			// inherit false label too (leading to the right sub tree)
			tree->left->left->threeAddCode->falseLabel = falseLabel;

			// recursive call with the left code node (NOTE: new labels will be created here only under the if statement)
			generate3Ac(prog, tree->left->left);
			// for the case of simple left value
			if (leftSimpleFlag)
			{
				char *lCode = NULL;
				int lCodeSize = 0;
				char* lVar = tree->left->left->threeAddCode->var;
				if (falseLabel && trueLabel)
				{
					lCodeSize = strlen("\n\t") * 2
								+ strlen("if  ")
								+ strlen("goto ") * 2
								+ strlen(lVar)
								+ strlen(trueLabel)
								+ strlen(falseLabel)
								+ 1;
					lCode = (char*)malloc(sizeof(char) * lCodeSize);
					snprintf(lCode, lCodeSize, "\n\tif %s goto %s\n\tgoto %s", lVar, trueLabel, falseLabel);				
				}
				else 
				{
					lCodeSize = strlen("goto")
								+ strlen(" ") * 3
								+ strlen("\n\tifZ")
								+ strlen(lVar)
								+ strlen(falseLabel)
								+ 1;
					lCode = (char*)malloc(sizeof(char) * lCodeSize);
					snprintf(lCode, lCodeSize, 
					"\n\tifZ %s goto %s", lVar, falseLabel);
				}
				tree->left->left->threeAddCode->code = strdup(lCode);
				free(lCode);
			}

			char *leftCode = tree->left->left->threeAddCode->code;

			// for the case of simple value
			int rightSimpleFlag = 0;
			if (tree->left->right->threeAddCode
					&& tree->left->right->threeAddCode->var
					&& strcmp(tree->left->right->token, "") != 0
					&& (
						place(prog->tableCopy, tree->left->right->threeAddCode->var)
						|| strcmp(tree->left->right->threeAddCode->var, "true") == 0
						|| strcmp(tree->left->right->threeAddCode->var, "false") == 0
						)
				)
			{
				rightSimpleFlag = 1;
			}

			// inherit false and true labels to right sub tree (false label will effectivly lead to the next condition\statement)
			if (!tree->left->right->threeAddCode)
			{
				tree->left->right->threeAddCode = mkThreeAddCode("", "");
			}
			tree->left->right->threeAddCode->falseLabel = tree->threeAddCode->falseLabel;
			tree->left->right->threeAddCode->trueLabel = trueLabel;
			
			// recursive call with the right sub tree
			generate3Ac(prog, tree->left->right);
			// for the case of simple value
			if (rightSimpleFlag)
			{
				char *rCode = NULL;
				int rCodeSize = 0;
				char* rVar = tree->left->right->threeAddCode->var;
				if (tree->threeAddCode->falseLabel && trueLabel)
				{
					rCodeSize = strlen("\n\t") * 2
								+ strlen("if  ")
								+ strlen("goto ") * 2
								+ strlen(rVar)
								+ strlen(trueLabel)
								+ strlen(tree->threeAddCode->falseLabel)
								+ 1;
					rCode = (char*)malloc(sizeof(char) * rCodeSize);
					snprintf(rCode, rCodeSize, "\n\tif %s goto %s\n\tgoto %s", rVar, trueLabel, tree->threeAddCode->falseLabel);				
				}
				else 
				{
					rCodeSize = strlen("goto")
								+ strlen(" ") * 3
								+ strlen("\n\tifZ")
								+ strlen(rVar)
								+ strlen(tree->threeAddCode->falseLabel)
								+ 1;
					rCode = (char*)malloc(sizeof(char) * rCodeSize);
					snprintf(chainCode, rCodeSize, 
					"\n\tifZ %s goto %s", rVar, tree->threeAddCode->falseLabel);
				}
				tree->left->right->threeAddCode->code = strdup(rCode);
				free(rCode);
			}

			char* rightCode = tree->left->right->threeAddCode->code;
			

			// create the 'or' code with false label connecting the two sub trees (NOTE: true labels will be handled appropriatly within each sub tree)
			int codeSize = strlen(leftCode) + strlen(falseLabel) + strlen(rightCode) + strlen("\n:") + 1;

			chainCode = (char*)malloc(sizeof(char) * codeSize);
			snprintf(chainCode, codeSize, "%s\n%s:%s", leftCode, falseLabel, rightCode);
			
		}
		else
		{
			// true label will jump to the true code based on the statement containing the 'or' condition
			// ---
			trueLabel = freshLabel(prog);
			// ---
			var = freshVar(prog);

			// inherit true label to left sub tree (so that if in any step on the way we know it is true we can jump to the true label)
			if (!tree->left->left->threeAddCode)
			{
				tree->left->left->threeAddCode = mkThreeAddCode("", "");
			}
			tree->left->left->threeAddCode->trueLabel = trueLabel;
			// inherit false label too (leading to the right sub tree)
			tree->left->left->threeAddCode->falseLabel = falseLabel;

			int leftSimpleFlag = 0;
			if (tree->left->left->threeAddCode 
					&& tree->left->left->threeAddCode->var
					&& strcmp(tree->left->left->token, "") != 0
					&& (
						place(prog->tableCopy, tree->left->left->threeAddCode->var)
						|| strcmp(tree->left->left->threeAddCode->var, "true") == 0
						|| strcmp(tree->left->left->threeAddCode->var, "false") == 0
						)
				)
			{
				leftSimpleFlag = 1;
			}

			// recursive call with the left code node (NOTE: new labels will be created here only under the if statement)
			generate3Ac(prog, tree->left->left);


			if (leftSimpleFlag)
			{
				char *lCode = NULL;
				int lCodeSize = 0;
				char* lVar = tree->left->left->threeAddCode->var;
				if (falseLabel && trueLabel)
				{
					lCodeSize = strlen("\n\t") * 2
								+ strlen("if  ")
								+ strlen("goto ") * 2
								+ strlen(lVar)
								+ strlen(trueLabel)
								+ strlen(falseLabel)
								+ 1;
					lCode = (char*)malloc(sizeof(char) * lCodeSize);
					snprintf(lCode, lCodeSize, "\n\tif %s goto %s\n\tgoto %s", lVar, trueLabel, falseLabel);				
				}
				else 
				{
					lCodeSize = strlen("goto")
								+ strlen(" ") * 3
								+ strlen("\n\tifZ")
								+ strlen(lVar)
								+ strlen(falseLabel)
								+ 1;
					lCode = (char*)malloc(sizeof(char) * lCodeSize);
					snprintf(lCode, lCodeSize, 
					"\n\tifZ %s goto %s", lVar, falseLabel);
				}
				tree->left->left->threeAddCode->code = strdup(lCode);
				free(lCode);
			}


			char *leftCode = tree->left->left->threeAddCode->code;
			

			// inherit false and true labels to right sub tree (false label will effectivly lead to the next condition\statement)
			if (!tree->left->right->threeAddCode)
			{
				tree->left->right->threeAddCode = mkThreeAddCode("", "");
			}
			// ---
			// tree->left->right->threeAddCode->falseLabel = tree->threeAddCode->falseLabel;
			char* falseZero = freshLabel(prog);
			tree->left->right->threeAddCode->trueLabel = trueLabel;
			tree->left->right->threeAddCode->next = falseZero;

			// for the case of simple value
			int rightSimpleFlag = 0;
			if (tree->left->right->threeAddCode 
					&& tree->left->right->threeAddCode->var
					&& strcmp(tree->left->right->token, "") != 0
					&& (
						place(prog->tableCopy, tree->left->right->threeAddCode->var)
						|| strcmp(tree->left->right->threeAddCode->var, "true") == 0
						|| strcmp(tree->left->right->threeAddCode->var, "false") == 0
						)
				)
			{
				rightSimpleFlag = 1;
			}

			// recursive call with the right sub tree
			generate3Ac(prog, tree->left->right);


			// for the case of simple value
			if (rightSimpleFlag)
			{
				char *rCode = NULL;
				int rCodeSize = 0;
				char* rVar = tree->left->right->threeAddCode->var;
				if (falseLabel && trueLabel)
				{
					rCodeSize = strlen("\n\t") * 2
								+ strlen("if  ")
								+ strlen("goto ") * 2
								+ strlen(rVar)
								+ strlen(trueLabel)
								+ strlen(falseZero)
								+ 1;
					rCode = (char*)malloc(sizeof(char) * rCodeSize);
					snprintf(rCode, rCodeSize, "\n\tif %s goto %s\n\tgoto %s", rVar, trueLabel, falseZero);				
				}
				else 
				{
					rCodeSize = strlen("goto")
								+ strlen(" ") * 3
								+ strlen("\n\tifZ")
								+ strlen(rVar)
								+ strlen(falseZero)
								+ 1;
					rCode = (char*)malloc(sizeof(char) * rCodeSize);
					snprintf(chainCode, rCodeSize, 
					"\n\tifZ %s goto %s", rVar, falseZero);
				}
				tree->left->right->threeAddCode->code = strdup(rCode);
				free(rCode);
			}


			char* rightCode = tree->left->right->threeAddCode->code;
			
			char* finalFalse = freshLabel(prog);
			// create the 'or' code with false label connecting the two sub trees (NOTE: true labels will be handled appropriatly within each sub tree)
			// char *chainCode = NULL;
			int codeSize = strlen(leftCode) 
						+ strlen(falseLabel) 
						+ strlen(rightCode) 
						+ strlen("\n:") 
						+ 1;
			// ---
			codeSize += strlen(trueLabel)
					+ strlen("\n\t") * 3
					+ strlen ("\n") * 4
					+ strlen(":: = 0goto : = 1:") 
					+ strlen(var)
					+ strlen(falseZero)
					+ strlen(finalFalse) * 2;
			chainCode = (char*)malloc(sizeof(char) * codeSize);
			snprintf(chainCode, codeSize, "%s\n%s:%s", leftCode, falseLabel, rightCode);
			
			// ---
			strcat(chainCode, "\n");
			// ---
			strcat(chainCode, falseZero);
			// ---
			strcat(chainCode, ":\n\t");
			// ---
			strcat(chainCode, var);
			// ---
			strcat(chainCode, " = 0\n\tgoto ");
			// ---
			strcat(chainCode, finalFalse);
			// ---
			strcat(chainCode, "\n");
			// ---
			strcat(chainCode, trueLabel);
			// ---
			strcat(chainCode, ":\n\t");
			// ---
			strcat(chainCode, var);
			// ---
			strcat(chainCode, " = 1\n");
			// ---
			strcat(chainCode, finalFalse);
			// ---
			strcat(chainCode, ":");
		}
		

		tree->threeAddCode = mkThreeAddCode(var, chainCode);
		free(chainCode);

		///////////////////////////////////////////////////////////////////////////


	}

	else if (strcmp(tree->token, "&&") == 0)
	{
		
		char *chainCode = NULL;
		char *trueLabel = freshLabel(prog);
		// false label will jump to the right sub tree to keep checking if that side is true
		char* falseLabel = NULL;
		char *var = "";

		// for the case that the 'or' is within an if/if-else/loop statement
		if (tree->threeAddCode)
		{
			
			int nextFlag = 0;
			if (tree->threeAddCode->falseLabel)
			{
				// true label will jump to the true code based on the statement containing the 'or' condition
				falseLabel = tree->threeAddCode->falseLabel;
				nextFlag = 1;
			}
			else
			{
				falseLabel =  tree->threeAddCode->next;
			}

			int leftSimpleFlag = 0;
			if (tree->left->left->threeAddCode 
					&& tree->left->left->threeAddCode->var
					&& strcmp(tree->left->left->token, "") != 0
					&& (
						place(prog->tableCopy, tree->left->left->threeAddCode->var)
						|| strcmp(tree->left->left->threeAddCode->var, "true") == 0
						|| strcmp(tree->left->left->threeAddCode->var, "false") == 0
						)
				)
			{
				leftSimpleFlag = 1;
			}
			
			// inherit true label to left sub tree (so that if in any step on the way we know it is true we can jump to the true label)
			if(!tree->left->left->threeAddCode)
			{
				tree->left->left->threeAddCode = mkThreeAddCode("", "");
			}
			tree->left->left->threeAddCode->trueLabel = trueLabel;
			// inherit false label too (leading to the right sub tree)
			tree->left->left->threeAddCode->falseLabel = falseLabel;

			// recursive call with the left code node (NOTE: new labels will be created here only under the if statement)
			generate3Ac(prog, tree->left->left);

			// for the case of simple left value
			if (leftSimpleFlag)
			{
				char *lCode = NULL;
				int lCodeSize = 0;
				
				char* lVar = tree->left->left->threeAddCode->var;
				if (falseLabel && trueLabel)
				{
					lCodeSize = strlen("\n\t") * 2
								+ strlen("if  ")
								+ strlen("goto ") * 2
								+ strlen(lVar)
								+ strlen(trueLabel)
								+ strlen(falseLabel)
								+ 1;
					lCode = (char*)malloc(sizeof(char) * lCodeSize);
					snprintf(lCode, lCodeSize, "\n\tif %s goto %s\n\tgoto %s", lVar, trueLabel, falseLabel);				
				}
				else 
				{
					lCodeSize = strlen("goto")
								+ strlen(" ") * 3
								+ strlen("\n\tifZ")
								+ strlen(lVar)
								+ strlen(falseLabel)
								+ 1;
					lCode = (char*)malloc(sizeof(char) * lCodeSize);
					snprintf(lCode, lCodeSize, 
					"\n\tifZ %s goto %s", lVar, falseLabel);
				}
				
				tree->left->left->threeAddCode->code = strdup(lCode);
				free(lCode);
			}

			char *leftCode = tree->left->left->threeAddCode->code;

			// for the case of simple value
			int rightSimpleFlag = 0;
			if (tree->left->right->threeAddCode
					&& tree->left->right->threeAddCode->var
					&& strcmp(tree->left->right->token, "") != 0
					&& (
						place(prog->tableCopy, tree->left->right->threeAddCode->var)
						|| strcmp(tree->left->right->threeAddCode->var, "true") == 0
						|| strcmp(tree->left->right->threeAddCode->var, "false") == 0
						)
				)
			{
				rightSimpleFlag = 1;
			}

			// inherit false and true labels to right sub tree (false label will effectivly lead to the next condition\statement)
			if(!tree->left->right->threeAddCode)
			{
				tree->left->right->threeAddCode = mkThreeAddCode("", "");
			}
			if(nextFlag)
			{
				tree->left->right->threeAddCode->falseLabel = falseLabel;
			}
			tree->left->right->threeAddCode->trueLabel = tree->threeAddCode->trueLabel;

			// recursive call with the right sub tree
			generate3Ac(prog, tree->left->right);

			// for the case of simple value
			if (rightSimpleFlag)
			{
				
				char *rCode = NULL;
				int rCodeSize = 0;
				char* rVar = tree->left->right->threeAddCode->var;
				if (tree->left->right->threeAddCode->falseLabel && tree->left->right->threeAddCode->trueLabel)
				{
					rCodeSize = strlen("\n\t") * 2
								+ strlen("if  ")
								+ strlen("goto ") * 2
								+ strlen(rVar)
								+ strlen(tree->left->right->threeAddCode->trueLabel)
								+ strlen(tree->left->right->threeAddCode->falseLabel)
								+ 1;
					rCode = (char*)malloc(sizeof(char) * rCodeSize);
					snprintf(rCode, rCodeSize, "\n\tif %s goto %s\n\tgoto %s", rVar, tree->left->right->threeAddCode->trueLabel, tree->left->right->threeAddCode->falseLabel);				
				}
				else 
				{
					rCodeSize = strlen("goto")
								+ strlen(" ") * 3
								+ strlen("\n\tifZ")
								+ strlen(rVar)
								+ strlen(tree->left->right->threeAddCode->falseLabel)
								+ 1;
					rCode = (char*)malloc(sizeof(char) * rCodeSize);
					snprintf(chainCode, rCodeSize, 
					"\n\tifZ %s goto %s", rVar, tree->left->right->threeAddCode->falseLabel);
				}
				tree->left->right->threeAddCode->code = strdup(rCode);
				free(rCode);
			}

			char* rightCode = tree->left->right->threeAddCode->code;

			// create the 'or' code with false label connecting the two sub trees (NOTE: true labels will be handled appropriatly within each sub tree)
			int codeSize = strlen(leftCode) + strlen(falseLabel) + strlen(rightCode) + strlen("\n:") + 1;

			chainCode = (char*)malloc(sizeof(char) * codeSize);
			snprintf(chainCode, codeSize, "%s\n%s:%s", leftCode, trueLabel, rightCode);
			
		}
		else
		{
			
			// true label will jump to the true code based on the statement containing the 'or' condition
			// ---
			falseLabel = freshLabel(prog);
			// ---
			var = freshVar(prog);
			char *totalFalseLabel = freshLabel(prog);

			int leftSimpleFlag = 0;
			if (tree->left->left->threeAddCode 
					&& tree->left->left->threeAddCode->var
					&& strcmp(tree->left->left->token, "") != 0
					&& (
						place(prog->tableCopy, tree->left->left->threeAddCode->var)
						|| strcmp(tree->left->left->threeAddCode->var, "true") == 0
						|| strcmp(tree->left->left->threeAddCode->var, "false") == 0
						)
				)
			{
				leftSimpleFlag = 1;
			}

			// inherit true label to left sub tree (so that if in any step on the way we know it is true we can jump to the true label)
			if(!tree->left->left->threeAddCode)
			{
				tree->left->left->threeAddCode = mkThreeAddCode("", "");
			}
			tree->left->left->threeAddCode->trueLabel = trueLabel;
			// inherit false label too (leading to the right sub tree)
			tree->left->left->threeAddCode->falseLabel = falseLabel;



			// recursive call with the left code node (NOTE: new labels will be created here only under the if statement)
			generate3Ac(prog, tree->left->left);
			
			if (leftSimpleFlag)
			{
							
				char *lCode = NULL;
				int lCodeSize = 0;
				char* lVar = tree->left->left->threeAddCode->var;
				if (falseLabel && trueLabel)
				{
					lCodeSize = strlen("\n\t") * 2
								+ strlen("if  ")
								+ strlen("goto ") * 2
								+ strlen(lVar)
								+ strlen(trueLabel)
								+ strlen(falseLabel)
								+ 1;
					lCode = (char*)malloc(sizeof(char) * lCodeSize);
					snprintf(lCode, lCodeSize, "\n\tif %s goto %s\n\tgoto %s", lVar, trueLabel, falseLabel);				
				}
				else 
				{
					lCodeSize = strlen("goto")
								+ strlen(" ") * 3
								+ strlen("\n\tifZ")
								+ strlen(lVar)
								+ strlen(falseLabel)
								+ 1;
					lCode = (char*)malloc(sizeof(char) * lCodeSize);
					snprintf(lCode, lCodeSize, 
					"\n\tifZ %s goto %s", lVar, falseLabel);
				}
				tree->left->left->threeAddCode->code = strdup(lCode);
				free(lCode);
			}

			char *leftCode = tree->left->left->threeAddCode->code;

			// for the case of simple value
			int rightSimpleFlag = 0;
			if (tree->left->right->threeAddCode
					&& tree->left->right->threeAddCode->var
					&& strcmp(tree->left->right->token, "") != 0
					&& (
						place(prog->tableCopy, tree->left->right->threeAddCode->var)
						|| strcmp(tree->left->right->threeAddCode->var, "true") == 0
						|| strcmp(tree->left->right->threeAddCode->var, "false") == 0
						)
				)
			{
				rightSimpleFlag = 1;
			}
						
			// inherit false and true labels to right sub tree (false label will effectivly lead to the next condition\statement)
			if(!tree->left->right->threeAddCode)
			{
				tree->left->right->threeAddCode = mkThreeAddCode("", "");
			}
			// ---
			// tree->left->right->threeAddCode->trueLabel = trueLabel;
			tree->left->right->threeAddCode->falseLabel = falseLabel;
			
			// recursive call with the right sub tree
			generate3Ac(prog, tree->left->right);

			if (rightSimpleFlag)
			{
				
				char *rCode = NULL;
				int rCodeSize = 0;
				char* rVar = tree->left->right->threeAddCode->var;
				if (tree->left->right->threeAddCode->falseLabel && tree->left->right->threeAddCode->trueLabel)
				{
					
					rCodeSize = strlen("\n\t") * 2
								+ strlen("if  ")
								+ strlen("goto ") * 2
								+ strlen(rVar)
								+ strlen(tree->left->right->threeAddCode->trueLabel)
								+ strlen(tree->left->right->threeAddCode->falseLabel)
								+ 1;
					rCode = (char*)malloc(sizeof(char) * rCodeSize);
					snprintf(rCode, rCodeSize, "\n\tif %s goto %s\n\tgoto %s", rVar, tree->left->right->threeAddCode->trueLabel, tree->left->right->threeAddCode->falseLabel);				
				}
				else if (tree->left->right->threeAddCode->trueLabel)
				{
					
					rCodeSize = strlen("\n\t")
								+ strlen("if  ")
								+ strlen("goto ")
								+ strlen(rVar)
								+ strlen(tree->left->right->threeAddCode->trueLabel)
								+ 1;
					rCode = (char*)malloc(sizeof(char) * rCodeSize);
					snprintf(rCode, rCodeSize, "\n\tif %s goto %s", rVar, tree->left->right->threeAddCode->trueLabel);
				}
				else
				{
					rCodeSize = strlen("goto")
								+ strlen(" ") * 3
								+ strlen("\n\tifZ")
								+ strlen(rVar)
								+ strlen(tree->left->right->threeAddCode->falseLabel)
								+ 1;
					
					rCode = (char*)malloc(sizeof(char) * rCodeSize);
					
					snprintf(rCode, rCodeSize, 
					"\n\tifZ %s goto %s", rVar, tree->left->right->threeAddCode->falseLabel);
				
				}
				tree->left->right->threeAddCode->code = strdup(rCode);
				free(rCode);
			}

			char* rightCode = tree->left->right->threeAddCode->code;
			char* finalTrue = freshLabel(prog);
			
			// create the 'or' code with false label connecting the two sub trees (NOTE: true labels will be handled appropriatly within each sub tree)
			// char *chainCode = NULL;
			int codeSize = strlen(leftCode) 
						+ strlen(falseLabel) 
						+ strlen(rightCode) 
						+ strlen("\n:") 
						+ 1;
			// ---
			codeSize += strlen(trueLabel)
					+ strlen("\n\t") * 3
					+ strlen ("\n") * 3
					+ strlen(": = 0goto : = 1:") 
					+ strlen(var)
					+ strlen(finalTrue) * 2;
			chainCode = (char*)malloc(sizeof(char) * codeSize);
			snprintf(chainCode, codeSize, "%s\n%s:%s", leftCode, trueLabel, rightCode);
			
			// ---
			strcat(chainCode, "\n\t");
			// ---
			strcat(chainCode, var);
			// ---
			strcat(chainCode, " = 1\n\tgoto ");
			// ---
			strcat(chainCode, finalTrue);
			// ---
			strcat(chainCode, "\n");
			// ---
			strcat(chainCode, falseLabel);
			// ---
			strcat(chainCode, ":\n\t");
			// ---
			strcat(chainCode, var);
			// ---
			strcat(chainCode, " = 0\n");
			// ---
			strcat(chainCode, finalTrue);
			// ---
			strcat(chainCode, ":");

		}
		

		tree->threeAddCode = mkThreeAddCode(var, chainCode);
		free(chainCode);
	}

	else if (relop(tree->token))
	{
		generate3Ac(prog, tree->left->left);
		generate3Ac(prog, tree->left->right);

		

		if (tree->threeAddCode)
		{
			char *chainCode = NULL;
			char *relOp = tree->token;
			char *trueLabel = tree->threeAddCode->trueLabel;
			char *falseLabel = tree->threeAddCode->falseLabel;
			char *var1 = tree->left->left->threeAddCode->var;
			char *var2 = tree->left->right->threeAddCode->var;
			int leftVarSize = strlen(var1);
			int rightVarSize = strlen(var2);
			int tokenSize = strlen(relOp);
			int constantsSize = 0;
			int codeSize = 0;
			if (falseLabel && trueLabel)
			{
				constantsSize = strlen("goto") * 2
								+ strlen(" ") * 6
								+ strlen("\n\tif\n\t");
				// create the 'or' code with false label connecting the two sub trees (NOTE: true labels will be handled appropriatly within each sub tree)
				codeSize = constantsSize + leftVarSize + tokenSize + rightVarSize + strlen(trueLabel) + strlen(falseLabel) + 1;
				
				chainCode = (char*)malloc(sizeof(char) * codeSize);
				snprintf(chainCode, codeSize, 
				"\n\tif %s %s %s goto %s\n\tgoto %s", var1, relOp, var2, trueLabel, falseLabel);
			}
			else if (falseLabel)
			{
				constantsSize = strlen("goto")
								+ strlen(" ") * 7
								+ strlen("\n\tifZ");
				// create the 'or' code with false label connecting the two sub trees (NOTE: true labels will be handled appropriatly within each sub tree)
				codeSize = constantsSize + leftVarSize + tokenSize + rightVarSize + strlen(falseLabel) + 1;
				
				chainCode = (char*)malloc(sizeof(char) * codeSize);
				snprintf(chainCode, codeSize, 
				"\n\tifZ %s %s %s goto %s", var1, relOp, var2, falseLabel);
			}
			else
			{
				constantsSize = strlen("goto")
								+ strlen(" ") * 5
								+ strlen("\n\tif");
				// create the 'or' code with false label connecting the two sub trees (NOTE: true labels will be handled appropriatly within each sub tree)
				codeSize = constantsSize + leftVarSize + tokenSize + rightVarSize + strlen(trueLabel) + 1;
				
				chainCode = (char*)malloc(sizeof(char) * codeSize);
				snprintf(chainCode, codeSize, 
				"\n\tif %s %s %s goto %s", var1, relOp, var2, trueLabel);
			}

			tree->threeAddCode = mkThreeAddCode("", chainCode);
			free(chainCode);
		}
		else
		{

			int leftCodeSize = strlen(tree->left->left->threeAddCode->code);
			int leftVarSize = strlen(tree->left->left->threeAddCode->var);
			int constantsSize = strlen("\n");
			int tokenSize = strlen(tree->token);
			char* var = freshVar(prog);

			int rightCodeSize = strlen(tree->left->right->threeAddCode->code);
			int rightVarSize = strlen(tree->left->right->threeAddCode->var);

			int genSize = strlen(var) + strlen("\t =   ") + leftVarSize + tokenSize + rightVarSize + 1;
			int codeSize = leftCodeSize + rightCodeSize + genSize + constantsSize + 1;
			
			char* chainCode = (char*)malloc(sizeof(char) * codeSize);
			char* gen = (char*)malloc(sizeof(char) * genSize);
			
			snprintf(gen, genSize, "\t%s = %s %s %s", var, tree->left->left->threeAddCode->var, tree->token, tree->left->right->threeAddCode->var);
			snprintf(chainCode, codeSize, "%s%s\n%s", tree->left->left->threeAddCode->code, tree->left->right->threeAddCode->code, gen);
			
			tree->threeAddCode = mkThreeAddCode(var, chainCode);

			free(gen);
			free(chainCode);
		}
	}

	else if (strcmp(tree->token, "=") == 0)
	{
		generate3Ac(prog, tree->right);

		generate3Ac(prog, tree->left);

		char *rightVar = NULL;
		int pointerFlag = 0;
		node *leftTr = tree->left, *rightTr = tree->right;

		if(tree->left->left && strcmp(tree->left->left->token, "[]") == 0)
		{
			leftTr = tree->left->left;
		
			rightTr = tree->left->right;
		}


		int leftCodeSize = strlen(leftTr->threeAddCode->code);
		
		int rightCodeSize = strlen(rightTr->threeAddCode->code);

		
		int leftVarSize = strlen(leftTr->threeAddCode->var);
		int rightVarSize = strlen(rightTr->threeAddCode->var);
		int constantsSize = strlen("\n");
		int tokenSize = strlen(tree->token);
		char* var = strdup(leftTr->threeAddCode->var);
		
		int genSize = leftVarSize + strlen("\t = ") + rightVarSize + 1;
		int codeSize = rightCodeSize + genSize + constantsSize + leftCodeSize + 1;

		char* chainCode = (char*)malloc(sizeof(char) * codeSize);
		char* gen = (char*)malloc(sizeof(char) * genSize);

		snprintf(gen, genSize, "\t%s = %s", var, rightTr->threeAddCode->var);
		snprintf(chainCode, codeSize, "%s%s\n%s", rightTr->threeAddCode->code, leftTr->threeAddCode->code, gen);
		tree->threeAddCode = mkThreeAddCode(var, chainCode);

		free(chainCode);
		free(gen);
	}

	else if (strcmp(tree->token, "+") == 0 
			|| strcmp(tree->token, "*")  == 0 
			|| strcmp(tree->token, "-")  == 0
			|| strcmp(tree->token, "-")  == 0
			|| strcmp(tree->token, "/")  == 0)
	{
		generate3Ac(prog, tree->left);
		
		char *leftVar = tree->left->left->threeAddCode->var;
		char *leftVarCode = tree->left->left->threeAddCode->code;
		int constantsSize = strlen("\n");
		int tokenSize = strlen(tree->token);

		if (strcmp(tree->left->left->type, "CHAR_PTR") == 0)
		{
			char *ptrAddition = NULL;
			char *ptrAddVar = freshVar(prog);

			int ptrAddSize = strlen(leftVarCode)
							+ strlen(ptrAddVar)
							+ strlen(leftVar)
							+ strlen("\n\t = &")
							+ 1;

			ptrAddition = (char*)malloc(sizeof(char) * ptrAddSize);

			snprintf(ptrAddition, ptrAddSize, "%s\n\t%s = &%s", leftVarCode, ptrAddVar, leftVar);
			leftVarCode = strdup(ptrAddition);
			leftVar = strdup(ptrAddVar);
			
			free(ptrAddition);
			
		}
		char *var = freshVar(prog);
		int leftCodeSize = strlen(leftVarCode);
		int leftVarSize = strlen(leftVar);
		// condition for unary operator plus (+)
		// if (!tree->left->right && (strcmp(tree->token, "+") == 0))
		// {
		// 	printf("here\n");
		// 	int genSize = strlen(var) + strlen("\t = ") + leftVarSize + 1;
		// 	int codeSize = leftCodeSize + genSize + constantsSize + 1;

		// 	char* chainCode = (char*)malloc(sizeof(char) * codeSize);
		// 	char* gen = (char*)malloc(sizeof(char) * genSize);

		// 	snprintf(gen, genSize, "\t%s = %s", var, tree->left->left->threeAddCode->var);
		// 	snprintf(chainCode, codeSize, "%s\n%s", tree->left->left->threeAddCode->code, gen);

		// 	tree->threeAddCode = mkThreeAddCode(var, chainCode);
			
		// 	free(chainCode);
		// 	free(gen);

		// 	return;
		// }
		// condition for the rest of unary operators
		if (!tree->left->right)
		{
			int genSize = strlen(var) + strlen("\t = ") + leftVarSize + tokenSize + 1;
			int codeSize = leftCodeSize + genSize + constantsSize + 1;

			char* chainCode = (char*)malloc(sizeof(char) * codeSize);
			char* gen = (char*)malloc(sizeof(char) * genSize);

			snprintf(gen, genSize, "\t%s = %s%s", var, tree->token, leftVar);
			snprintf(chainCode, codeSize, "%s\n%s", leftVarCode, gen);

			tree->threeAddCode = mkThreeAddCode(var, chainCode);
			
			free(chainCode);
			free(gen);

			return;
		}

		int rightCodeSize = strlen(tree->left->right->threeAddCode->code);
		int rightVarSize = strlen(tree->left->right->threeAddCode->var);
		
		int genSize = strlen(var) + strlen("\t =   ") + leftVarSize + tokenSize + rightVarSize + 1;
		int codeSize = leftCodeSize + rightCodeSize + genSize + constantsSize + 1;
		
		char* chainCode = (char*)malloc(sizeof(char) * codeSize);
		char* gen = (char*)malloc(sizeof(char) * genSize);
		
		snprintf(gen, genSize, "\t%s = %s %s %s", var, leftVar, tree->token, tree->left->right->threeAddCode->var);
		snprintf(chainCode, codeSize, "%s%s\n%s", leftVarCode, tree->left->right->threeAddCode->code, gen);
	
		tree->threeAddCode = mkThreeAddCode(var, chainCode);
		free(chainCode);
		free(gen);

	}

	else if(strcmp(tree->token, "[]") == 0)
	{

		generate3Ac(prog, tree->left);
		generate3Ac(prog, tree->right);

		char *var = tree->left->threeAddCode->var;
		if (!tree->right->threeAddCode)
		{
			
			tree->threeAddCode = mkThreeAddCode(tree->left->threeAddCode->var, "");
			return;
		}
		char *positionJump = tree->right->threeAddCode->var;
		char *postionJumpCode = tree->right->threeAddCode->code;
				
		char *addrVar = freshVar(prog);
		char *chainCode = NULL;
		char *varCode = (char*)malloc(sizeof(char) * strlen(addrVar) + strlen("*") + 1);
		int codeSize = strlen("\t\t\n = &\n =  + ")
						+ strlen(postionJumpCode)
						+ strlen(addrVar) * 4
						+ strlen(var)
						+ strlen(positionJump)
						+ 1;

		chainCode = (char*)malloc(sizeof(char) * codeSize);

		snprintf(chainCode, codeSize, 
				"%s\n\t%s = &%s\n\t%s = %s + %s", 
				postionJumpCode, addrVar, var, addrVar, addrVar, positionJump);
		
		snprintf(varCode, strlen(addrVar) + strlen("*") + 1, "*%s", addrVar);
		tree->threeAddCode = mkThreeAddCode(varCode, chainCode);

		free(varCode);
		free(chainCode);
	}

	else if(strcmp(tree->token, "DE_REF") == 0)
	{
		generate3Ac(prog, tree->left);

		int leftCodeSize = strlen(tree->left->left->threeAddCode->code);
		int leftVarSize = strlen(tree->left->left->threeAddCode->var);
		int constantsSize = strlen("\n");
		int tokenSize = strlen("*");
		char* var = freshVar(prog);

		int genSize = strlen(var) + strlen("\t = ") + leftVarSize + tokenSize + 1;
		int codeSize = leftCodeSize + genSize + constantsSize + 1;

		char* chainCode = (char*)malloc(sizeof(char) * codeSize);
		char* gen = (char*)malloc(sizeof(char) * genSize);

		snprintf(gen, genSize, "\t%s = *%s", var, tree->left->left->threeAddCode->var);
		snprintf(chainCode, codeSize, "%s\n%s", tree->left->left->threeAddCode->code, gen);

		tree->threeAddCode = mkThreeAddCode(var, chainCode);
		
		free(chainCode);
		free(gen);
	}

	else if(strcmp(tree->token, "REF") == 0)
	{


		generate3Ac(prog, tree->left);
		
		char *leftVar = tree->left->threeAddCode->var;
		char *leftVarCode = tree->left->threeAddCode->code;
		int constantsSize = strlen("\n");
		int tokenSize = strlen("&");
		
		if (leftVar[0] = '*')
		{
			char *ptrAddition = NULL;
			char *ptrAddVar = freshVar(prog);

			int ptrAddSize = strlen(leftVarCode)
							+ strlen(ptrAddVar)
							+ strlen(leftVar)
							+ strlen("\n\t = ")
							+ 1;

			ptrAddition = (char*)malloc(sizeof(char) * ptrAddSize);

			snprintf(ptrAddition, ptrAddSize, "%s\n\t%s = %s", leftVarCode, ptrAddVar, leftVar);
			leftVarCode = strdup(ptrAddition);
			leftVar = strdup(ptrAddVar);
			
			free(ptrAddition);
			
		}

		char *var = freshVar(prog);
		int leftCodeSize = strlen(leftVarCode);
		int leftVarSize = strlen(leftVar);



		int genSize = strlen(var) + strlen("\t = ") + leftVarSize + tokenSize + 1;
		int codeSize = leftCodeSize + genSize + constantsSize + 1;

		char* chainCode = (char*)malloc(sizeof(char) * codeSize);
		char* gen = (char*)malloc(sizeof(char) * genSize);

		snprintf(gen, genSize, "\t%s = &%s", var, leftVar);
		snprintf(chainCode, codeSize, "%s\n%s", leftVarCode, gen);

		tree->threeAddCode = mkThreeAddCode(var, chainCode);
		
		free(chainCode);
		free(gen);
	}

	else if(strcmp(tree->token, "LEN") == 0)
	{
		// generate3Ac(prog, tree->left);

		int leftCodeSize = strlen(tree->threeAddCode->code);
		int leftVarSize = strlen(tree->threeAddCode->var);
		int constantsSize = strlen("\n");
		int tokenSize = strlen("||");
		char* var = freshVar(prog);



		int genSize = strlen(var) + strlen("\t = ") + leftVarSize + tokenSize + 1;
		int codeSize = leftCodeSize + genSize + constantsSize + 1;

		char* chainCode = (char*)malloc(sizeof(char) * codeSize);
		char* gen = (char*)malloc(sizeof(char) * genSize);

		snprintf(gen, genSize, "\t%s = |%s|", var, tree->threeAddCode->var);
		snprintf(chainCode, codeSize, "%s\n%s", tree->threeAddCode->code, gen);

		tree->threeAddCode->code = strdup(chainCode);
		tree->threeAddCode->var = strdup(var);
		
		free(chainCode);
		free(gen);
	}

	else if (strcmp(tree->token, "FUNC-CALL") == 0)
	{
		char* typeCode = "\t";
		char* var = "";
		char* paramVar = "";
		char* pushParams = "";
		char* popParams = "";
		int pushParamsSize = 0;
		int notVoidFlag = 0;
		int paramBytesSize = 0;
		int byteSizeLen = 0;
		node *paramIter = tree->right;

		while (paramIter)
		{
			paramBytesSize += getBytes(paramIter->left->type);
			generate3Ac(prog, paramIter->left);
			if (pushParams == "")
			{
				pushParams = (char*)malloc(sizeof(char));
				pushParams[0] = '\0';
			}
			LinkedList** htResult = place(prog->tableCopy, paramIter->left->threeAddCode->var);
			if (!(htResult && *htResult))
			{
				paramVar = freshVar(prog);
			}
			else
			{
				paramVar = paramIter->left->threeAddCode->var;
			}

			pushParamsSize += strlen("\tPushParam \n") + strlen(paramVar) + 1;
			pushParams = (char*)realloc(pushParams, strlen(pushParams) + pushParamsSize);
			prependStr(pushParams, paramVar);
			prependStr(pushParams, "\n\tPushParam ");
			// free(paramVar);
			if (!(htResult && *htResult))
			{
				int tempLineSize = strlen(paramVar) 
				+ strlen("\t = \n") 
				+ strlen(paramIter->left->threeAddCode->var) 
				+ 1;
				char* tempLine = (char*)malloc(sizeof(char) * tempLineSize);
				pushParamsSize += tempLineSize;
				// pushParamsSize += strlen("\t%s = %s\n") + strlen(paramIter->left->threeAddCode->var);
				snprintf(tempLine, tempLineSize, "\n\t%s = %s", paramVar, paramIter->left->threeAddCode->var);
				pushParams = (char*)realloc(pushParams, strlen(pushParams) + pushParamsSize);
				prependStr(pushParams, tempLine);
				free(tempLine);
			}

			paramIter = paramIter->right;
		}

		if (paramBytesSize)
		{
			byteSizeLen = strlen("\n\tPopParams ") + floor(log10(abs(paramBytesSize))) + 2;
			popParams = (char*)malloc(sizeof(char) * byteSizeLen);
			snprintf(popParams, byteSizeLen, "\n\tPopParams %d", paramBytesSize);
		}
		
		LinkedList** htResult = place(prog->tableCopy, tree->left->token);
		if (!(strcmp((*htResult)->decList->type, "VOID") == 0))
		{
			notVoidFlag = 1;
			var = freshVar(prog);
			
			int typeLen = strlen(pushParams) + strlen(var) + strlen("\t = ") + strlen(popParams) + 1;

			typeCode = (char*)malloc(sizeof(char) * (typeLen));
			snprintf(typeCode, typeLen, "\t%s = ", var);
		}
		

		int codeSize = strlen(pushParams) + strlen(typeCode) + strlen("\n\tLCall ") + strlen(tree->left->token) + strlen(popParams) + 1;
		char* code = (char*)malloc(sizeof(char) * codeSize);
		snprintf(code, codeSize, "%s\n%sLCall %s%s", pushParams, typeCode, tree->left->token, popParams);
		tree->threeAddCode = mkThreeAddCode(var, code);

		free(code);
		if (notVoidFlag)
		{
			free(typeCode);
		}
		if (paramBytesSize)
		{
			free(pushParams);
			free(popParams);
		}
	}

	else if ((strcmp(tree->token, "") == 0) || (strcmp(tree->token, "\n") == 0))
	{
		int inheritenceFlag = 0;
		if (tree->threeAddCode)
		{
			inheritenceFlag = 1;
		}
		
		if (tree->left)
		{
			// inherit to left
			if (inheritenceFlag)
			{
				if (!tree->left->threeAddCode)
				{
					tree->left->threeAddCode = mkThreeAddCode("", "");
				}
				tree->left->threeAddCode->falseLabel = tree->threeAddCode->falseLabel;
				tree->left->threeAddCode->trueLabel = tree->threeAddCode->trueLabel;
				tree->left->threeAddCode->next = tree->threeAddCode->next;
			}

			generate3Ac(prog, tree->left);
		
			if (tree->left->threeAddCode)
			{
				tree->threeAddCode = mkThreeAddCode(tree->left->threeAddCode->var, tree->left->threeAddCode->code);
				tree->threeAddCode->falseLabel = tree->left->threeAddCode->falseLabel;
				tree->threeAddCode->trueLabel = tree->left->threeAddCode->trueLabel;
				tree->threeAddCode->next = tree->left->threeAddCode->next;
			}

		}
		if (tree->right)
		{
			
			// inherit to right
			if (inheritenceFlag)
			{
				if (!tree->right->threeAddCode)
				{
					tree->right->threeAddCode = mkThreeAddCode("", "");
				}
				tree->right->threeAddCode->falseLabel = tree->threeAddCode->falseLabel;
				tree->right->threeAddCode->trueLabel = tree->threeAddCode->trueLabel;
				tree->right->threeAddCode->next = tree->threeAddCode->next;
			}

			generate3Ac(prog, tree->right);

			if (tree->threeAddCode && tree->right->threeAddCode)
			{
				int codeSize = strlen(tree->threeAddCode->code) + strlen(tree->right->threeAddCode->code) + 1;
				tree->threeAddCode->code = realloc(tree->threeAddCode->code, codeSize);
				
				strcat(tree->threeAddCode->code, tree->right->threeAddCode->code);
				tree->threeAddCode->next = tree->right->threeAddCode->next;
			}
			else if (tree->right->threeAddCode)
			{
				tree->threeAddCode = mkThreeAddCode(tree->right->threeAddCode->var, tree->right->threeAddCode->code);
				tree->threeAddCode->falseLabel = tree->right->threeAddCode->falseLabel;
				tree->threeAddCode->trueLabel = tree->right->threeAddCode->trueLabel;
				tree->threeAddCode->next = tree->right->threeAddCode->next;
			}
		}
	}

}

%}

%union
{
	char* string;
	struct node* node_struct;
}


%start code

%token <string> BOOL CHAR INT REAL STRING INT_PTR CHAR_PTR REAL_PTR IF ELSE WHILE FOR VAR RET NULL_PTR VOID DO
%token <string> AND DIV ASS EQ BIGGER BIGGER_EQ SMALLER SMALLER_EQ MINUS NOT NOT_EQ OR PLUS MUL REF
%token <string> VAR_BOOL VAR_CHAR VAR_INT_HEX VAR_INT_DEC VAR_REAL VAR_STRING
%token <string> ID
%token <string> SEMC COMMA LEN S_BLOCK E_BLOCK S_BRACK E_BRACK S_ARR E_ARR

%type <node_struct> functions function func func_header void_func_block func_block parameter_list
%type <node_struct> value_list_function par_func body_func func_declarations func_statements func_statement
%type <node_struct> id string_literal value type epsilon int string_element
%type <node_struct> declarations variable_declaration vars_declaration strings_declaration string_declaration statements statement
%type <node_struct> code_blocks func_call exps exp simple_exp conditions
%type <node_struct> loops for while do_while init update return
%type <node_struct> assignment lhs
%type <string> single_op 


%nonassoc IF_PREC
%nonassoc ELSE

%left ASS
%left OR
%left AND
%left EQ NOT_EQ
%left BIGGER BIGGER_EQ SMALLER SMALLER_EQ
%left PLUS MINUS
%left MUL DIV
%right SINGLE_OP


%%
code:
	functions { startProgram(mknode("CODE", $1, mknode("\n", NULL, NULL))); }
	;
	
functions:
	function functions { $$ = mknode("", $1, $2); }
	| function { $$ = $1; }
	;

function: 
	func { $$ = mknode("FUNC", $1, mknode("\n", NULL, NULL)); }
	;
	
func:
	VOID func_header void_func_block { $$ = mknode("", mknode("", $2, mknode("", mknode("RET", mknode($1, NULL, NULL), NULL), NULL)), mknode("BODY", $3, mknode("\n", NULL, NULL))); }
	| type func_header func_block { $$ = mknode("", mknode("", $2, mknode("", mknode("RET", mknode($1->token, NULL, NULL), NULL), NULL)), mknode("BODY", $3, mknode("\n", NULL, NULL))); }
	;

func_header:
	id S_BRACK parameter_list E_BRACK { $$ = mknode("\n", mknode("", $1, mknode("", NULL, NULL)), $3); }
		;
		
void_func_block:
	S_BLOCK body_func E_BLOCK { $$ = mknode("", $2, NULL); }
	;

func_block:
	S_BLOCK body_func return E_BLOCK { $$ = mknode("", $2, $3); }
	;
		
type:
	BOOL { $$ = mknode($1, NULL, NULL); }
	| CHAR  { $$ = mknode($1, NULL, NULL); }
	| INT { $$ = mknode($1, NULL, NULL); }
	| REAL { $$ = mknode($1, NULL, NULL); }
	| INT_PTR { $$ = mknode($1, NULL, NULL); }
	| CHAR_PTR { $$ = mknode($1, NULL, NULL); }
	| REAL_PTR { $$ = mknode($1, NULL, NULL); }
	;

parameter_list:
	epsilon { $$ = $1; }
	| value_list_function { $$ = mknode("ARGS", mknode("", $1, NULL), mknode("\n", NULL, NULL)); }
	;

epsilon:
	{ $$ = NULL; }
	;

value_list_function:
	type par_func SEMC value_list_function { $$ = mknode("", mknode($1->token, $2, NULL), $4); }
	| type par_func { $$ = mknode("", mknode($1->token, $2, NULL), NULL); }
	;

par_func: 
	id COMMA par_func { $$ = mknode("", $1, $3); }
	| id { $$ = mknode("", $1, NULL);} 
	;

body_func:
	func_declarations { $$ = $1; }
	| function body_func { $$ = mknode("", $1, $2); }
	;

func_declarations:
	variable_declaration func_declarations { $$ = mknode("", $1, $2); }
	| func_statements { $$ = $1; }
	;

func_statements:
	func_statement func_statements  { $$ = mknode("", $1, $2); }
	| epsilon { $$ = $1; }

func_statement:
	assignment SEMC { $$ = $1; }
	| func_call SEMC { $$ = $1; }
	| conditions { $$ = $1; }
	| code_blocks { $$ = $1; }
	| loops { $$ = $1; }
	;

declarations:
	variable_declaration declarations { $$ = mknode("", $1, $2); }
	| statements { $$ = $1; }
	;

variable_declaration:
	VAR type vars_declaration SEMC 
	{ $$ = mknode($1, mknode("", $2, $3), mknode("\n", NULL, NULL)); }
	| STRING strings_declaration SEMC { $$ = mknode($1, $2, NULL); }
	;

vars_declaration:
	id COMMA vars_declaration { $$ = mknode("", mknode("", $1, mknode("", $3, NULL)), NULL); }
	| id ASS exp { $$ = mknode("", mknode("=", $1, $3), mknode("", NULL, NULL)); }
	| id ASS exp COMMA vars_declaration { $$ = mknode("", mknode("", mknode("=", $1, $3), mknode("", NULL, NULL)), mknode("", $5, NULL)); }
	| id { $$ = mknode($1->token, mknode("", NULL, NULL), NULL); $$->threeAddCode = $1->threeAddCode; }
	;
	
assignment: 
	lhs ASS exp { $$ = mknode("", mknode("=", $1, $3), NULL); }
	| lhs ASS string_literal { $$ = mknode("", mknode("=", $1, $3), mknode("", NULL, NULL)); }
	;

lhs:
	id { $$ = $1; }
	| MUL id { $$ = mknode("DE_REF", mknode("", $2, NULL), mknode("\n", NULL, NULL)); }
	| id S_ARR exp E_ARR { mknode("", $$ = mknode("[]", $1, $3), mknode("\n", NULL, NULL)); }
	;
	
string_declaration:
	id S_ARR int E_ARR ASS exp { $$ = mknode("", mknode("=", mknode("", mknode("[]", $1, $3), $6), mknode("\n", NULL, NULL)), NULL); }
	| id S_ARR int E_ARR { $$ = mknode("", mknode("[]", $1, $3), NULL); }
	| id S_ARR int E_ARR ASS string_literal { $$ = mknode("", mknode("=", mknode("", mknode("[]", $1, $3), $6), mknode("\n", NULL, NULL)), NULL); }
	;
	
strings_declaration:
	string_declaration COMMA strings_declaration { $$ = mknode("", $1, $3); }
	| string_declaration { $$ = mknode("", $1, mknode("\n", NULL, NULL)); }
	;

statements:
	statement statements { $$ = mknode("", $1, $2); }
	| epsilon { $$ = $1; }
	;

statement:
	assignment SEMC { $$ = $1; }
	| func_call SEMC { $$ = $1; }
	| conditions { $$ = $1; }
	| code_blocks { $$ = $1; }
	| loops { $$ = $1; }
	| return { $$ = $1; }
	;

code_blocks:
	S_BLOCK declarations E_BLOCK { $$ = mknode("BLOCK", mknode("", $2, NULL), mknode("\n", NULL, NULL)); }
	;

func_call:
	id S_BRACK exps E_BRACK { $$ = mknode("FUNC-CALL", $1, $3); }
	| id S_BRACK E_BRACK { $$ = mknode("FUNC-CALL", $1, NULL); }
	;

exps:
	exp COMMA exps { $$ = mknode("", $1, $3); }
	| exp { $$ = mknode("", $1, NULL); }
	;

exp:
	exp PLUS exp { $$ = mknode("", mknode($2, mknode("", $1, $3), NULL), mknode("\n", NULL, NULL)); }
	| exp MINUS exp { $$ = mknode("", mknode($2, mknode("", $1, $3), NULL), mknode("\n", NULL, NULL)); }
	| exp MUL exp { $$ = mknode("", mknode($2, mknode("", $1, $3), NULL), mknode("\n", NULL, NULL)); }
	| exp DIV exp { $$ = mknode("", mknode($2, mknode("", $1, $3), NULL), mknode("\n", NULL, NULL)); }
	| exp EQ exp { $$ = mknode("", mknode($2, mknode("", $1, $3), NULL), mknode("\n", NULL, NULL)); }
	| exp BIGGER exp { $$ = mknode("", mknode($2, mknode("", $1, $3), NULL), mknode("\n", NULL, NULL)); }
	| exp BIGGER_EQ exp { $$ = mknode("", mknode($2, mknode("", $1, $3), NULL), mknode("\n", NULL, NULL)); }
	| exp SMALLER exp { $$ = mknode("", mknode($2, mknode("", $1, $3), NULL), mknode("\n", NULL, NULL)); }
	| exp SMALLER_EQ exp { $$ = mknode("", mknode($2, mknode("", $1, $3), NULL), mknode("\n", NULL, NULL)); }
	| exp NOT_EQ exp { $$ = mknode("", mknode($2, mknode("", $1, $3), NULL), mknode("\n", NULL, NULL)); }
	| exp AND exp { $$ = mknode("", mknode($2, mknode("", $1, $3), NULL), mknode("\n", NULL, NULL)); }
	| exp OR exp { $$ = mknode("", mknode($2, mknode("", $1, $3), NULL), mknode("\n", NULL, NULL)); }
	| simple_exp { $$ = $1; }
	| single_op exp	%prec SINGLE_OP { $$ = mknode($1, mknode("", $2, NULL), mknode("\n", NULL, NULL)); }
	| REF id %prec SINGLE_OP { $$ = mknode("", mknode($1, $2, NULL), mknode("\n", NULL, NULL)); }
	| REF string_element %prec SINGLE_OP { $$ = mknode("", mknode($1, $2, NULL), mknode("\n", NULL, NULL)); }
	;

simple_exp:
	id { $$ = $1; }
	| value { $$ = $1; }
	| func_call { $$ = $1; }
	| S_BRACK exp E_BRACK { $$ = mknode("()", $2, NULL); }
	| LEN id LEN { $$ = mknode($1, mknode($2->token, NULL, NULL), NULL); $$->threeAddCode = $2->threeAddCode; }
	| LEN string_literal LEN { $$ = mknode($1, $2, NULL); $$->threeAddCode = $2->threeAddCode; }
	| string_element { $$ = $1; }
	;

string_element:
	id S_ARR exp E_ARR { $$ = mknode("", mknode("[]", $1, $3), mknode("\n", NULL, NULL)); }
	;

conditions:
	IF S_BRACK exp E_BRACK statement %prec IF_PREC { $$ = mknode($1, mknode("", mknode("COND", $3, NULL), mknode("", $5, NULL)), mknode("\n", NULL, NULL)); }
	| IF S_BRACK exp E_BRACK statement ELSE statement { $$ = mknode("IF-ELSE", mknode("", mknode("COND", $3, NULL), mknode("", $5, $7)), mknode("\n", NULL, NULL)); }
	;

single_op:
	PLUS { $$ = $1; }
	| MINUS { $$ = $1; }
	| NOT { $$ = $1; }
	| MUL { $$ = "DE_REF"; }
	;

value:
	VAR_BOOL { $$ = mknode($1, NULL, NULL); $$->type = "BOOL"; $$->threeAddCode = mkThreeAddCode($1, ""); }
	| VAR_CHAR { $$ = mknode($1, NULL, NULL);  $$->type = "CHAR";$$->threeAddCode = mkThreeAddCode($1, ""); }
	| int { $$ = $1; $$->type = "INT"; $$->threeAddCode = mkThreeAddCode($1->token, "");}
	| VAR_REAL { $$ = mknode($1, NULL, NULL);  $$->type = "REAL"; $$->threeAddCode = mkThreeAddCode($1, ""); }
	| NULL_PTR { $$ = mknode($1, NULL, NULL);  $$->type = "NULL_PTR"; $$->threeAddCode = mkThreeAddCode("0", ""); }
	;
	
id:
	ID { $$ = mknode($1, NULL, NULL); $$->threeAddCode = mkThreeAddCode($1, ""); }
	;
	
string_literal:
	VAR_STRING { $$ = mknode($1, NULL, NULL);  $$->type = "STRING"; $$->threeAddCode = mkThreeAddCode($1, ""); }
	;

int:
	VAR_INT_HEX { $$ = mknode($1, NULL, NULL); }
	| VAR_INT_DEC { $$ = mknode($1, NULL, NULL); }
	;	
	
loops:
	for { $$ = $1; }
	| while { $$ = $1; }
	| do_while { $$ = $1; }
	;

for:
	FOR S_BRACK init SEMC exp SEMC update E_BRACK statement 
		{ $$ = mknode("FOR", mknode("", mknode("INIT", $3, mknode("\n", NULL, NULL)), 
		mknode("", mknode("COND", $5, NULL), 
		mknode("", mknode("UPDATE", $7, mknode("\n", NULL, NULL)), $9))), mknode("\n", NULL, NULL)); }
	;

while:
	WHILE S_BRACK exp E_BRACK statement { $$ = mknode($1, mknode("", mknode("COND", $3, NULL), mknode("", $5, NULL)), mknode("\n", NULL, NULL)); }
	;

do_while:
	DO statement WHILE S_BRACK exp E_BRACK SEMC { $$ = mknode("DO-WHILE", mknode("", mknode("", $2, NULL), mknode("COND", $5, NULL)), mknode("\n", NULL, NULL)); }
	;

init:
	id ASS value { $$ = mknode("=", $1, $3); }
	;

update:
	assignment { $$ = $1; }
	;

return:
	RET exp SEMC { $$ = mknode($1, $2, NULL); }
	| RET SEMC { $$ = mknode($1, mknode("VOID", NULL, NULL), NULL); $$->type = "VOID"; }
	;


%%

void main()
{
	yyparse();
}

int yyerror(const char *error)
{
	fflush(stdout);

    fprintf(stderr, "%s: at line %d\n", error, yylineno);
	fprintf(stderr, "'%s' is not recognized or invalid in this position.\n", yytext);
	fprintf(stderr, " ^\n");

	return 0;
}

int yywrap()
{
	return 1;
}
char* freshVar(Program* prog)
{
	char buf1[1000];
	snprintf(buf1, 1000, "t%d", prog->varCount++); // puts string into buffer
   	return strdup(buf1);
}
char* freshLabel(Program* prog)
{
	char buf[1000];
	snprintf(buf, 1000, "L%d", prog->labelCount++); // puts string into buffer
   	return strdup(buf);
}


ThreeAddCode* mkThreeAddCode(char* var,char* code)
{
	ThreeAddCode *newThree = (ThreeAddCode*)malloc(sizeof(ThreeAddCode));
	newThree->code = (char*)malloc(sizeof(char) * (strlen(code)+1));
	newThree->var = (char*)malloc(sizeof(char) * (strlen(var)+1));
	strcpy(newThree->code, code);
	strcpy(newThree->var, var);
	newThree->trueLabel = NULL;
	newThree->falseLabel = NULL;
	newThree->next = NULL;

	return newThree;
}




node *mknode(char *token, node *left, node *right)
{
	node *newnode = (node*)malloc(sizeof(node));
	// char *newstr = (char*)malloc(sizeof(token)+1);
	newnode->type = NULL;
	newnode->threeAddCode = NULL;
	// strcpy(newstr, token);

	newnode->left=left;
	newnode->right=right;
	// newnode->token=newstr;
	newnode->token = strdup(token);
	return newnode;
}



Program* mkprogram(node* tree)
{
	Program *prog = (Program*)malloc(sizeof(Program));
	if (prog == NULL)
	{
		// TODO: free the tree
		printf("out of memory\n");
		return NULL;
	}
	prog->isSemanticsOk = 1;
	prog->tree = tree;
	prog->scopeStack = NULL;
	prog->scopeCount = 0;
	prog->symbolTable = initTable(SYMBOL_TABLE_SIZE);
	prog->tableCopy = initTable(SYMBOL_TABLE_SIZE);
	prog->varCount=0;
	prog->labelCount=0;
	
	return prog;
}

IdNode* mkIdNode(const char* id)
{
	IdNode *idNode = (IdNode*)malloc(sizeof(IdNode));
	if (idNode == NULL)
	{
		// TODO: free the tree
		printf("out of memory\n");
		return NULL;
	}
	idNode->id = strdup(id);

	idNode->next = NULL;
	return idNode;
}

IdNode* addIdNodeToStart(IdNode* head, const char* id)
{
	IdNode* new_head = mkIdNode(id);
	new_head->next = head;
	head = new_head;
	return head;
}

Scope* addScopeToStart(Program *prog, Scope* s)
{
	s->previous = prog->scopeStack;
	prog->scopeStack = s;
	s->id = (prog->scopeCount)++;

	return s;
}

void printIdList(IdNode* idNode)
{
	while(idNode)
	{
		printf("%s  ", idNode->id);
		idNode = idNode->next;
	}
}

Scope* FreeScopes(HashTable *ht, Scope* head)
{
	if (head == NULL)
		return head;
	head->declarations = FreeIdList(ht, head->declarations);
	if (head->previous != NULL)
		FreeScopes(ht, head->previous);
	free(head);
	head = NULL;

	return head;
}

Scope* DeleteScopeElement(HashTable *ht, Scope* head)
{
	Scope* temp = head->previous;
	head->previous = NULL;
	FreeScopes(ht, head);
	head = temp;
	return head;
}

IdNode* FreeIdList(HashTable* ht, IdNode* head)
{
	if (head == NULL)
	{
		return head;
	}
	DeleteIdFromHashTable(ht, head->id);
	if (head->next != NULL)
	{
		// printf("JJJJJJJJJJJJJJJJJJJJJJJJJJJ\n");
		// printHashTabe(ht);
		FreeIdList(ht, head->next);
		// printf("JJJJJJJJJJ23132232JJJJJJJJJJJJ\n");
		// printHashTabe(ht);
	}
	free(head->id);
	free(head);
	head = NULL;
	return head;
}


void DeleteIdFromHashTable(HashTable* ht, char* id)
{
	LinkedList** identifierInHt = place(ht, id);
	if ((*identifierInHt)->decList)
	{
		(*identifierInHt)->decList = DeleteDecElement((*identifierInHt)->decList);
	}
	if (!((*identifierInHt)->decList))
	{
		*identifierInHt = DeleteElement((*identifierInHt), id);
		--ht->numOfElements;
		if (*identifierInHt == NULL)
			--ht->cellsTaken;
	}
}


void printScopes(Scope* s)
{
	while(s)
	{
		printf("---------------------------------------\n");
		printf("scope no. %d\n    declarations: ", s->id);
		printIdList(s->declarations);
		printf("\n---------------------------------------\n");
		s = s->previous;
	}
}

Program* startProgram(node* tree)
{
	Program *prog = mkprogram(tree);

	checkSemantics(prog);
	
	if (prog->isSemanticsOk)
	{
		printtree(tree, 0);
		printf("\n");
		generate3Ac(prog, prog->tree);
		printf("\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n");
		print3AddCode(prog->tree);
		printf("\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n");
	}
	
	
	
	//printf("Daniel-----%s", prog->tree->threeAddCode->code);
	// printtree(tree, 0);

	/*
	printf("\n");
	*/
}


int checkSemantics(Program* prog)
{
	if (!prog->tree)
	{
		return NO_ERRORS;
	}
	if (strcmp(prog->tree->token, "CODE") != 0)
	{
		return 1;
	}

	checkAddScope(prog, prog->tree);
	FreeScopes(prog->symbolTable, prog->scopeStack);

	return NO_ERRORS;
}


char* checkCond(HashTable *ht, node *checkedNode)
{
	node n;
	n.token = NULL;
	n.left = NULL;
	n.right = NULL;
	n.type = "BOOL";
	return checkTypeConversion(ht, checkedNode, &n);
}


char* checkNumbers(HashTable *ht, node *node1, node *node2)
{
	char *checkResult = NULL;
	checkResult = checkTypeConversion(ht, node1, node2);
	if (!(strcmp(checkResult, "REAL") == 0 || strcmp(checkResult, "INT") == 0))
	{
		return "INVALID_CONVERSION";
	}
	else
	{
		return checkResult;
	}
}

int checkAddScope(Program *prog, node *tree)
{
	/*
	const char* blockNamesArray[] = {"CODE", "BLOCK", "IF", "IF-ELSE", "FOR", "WHILE", "DO-WHILE"};
	const int arrSize = 7;
	*/

	if (tree)
	{
		// if (!((strcmp(tree->token, "") == 0) || strcmp(tree->token, "\n") == 0))
		// {
			// printf("%s\n", tree->token);
		// }
	}
	else
	{
		return 1;
	}
	// printtree(prog->tree, 0);

	if ((strcmp(tree->token, "") == 0) || strcmp(tree->token, "\n") == 0)
	{
		if (tree->left)
			checkAddScope(prog, tree->left);
		if (tree->right)
			checkAddScope(prog, tree->right);

		
		if (tree->right && tree->left && tree->left->type && tree->right->type)
		{
			tree->type = checkTypeConversion(prog->symbolTable, tree->left, tree->right);
		}
		else if (tree->left && tree->left->type)
		{
			tree->type = strdup(tree->left->type);
		}
		else if (tree->right && tree->right->type)
		{
			tree->type = strdup(tree->right->type);
		}
	}

	else if (strcmp(tree->token, "CODE") == 0)
	{
		addScopeToStart(prog, (Scope*)malloc(sizeof(Scope)));
		checkAddScope(prog, tree->left);
		
		// free the code scope at the end of it
		prog->scopeStack = DeleteScopeElement(prog->symbolTable, prog->scopeStack);
		
	}

	else if (strcmp(tree->token, "BLOCK") == 0)
	{
		addScopeToStart(prog, (Scope*)malloc(sizeof(Scope)));
		checkAddScope(prog, tree->left->left);
		// free the block scope at the end of it
		prog->scopeStack = DeleteScopeElement(prog->symbolTable, prog->scopeStack);
	}

	else if (strcmp(tree->token, "IF") == 0)
	{
		// TODO: check condition and only then continue to block with recursive call
		// if...
		// recursive call with the condition node
		checkAddScope(prog, tree->left->left->left);
		tree->left->left->type = checkCond(prog->symbolTable, tree->left->left->left);
		// recursive call with the block node
		checkAddScope(prog, tree->left->right->left);
	}

	else if (strcmp(tree->token, "IF-ELSE") == 0)
	{
		// TODO: check condition and only then continue to block with recursive call
		// if...
		checkAddScope(prog, tree->left->left->left);
		tree->left->left->type = checkCond(prog->symbolTable, tree->left->left->left);
		// recursive call with the true block node
		checkAddScope(prog, tree->left->right->left);
		// else...
		// recursive call with the falseblock node
		checkAddScope(prog, tree->left->right->right);
	}

	else if (strcmp(tree->token, "FOR") == 0)
	{
		// TODO: check condition and only then continue to block with recursive call
		// init call
		checkAddScope(prog, tree->left->left->left);
		// if...
		// recursive call with the condition node
		checkAddScope(prog, tree->left->right->left->left);
		tree->left->right->left->type = checkCond(prog->symbolTable, tree->left->right->left->left);
		// recursive call with the block node
		checkAddScope(prog, tree->left->right->right->right);
		// recursive call with the update node
		checkAddScope(prog, tree->left->right->right->left->left);
	}

	else if (strcmp(tree->token, "WHILE") == 0)
	{
		// TODO: check condition and only then continue to block with recursive call
		// if...
		checkAddScope(prog, tree->left->left->left);
		
		tree->left->left->type = checkCond(prog->symbolTable, tree->left->left->left);
		// recursive call with the block node
		checkAddScope(prog, tree->left->right->left);
	}

	else if (strcmp(tree->token, "DO-WHILE") == 0)
	{
		// TODO: check condition and only then continue to block with recursive call
		// if...
		checkAddScope(prog, tree->left->right->left);
		tree->left->right->type = checkCond(prog->symbolTable, tree->left->right->left);
		// recursive call with the block node
		checkAddScope(prog, tree->left->left->left);
	}

	else if (strcmp(tree->token, "FUNC") == 0)
	{
		Parameter *paramList = NULL;
		int* paramCount = (int*)malloc(sizeof(int)), *copyParamCount = (int*)malloc(sizeof(int));
		*paramCount = 0;
		Scope *s = (Scope*)malloc(sizeof(Scope));
		char* funcName = tree->left->left->left->left->left->token;
		char* type = tree->left->left->right->left->left->token;
		
		node *paramSubTree = tree->left->left->left->right;

		if (strcmp(funcName, "main") == 0)
		{
			LinkedList** htResult = place(prog->symbolTable, "main");
			if (htResult && *htResult)
			{
				tree->type = "MAIN_REDECLARED_ERROR";
				printf(ANSI_COLOR_RED "%s: '%s' redeclared at scope number #%d.\n" ANSI_COLOR_RESET, tree->type, funcName, prog->scopeStack->id);
				prog->isSemanticsOk = 0;

				return 0;
			}
			if (paramSubTree)
			{
				
				free(paramCount);
				free(copyParamCount);
				FreeScopes(prog->symbolTable, s);
				tree->type = "MAIN_WITH_PARAMATERS_ERROR";
				printf(ANSI_COLOR_RED "%s: '%s' declared with paramaters at scope number #%d.\n" ANSI_COLOR_RESET, tree->type, funcName, prog->scopeStack->id);
				prog->isSemanticsOk = 0;

				return 0;
			}
		}

		// add empty param list node to build the parameters upon (deleted after they are all added)
		if (paramSubTree)
		{
			paramList = (Parameter*)malloc(sizeof(Parameter));
			paramList->next = NULL;
		}

		if (insert(prog->symbolTable, funcName, strdup(type), prog->scopeStack->id, paramCount, paramList) == REDECLARATION_ERROR)
		{
			
			FreeParamList(paramList);
			free(paramCount);
			free(copyParamCount);
			free(s);
			// TODO: throw an error
			tree->type = "REDECLARATION_ERROR";
			printf(ANSI_COLOR_RED "%s: function '%s' redeclared at scope number #%d.\n" ANSI_COLOR_RESET, "REDECLARATION_ERROR", funcName, prog->scopeStack->id);
			prog->isSemanticsOk = 0;

			return 0;
		}
		*copyParamCount = *paramCount;
		insert(prog->tableCopy, funcName, strdup(type), prog->scopeStack->id, copyParamCount, paramList);
		//add func id to upper scope
		prog->scopeStack->declarations = addIdNodeToStart(prog->scopeStack->declarations, funcName);
		// add scope
		addScopeToStart(prog, s);
		// add return type
		if (insert(prog->symbolTable, "RET", strdup(type), s->id, NULL, NULL) == REDECLARATION_ERROR)
		{
			// TODO: throw an error 
			return 0;
		}
		
		insert(prog->tableCopy, "RET", strdup(type), s->id, NULL, NULL);
		
		s->declarations = addIdNodeToStart(s->declarations, "RET");
		
		//s->id = ++(prog->scopeCount);

		if (paramSubTree)
		{
			// printf("_=_+_+_+_+_+_+_+_=_\nfunc name: %s\n", funcName);
			// printf("args: %s<\n", paramSubTree->token);
			node *typeSubTree = NULL;
			char* paramName = NULL;
			// turn to params from args
			paramSubTree = paramSubTree->left->left;
			// for the case that there are multiple typed params
			// if (paramSubTree->left->right)
			// {
			// 	paramSubTree = paramSubTree->left;
			// }

			// types loop
			do{
				typeSubTree = paramSubTree->left;
				type = typeSubTree->token;
				// printf("type param: %s<\n", type);
				//typeSubTree = typeSubTree->right;
				// single type param loop
				typeSubTree = typeSubTree->left;

				do{
					// add parameter to function parameter list
					++(*paramCount);
					paramList = addParamToEnd(paramList, BuildParamNode(type));

					paramName = typeSubTree->left->token;

					// check if one of the param names is a duplicate 
					if (insert(prog->symbolTable, paramName, strdup(type), s->id, NULL, NULL) == REDECLARATION_ERROR)
					{
						// TODO: throw an error
						tree->type = "REDECLARATION_ERROR";
						printf(ANSI_COLOR_RED "%s: '%s' redeclared at scope number #%d.\n" ANSI_COLOR_RESET, "REDECLARATION_ERROR", paramName, prog->scopeStack->id);
						prog->isSemanticsOk = 0;

						return 0;
					}
					insert(prog->tableCopy, paramName, strdup(type), s->id, NULL, NULL);
					// add parameter id to scope's declarations
					s->declarations = addIdNodeToStart(s->declarations, paramName);
					
					typeSubTree = typeSubTree->right;

				} while(typeSubTree);
				
				paramSubTree = paramSubTree->right;
			} while(paramSubTree);
		
			// delete the empty paramater element that was used to build the aram list upon
			LinkedList** funcInHt = place(prog->symbolTable, funcName);
			// PrintList(*funcInHt);
			(*funcInHt)->decList->params = DeleteParamElement((*(funcInHt))->decList->params);
		}
		
		// recursive call with body
		// printf("body: %s<\n", tree->left->right->token);

		int res = checkAddScope(prog, tree->left->right->left->left);

		// recursive call with the return because return is seperate from body func (should only check the type)
		if (tree->left->right->left)
			res *= checkAddScope(prog, tree->left->right->left->right);
		// free the function scope at the end of it
		// printf("reached the end\n");
		// printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
		// printHashTabe(prog->symbolTable);

		prog->scopeStack = DeleteScopeElement(prog->symbolTable, prog->scopeStack);
		// return the result of both recursive calls
		return res;
	}

	else if (strcmp(tree->token, "VAR") == 0)
	{
		char* type = tree->left->left->token;

		node *varsDec = tree->left->right;
		do {
			// one id declaration
			if (!(strcmp(varsDec->token, "") == 0))
			{
				//printf("single declaration\n");
				if (insert(prog->symbolTable, varsDec->token, strdup(type), prog->scopeStack->id, NULL, NULL) == REDECLARATION_ERROR)
				{
						// TODO: throw an error
						tree->type = "REDECLARATION_ERROR";
						printf(ANSI_COLOR_RED "%s: '%s' redeclared at scope number #%d.\n" ANSI_COLOR_RESET, "REDECLARATION_ERROR", varsDec->token, prog->scopeStack->id);
						prog->isSemanticsOk = 0;

						return 0;
				}
				insert(prog->tableCopy, varsDec->token, strdup(type), prog->scopeStack->id, NULL, NULL);
				prog->scopeStack->declarations = addIdNodeToStart(prog->scopeStack->declarations, varsDec->token);
				break;
			}
			// multiple declarations
			else if (!(varsDec->right))
			{
				//printf("multi declaration\n");
				if (insert(prog->symbolTable, varsDec->left->left->token, strdup(type), prog->scopeStack->id, NULL, NULL) == REDECLARATION_ERROR)
				{
						// TODO: throw an error
						tree->type = "REDECLARATION_ERROR";
						printf(ANSI_COLOR_RED "%s: '%s' redeclared at scope number #%d.\n" ANSI_COLOR_RESET, "REDECLARATION_ERROR", varsDec->left->left->token, prog->scopeStack->id);
						prog->isSemanticsOk = 0;

						return 0;
				}
				insert(prog->tableCopy, varsDec->left->left->token, strdup(type), prog->scopeStack->id, NULL, NULL);
				prog->scopeStack->declarations = addIdNodeToStart(prog->scopeStack->declarations, varsDec->left->left->token);
				varsDec = varsDec->left->right->left;
			}
			// TODO: in vars_declaration add the cases of assignment here in "else if's"
			else if (!varsDec->right->left)
			{
				//printf("single assignment\n");
				if (insert(prog->symbolTable, varsDec->left->left->token, strdup(type), prog->scopeStack->id, NULL, NULL) == REDECLARATION_ERROR)
				{
						// TODO: throw an error
						tree->type = "REDECLARATION_ERROR";
						printf(ANSI_COLOR_RED "%s: '%s' redeclared at scope number #%d.\n" ANSI_COLOR_RESET, "REDECLARATION_ERROR", varsDec->left->left->token, prog->scopeStack->id);
						prog->isSemanticsOk = 0;

						return 0;
				}
				insert(prog->tableCopy, varsDec->left->left->token, strdup(type), prog->scopeStack->id, NULL, NULL);
				prog->scopeStack->declarations = addIdNodeToStart(prog->scopeStack->declarations, varsDec->left->left->token);
				checkAddScope(prog, varsDec->left);
				break;
			}
			else
			{
				//printf("single assignment with multi dec\n");
				if (insert(prog->symbolTable, varsDec->left->left->left->token, strdup(type), prog->scopeStack->id, NULL, NULL) == REDECLARATION_ERROR)
				{
						// TODO: throw an error
						tree->type = "REDECLARATION_ERROR";
						printf(ANSI_COLOR_RED "%s: '%s' redeclared at scope number #%d.\n" ANSI_COLOR_RESET, "REDECLARATION_ERROR", varsDec->left->left->left->token, prog->scopeStack->id);
						prog->isSemanticsOk = 0;

						return 0;
				}
				insert(prog->tableCopy, varsDec->left->left->left->token, strdup(type), prog->scopeStack->id, NULL, NULL);
				prog->scopeStack->declarations = addIdNodeToStart(prog->scopeStack->declarations, varsDec->left->left->left->token);
				checkAddScope(prog, varsDec->left->left);
				varsDec = varsDec->right->left;
			}
		} while(1);
		return 1;
		// TODO: add string declaration case here
	}



	else if (strcmp(tree->token, "STRING") == 0)
	{
		char* type = "STRING";
		int multiFlag = 0;

		node *varsDec = tree->left,  *multiContinue = NULL;
		do {
			// one id declaration
			if (!strcmp(varsDec->right->token, "\n") == 0)
			{
				multiContinue = varsDec;
			}
			varsDec = varsDec->left;
		
			// single declaration
			if (strcmp(varsDec->left->token, "[]") == 0)
			{
				if(insert(prog->symbolTable, varsDec->left->left->token, strdup(type), prog->scopeStack->id, NULL, NULL) == REDECLARATION_ERROR)
				{
						// TODO: throw an error
						tree->type = "REDECLARATION_ERROR";
						printf(ANSI_COLOR_RED "%s: '%s' redeclared at scope number #%d.\n" ANSI_COLOR_RESET, "REDECLARATION_ERROR", varsDec->left->left->token, prog->scopeStack->id);
						prog->isSemanticsOk = 0;

						return 0;
				}
				insert(prog->tableCopy, varsDec->left->left->token, strdup(type), prog->scopeStack->id, NULL, NULL);
				prog->scopeStack->declarations = addIdNodeToStart(prog->scopeStack->declarations, varsDec->left->left->token);

				
				if(multiContinue)
				{
					varsDec = multiContinue->right;
					multiContinue = NULL;
					continue;
				}
				else
				{
					return 1;
				}
				
			}
			// single declaration with assignment
			varsDec = varsDec->left;
			
			varsDec->left->type = type;
			if (strcmp(varsDec->left->token, "") == 0)
			{
				varsDec->left->left->type = type;
				if (insert(prog->symbolTable, varsDec->left->left->left->token, strdup(type), prog->scopeStack->id, NULL, NULL) == REDECLARATION_ERROR)
				{
					// TODO: throw an error 
					return 0;
				}
				insert(prog->tableCopy, varsDec->left->left->left->token, strdup(type), prog->scopeStack->id, NULL, NULL);
				prog->scopeStack->declarations = addIdNodeToStart(prog->scopeStack->declarations, varsDec->left->left->left->token);
			}
			else
			{
				if (insert(prog->symbolTable, varsDec->left->left->token, strdup(type), prog->scopeStack->id, NULL, NULL) == REDECLARATION_ERROR)
				{
						// TODO: throw an error
						tree->type = "REDECLARATION_ERROR";
						printf(ANSI_COLOR_RED "%s: '%s' redeclared at scope number #%d.\n" ANSI_COLOR_RESET, "REDECLARATION_ERROR", varsDec->left->left->token, prog->scopeStack->id);
						prog->isSemanticsOk = 0;

						return 0;
				}
				insert(prog->tableCopy, varsDec->left->left->token, strdup(type), prog->scopeStack->id, NULL, NULL);
				prog->scopeStack->declarations = addIdNodeToStart(prog->scopeStack->declarations, varsDec->left->left->token);
			}
			
			varsDec->type = checkTypeConversion(prog->symbolTable, varsDec->left, varsDec->right);
			if (!strcmp(varsDec->type, "INVALID_CONVERSION") == 0)
			{
				varsDec->type = NULL;
				if(multiContinue)
				{
					varsDec = multiContinue->right;
					multiContinue = NULL;
					continue;
				}
				else
				{
					return 1;
				}
			}
			return 0;

		} while(1);
		return 1;
	}

	else if(strcmp(tree->token, "=") == 0)
	{
		char *checkResult = NULL;
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		checkAddScope(prog, tree->left);
		checkAddScope(prog, tree->right);
		
		// TODO: make try except for conversion error
		// TODO: after exception handling - remove the assginment to type (can't chain assignments)
		checkResult = checkTypeConversion(prog->symbolTable, tree->left, tree->right);
		if (strcmp(checkResult, "INVALID_CONVERSION") == 0 || strcmp(checkResult, "INVALID_TOKEN") == 0)
		{
			tree->type = "INVALID_CONVERSION";
			printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot assign to '%s' a type of '%s'.\n" ANSI_COLOR_RESET, checkResult, prog->scopeStack->id, tree->left->type, tree->right->type);
			prog->isSemanticsOk = 0;

			return 0;
		}
		return 1;
	}

	else if(strcmp(tree->token, "==") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		
		checkAddScope(prog, tree->left);

		// checkAddScope(prog, tree->left->right);
		char *res = checkTypeConversion(prog->symbolTable, tree->left->left, tree->left->right);

		// TODO: make try except for conversion error
		
		if ((strcmp(tree->left->left->type, tree->left->right->type) != 0) || (strcmp(res, "INVALID_TOKEN") == 0 ) || (strcmp(res, "INVALID_CONVERSION") == 0))
		{
			tree->type = "INVALID_CONVERSION";
			printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot use '==' with '%s' and '%s'.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->left->type, tree->left->right->type);
			prog->isSemanticsOk = 0;
			
			return 0;
		}
		else
		{
			tree->type = "BOOL";
		}
		return 1;
	}

	else if(strcmp(tree->token, "+") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		checkAddScope(prog, tree->left->left);
		if (!tree->left->right)
		{
			tree->type = checkNumbers(prog->symbolTable, tree->left->left, tree->left->left);
			if (!((strcmp(tree->type, "INVALID_CONVERSION") == 0) || (strcmp(tree->type, "INVALID_TOKEN") == 0)))
			{
				return 1;
			}
			printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot use plus (+) on %s %s.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->left->type, tree->left->left->token);
			prog->isSemanticsOk = 0;

			return 0;
		}
		checkAddScope(prog, tree->left->right);
		// TODO: make try except for conversion error
		tree->type = checkNumbers(prog->symbolTable, tree->left->left, tree->left->right);
		if (!((strcmp(tree->type, "INVALID_CONVERSION") == 0) || (strcmp(tree->type, "INVALID_TOKEN") == 0)))
		{
			return 1;
		}
		else if ((strcmp(tree->left->left->type, "CHAR_PTR") == 0) && (strcmp(tree->left->right->type, "INT") == 0))
		{
			tree->type = "CHAR_PTR";
			return 1;
		}
		printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot add '%s' and '%s'.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->left->type, tree->left->right->type);
		prog->isSemanticsOk = 0;

		return 0;
	}

	else if(strcmp(tree->token, "-") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		checkAddScope(prog, tree->left->left);

		if (!tree->left->right)
		{
			tree->type = checkNumbers(prog->symbolTable, tree->left->left, tree->left->left);
			if (!((strcmp(tree->type, "INVALID_CONVERSION") == 0) || (strcmp(tree->type, "INVALID_TOKEN") == 0)))
			{
				return 1;
			}
			printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot use minus (-) on %s %s.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->left->type, tree->left->left->token);
			prog->isSemanticsOk = 0;

			return 0;
		}
		checkAddScope(prog, tree->left->right);
		// TODO: make try except for conversion error
		tree->type = checkNumbers(prog->symbolTable, tree->left->left, tree->left->right);
		if (!((strcmp(tree->type, "INVALID_CONVERSION") == 0) || (strcmp(tree->type, "INVALID_TOKEN") == 0)))
		{
			return 1;
		}
		else if ((strcmp(tree->left->left->type, "CHAR_PTR") == 0) && (strcmp(tree->left->right->type, "INT") == 0))
		{
			tree->type = "CHAR_PTR";
			return 1;
		}

		printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot subtract '%s' and '%s'.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->left->type, tree->left->right->type);
		prog->isSemanticsOk = 0;

		return 0;
	}

	else if(strcmp(tree->token, "*") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		checkAddScope(prog, tree->left->left);
		checkAddScope(prog, tree->left->right);
		// TODO: make try except for conversion error
		tree->type = checkNumbers(prog->symbolTable, tree->left->left, tree->left->right);
		if (!((strcmp(tree->type, "INVALID_CONVERSION") == 0) || (strcmp(tree->type, "INVALID_TOKEN") == 0)))
		{
			return 1;
		}
		printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot multiply '%s' and '%s'.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->left->type, tree->left->right->type);
		prog->isSemanticsOk = 0;

		return 0;
	}

	else if(strcmp(tree->token, "/") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		checkAddScope(prog, tree->left->left);
		checkAddScope(prog, tree->left->right);
		// TODO: make try except for conversion error
		tree->type = checkNumbers(prog->symbolTable, tree->left->left, tree->left->right);
		if (!((strcmp(tree->type, "INVALID_CONVERSION") == 0) || (strcmp(tree->type, "INVALID_TOKEN") == 0)))
		{
			return 1;
		}
		printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot divide '%s' and '%s'.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->left->type, tree->left->right->type);
		prog->isSemanticsOk = 0;

		return 0;
	}

	else if(strcmp(tree->token, "!=") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		checkAddScope(prog, tree->left->left);
		checkAddScope(prog, tree->left->right);
		checkTypeConversion(prog->symbolTable, tree->left->left, tree->left->right);
		// TODO: make try except for conversion error
		if ((strcmp(tree->left->left->type, tree->left->right->type) != 0) || (strcmp(tree->left->left->type, "INVALID_CONVERSION") == 0) || (strcmp(tree->left->left->type, "INVALID_TOKEN") == 0))
		{
			tree->type = "INVALID_CONVERSION";
			printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot use '!=' with '%s' and '%s'.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->left->type, tree->left->right->type);
			prog->isSemanticsOk = 0;

			return 0;
		}
		else
		{
			tree->type = "BOOL";
		}
		return 1;
	}

	else if(strcmp(tree->token, "||") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		checkAddScope(prog, tree->left->left);
		checkAddScope(prog, tree->left->right);
		// TODO: make try except for conversion error
		tree->type = checkTypeConversion(prog->symbolTable, tree->left->left, tree->left->right);
		if (strcmp(tree->type, "BOOL") == 0)
		{
			return 1;
		}
		printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot use or ('||') with '%s' and '%s' - or can only be used between bool types.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->left->type, tree->left->right->type);
		prog->isSemanticsOk = 0;

		return 0;
	}

	else if(strcmp(tree->token, "&&") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		checkAddScope(prog, tree->left->left);
		checkAddScope(prog, tree->left->right);
		// TODO: make try except for conversion error
		tree->type = checkTypeConversion(prog->symbolTable, tree->left->left, tree->left->right);
		if (strcmp(tree->type, "BOOL") == 0)
		{
			return 1;
		}
		printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot use and ('&&') with '%s' and '%s' - and can only be used between bool types.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->left->type, tree->left->right->type);
		prog->isSemanticsOk = 0;

		return 0;
	}

	else if(strcmp(tree->token, "<") == 0)
	{
		char *checkResult = NULL;
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		checkAddScope(prog, tree->left->left);
		checkAddScope(prog, tree->left->right);
		// TODO: make try except for conversion error
		tree->type = checkNumbers(prog->symbolTable, tree->left->left, tree->left->right);
		if (!((strcmp(tree->type, "INVALID_CONVERSION") == 0) || (strcmp(tree->type, "INVALID_TOKEN") == 0)))
		{
			tree->type = "BOOL";
			return 1;
		}
		printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot use '<' with '%s' and '%s' - comparison can only be used between numbers.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->left->type, tree->left->right->type);
		prog->isSemanticsOk = 0;
		
		return 0;
	}

	else if(strcmp(tree->token, ">") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		checkAddScope(prog, tree->left->left);
		checkAddScope(prog, tree->left->right);
		// TODO: make try except for conversion error
		tree->type = checkNumbers(prog->symbolTable, tree->left->left, tree->left->right);
		if (!((strcmp(tree->type, "INVALID_CONVERSION") == 0) || (strcmp(tree->type, "INVALID_TOKEN") == 0)))
		{
			tree->type = "BOOL";
			return 1;
		}
		printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot use '>' with '%s' and '%s' - comparison can only be used between numbers.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->left->type, tree->left->right->type);
		prog->isSemanticsOk = 0;
		
		return 0;
	}

	else if(strcmp(tree->token, ">=") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		checkAddScope(prog, tree->left->left);
		checkAddScope(prog, tree->left->right);
		// TODO: make try except for conversion error
		tree->type = checkNumbers(prog->symbolTable, tree->left->left, tree->left->right);
		if (!((strcmp(tree->type, "INVALID_CONVERSION") == 0) || (strcmp(tree->type, "INVALID_TOKEN") == 0)))
		{
			tree->type = "BOOL";
			return 1;
		}
		printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot use '>=' with '%s' and '%s' - comparison can only be used between numbers.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->left->type, tree->left->right->type);
		prog->isSemanticsOk = 0;
		
		return 0;
	}

	else if(strcmp(tree->token, "<=") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		checkAddScope(prog, tree->left->left);
		checkAddScope(prog, tree->left->right);
		// TODO: make try except for conversion error
		tree->type = checkNumbers(prog->symbolTable, tree->left->left, tree->left->right);
		if (!((strcmp(tree->type, "INVALID_CONVERSION") == 0) || (strcmp(tree->type, "INVALID_TOKEN") == 0)))
		{
			tree->type = "BOOL";
			return 1;
		}
		printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot use '<=' with '%s' and '%s' - comparison can only be used between numbers.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->left->type, tree->left->right->type);
		prog->isSemanticsOk = 0;
		
		return 0;
	}

	else if(strcmp(tree->token, "()") == 0)
	{
		// TODO: call left child with a recursive call, then check the type of the node
		checkAddScope(prog, tree->left);
		tree->left->type = checkTypeConversion(prog->symbolTable, tree->left, tree->left);
		// TODO: make try except for conversion error
		tree->type = tree->left->type;
		if (!((strcmp(tree->type, "INVALID_CONVERSION") == 0) || (strcmp(tree->type, "INVALID_TOKEN") == 0)))
		{
			return 1;
		}
		return 0;
	}

	else if(strcmp(tree->token, "[]") == 0)
	{
		node n;
		n.token = NULL;
		n.left = NULL;
		n.right = NULL;
		n.type = "INT";
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		checkAddScope(prog, tree->left);
		checkAddScope(prog, tree->right);
		
		tree->left->type = checkTypeConversion(prog->symbolTable, tree->left, tree->left);
		tree->right->type = checkTypeConversion(prog->symbolTable, tree->right, &n);
		// TODO: make try except for conversion error
		tree->type = tree->left->type;
		if (!(strcmp(tree->type, "STRING") == 0))
		{
			tree->type = "TYPE_NOT_SUBSCRIPTABLE";
			printf(ANSI_COLOR_RED "%s: at scope #%d -> '%s' is not subscriptable (can't use '[]') - only string arrays are allowed.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->type);
			prog->isSemanticsOk = 0;
			
			return 0;
		}
		if (!(strcmp(tree->right->type, "INT") == 0))
		{
			tree->type = "INDEX_ERROR";
			printf(ANSI_COLOR_RED "%s: at scope #%d -> '%s' can't be used as index (can't use '[%s]') - index must be an integer.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->right->type, tree->right->type);
			prog->isSemanticsOk = 0;
			
			return 0;
		}
		tree->type = "CHAR";

		return 1;
	}

	else if(strcmp(tree->token, "LEN") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		tree->left->type = checkTypeConversion(prog->symbolTable, tree->left, tree->left);

		// TODO: make try except for conversion error
	
		if (!(strcmp(tree->left->type, "STRING") == 0))
		{
			tree->type = "LEN_TYPE_ERROR";
			printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot apply length operator with type '%s' - only string lengths are possible.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->type);
			prog->isSemanticsOk = 0;
			
			return 0;
		}
		tree->type = "INT";
		return 1;
	}

	else if(strcmp(tree->token, "!") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		
		checkAddScope(prog, tree->left);
		tree->left->type = checkTypeConversion(prog->symbolTable, tree->left->left, tree->left->left);

		// TODO: make try except for conversion error
	
		if (!(strcmp(tree->left->type, "BOOL") == 0))
		{
			tree->type = "NOT_TYPE_ERROR";
			printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot apply not ('!') operator with type '%s' - only string lengths are possible.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->type);
			prog->isSemanticsOk = 0;
			
			return 0;
		}
		tree->type = "BOOL";
		return 1;
	}

	else if(strcmp(tree->token, "REF") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		
		checkAddScope(prog, tree->left);
		tree->left->type = checkTypeConversion(prog->symbolTable, tree->left, tree->left);

		// TODO: make try except for conversion error
	
		if (strcmp(tree->left->type, "INT") == 0)
		{
			tree->type = "INT_PTR";
			return 1;
		}
		else if (strcmp(tree->left->type, "CHAR") == 0)
		{
			tree->type = "CHAR_PTR";
			return 1;
		}
		else if (strcmp(tree->left->type, "REAL") == 0)
		{
			tree->type = "REAL_PTR";
			return 1;
		}
		
		tree->type = "REF_TYPE_ERROR";
		printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot reference ('&') type '%s' - only int, char and real can be referenced.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->type);
		prog->isSemanticsOk = 0;
		
		return 0;
	}

	else if(strcmp(tree->token, "DE_REF") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		
		checkAddScope(prog, tree->left);
		tree->left->type = checkTypeConversion(prog->symbolTable, tree->left->left, tree->left->left);

		// TODO: make try except for conversion error
	
		if (strcmp(tree->left->type, "INT_PTR") == 0)
		{
			tree->type = "INT";
			return 1;
		}
		else if (strcmp(tree->left->type, "CHAR_PTR") == 0)
		{
			tree->type = "CHAR";
			return 1;
		}
		else if (strcmp(tree->left->type, "REAL_PTR") == 0)
		{
			tree->type = "REAL";
			return 1;
		}
		
		tree->type = "DE_REF_TYPE_ERROR";
		printf(ANSI_COLOR_RED "%s: at scope #%d -> cannot dereference ('&') type '%s' - only pointers of int, char and real can be dereferenced.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id, tree->left->type);
		prog->isSemanticsOk = 0;
		
		return 0;
	}

	else if(strcmp(tree->token, "FUNC-CALL") == 0)
	{
		// TODO: call left and right children with a recursive call, then check the types of the nodes
		char* funcName = tree->left->token;
		node *paramIter = tree->right;
		Parameter *params = NULL;

		LinkedList** htResult = place(prog->symbolTable, funcName);
		if (!(htResult && *htResult))
		{
			tree->type = "FUNC_CALL_BEFORE_DECLARATION_ERROR";
			printf(ANSI_COLOR_RED "%s: function '%s' called before declaration at scope #%d.\n" ANSI_COLOR_RESET, tree->type, funcName, prog->scopeStack->id);
			prog->isSemanticsOk = 0;
			
			return 0;
		}

		if((*htResult)->decList->paramCount == NULL)
		{
			tree->type = "IDENTIFIER_NOT_FUNCTION_ERROR";
			printf(ANSI_COLOR_RED "%s: identifier '%s' is not a function, called at scope #%d.\n" ANSI_COLOR_RESET, tree->type, funcName, prog->scopeStack->id);
			prog->isSemanticsOk = 0;
			
			return 0;
		}

		if (paramIter)
		{
			params = (Parameter*)malloc(sizeof(Parameter));
			params->next  = NULL;
		}
		int counter = 0;
		while(paramIter && paramIter->left)
		{
			checkAddScope(prog, paramIter->left);
			paramIter->left->type = checkTypeConversion(prog->symbolTable, paramIter->left, paramIter->left);
			params = addParamToEnd(params, BuildParamNode(paramIter->left->type));
			paramIter = paramIter->right;
			++counter;
			if (*((*htResult)->decList->paramCount) < counter)
			{
				tree->type = "PARAMETERS_COUNT_ERROR";
				printf(ANSI_COLOR_RED "%s: in function '%s' call at scope #%d.\n" ANSI_COLOR_RESET, tree->type, funcName, prog->scopeStack->id);
				prog->isSemanticsOk = 0;
				FreeParamList(params);

				return 0;
			}
		}

		if (counter)
		{
			params = DeleteParamElement(params);
		}

		if (*((*htResult)->decList->paramCount) != counter)
		{
			tree->type = "PARAMETERS_COUNT_ERROR";
			FreeParamList(params);
			printf(ANSI_COLOR_RED "%s: in function '%s' call at scope #%d.\n" ANSI_COLOR_RESET, tree->type, funcName, prog->scopeStack->id);
			prog->isSemanticsOk = 0;
			
			return 0;
		}
		Parameter *iter1 = (*htResult)->decList->params, *iter2 = params;
		node node1, node2;
		node1.token = NULL;
		node1.left = NULL;
		node1.right = NULL;
		node2.token = NULL;
		node2.left = NULL;
		node2.right = NULL;
		char* typeCheck = NULL;
		for (int i = 0; i < counter; ++i)
		{
			
			node1.type = strdup(iter1->type);
			node2.type = strdup(iter2->type);

			typeCheck = checkTypeConversion(prog->symbolTable, &node1, &node2);

			if(strcmp(typeCheck, "INVALID_CONVERSION") == 0)
			{
				tree->type = "PARAMETERS_TYPE_ERROR";
				printf(ANSI_COLOR_RED "%s: in function '%s' call at scope #%d.\n" ANSI_COLOR_RESET, tree->type, funcName, prog->scopeStack->id);
				FreeParamList(params);
				prog->isSemanticsOk = 0;
				
				return 0;
			}
			iter1 = iter1->next;
			iter2 = iter2->next;
		}
		if (counter)
		{
			FreeParamList(params);
		}

		// if all ok - function call node gets the correct return type
		tree->type = strdup((*htResult)->decList->type);

		return 1;
	}

	else if(strcmp(tree->token, "RET") == 0)
	{

		LinkedList** htResult = place(prog->symbolTable, "RET");
		// this check should never be false as lexems dissallow code not within a function at upper scopes
		if (!(htResult && *htResult))
		{
			tree->type = "RETURN_WITHOUT_FUNCTION_ERROR";
			printf(ANSI_COLOR_RED "%s: return without a function in upper scope at scope #%d.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id);
			prog->isSemanticsOk = 0;
			
			return 0;
		}

		// TODO: call left child with a recursive call, then check the types of the nodes
		checkAddScope(prog, tree->left);
		node n;
		n.token = NULL;
		n.left = NULL;
		n.right = NULL;
		n.type = (*htResult)->decList->type;
	
		tree->type = checkTypeConversion(prog->symbolTable, &n, tree->left);

		// TODO: make try except for conversion error
		if(strcmp(tree->type, "INVALID_CONVERSION") == 0)
		{
			tree->type = "INVALID_RETURN_TYPE_ERROR";
			printf(ANSI_COLOR_RED "%s: invalid return type at scope #%d.\n" ANSI_COLOR_RESET, tree->type, prog->scopeStack->id);
			prog->isSemanticsOk = 0;
			
			return 0;
		}

		tree->type = NULL;

		return 1;
	}
	
	
	

	


	/*
	for(int i = 0; i < arrSize - 1; ++i)
	{
		if (strcmp(tree->token, "CODE") == 0)
		{

		}
	}
	*/
}

char* checkTypeConversion(HashTable *ht, node* node1, node* node2)
{
	
	LinkedList** htResult = NULL;

	char *type1 = NULL, *type2 = NULL;

	if (!node1->type)
	{
		htResult = place(ht, node1->token);

		if (htResult && *htResult)
		{
			type1 = (*htResult)->decList->type;
			node1->type = strdup(type1);

		}
		else
		{
			// TODO: add exception invalid token (meaning it is not a known identifier in the symbole table)
			node1->type = "INVALID_TOKEN";
			return "INVALID_TOKEN";
		}
	}
	else
	{
		type1 = node1->type;
	}

	htResult = NULL;

	if (!node2->type)
	{
		htResult = place(ht, node2->token);
		if (htResult && *htResult)
		{
			type2 = (*htResult)->decList->type;
			node2->type = strdup(type2);
		}
		else
		{
			// TODO: add exception invalid token (meaning it is not a known identifier in the symbole table)
			node2->type = "INVALID_TOKEN";
			return "INVALID_TOKEN";
		}
	}
	else
	{
		type2 = node2->type;
	}
	
	if ((strcmp(type1, type2) == 0) && !(strcmp(type1, "INVALID_TOKEN") == 0) )
	{
		return strdup(type1);
	}
	else if (((strcmp(type1, "INT") == 0) && (strcmp(type2, "REAL") == 0)) || ((strcmp(type2, "INT") == 0) && (strcmp(type1, "REAL") == 0)))
	{
		return "REAL";
	}
	else if (strcmp(type2, "NULL_PTR") == 0)
	{

		if (strcmp(type1, "INT_PTR") == 0 || strcmp(type1, "CHAR_PTR") == 0 || strcmp(type1, "REAL_PTR") == 0 || strcmp(type1, "STRING") == 0)
		{
			return strdup(type2);
		}
		return "INVALID_CONVERSION";
	}
	else
	{
		// TODO: raise exception incompatible types
		return "INVALID_CONVERSION";
	}

}

int is_leaf(node *checked_node)
{
	return !(checked_node->left || checked_node->right);
}

void print_tabs(int tabs)
{
	for (int i = 0; i < tabs; ++i)
	{
		printf("    ");
	}
}

int is_connecting_node(node* check_node)
{
	return strcmp(check_node->token, "") == 0 || strcmp(check_node->token, "\n") == 0;
}

void printtree(node *tree, int tabs)
{
	if (!tree)
	{
		return;
	}

	int has_sons = !is_leaf(tree);
	int is_node_connecting = is_connecting_node(tree);
	int father = has_sons && !is_node_connecting;
	
	
	if (father)
	{
		printf("\n");
		print_tabs(tabs);
		printf("(");
	}
	if (!has_sons && strcmp(tree->token, "") != 0)
	{
		printf(" ");
	}
	if (tree->type && !is_node_connecting)
	{
		printf("%s ", tree->type);
	}
	printf("%s", tree->token);

	// if (tree->threeAddCode)
	// {
	// 	printf("\ncode:\n\t%s", tree->threeAddCode->code);
	// }
	
	if (strcmp(tree->token, "\n") == 0)
	{
		print_tabs(tabs);
	}
	
	if(tree->left)
	{
		if (is_node_connecting || strcmp(tree->left->token, "\n") == 0)
		{
			printtree(tree->left, tabs);
		}
		else
		{
			printtree(tree->left, tabs + 1);
		}
		
		// printtree(tree->left, tabs + 1);
	}

	if(tree->right)
	{
		if (strcmp(tree->token, "") == 0 && strcmp(tree->right->token, "\n") == 0)
		{
			printtree(tree->right, tabs-1);
		}
		else if (is_node_connecting || strcmp(tree->right->token, "\n") == 0 )
		{
			printtree(tree->right, tabs);
		}
		else
		{
			printtree(tree->right, tabs + 1);
		}
	}

	if (father)
	{
		/*
		if (check_if_block(tree->token))
		{
			printf("\n");
			print_tabs(tabs);
		}
		*/
		printf(")");
	}
}




































