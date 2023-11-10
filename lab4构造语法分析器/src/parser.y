// 使用子结点构造父节点，从而构造出整个AST
%code top{
    #include <iostream>
    #include <assert.h>
    #include "parser.h"
    extern Ast ast;
    int yylex();
    int yyerror( char const * );
    Type* currentType;
}

%code requires {
    #include "Ast.h"
    #include "SymbolTable.h"
    #include "Type.h"
}

//属性值可能的取值类型
%union {
    int itype;
    float ftype;
    char* strtype;
    StmtNode* stmttype;
    ExprNode* exprtype;
    Type* type;
}

%start Program
%token <strtype> ID 
%token <itype> INTEGER
%token <ftype> FLOATYPE
%token IF ELSE WHILE RETURN BREAK CONTINUE
%token INT VOID FLOAT
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON LBRACKET RBRACKET COMMA  
%token ADD SUB MUL DIV MOD OR AND NOT LESS LESSEQUAL GREATER GREATEREQUAL ASSIGN EQUAL NOTEQUAL 
%token CONST

%type <stmttype> Stmts Stmt AssignStmt ExpStmt BlockStmt IfStmt WhileStmt BreakStmt ContinueStmt ReturnStmt
%type <stmttype> DeclStmt ConstDefList ConstDef ConstInitVal VarDefList VarDef VarInitVal FuncDef FuncParams FuncParam FuncRParams
%type <stmttype> ArrConstIndices ArrValIndices ConstInitValList VarInitValList
%type <exprtype> Exp ConstExp AddExp MulExp UnaryExp PrimaryExp LVal Cond LOrExp LAndExp EqExp RelExp
%type <type> Type

%precedence THEN
%precedence ELSE   //让else的优先级更高，即else优先与最近的if匹配
%%

//----------------------------编译单元---------------------------
Program
    : Stmts {
        ast.setRoot($1);
    }
    ;
//----------------------------类型---------------------------

Type
    : INT {
        $$ = TypeSystem::intType;
        currentType = TypeSystem::intType;
    }
    | VOID {
        $$ = TypeSystem::voidType;
        
    }
    | FLOAT{
        $$ = TypeSystem::floatType;
        currentType = TypeSystem::floatType;
    }
    ;

//----------------------------语句---------------------------
Stmts
    : Stmts Stmt{
            SeqNode* node = (SeqNode*)$1;
            node->addNext((StmtNode*)$2);
            $$ = (StmtNode*) node;
    }
    |Stmt{
            SeqNode* node = new SeqNode();
            node->addNext((StmtNode*)$1);
            $$ = (StmtNode*) node;
        }
    ;
Stmt
    : AssignStmt {$$=$1;}
    | BlockStmt {$$=$1;}
    | IfStmt {$$=$1;}
    | WhileStmt {$$=$1;}
    | BreakStmt {$$=$1;}
    | ContinueStmt {$$=$1;}
    | ReturnStmt {$$=$1;}
    | DeclStmt {$$=$1;}
    | FuncDef {$$=$1;}

    | ExpStmt SEMICOLON{$$=$1;}
    | SEMICOLON {$$ = new EmptyStmt();}
    ;

//左值    
LVal
    : ID {
        SymbolEntry *se;
        //identifiers为一个SymbolTable*类型的外部变量
        //寻找当前域中是否有这个标识符，并返回表项指针，若没有，则语法有问题，报错
        se = identifiers->lookup($1);
        if(se == nullptr)
        {
            // 如果找不到报错
            fprintf(stderr, "identifier \"%s\" is undefined\n", (char*)$1);
            delete [](char*)$1;
            assert(se != nullptr);
        }
        //new了一个ID类的结点，这个类继承自ExprNode
        $$ = new Id(se);
        delete []$1;
    }
    |ID ArrValIndices {//数组左值
            SymbolEntry *se;
            se = identifiers->lookup($1);
            if(se == nullptr)
            {
                fprintf(stderr, "identifier \"%s\" is undefined\n", (char*)$1);
                delete [](char*)$1;
                assert(se != nullptr);
            }
            Id* newId = new Id(se);
            newId->addIndices((ExprStmtNode*)$2);
            $$ =  newId;
            delete []$1;
        }
    ;
// 赋值语句
AssignStmt
    :
    LVal ASSIGN Exp SEMICOLON {
        $$ = new AssignStmt($1, $3);
    }
    ;
