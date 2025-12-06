%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int line_num;
extern FILE *yyin;

void yyerror(const char *s);

typedef struct {
    char *name;
    char *type;
    union {
        int ival;
        float fval;
        char *sval;
    } value;
} Symbol;

Symbol symbol_table[100];
int symbol_count = 0;

Symbol* lookup_symbol(char *name);
void add_symbol(char *name, char *type);
void set_symbol_value(char *name, int ival, float fval, char *sval);
%}

%union {
    int ival;
    float fval;
    char *str;
}

%token <str> IDENTIFIER STRING_LITERAL
%token <ival> INT_LITERAL
%token <fval> FLOAT_LITERAL
%token VAR NUMBER DECIMAL TEXT INPUT OUTPUT
%token ASSIGN PLUS MINUS MULTIPLY DIVIDE
%token LPAREN RPAREN SEMICOLON COMMA

%type <ival> expression
%type <fval> float_expression

%left PLUS MINUS
%left MULTIPLY DIVIDE

%%

program:
    statements
    ;

statements:
      statement
    | statements statement
    ;

statement:
      declaration SEMICOLON
    | assignment SEMICOLON
    | input_stmt SEMICOLON
    | output_stmt SEMICOLON
    | SEMICOLON
    ;

declaration:
      VAR NUMBER IDENTIFIER
        { add_symbol($3,"number"); printf("Declared number variable: %s\n",$3); }
    | VAR DECIMAL IDENTIFIER
        { add_symbol($3,"decimal"); printf("Declared decimal variable: %s\n",$3); }
    | VAR TEXT IDENTIFIER
        { add_symbol($3,"text"); printf("Declared text variable: %s\n",$3); }
    | VAR NUMBER IDENTIFIER ASSIGN expression
        { add_symbol($3,"number"); set_symbol_value($3,$5,0,NULL);
          printf("Assigned %s = %d\n",$3,$5); }
    | VAR DECIMAL IDENTIFIER ASSIGN float_expression
        { add_symbol($3,"decimal"); set_symbol_value($3,0,$5,NULL);
          printf("Assigned %s = %.2f\n",$3,$5); }
    | VAR TEXT IDENTIFIER ASSIGN STRING_LITERAL
        { add_symbol($3,"text"); set_symbol_value($3,0,0,$5);
          printf("Assigned %s = \"%s\"\n",$3,$5); }
    ;

assignment:
      IDENTIFIER ASSIGN expression
        { Symbol *s=lookup_symbol($1);
          if(s){ set_symbol_value($1,$3,0,NULL); printf("Assigned %s = %d\n",$1,$3); }
          else yyerror("Variable not declared"); }
    | IDENTIFIER ASSIGN float_expression
        { Symbol *s=lookup_symbol($1);
          if(s){ set_symbol_value($1,0,$3,NULL); printf("Assigned %s = %.2f\n",$1,$3); }
          else yyerror("Variable not declared"); }
    | IDENTIFIER ASSIGN STRING_LITERAL
        { Symbol *s=lookup_symbol($1);
          if(s){ set_symbol_value($1,0,0,$3); printf("Assigned %s = \"%s\"\n",$1,$3); }
          else yyerror("Variable not declared"); }
    ;

input_stmt:
    INPUT IDENTIFIER {
        Symbol *s = lookup_symbol($2);
        if(s){
            if(strcmp(s->type,"number")==0) scanf("%d",&s->value.ival);
            else if(strcmp(s->type,"decimal")==0) scanf("%f",&s->value.fval);
            else if(strcmp(s->type,"text")==0){
                char buf[256]; scanf("%s",buf); s->value.sval=strdup(buf);
            }
        } else yyerror("Variable not declared");
    }
    ;

output_stmt:
      OUTPUT output_list { printf("\n"); }
    | OUTPUT LPAREN output_list RPAREN { printf("\n"); }
    ;

output_list:
      output_item
    | output_list COMMA output_item
    ;

output_item:
      expression { printf("%d ", $1); }
    | FLOAT_LITERAL { printf("%.2f ", $1); }
    | STRING_LITERAL { printf("%s ", $1); }
    | IDENTIFIER {
        Symbol *s = lookup_symbol($1);
        if(!s) yyerror("Variable not declared");
        else if(strcmp(s->type,"number")==0) printf("%d ", s->value.ival);
        else if(strcmp(s->type,"decimal")==0) printf("%.2f ", s->value.fval);
        else printf("%s ", s->value.sval);
    }
    ;

expression:
      INT_LITERAL                 { $$ = $1; }
    | IDENTIFIER
        { Symbol *s=lookup_symbol($1); $$ = (s && strcmp(s->type,"number")==0) ? s->value.ival : 0; }
    | expression PLUS expression      { $$ = $1 + $3; }
    | expression MINUS expression     { $$ = $1 - $3; }
    | expression MULTIPLY expression  { $$ = $1 * $3; }
    | expression DIVIDE expression
        { if($3==0){ yyerror("Division by zero"); $$=0;} else $$=$1/$3; }
    | LPAREN expression RPAREN        { $$=$2; }
    ;

float_expression:
      FLOAT_LITERAL  { $$ = $1; }
    | INT_LITERAL    { $$ = (float)$1; }
    ;

%%

void yyerror(const char *s){ fprintf(stderr,"Error at line %d: %s\n",line_num,s); }

Symbol* lookup_symbol(char *name){
    for(int i=0;i<symbol_count;i++)
        if(strcmp(symbol_table[i].name,name)==0) return &symbol_table[i];
    return NULL;
}

void add_symbol(char *name,char *type){
    if(lookup_symbol(name)!=NULL){ yyerror("Variable already declared"); return; }
    symbol_table[symbol_count].name=strdup(name);
    symbol_table[symbol_count].type=strdup(type);
    symbol_count++;
}

void set_symbol_value(char *name,int ival,float fval,char *sval){
    Symbol *s=lookup_symbol(name);
    if(s){
        if(strcmp(s->type,"number")==0) s->value.ival=ival;
        else if(strcmp(s->type,"decimal")==0) s->value.fval=fval;
        else if(strcmp(s->type,"text")==0) s->value.sval=strdup(sval);
    }
}

int main(int argc,char **argv){
    if(argc>1){
        FILE *f=fopen(argv[1],"r");
        if(!f){ perror("File"); return 1; }
        yyin=f;
    }
    printf("=== Aura Language Compiler ===\nStarting compilation...\n\n");
    yyparse();
    printf("\n=== Compilation Complete ===\nSymbol Table:\n");
    for(int i=0;i<symbol_count;i++)
        printf("  %s (%s)\n", symbol_table[i].name, symbol_table[i].type);
    return 0;
}
