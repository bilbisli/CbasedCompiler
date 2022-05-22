%{
#include <stdio.h>
#include "y.tab.h"
%}

%x COMMENT

%%
"bool" { yylval.string = "BOOL"; return BOOL; }
"char" { yylval.string = "CHAR"; return CHAR; }
"int" { yylval.string = "INT"; return INT; }
"real" { yylval.string = "REAL"; return REAL; }
"string" { yylval.string = "STRING"; return STRING; }
"int*" { yylval.string = "INT_PTR"; return INT_PTR; }
"char*" { yylval.string = "CHAR_PTR"; return CHAR_PTR; }
"real*" { yylval.string = "REAL_PTR"; return REAL_PTR; }
"if" { yylval.string = "IF"; return IF; }
"else" { yylval.string = "ELSE"; return ELSE; }
"while" { yylval.string = "WHILE"; return WHILE; }
"for" { yylval.string = "FOR"; return FOR; }
"var" { yylval.string = "VAR"; return VAR; }
"return" { yylval.string = "RET"; return RET; }
"null" { yylval.string = "NULL"; return NULL_PTR; }
"void" { yylval.string = "VOID"; return VOID; }
"do" { yylval.string = "DO"; return DO; }

"&&" { yylval.string = "&&"; return AND; }
"/" { yylval.string = "/"; return DIV; }
"=" { yylval.string = "="; return ASS; }
"==" { yylval.string = "=="; return EQ; }
">" { yylval.string = ">"; return BIGGER; }
">=" { yylval.string = ">="; return BIGGER_EQ; }
"<" { yylval.string = "<"; return SMALLER; }
"<=" { yylval.string = "<="; return SMALLER_EQ; }
"-" { yylval.string = "-"; return MINUS; }
"!" { yylval.string = "!"; return NOT; }
"!=" { yylval.string = "!="; return NOT_EQ; }
"||" { yylval.string = "||"; return OR; }
"+" { yylval.string = "+"; return PLUS; }
"*" { yylval.string = "*"; return MUL; }
"&" { yylval.string = "REF"; return REF; }

";" { yylval.string = ";"; return SEMC; }
"," { yylval.string = ","; return COMMA; }
"|" { yylval.string = "LEN"; return LEN; }
"{" { yylval.string = "{"; return S_BLOCK; }
"}" { yylval.string = "}"; return E_BLOCK; }
"(" { yylval.string = "("; return S_BRACK; }
")" { yylval.string = ")"; return E_BRACK; }
"[" { yylval.string = "["; return S_ARR; }
"]" { yylval.string = "]"; return E_ARR; }


"true"|"false" { yylval.string = strdup(yytext); return VAR_BOOL; }
'[^'\n]'|'\\n'|'' { yylval.string = strdup(yytext); return VAR_CHAR; }
(^[-+])?(0|[1-9][0-9]*) { yylval.string = strdup(yytext); return VAR_INT_DEC; }
(^[-+])?(0[xX][0-9A-F]+) { yylval.string = strdup(yytext); return VAR_INT_HEX; }
(^[-+])?([1-9][0-9]*)?([0\.]|[\.])?(0|[1-9][0-9]*)?([eE][-+]?)?[0-9]* { yylval.string = strdup(yytext); return VAR_REAL; }
\"[^\"\n]*\" { yylval.string = strdup(yytext); return VAR_STRING; }
[a-zA-Z]+[0-9_a-zA-Z]* { yylval.string = strdup(yytext); return ID; }


"\n" { ++yylineno; }
[ \t\r] { ; }
"/*" { BEGIN(COMMENT); }
<COMMENT>"*/" { BEGIN(INITIAL); }
<COMMENT>\n { ++yylineno; }
<COMMENT>. { yylval.string = strdup(yytext); }


%%