// 表达式语句
ExpStmt
    :   ExpStmt COMMA Exp {
            ExprStmtNode* node = (ExprStmtNode*)$1;
            node->addNext($3);
            $$ = node;
        }
    |   Exp {
            ExprStmtNode* node = new ExprStmtNode();
            node->addNext($1);
            $$ = node;
        }
    ;
//语句块
BlockStmt  
    :   LBRACE 
        //每一个块{}都新建一个符号表来保存当前标识符,原有的符号表会由现在符号表的pre指针指向
        {identifiers = new SymbolTable(identifiers);} 
        Stmts RBRACE 
        {
            //每一个{}的作用域里面都是一个复合语句-此处为抽象的非终结符Stmts
            $$ = new CompoundStmt($3);
            //遇到}，当前的块语句结束，删除top符号表
            SymbolTable *top = identifiers;
            identifiers = identifiers->getPrev();
            delete top;
        }
        |LBRACE RBRACE {
            $$ = new CompoundStmt(nullptr);
        }
    ;
//if语句
IfStmt
    //之前已经约定else优先级高于then；产生式的优先级与该产生式最右边的终结符优先级相同
    //%prec THEN的作用是解决悬空-else的二义性问题，他会将终结符THEN的优先级赋给下述产生式
    //这样的话，下述第二个候选式优先级更高（即else优先匹配）
    : IF LPAREN Cond RPAREN Stmt %prec THEN {
        $$ = new IfStmt($3, $5);
    }
    | IF LPAREN Cond RPAREN Stmt ELSE Stmt {
        $$ = new IfElseStmt($3, $5, $7);
    }
    ;
//While语句
WhileStmt  
    : WHILE LPAREN Cond RPAREN Stmt {
        $$ = new WhileStmt($3, $5);
    }
    ;
BreakStmt   //Break语句
    : BREAK SEMICOLON {
        $$ = new BreakStmt();
    }
    ;
ContinueStmt   //Continue语句
    : CONTINUE SEMICOLON {
        $$ = new ContinueStmt();
    }
    ;
ReturnStmt    // 返回语句
    :
    RETURN Exp SEMICOLON{
        $$ = new ReturnStmt($2);
    }
    | RETURN SEMICOLON {
            $$ = new ReturnStmt(nullptr);
        }
    ;

Exp   // 算数表达式
    :
    AddExp {$$ = $1;}
    ;
// 常量表达式
ConstExp
    :   AddExp {
            $$ = $1;
        }
    ;
Cond   // 条件表达式：关系+逻辑运算（补）
    :
    LOrExp {$$ = $1;}
    ;

AddExp  // 加减法(双目算数表达式)
    : MulExp {$$ = $1;}
    | AddExp ADD MulExp
    {
        SymbolEntry *se;
            if($1->getType()->isInt() && $3->getType()->isInt()){
                se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            }
            else{
                se = new TemporarySymbolEntry(TypeSystem::floatType, SymbolTable::getLabel());
            }
            $$ = new BinaryExpr(se, BinaryExpr::ADD, $1, $3);
    }
    | AddExp SUB MulExp
    {
        SymbolEntry *se;
            if($1->getType()->isInt() && $3->getType()->isInt()){
                se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            }
            else{
                se = new TemporarySymbolEntry(TypeSystem::floatType, SymbolTable::getLabel());
            }
            $$ = new BinaryExpr(se, BinaryExpr::SUB, $1, $3);
    }
    ;

MulExp  // 乘法级表达式
    : UnaryExp {$$ = $1;}
    | MulExp MUL UnaryExp {
        SymbolEntry *se;
            if($1->getType()->isInt() && $3->getType()->isInt()){
                se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            }
            else{
                se = new TemporarySymbolEntry(TypeSystem::floatType, SymbolTable::getLabel());
            }
            $$ = new BinaryExpr(se, BinaryExpr::MUL, $1, $3);
    }
    | MulExp DIV UnaryExp {
        SymbolEntry *se;
            if($1->getType()->isInt() && $3->getType()->isInt()){
                se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            }
            else{
                se = new TemporarySymbolEntry(TypeSystem::floatType, SymbolTable::getLabel());
            }
            $$ = new BinaryExpr(se, BinaryExpr::DIV, $1, $3);
    }
    | MulExp MOD UnaryExp {
        SymbolEntry *se;
            if($1->getType()->isInt() && $3->getType()->isInt()){
                se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            }
            else{
                se = new TemporarySymbolEntry(TypeSystem::floatType, SymbolTable::getLabel());
            }
            $$ = new BinaryExpr(se, BinaryExpr::MOD, $1, $3);
    }
    ;

