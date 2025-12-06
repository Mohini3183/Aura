all: aura

# Compile everything
aura: parser/aura_parser.tab.c lexer/lex.yy.c
	gcc -Wall -g -o aura parser/aura_parser.tab.c lexer/lex.yy.c -lfl

# Bison generates parser .c and .h
parser/aura_parser.tab.c parser/aura_parser.tab.h: parser/aura_parser.y
	bison -d -o parser/aura_parser.tab.c parser/aura_parser.y

# Flex generates lexer .c, must depend on Bison header
lexer/lex.yy.c: lexer/aura_lexer.l parser/aura_parser.tab.h
	flex -o lexer/lex.yy.c lexer/aura_lexer.l

clean:
	rm -f aura parser/aura_parser.tab.c parser/aura_parser.tab.h lexer/lex.yy.c
