#ifndef __AST_H__
#define __AST_H__

#include <fstream>
#include <vector>
class SymbolEntry;//符号表项类，在SymbolTable.h中实现
class Type;
//节点类
class Node
{
private:
    static int counter;//静态整数，用于所有Node对象共享
    int seq;//表示节点的序列号
public:
    Node *next;//节点指向的下一个节点，用于表示表达式声明列表，函数参数列表等若干个表达式拼接而成的表达式
    Node();
    int getSeq() const {return seq;};
    virtual void output(int level) = 0;//虚函数，在子类中实现
    //添加next节点
    void setNext(Node *node);
    //获取当前的节点的next节点
    Node *getNext();
};
//表达式节点类
class ExprNode : public Node
{
protected:
    SymbolEntry *symbolEntry;//指向 SymbolEntry 类型的指针
public:
    ExprNode(SymbolEntry *symbolEntry) : symbolEntry(symbolEntry){};
    Type* getType();
    //virtual int getValue(){return 0;}//获取这个表达式节点的值,子类中重写这个函数以返回不同的值。
   // SymbolEntry *getSymbolEntry() { return symbolEntry; }
};
//二元表达式节点
class BinaryExpr : public ExprNode
{
private:
    int op;
    ExprNode *expr1, *expr2;
public:
    enum {ADD, SUB, AND, OR, LESS,MUL,DIV,MOD,LESSEQUAL,GREATER,GREATEREQUAL,EQUAL,NOTEQUAL};//增加了一些运算符
    BinaryExpr(SymbolEntry *se, int op, ExprNode*expr1, ExprNode*expr2) : ExprNode(se), op(op), expr1(expr1), expr2(expr2){};
    void output(int level);
    int getValue();
};
//一元表达式节点
class UnaryExpr : public ExprNode
{
private:
    int op;
    ExprNode *expr;
public:
    enum {ADD, SUB, NOT};//一元表达式运算符
    UnaryExpr(SymbolEntry *se, int op, ExprNode*expr) : ExprNode(se), op(op), expr(expr){};
    void output(int level);
};
//常量表达式节点
class Constant : public ExprNode
{
public:
    Constant(SymbolEntry *se) : ExprNode(se){};
    void output(int level);
};
//函数调用表达式节点
class FuncCallExp : public ExprNode
{
private:
    ExprNode *param;//参数

public:
    FuncCallExp(SymbolEntry *se, ExprNode *param = nullptr)
        : ExprNode(se), param(param){};
    void output(int level);
};