UnaryExp  //单目运算(双目算数表达式)
    :
    PrimaryExp {$$ = $1;}
    |ID LPAREN FuncRParams RPAREN {
            SymbolEntry *se;
            se = identifiers->lookup($1);
            if(se == nullptr)
            {
                fprintf(stderr, "identifier \"%s\" is undefined\n", (char*)$1);
                delete [](char*)$1;
                assert(se != nullptr);
            }
            SymbolEntry *tmp = new TemporarySymbolEntry(se->getType(), SymbolTable::getLabel());
            $$ = new FuncCallNode(tmp, new Id(se), (FuncCallParamsNode*)$3);
        }
    |
    ADD UnaryExp  //'+'号
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new UnaryExpr(se, UnaryExpr::ADD, $2);
    }
    |
    SUB UnaryExp  //'-'号
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new UnaryExpr(se, UnaryExpr::SUB, $2);
    }
    |
    NOT UnaryExp  //'!'号
    {
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new UnaryExpr(se, UnaryExpr::NOT, $2);
    }
    ;
// 原始表达式  基本数字/ID
PrimaryExp
    :   LVal {
            $$ = $1;
        }
    |   LPAREN Exp RPAREN {
            $$ = $2;
        }
    |   INTEGER {
            SymbolEntry *se = new ConstantSymbolEntry(TypeSystem::intType, $1);
            $$ = new Constant(se);
        }
    |   FLOATYPE {
            SymbolEntry *se = new ConstantSymbolEntry(TypeSystem::floatType, $1);
            $$ = new Constant(se);
        }
    ;
// 函数参数列表
FuncRParams
    :   FuncRParams COMMA Exp {
            FuncCallParamsNode* node = (FuncCallParamsNode*) $1;
            node->addNext($3);
            $$ = node;
        }
    |   Exp {
            FuncCallParamsNode* node = new FuncCallParamsNode();
            node->addNext($1);
            $$ = node;
        }
    |   %empty {
            $$ = nullptr;
        }
    ;

// 或运算表达式
LOrExp
    : LAndExp {$$ = $1;}
    | LOrExp OR LAndExp {
        SymbolEntry* se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::OR, $1, $3);
    }
    ;

LAndExp
    : EqExp {$$ = $1;}
    | LAndExp AND EqExp {
        SymbolEntry* se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::AND, $1, $3);
    }
    ;

EqExp
    : RelExp {$$ = $1;}
    | EqExp EQUAL RelExp {
        SymbolEntry* se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::EQUAL, $1, $3);
    }
    | EqExp NOTEQUAL RelExp {
        SymbolEntry* se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::NOTEQUAL, $1, $3);
    }
    ;
// 关系表达式
RelExp
    : AddExp {$$ = $1;}
    | RelExp LESS AddExp {
        SymbolEntry* se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::LESS, $1, $3);
    }
    | RelExp LESSEQUAL AddExp {
        SymbolEntry* se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::LESSEQUAL, $1, $3);
    }
    | RelExp GREATER AddExp {
        SymbolEntry* se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::GREATER, $1, $3);
    }
    | RelExp GREATEREQUAL AddExp {
        SymbolEntry* se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::GREATEREQUAL, $1, $3);
    }
    ;

// 数组的常量下标表示
ArrConstIndices 
    :   ArrConstIndices LBRACKET ConstExp RBRACKET {
            ExprStmtNode* node = (ExprStmtNode*)$1;
            node->addNext($3);
            $$ = node;          
        }
    |   LBRACKET ConstExp RBRACKET {
            ExprStmtNode* node = new ExprStmtNode();
            node->addNext($2);
            $$ = node;
        }
    ;

// 数组的变量下标表示
ArrValIndices 
    :   ArrValIndices LBRACKET Exp RBRACKET {
            ExprStmtNode* node = (ExprStmtNode*)$1;
            node->addNext($3);
            $$ = node;          
        }
    |   LBRACKET Exp RBRACKET {
            ExprStmtNode* node = new ExprStmtNode();
            node->addNext($2);
            $$ = node;
        }
    ;

//----------------------------声明---------------------------
DeclStmt
    :   CONST Type ConstDefList SEMICOLON {//常量声明
            $$ = $3;
        }
    |   Type VarDefList SEMICOLON {//变量声明
            $$ = $2;
        }
    ;
