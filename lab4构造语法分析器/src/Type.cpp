#include "Type.h"
#include <assert.h>
#include <iostream>
#include <sstream>
//增加数组类型、函数类型和浮点数类型
IntType TypeSystem::commonInt = IntType(4);
VoidType TypeSystem::commonVoid = VoidType();
FloatType TypeSystem::commonFloat = FloatType();
BoolType TypeSystem::commonBool = BoolType();
ConstIntType TypeSystem::commonConstInt = ConstIntType();
ConstFloatType TypeSystem::commonConstFloat = ConstFloatType();

Type* TypeSystem::intType = &commonInt;
Type* TypeSystem::floatType = &commonFloat;
Type* TypeSystem::voidType = &commonVoid;
Type* TypeSystem::constIntType = &commonConstInt;
Type* TypeSystem::constFloatType = &commonConstFloat;

std::string IntType::toStr()
{
    return "int";
}
std::string FloatType::toStr()
{
    return "float";
    
}
std::string VoidType::toStr()
{
    return "void";
}
std::string BoolType::toStr()
{
    return "bool";
}
std::string ConstIntType::toStr()
{
    return "const int";
}

std::string ConstFloatType::toStr()
{
    return "const float";
}

void FunctionType::setparamsType(std::vector<Type*> in)
{
    paramsType = in;
}

std::string FunctionType::toStr()
{
    std::ostringstream buffer;
    buffer << returnType->toStr() << "(";
   for(int i = 0;i < (int)paramsType.size();i++){
        if(i!=0) buffer << ", ";
        buffer << paramsType[i]->toStr();
    }
    buffer << ')';
    return buffer.str();
}

void IntArrayType::pushBackDimension(int dim)
{
    dimensions.push_back(dim);
}

std::vector<int> IntArrayType::getDimensions()
{
    return dimensions;
}

std::string IntArrayType::toStr()
{
    return "int array";
}

void FloatArrayType::pushBackDimension(int dim)
{
    dimensions.push_back(dim);
}

std::vector<int> FloatArrayType::getDimensions()
{
    return dimensions;
}

std::string FloatArrayType::toStr()
{
    return "float array";
}
void ConstIntArrayType::pushBackDimension(int dim)
{
    dimensions.push_back(dim);
}

std::vector<int> ConstIntArrayType::getDimensions()
{
    return dimensions;
}

std::string ConstIntArrayType::toStr()
{
    return "const int array";
}

void ConstFloatArrayType::pushBackDimension(int dim)
{
    dimensions.push_back(dim);
}

std::vector<int> ConstFloatArrayType::getDimensions()
{
    return dimensions;
}

std::string ConstFloatArrayType::toStr()
{
    return "const float array";
}
