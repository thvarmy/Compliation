%option noyywrap
%option nounput
%option noinput
%top{
    #include <stdarg.h>
    #include "common.h"
    #include "parser.h"
}
%{
    extern dump_type_t dump_type;

    inline void dump_tokens(const char* format, ...){
        va_list args;
        va_start(args, format);
        if (dump_type == TOKENS)
            vfprintf(yyout, format, args);
        va_end(args);
    }

    /* Your code here, if desired (lab3). */
%}

/* definitions section */

/*十进制*/
DECIMIAL ([1-9][0-9]*|0)
/*八进制*/
OCTAL 0[0-7]+
/*十六进制*/
HEX 0[xX][0-9a-fA-F]+
/*浮点型常量*/
FLOAT ([0-9]+[.][0-9]*|[.][0-9]+)([eE][-+]?[0-9]+)?



ID [[:alpha:]_][[:alpha:][:digit:]_]*
EOL (\r\n|\n|\r)
WHITE [\t ]
/*  Your code here (lab3). */
%x BLOCKCOMMENT            
 //块注释    
BLOCKCOMMENTBEGIN "/*"           
 //通配符+换行
BLOCKCOMMENTELEMENT .|\n         
BLOCKCOMMENTEND "*/" 
 //行注释：以双斜杠开头，后跟若干个非换行的字符
LINECOMMENT \/\/[^\n]*



%%
    /* rules section */
"int" {
    dump_tokens("INT\t%s\n", yytext);
    return INT;
}

"void" {
    dump_tokens("VOID\t%s\n", yytext);
    return VOID;
}
"float" {
    dump_tokens("FLOAT\t%s\n", yytext);
    return FLOAT;
}
"if" {
    dump_tokens("IF\t%s\n", yytext);
    return IF;
}

"else" {
    dump_tokens("ELSE\t%s\n", yytext);
    return ELSE;
}
"while" {
    dump_tokens("WHILE\t%s\n", yytext);
    return WHILE;
}
"break" {
    dump_tokens("BREAK\t%s\n", yytext);
    return BREAK;
}
"continue" {
    dump_tokens("CONTINUE\t%s\n", yytext);
    return CONTINUE;
}
"const" {
    dump_tokens("CONST\t%s\n", yytext);
    return CONST;
}

"return" {
    dump_tokens("RETURN\t%s\n", yytext);
    return RETURN;
}

"=" {
    dump_tokens("ASSIGN\t%s\n", yytext);
    return ASSIGN;
}

"<" {
    dump_tokens("LESS\t%s\n", yytext);
    return LESS;
}
">" {
    dump_tokens("GREATER\t%s\n", yytext);
    return GREATER;
}
"==" {
    dump_tokens("EQUAL\t%s\n", yytext);
    return EQUAL;
}
"!=" {
    dump_tokens("NOTEQUAL\t%s\n", yytext);
    return NOTEQUAL;
}
"<=" {
    dump_tokens("LESSEQUAL\t%s\n", yytext);
    return LESSEQUAL;
}
">=" {
    dump_tokens("GREATEREQUAL\t%s\n", yytext);
    return GREATEREQUAL;
}

"+" {
    dump_tokens("ADD\t%s\n", yytext);
    return ADD;
}
"-" {
    dump_tokens("SUB\t%s\n", yytext);
    return SUB;
}

"*" {
    dump_tokens("MUL\t%s\n", yytext);
    return MUL;
}

"/" {
    dump_tokens("DIV\t%s\n", yytext);
    return DIV;
}

"%" {
    dump_tokens("MOD\t%s\n", yytext);
    return MOD;
}

"&&" {
    dump_tokens("AND\t%s\n", yytext);
    return AND;
}

"||" {
    dump_tokens("OR\t%s\n", yytext);
    return OR;
}

"!" {
    dump_tokens("NOT\t%s\n", yytext);
    return NOT;
}

";" {
    dump_tokens("SEMICOLON\t%s\n", yytext);
    return SEMICOLON;
}

"(" {
    dump_tokens("LPAREN\t%s\n", yytext);
    return LPAREN;
}

")" {
    dump_tokens("RPAREN\t%s\n", yytext);
    return RPAREN;
}

"{" {
    dump_tokens("LBRACE\t%s\n", yytext);
    return LBRACE;
}

"}" {
    dump_tokens("RBRACE\t%s\n", yytext);
    return RBRACE;
}
"[" {
    dump_tokens("LBRACKET\t%s\n", yytext);
    return LBRACKET;
}

"]" {
    dump_tokens("RBRACKET\t%s\n", yytext);
    return RBRACKET;
}

"," {
    dump_tokens("COMMA\t%s\n", yytext);
    return COMMA;
}

{DECIMIAL} {
    int decimal;
    decimal = atoi(yytext);
    dump_tokens("DECIMAL\t%s\t%d\n", yytext, decimal);
    yylval.itype = decimal;
    return INTEGER;
}
{OCTAL} {
    int decimal = strtol(yytext + 1, NULL, 8);
    dump_tokens("OCTAL\t%s\t%d\n", yytext, decimal);
    yylval.itype = decimal;
    return INTEGER;
}
{HEX} {
    int decimal = strtol(yytext + 2, NULL, 16);
    dump_tokens("HEX\t%s\t%d\n", yytext, decimal);
    yylval.itype = decimal;
    return INTEGER;
}
{FLOAT} {
    float floatValue = strtof(yytext, NULL);
    dump_tokens("FLOAT\t%s\t%f\n", yytext, floatValue);
    yylval.ftype = floatValue;
    return FLOATYPE;
}
{ID} {
    char *lexeme;
    dump_tokens("ID\t%s\n", yytext);
    lexeme = new char[strlen(yytext) + 1];
    strcpy(lexeme, yytext);
    
    yylval.strtype = lexeme;
    return ID;
}

{EOL} yylineno++;

{WHITE}

    /*  Your code here (lab3). */
{LINECOMMENT} {}   //处理注释，使用定义好的独占状态BLOCKCOMMENT
{BLOCKCOMMENTBEGIN} {BEGIN BLOCKCOMMENT;}
<BLOCKCOMMENT>{BLOCKCOMMENTELEMENT} {}
<BLOCKCOMMENT>{BLOCKCOMMENTEND} {BEGIN INITIAL;} //使用宏BEGIN来切换状态，初始状态默认为INITIAL


%%
/* user code section */