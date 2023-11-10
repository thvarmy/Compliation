%option noyywrap
%option nounput
%option noinput
%top{
    #include <stdarg.h>
    #include "common.h"
    #include <stdio.h>
    #include <string>
    #include <ostream>
    #include <fstream>
    #include <malloc.h>
    #include <unordered_map>
    #include <iostream>
    #include <cstring>
    #include <cstdlib>

}
%{
   
    extern dump_type_t dump_type;
    // 定义变量来跟踪行和列
    int line_number = 1;
    int column_number = 1;
    // 函数用于更新行和列号
    void update_position(int num_chars) {
        for (int i = 0; i < num_chars; i++) {
            if (yytext[i] == '\n') {
                line_number++;//如果换行就行号+1，列号重新从1开始计算
                column_number = 1;
            } else {
                column_number++;
            }  
        }
    }
  /* Your code here, if desired (lab3). */
    //链表形式组织符号表（此处符号表只记录ID）
    //链表节点
    // struct node {
    //     char name[56];
    //     node* prev, * next;
    // };
    class Node {
        public:
        std::string name;
        Node* prev;
        Node* next;
        Node(const std::string& s) : name(s), prev(nullptr), next(nullptr) {}
};
    //链表
    class LinkedList {
public:
    LinkedList() : head(nullptr), tail(nullptr), count(0) {}
    ~LinkedList() {
        Node* current = head;
        while (current != nullptr) {
            Node* temp = current;
            current = current->next;
            delete temp;
        }
    }
    Node* add(const std::string& s) {
        Node* newNode = new Node(s);

        if (head == nullptr) {
            head = newNode;
            tail = newNode;
        } else {
            tail->next = newNode;
            newNode->prev = tail;
            tail = newNode;
        }
        count++;
        return newNode;
    }
    Node* find(const std::string& s) {
        Node* current = head;
        while (current != nullptr) {
            if (current->name == s) {
                return current;
            }
            current = current->next;
        }
        return nullptr;
    }

private:
    Node* head;
    Node* tail;
    int count;
};
    LinkedList idlist;
    //自定义stack_element类（符号栈中元素）
    /*
    每个栈元素stack_element会持有一个指向前一元素的指针pre和一个map
    map是无序的，存储的是当前这个{}范围下所有的映射对：<标识符名，对应符号表表项的地址>
    */
    class stack_element {
    private:
        std::unordered_map<std::string, Node*> map;
        stack_element* prev;
    public:
        //初始化空的符号栈的首元素
        stack_element() {
            prev = nullptr;
        }
        //往符号栈里压元素，新压入元素的pre自然就是低他一层的元素
        stack_element(stack_element* back) {
            prev = back;
        }
        void add_into_map(std::string name, Node* id) {
            map[name] = id;
        }
        stack_element* get_prev() {
            return prev;
        }
        Node* get_identifier(std::string name) {
            if (map.empty()) {
                return nullptr;
            }
            if (map.find(name) != map.end()) {
                return map[name];
            }
            else return nullptr;
        }
        ~stack_element() {
            prev = nullptr;
            std::unordered_map<std::string, Node*>().swap(map);
            malloc_trim(0);
        }
    };
    // symble_stack 类，识别到标识符将其存入符号栈中，最后再一次性输出
    class symble_stack: public stack_element {
    private:
        // 栈的顶部
        stack_element* top;
    public:
        // 初始化，之所以要初始化一个top表项，是为了存储全局标识符，这些标识符没有{}标识
        symble_stack() {
            stack_element* t = new stack_element();
            top = t;
        }
        //栈中的每一个元素都代表一个{}范围内所有标识符相关的存储
        // 添加元素
        void push() {
            stack_element* t = new stack_element(top);
            top = t;
        }
        // 弹出元素
        void pop() {
            stack_element* p;
            p = top;
            top = top->get_prev();
            p->~stack_element();
        }
        // 添加标识符
        void add_map(std::string name, Node* id) {
            top->add_into_map(name, id);
        }
        //查找符号栈中是否曾出现过同样的标识符
        Node* lookup(std::string name) {
        // 1. 未出现：创建一个新的idlist_entry，并添加到top指针指向的map中，然后返回idlist_entry的地址
        // 2. 已出现：返回对应的idlist_entry地址
            Node* p_entry = nullptr;
            //搜索：从栈顶依次向下搜索,因为{}可能层层嵌套
            stack_element* p;
            p = top;
            do {
                p_entry = p->get_identifier(name);
                if (p_entry) {
                    //p_entry不为空，意味着已经找到了
                    return p_entry;
                }
                //p_entry为空，意味着还没找到，继续向下搜索
                p = p->get_prev();
            } while (p);
            //搜索不到，于是这是一个新的标识符
            p_entry = idlist.add((char*)name.c_str());
            top->add_into_map(name, p_entry);
            return p_entry;
        }
    };
    symble_stack stack;
    inline void dump_tokens(const char* format, ...) {
         va_list args;
         va_start(args, format);
         if (dump_type == TOKENS){
             fprintf(yyout, "Line %d, Column %d: ", yylineno,  column_number);//输出行号和列号
             vfprintf(yyout, format, args);
         }
        
         va_end(args);
    }
    // 打印ID:单词，词素，行号，符号表项的地址
    void print_id(Node* id_elem) {
    // 输出行号和列号
    fprintf(yyout, "Line %d, Column %d: ", yylineno, column_number);
    // 打印标识符的信息
    int num_spaces = 15 - strlen(yytext);  // Calculate the number of spaces needed for alignment
    fprintf(yyout, "ID\t%s", yytext);
    for (int i = 0; i < num_spaces; ++i)
        fprintf(yyout, " ");
    fprintf(yyout, "Node Address:\t\t%p\n", (void*)id_elem);
}

%}