// 常量定义列表
ConstDefList
    :   ConstDefList COMMA ConstDef {
            DeclStmt* node = (DeclStmt*) $1;
            node->addNext((DefNode*)$3);
            $$ = node;
        }
    |   ConstDef {
            DeclStmt* node = new DeclStmt(true);
            node->addNext((DefNode*)$1);
            $$ = node;
        }
    ;

// 常量定义
ConstDef
    :   ID ASSIGN ConstExp {//此处文法有改动
            // 首先将ID插入符号表中
            Type* type;
            if(currentType->isInt()){
                type = TypeSystem::constIntType;
            }
            else{
                type = TypeSystem::constFloatType;
            }
            SymbolEntry *se;
            se = new IdentifierSymbolEntry(type, $1, identifiers->getLevel());
            identifiers->install($1, se);
            $$ = new DefNode(new Id(se), (Node*)$3, true, false);//类型向上转换
        }
    |   ID ArrConstIndices ASSIGN ConstInitVal{ 
            // 首先将ID插入符号表中
            Type* type;
            if(currentType->isInt()){
                type = new ConstIntArrayType();
            }
            else{
                type = new ConstFloatArrayType();
            }
            SymbolEntry *se;
            se = new IdentifierSymbolEntry(type, $1, identifiers->getLevel());
            identifiers->install($1, se);
            Id* id = new Id(se);
            id->addIndices((ExprStmtNode*)$2);
            $$ = new DefNode(id, (Node*)$4, true, true);//类型向上转换
        }//数组常量的定义
    ;

// 常量初始化值
ConstInitVal
    :   ConstExp {//不能直接赋值，否则根本无法判断是list还是expr
            InitValNode* newNode = new InitValNode(true);
            newNode->setLeafNode((ExprNode*)$1);
            $$ = newNode;
        }
    // todo 常量数组的初始化值 
    |   LBRACE ConstInitValList RBRACE{
            $$ = $2;
        }
    |   LBRACE RBRACE{
            $$ = new InitValNode(true);
    }
    ;

// 数组常量初始化列表
ConstInitValList
    :   ConstInitValList COMMA ConstInitVal{
            InitValNode* node = (InitValNode*)$1;
            node->addNext((InitValNode*)$3);
            $$ = node;
        }
    |   ConstInitVal{
            InitValNode* newNode = new InitValNode(true);
            newNode->addNext((InitValNode*)$1);
            $$ = newNode;
        }
    ;

// 变量定义列表
VarDefList
    :   VarDefList COMMA VarDef {
            DeclStmt* node = (DeclStmt*) $1;
            node->addNext((DefNode*)$3);
            $$ = node;
        }
    |   VarDef {
            DeclStmt* node = new DeclStmt(true);
            node->addNext((DefNode*)$1);
            $$ = node;
        }
    ;

// 变量定义
VarDef
    :   ID {
            // 首先将ID插入符号表中
            Type* type;
            if(currentType->isInt()){
                type = TypeSystem::intType;
            }
            else{
                type = TypeSystem::floatType;
            }
            SymbolEntry *se;
            se = new IdentifierSymbolEntry(type, $1, identifiers->getLevel());
            identifiers->install($1, se);
            $$ = new DefNode(new Id(se), nullptr, false, false);
        }
    |   ID ASSIGN Exp {
            // 首先将ID插入符号表中
            Type* type;
            if(currentType->isInt()){
                type = TypeSystem::intType;
            }
            else{
                type = TypeSystem::floatType;
            }
            SymbolEntry *se;
            se = new IdentifierSymbolEntry(type, $1, identifiers->getLevel());
            identifiers->install($1, se);
            $$ = new DefNode(new Id(se), (Node*)$3, false, false);//类型向上转换
        }
    // todo 数组变量的定义
    |   ID ArrConstIndices {
            Type* type;
            if(currentType->isInt()){
                type = new IntArrayType();
            }
            else{
                type = new FloatArrayType();
            }
            SymbolEntry *se;
            se = new IdentifierSymbolEntry(type, $1, identifiers->getLevel());
            identifiers->install($1, se);
            Id* id = new Id(se);
            id->addIndices((ExprStmtNode*)$2);
            $$ = new DefNode(id, nullptr, false, true);//类型向上转换
        }
    |   ID ArrConstIndices ASSIGN VarInitVal{
            Type* type;
            if(currentType->isInt()){
                type = new IntArrayType();
            }
            else{
                type = new FloatArrayType();
            }
            SymbolEntry *se;
            se = new IdentifierSymbolEntry(type, $1, identifiers->getLevel());
            identifiers->install($1, se);
            Id* id = new Id(se);
            id->addIndices((ExprStmtNode*)$2);
            $$ = new DefNode(id, (Node*)$4, false, true);//类型向上转换
        }
    ;

