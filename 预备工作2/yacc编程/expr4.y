%{
/*********************************************
在第二步要求的基础上，实现功能更强的词法分析和语法分析程序，使
之能支持变量，修改词法分析程序，能识别变量（标识符）和 “=” 符号，修
改语法分析器，使之能分析、翻译 “a=2” 形式的（或更复杂的，“a= 表达
式”）赋值语句，当变量出现在表达式中时，能正确获取其值进行计算（未
赋值的变量取 0）。当然，这些都需要实现符号表功能。
**********************************************/
#include<stdio.h>
#include<stdlib.h>
#include<ctype.h>
#include<string.h>
#ifndef YYSTYPE
#define YYSTYPE double
#endif

int yylex();
extern int yyparse();
FILE* yyin;
void yyerror(const char* s);

struct if_struct{
    char id_name[50];
    double id_value;
}id;

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
%token ASSIGN

%right ASSIGN
%left ADD MINUS
%left MULTIPLY DIVIDE
%right UMINUS         

%%


lines   :       lines expr ';' { printf("%f\n", $2); }
        |       lines ';'
        |
        ;

expr    :       expr ADD expr   { $$=$1+$3; }
        |       expr MINUS expr   { $$=$1-$3; }
        |       expr MULTIPLY expr   { $$=$1*$3; }
        |       expr DIVIDE expr   { $$=$1/$3; }
        |       LB expr RB      { $$=$2;}
        |       MINUS expr %prec UMINUS   {$$=-$2;}
        |       NUMBER  {$$=$1;}
        |       ID  {$$=id.id_value;}
        |       ID ASSIGN expr  {
                                    $$=$3;
                                    id.id_value=$3;
                                }
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
            yylval=0;
            while((t>='0'&&t<='9')){
                yylval=yylval*10+t-'0';
                t=getchar();
            }
            ungetc(t,stdin);
            return NUMBER;
        }else if((t>='a'&&t<='z')||(t>='A'&&t<='Z')||(t=='_')){
            int ti=0;
            while((t>='a'&&t<='z')||(t>='A'&&t<='Z')||(t=='_')||(t>='0'&&t<='9')){
                id.id_name[ti]=t;
                ti++;
                t=getchar();
            }
           id.id_name[ti]='\0';
            ungetc(t,stdin);
            return ID;
        }else if(t=='='){
            return ASSIGN;
        }else if(t=='+'){
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