%option noyywrap


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
/*回车换行*/
EOL (\r\n|\n|\r)
/*制表符 空格*/
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
   update_position(3); // 更新行和列号
}

"void" {

    dump_tokens("VOID\t%s\n", yytext);
    update_position(4);
}

"if" {
    dump_tokens("IF\t%s\n", yytext);
    update_position(2);
}

"else" {
    dump_tokens("ELSE\t%s\n", yytext);
    update_position(4);
}

"return" {
    dump_tokens("RETURN\t%s\n", yytext);
    update_position(6);
}

"while" {
    dump_tokens("WHILE\t%s\n", yytext);
    update_position(5);
}
"break" {
    dump_tokens("BREAK\t%s\n", yytext);
    update_position(5);
}
"continue" {
    dump_tokens("CONTINUE\t%s\n", yytext);
}
"const" {
    dump_tokens("CONST\t%s\n", yytext);
    update_position(5);
}

"==" {
    dump_tokens("EQUAL\t%s\n", yytext);
    update_position(2);
}
"!=" {
    dump_tokens("NOTEQUAL\t%s\n", yytext);
    update_position(2);
}
"<=" {
    dump_tokens("LESSEQUAL\t%s\n", yytext);
    update_position(2);
}
">=" {
    dump_tokens("GREATEREQUAL\t%s\n", yytext);
    update_position(2);
}


"=" {
    dump_tokens("ASSIGN\t%s\n", yytext);
    update_position(yyleng);
    update_position(1);
}

"<" {
    dump_tokens("LESS\t%s\n", yytext);
    update_position(1);
}

">" {
    dump_tokens("GREAT\t%s\n", yytext);
    update_position(1);
}

"+" {
    dump_tokens("ADD\t%s\n", yytext);
    update_position(1);
}
"-" {
    dump_tokens("SUB\t%s\n", yytext);
    update_position(1);
}
"*" {
    dump_tokens("MUL\t%s\n", yytext);
    update_position(1);
}
"/" {
    dump_tokens("DIV\t%s\n", yytext);
    update_position(1);
}
"%" {
    dump_tokens("MOD\t%s\n", yytext);
    update_position(1);
}
"&&" {
    dump_tokens("AND\t%s\n", yytext);
    update_position(2);
}
"||" {
    dump_tokens("OR\t%s\n", yytext);
    update_position(2);
}
"!" {
    dump_tokens("NOT\t%s\n", yytext);
    update_position(1);
}

";" {
    dump_tokens("SEMICOLON\t%s\n", yytext);
    update_position(1);
}

"(" {
    dump_tokens("LPAREN\t%s\n", yytext);
     update_position(1);
}

")" {
    dump_tokens("RPAREN\t%s\n", yytext);
    update_position(1);
}

"{" {
    dump_tokens("LBRACE\t%s\n", yytext);
    update_position(1);
}

"}" {
    dump_tokens("RBRACE\t%s\n", yytext);
    update_position(1);
}

"[" {
    dump_tokens("LBRACKET\t%s\n", yytext);
    update_position(1);
}

"]" {
    dump_tokens("RBRACKET\t%s\n", yytext);
    update_position(1);
}

"," {
    dump_tokens("COMMA\t%s\n", yytext);
    update_position(1);
}


{OCTAL} {
    int decimal = strtol(yytext + 1, NULL, 8);
    dump_tokens("OCTAL\t%s\t%d\n", yytext, decimal);
}


{DECIMIAL} {
    int decimal;
    if (yytext[0] == '-') {
        // 如果第一个字符是负号，使用负数处理
        decimal = atoi(yytext + 1); // 跳过负号
        decimal = -decimal; // 负数处理
        dump_tokens("DECIMAL\t%s\t%d\n", yytext, decimal);
    } else {
        // 否则，处理正整数
        decimal = atoi(yytext);
        dump_tokens("DECIMAL\t%s\t%d\n", yytext, decimal);
    }
}

{HEX} {
    int decimal = strtol(yytext + 2, NULL, 16);
    dump_tokens("HEX\t%s\t%d\n", yytext, decimal);
}

{FLOAT} {
    float floatValue = strtof(yytext, NULL);
    dump_tokens("FLOAT\t%s\t%f\n", yytext, floatValue);
}

{ID} {
    std::string str = yytext; //yytext = 词素
    Node *p = stack.lookup(str);
    print_id(p);
    //dump_tokens("ID\t%s\n", yytext);
    update_position(yyleng);
}

{EOL} {
    yylineno++;
    update_position(yyleng);
}

{WHITE} {
   update_position(1);
}

{LINECOMMENT} {}   //处理注释，使用定义好的独占状态BLOCKCOMMENT
{BLOCKCOMMENTBEGIN} {BEGIN BLOCKCOMMENT;}
<BLOCKCOMMENT>{BLOCKCOMMENTELEMENT} {}
<BLOCKCOMMENT>{BLOCKCOMMENTEND} {BEGIN INITIAL;} //使用宏BEGIN来切换状态，初始状态默认为INITIAL

%%

