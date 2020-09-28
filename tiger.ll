%option noyywrap
%option c++

%{
/* Name: Paul Myers
   Due Date: 09/21/2020
   Class: CSCI 4160
   Project: 2 
   Description: Scanner Using Flex and Lexical Analysis
*/

#include <iostream>
#include <string>
#include <sstream>
#include "tokens.h"
#include "ErrorMsg.h"

using std::string;
using std::stringstream;


ErrorMsg			errormsg;	//error handler

int		comment_depth = 0;	// depth of the nested comment
string	value = "";			// the value of current string
int		x=0, y=0;			// The beginning position for comments

int			beginLine=-1;	//beginning line no of a string or comment
int			beginCol=-1;	//beginning column no of a string or comment

int		linenum = 1;		//beginning line no of the current matched token
int		colnum = 1;			//beginning column no of the current matched token
int		tokenCol = 1;		//column no after the current matched token

//the following defines actions that will be taken automatically after 
//each token match. It is used to update colnum and tokenCol automatically.
#define YY_USER_ACTION {colnum = tokenCol; tokenCol=colnum+yyleng;}

int string2int(string);			//convert a string to integer value
void newline(void);				//trace the line #
void error(int, int, string);	//output the error message referring to the current token
%}

ALPHA				[A-Za-z]
DIGIT				[0-9]
INT					[0-9]+
IDENTIFIER			{ALPHA}(({ALPHA}|{DIGIT}|"_")*)

%x	COMMENT
%x	STR

%%  
" "						{}	// PUNCTUATION & CHARACTER SYMBOLS: Whitespace 
\t						{}	// Tab character   
\b						{}	// Backspace character   
\n						{newline(); }	// newline character 

","						{ return COMMA; }	// Comma
":"						{ return COLON; }	// Colon 
";"						{ return SEMICOLON; }	// Semi colon
"("						{ return LPAREN; }	// Left Parenthesis
")"						{ return RPAREN; }	// Right Paranthesis 
"["						{ return LBRACK; }	// Left bracket 
"]"						{ return RBRACK; }	// Right bracket 
"{"						{ return LBRACE; }	// Left brace 
"}"						{ return RBRACE; }	// Right brace 
"."						{ return DOT; }		// Dot
"+"						{ return PLUS; }	// Plus sign
"-"						{ return MINUS; }	// Minus sign 
"*"						{ return TIMES; }	// Multiplication sign 
"/"						{ return DIVIDE; }	// Division sign
"="						{ return EQ; }		// Equal sign
"<>"					{ return NEQ; }		// Unequal sign
"<" 					{ return LT; }	 // Less than  
"<="					{ return LE; }	 // Less or Equal to  
">" 					{ return GT; }	 // Greater than 
">="					{ return GE; }	 // Greater or Equal to
"&"						{ return AND; }		// AND 
"|"						{ return OR; }		// OR 
":="					{ return ASSIGN; }	// Assignment 
"array"					{ return ARRAY; }	// Array call
"if"					{ return IF; }		// If statement 
"then"					{ return THEN; }	// Then clause
"else"					{ return ELSE; }	// Else clause
"while"					{ return WHILE; }	// while loop 
"for"					{ return FOR; }		// for loop 
"to"					{ return TO; }		// to statement 
"do"					{ return DO; }		// do statement 
"let"					{ return LET; }		// let statement 
"in"					{ return IN; }		// in statement 
"end"					{ return END; }		// end statement
"of"					{ return OF; }		// of statement 
"break"					{ return BREAK; }	// break statement 
"nil"					{ return NIL; }		// nil statement 
"function"				{ return FUNCTION;} // function call 
"var"					{ return VAR; }		// variable declaration
"type"					{ return TYPE; }	// Type set 
		
"/*"					{	comment_depth++;		// Start of comment
							x = linenum;			// Set x and y variables
							y = colnum;
							BEGIN(COMMENT);			// Begin the comment
						}

<COMMENT>"/*"			{
							comment_depth++;	// Increase the depth by 1 to keep track of the depth of the comment
						}

<COMMENT>[^*/\n]*		{/* ignore everything that's not '*' */}

<COMMENT>"/"+[^/*\n]*	{/* ignore everything that's not '*' */}

<COMMENT>"*"+[^*/\n]*	{/* keep ignoring if '*' is not followed by a '/' */}

<COMMENT>\n				{
							newline();	// Call newline to follow comment
						}

<COMMENT>"*"+"/"		{
							comment_depth--;		//subtract depth to see if you are still in a comment
							if(comment_depth == 0)
							{
								BEGIN(INITIAL);	//you are out of the comment block and can continue
							}
						}

<COMMENT><<EOF>>		{
							error(x, y, "unclosed comments");	// Comment is unclosed
							yyterminate();						// Throw ERROR and CLOSE file
						}

"\""					{
							value = "";		// Start of a string is being recognized
							beginLine = linenum;	// Set begin line/col values
							beginCol = colnum;
							BEGIN(STR);
						}

<STR>[^"\n\t\\]*		{
							value = value + YYText();	//avoid concatenating with end of string
						}

<STR>\\n				{
							value = value + "\n"; // add a new line to the string
						}

<STR>\\t				{
							value = value + "\t"; // add a tab to the string
						}

<STR>\\\"				{
							value = value + "\""; // add backslash to string 
						}

<STR>\\\\				{
							value = value + "\\"; // add backslash to string 
						}

<STR>"\""				{
							yylval.sval = new string(value);	// End of string
							BEGIN(INITIAL);						// finish string
							return STRING;						// return string 
						}

<STR>\n					{
							error(beginLine, beginCol, "unclosed string");		// Unclosed string with illegal escape 
							yylval.sval = new string(value);	// Store string for return
							newline();							// Call newline to continue
							BEGIN(INITIAL);						// Begin initial again
							return(STRING);						// Return the stored string
						}

<STR><<EOF>>			{
							error(linenum, colnum, "unclosed string");	// Error: string wasn't closed
							yyterminate();								// End file
						}

<STR>\\[^"nt\\]			{
							string line = YYText();						// Check for illegal tokens
							error(linenum, colnum, line + " illegal token");	// Error: token was illegal
						}

{IDENTIFIER} 	{ value = YYText(); yylval.sval = new string(value); return ID; } 
{INT}		 	{ yylval.ival = string2int(YYText()); return INT; } 

<<EOF>>			{	yyterminate(); }	// File end, exit...
.				{	error(linenum, colnum, string(YYText()) + " illegal token");}
%%

int string2int( string val )
{
	stringstream	ss(val);
	int				retval;

	ss >> retval;

	return retval;
}

void newline()
{
	linenum ++;
	colnum = 1;
	tokenCol = 1;
}

void error(int line, int col, string msg)
{
	errormsg.error(line, col, msg);
}
