/*	TEAM MEMBERS: Kiran Patel, Paul Myers, Dakota Myers
	INSTRUCTOR: Dr. Dong
	COURSE: CSCI 4160-001
	PROJECT: 3
	DUE DATE: 09/30/2020

	DESCRIPTION: This file constructs the CFG.
 */

%debug
%verbose	/*generate file: tiger.output to check grammar*/
%{
#include <iostream>
#include "ErrorMsg.h"
#include <FlexLexer.h>

int yylex(void);		/* function prototype */
void yyerror(char *s);	//called by the parser whenever an eror occurs
int count = 0;

%}

%union {
	int		ival;	//integer value of INT token
	string* sval;	//pointer to name of IDENTIFIER or value of STRING	
					//I have to use pointers since C++ does not support 
					//string object as the union member
}

/* TOKENs and their associated data type */
%token <sval> ID STRING
%token <ival> INT

%token 
  COMMA COLON SEMICOLON DOT 
  IF THEN ELSE WHILE FOR TO DO LET IN END OF 
  BREAK NIL AND ASSIGN EQ GE GT LE LT NEQ OR
  FUNCTION VAR TYPE 


/* add your own predence level of operators here */ 
%left PLUS MINUS
%left TIMES DIVIDE
%left UMINUS
%right POWER

%token NEWLINE LPAREN RPAREN
%token <ival> NUMBER
%type <ival> exp 


%start input

%%

/* This is a skeleton grammar file, meant to illustrate what kind of
 * declarations are necessary above the %% mark.  Students are expected
 *  to replace the two dummy productions below with an actual grammar. 
 */

input	:	/* empty */
		|	input line	
		;

line	:	NEWLINE
		|	exp NEWLINE	{ count = 0; }
		|	error NEWLINE
		;

exp		:	STRING					/* String */
		|	INT						/* integer */
		|	NUMBER					/* NUMBER */
		|	NIL						/* Nill */		
		|	lvalue
		
		/* Boolean Operation */
		|	exp AND exp				/* And Operation */
		|	exp OR exp				/* Or Operation */
		|	exp GE exp				/* Greater than equal */
		|	exp LE exp				/* Less than equal */
		|	exp EQ 					/* equal */
		|	exp NEQ exp				/* Not equal */
		|	exp GT exp				/* Greater than */
		|	exp LT exp				/* Less than */
		
		/* Arithmatic Operation */
		|	exp PLUS exp			/* '+' Operation */
		|	exp MINUS exp			/* '-' Operation */
		|	exp TIMES exp			/* '*' Operation */
		|	exp DIVIDE exp			/* '/' Operation */

		/* exponentiation */
		|	exp POWER exp

		|	LPAREN exp RPAREN

		/* Unary minus */
		|	MINUS exp %prec UMINUS

		|	lvalue ASSIGN exp
		|	ID LPAREN expList RPAREN
		|	LPAREN exprseq RPAREN

		/* if else expression */
		|	IF exp THEN exp
		|	IF exp THEN exp ELSE exp

		/* while loop */
		|	WHILE exp DO exp

		/* for loop */
		|	FOR ID ASSIGN exp TO exp DO exp
		|	BREAK
		|	LET declarationlist IN exprseq END
		|	error
		;

/**************** Recursive rules ****************/

/** Semicolon **/
/** define a expression sequence using semicolon **/
exprseq:	exp
		|	exprseq SEMICOLON exp
		;

/** Comma **/
/** define a comma-separated sequence of zero or more exp groupings **/
expList:
		|	exp
		|	expList COMMA exp
		;

fieldlist:
		 |	ID EQ exp
		 | fieldlist COMMA ID EQ exp

lvalue	:	ID
		|	lvalue DOT ID
		;


declaration :	typedeclaration
			|	variabledeclaration
			|	functiondeclaration
			;

/*Recursive declaration list rule*/
declarationlist:	declaration
				|	declarationlist declaration
				|	error
				;

typedeclaration:	TYPE typeid EQ type

type:	typeid
	|	typefields
	;

typefields:	
			|	typefield
			|	typefields COMMA typefield
			;

typefield:	ID COLON typeid
		;

typeid	:	INT
		|	STRING
		|	ID
		;

/* variable declaration */
variabledeclaration	:	VAR ID ASSIGN exp
					|	VAR ID COLON typeid ASSIGN exp
					;

/* function declaration */
functiondeclaration:	FUNCTION ID LPAREN typefields RPAREN EQ exp
					|	FUNCTION ID LPAREN typefields RPAREN COLON typeid EQ exp
					;

input	:	exp


%%
extern yyFlexLexer	lexer;
int yylex(void)
{
	return lexer.yylex();
}

void yyerror(char *s)
{
	extern int	linenum;			//line no of current matched token
	extern int	colnum;
	extern void error(int, int, std::string);

	error(linenum, colnum, s);
}