// 变量初始化值
VarInitVal
    :   Exp {
            InitValNode* node = new InitValNode(false);
            node->setLeafNode((ExprNode*)$1);
            $$ = node;
        }
    // todo 数组变量的初始化值
    |   LBRACE VarInitValList RBRACE{
            $$ = $2;
        }
    |   LBRACE RBRACE{
            $$ = new InitValNode(false);
    }
    ; 

// 数组变量初始化列表
VarInitValList
    :   VarInitValList COMMA VarInitVal{
            InitValNode* node = (InitValNode*)$1;
            node->addNext((InitValNode*)$3);
            $$ = node;
        }
    |   VarInitVal{
            InitValNode* newNode = new InitValNode(false);
            newNode->addNext((InitValNode*)$1);
            $$ = newNode;
        }
    ;

// 函数定义
FuncDef
    :   Type ID {
            Type *funcType;
            funcType = new FunctionType($1,{});
            SymbolEntry *se = new IdentifierSymbolEntry(funcType, $2, identifiers->getLevel());
            identifiers->install($2, se);
            identifiers = new SymbolTable(identifiers);
        }
        LPAREN FuncParams{
            SymbolEntry *se;
            se = identifiers->lookup($2);
            assert(se != nullptr);
            if($5!=nullptr){
                //将函数参数类型写入符号表
                ((FunctionType*)(se->getType()))->setparamsType(((FuncDefParamsNode*)$5)->getParamsType());
            }   
        } 
        RPAREN BlockStmt {
            SymbolEntry *se;
            se = identifiers->lookup($2);
            assert(se != nullptr);
            $$ = new FunctionDef(se, (FuncDefParamsNode*)$5, $8);
            SymbolTable *top = identifiers;
            identifiers = identifiers->getPrev();
            delete top;
            delete []$2;
        }
    ;

// 函数参数列表
FuncParams
    :   FuncParams COMMA FuncParam {
            FuncDefParamsNode* node = (FuncDefParamsNode*)$1;
            node->addNext(((DefNode*)$3)->getId());
            $$ = node;
        }
    |   FuncParam {
            FuncDefParamsNode* node = new FuncDefParamsNode();
            node->addNext(((DefNode*)$1)->getId());
            $$ = node;
        }
    |   %empty {
            $$ = nullptr;
        }
    ;

// 函数参数
FuncParam
    :   Type ID {
            SymbolEntry *se = new IdentifierSymbolEntry($1, $2, identifiers->getLevel());
            identifiers->install($2, se);
            $$ = new DefNode(new Id(se), nullptr, false, false);
        }
    //数组函数参数
    |   Type ID LBRACKET RBRACKET ArrConstIndices{
            Type* arrayType= new IntArrayType(); 
            if($1==TypeSystem::intType){
                arrayType = new IntArrayType();
                ((IntArrayType*)arrayType)->pushBackDimension(-1);
            }
            else if($1==TypeSystem::floatType){
                arrayType = new FloatArrayType();
                ((FloatArrayType*)arrayType)->pushBackDimension(-1);
            }
            //最高维未指定，记为默认值-1
            SymbolEntry *se = new IdentifierSymbolEntry(arrayType, $2, identifiers->getLevel());
            identifiers->install($2, se);
            Id* id = new Id(se);
            id->addIndices((ExprStmtNode*)$5);
            $$ = new DefNode(id, nullptr, false, true);
        }
    |   Type ID LBRACKET RBRACKET{
            Type* arrayType= new IntArrayType(); 
            if($1==TypeSystem::intType){
                arrayType = new IntArrayType();
                ((IntArrayType*)arrayType)->pushBackDimension(-1);
            }
            else if($1==TypeSystem::floatType){
                arrayType = new FloatArrayType();
                ((FloatArrayType*)arrayType)->pushBackDimension(-1);
            }
            //最高维未指定，记为默认值-1
            SymbolEntry *se = new IdentifierSymbolEntry(arrayType, $2, identifiers->getLevel());
            identifiers->install($2, se);
            Id* id = new Id(se);
            $$ = new DefNode(id, nullptr, false, true);
        }
    ;
%%

int yyerror(char const* message)
{
    std::cerr<<message<<std::endl;
    return -1;
}