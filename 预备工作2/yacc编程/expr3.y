%{
/*********************************************
修改yacc程序，不进行表达式的计算，而是实现中缀转后缀表达式
**********************************************/
#include<stdio.h>
#include<stdlib.h>
#include<ctype.h>
#include<string.h>
#ifndef YYSTYPE
#define YYSTYPE char*//将YYSTYPE改为char*
#endif
char idstr[50];
char numstr[50];
int yylex();
extern int yyparse();
FILE* yyin;
void yyerror(const char* s);
%}

//TODO:给每个符号定义一个单词类别
%token ADD 
%token MINUS
%token MULTIPLY
%token DIVIDE
%token LB
%token RB
%token NUMBER
%token ID
%left ADD MINUS
%left MULTIPLY DIVIDE
%right UMINUS         

%%


lines   :       lines expr ';' { printf("%s\n", $2); }
        |       lines ';'
        |
        ;

expr    :       expr ADD expr   { $$=(char*)malloc(50*sizeof(char));strcpy($$,$1);strcat($$,$3);strcat($$,"+ "); }
        |       expr MINUS expr   { $$=(char*)malloc(50*sizeof(char));strcpy($$,$1);strcat($$,$3);strcat($$,"- "); }
        |       expr MULTIPLY expr   { $$=(char*)malloc(50*sizeof(char));strcpy($$,$1);strcat($$,$3);strcat($$,"* "); }
        |       expr DIVIDE expr   { $$=(char*)malloc(50*sizeof(char));strcpy($$,$1);strcat($$,$3);strcat($$,"/ "); }
        |       LB expr RB      { $$=$2;}
        |       MINUS expr %prec UMINUS   {$$=(char*)malloc(50*sizeof(char));strcpy($$,"-");strcat($$,$2);}
        |       NUMBER  {$$=(char*)malloc(50*sizeof(char));strcpy($$,$1);strcat($$," ");}
        |       ID  {$$=(char*)malloc(50*sizeof(char));strcpy($$,$1);strcat($$," ");}
        ;
%%

// programs section

int yylex()
{
    int t;
    while(1){
        t=getchar();
        if(t==' '||t=='\t'||t=='\n'){
            //do noting
        }else if((t>='0'&&t<='9')){//如果t是一个数字
            int ti=0;
            while((t>='0'&&t<='9')){
                numstr[ti]=t;
                ti++;
                t=getchar();
                //ti++;
            }
            numstr[ti]='\0';
            yylval=numstr;
            ungetc(t,stdin);
            return NUMBER;
        }else if((t>='a'&&t<='z')||(t>='A'&&t<='Z')||(t=='_')){
            int ti=0;
            while((t>='a'&&t<='z')||(t>='A'&&t<='Z')||(t=='_')||(t>='0'&&t<='9')){
                idstr[ti]=t;
                ti++;
                t=getchar();
            }
            idstr[ti]='\0';
            yylval=idstr;
            ungetc(t,stdin);
            return ID;
        }
        else if(t=='+'){
            return ADD;
        }else if(t=='-'){
            return MINUS;
        }else if(t=='*'){
            return MULTIPLY;
        }else if(t=='/'){
            return DIVIDE;
        }else if(t=='('){
            return LB;
        }else if(t==')'){
            return RB;
        }
        else{
            return t;
        }
    }
}

int main(void)
{
    yyin=stdin;
    do{
        yyparse();
    }while(!feof(yyin));
    return 0;
}
void yyerror(const char* s){
    fprintf(stderr,"Parse error: %s\n",s);
    exit(1);
}