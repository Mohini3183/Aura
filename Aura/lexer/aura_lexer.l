%{
#include "../parser/aura_parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int line_num = 1;
%}

%option noyywrap

DIGIT    [0-9]
LETTER   [a-zA-Z_]
ID       {LETTER}({LETTER}|{DIGIT})*
INTEGER  {DIGIT}+
FLOAT    {DIGIT}+\.{DIGIT}+
STRING   \"([^\\\"]|\\.)*\"

%%

~#[^\n]*        { }

~\*([^*]|\*+[^*~])*\*~ {
    char *p = yytext;
    while (*p) { if (*p=='\n') line_num++; p++; }
}

"var"         { return VAR; }
"number"      { return NUMBER; }
"decimal"     { return DECIMAL; }
"text"        { return TEXT; }
"input"       { return INPUT; }
"output"      { return OUTPUT; }

{ID}          { yylval.str = strdup(yytext); return IDENTIFIER; }
{INTEGER}     { yylval.ival = atoi(yytext); return INT_LITERAL; }
{FLOAT}       { yylval.fval = atof(yytext); return FLOAT_LITERAL; }

{STRING} {
    int len = strlen(yytext);
    char *str = (char*)malloc(len - 1);
    strncpy(str, yytext + 1, len - 2);
    str[len - 2] = '\0';
    yylval.str = str;
    return STRING_LITERAL;
}

"="           { return ASSIGN; }
"+"           { return PLUS; }
"-"           { return MINUS; }
"*"           { return MULTIPLY; }
"/"           { return DIVIDE; }
"("           { return LPAREN; }
")"           { return RPAREN; }
";"           { return SEMICOLON; }
","           { return COMMA; }

[ \t]+        { }
\r            { }
\n            { line_num++; }

.             { printf("Unexpected character: %s at line %d\n", yytext, line_num); }

%%