//语句节点
class StmtNode : public Node
{};
//表达式语句节点
class ExprStmtNode : public StmtNode//注意：该类由ExprStmt与ArrayIndices共享，二者的行为完全一致
{
private:
    std::vector<ExprNode*> exprList;
public:
    ExprStmtNode(){};
    void addNext(ExprNode* next);//增加节点
    void output(int level);
};
//标识符节点
class Id : public ExprNode
{
private:
    ExprStmtNode* indices;
public:
    Id(SymbolEntry *se) : ExprNode(se), indices(nullptr){};
    SymbolEntry* getSymbolEntry() {return symbolEntry;}
    bool isArray();     //必须配合indices!=nullptr使用（a[]的情况）
    void addIndices(ExprStmtNode* idx) {indices = idx;}
    void output(int level);
};
//表达式语句
class ExprStmt : public StmtNode
{
private:
    ExprNode *expr;

public:
    ExprStmt(ExprNode *expr) : expr(expr){};
    void output(int level);
};
//复合语句
class CompoundStmt : public StmtNode
{
private:
    StmtNode *stmt;
public:
    CompoundStmt(StmtNode *stmt) : stmt(stmt) {};
    void output(int level);
};
//序列节点
class SeqNode : public StmtNode
{
private:
    std::vector<StmtNode*> stmtList;
public:
    SeqNode(){};
    void addNext(StmtNode* next);
    void output(int level);
};
//初始化值节点，用于表示初始化语句中的值。
class InitValNode : public StmtNode
{
private:
    bool isConst;
    ExprNode* leafNode; //可能为空，j即使是叶节点（考虑{}）
    std::vector<InitValNode*> innerList;//为空则为叶节点，这是唯一判断标准
public:
    InitValNode(bool isConst) : 
        isConst(isConst), leafNode(nullptr){};
    void addNext(InitValNode* next);
    void setLeafNode(ExprNode* leaf);
    bool isLeaf();
    void output(int level);
};
//表示变量或常量的声明语句
class DefNode : public StmtNode
{
private:
    bool isConst;
    bool isArray;
    Id* id;//表示声明的标识符
    Node* initVal;//对于非数组，是ExprNode；对于数组，是InitValueNode。获取赋值给标识符的表达式,如果为空，代表只声明，不赋初值
public:
    DefNode(Id* id, Node* initVal, bool isConst, bool isArray) : 
        isConst(isConst), isArray(isArray), id(id), initVal(initVal){};
    Id* getId() {return id;}
    void output(int level);
};
//声明语句节点
class DeclStmt : public StmtNode
{
private:
    bool isConst;
    std::vector<DefNode*> defList;
public:
    DeclStmt(bool isConst) : isConst(isConst){};
    void addNext(DefNode* next);
    void output(int level);
};
//IF语句
class IfStmt : public StmtNode
{
private:
    ExprNode *cond;
    StmtNode *thenStmt;
public:
    IfStmt(ExprNode *cond, StmtNode *thenStmt) : cond(cond), thenStmt(thenStmt){};
    void output(int level);
};
//IfElse语句
class IfElseStmt : public StmtNode
{
private:
    ExprNode *cond;
    StmtNode *thenStmt;
    StmtNode *elseStmt;
public:
    IfElseStmt(ExprNode *cond, StmtNode *thenStmt, StmtNode *elseStmt) : cond(cond), thenStmt(thenStmt), elseStmt(elseStmt) {};
    void output(int level);
};
//While语句
class WhileStmt:public StmtNode
{
private:
    ExprNode *cond;
    StmtNode *stmt;
public:
    WhileStmt(ExprNode *cond,StmtNode *stmt):cond(cond),stmt(stmt){};
    void output(int level);
};
//Break语句
class BreakStmt : public StmtNode
{
public:
    BreakStmt(){};
    void output(int level);
};
//Continue语句
class ContinueStmt : public StmtNode
{
public:
    ContinueStmt(){};
    void output(int level);
};
//Return语句
class ReturnStmt : public StmtNode
{
private:
    ExprNode *retValue;
public:
    ReturnStmt(ExprNode*retValue) : retValue(retValue) {};
    void output(int level);
};
//空语句
class EmptyStmt : public StmtNode
{
public:
    EmptyStmt(){};
    void output(int level);
};
//赋值语句
class AssignStmt : public StmtNode
{
private:
    ExprNode *lval;
    ExprNode *expr;
public:
    AssignStmt(ExprNode *lval, ExprNode *expr) : lval(lval), expr(expr) {};
    void output(int level);
};
//函数调用参数节点
class FuncCallParamsNode : public StmtNode
{
private:
    std::vector<ExprNode*> paramsList;
public:
    FuncCallParamsNode(){};
    void addNext(ExprNode* next);
    void output(int level);
};
//函数调用节点
class FuncCallNode : public ExprNode
{
private:
    Id* funcId;
    FuncCallParamsNode* params;
public:
    FuncCallNode(SymbolEntry *se, Id* id, FuncCallParamsNode* params) : ExprNode(se), funcId(id), params(params){};
    void output(int level);
};
//函数声明参数节点
class FuncDefParamsNode : public StmtNode
{
private:
    std::vector<Id*> paramsList;
public:
    FuncDefParamsNode() {};
    void addNext(Id* next);
    std::vector<Type*> getParamsType();
    void output(int level);
};
//函数声明节点
class FunctionDef : public StmtNode
{
private:
    SymbolEntry *se;
    FuncDefParamsNode *params;
    StmtNode *stmt;
public:
    FunctionDef(SymbolEntry *se, FuncDefParamsNode *params, StmtNode *stmt) : se(se), params(params), stmt(stmt){};
    void output(int level);
};


class Ast
{
private:
    Node* root;
public:
    Ast() {root = nullptr;}
    void setRoot(Node*n) {root = n;}
    void output();
};

#endif
