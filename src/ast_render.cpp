#include "ast_render.hpp"

#include <stdio.h>

static const char *bin_op_str(BinOpType bin_op) {
    switch (bin_op) {
        case BinOpTypeInvalid:                return "(invalid)";
        case BinOpTypeBoolOr:                 return "||";
        case BinOpTypeBoolAnd:                return "&&";
        case BinOpTypeCmpEq:                  return "==";
        case BinOpTypeCmpNotEq:               return "!=";
        case BinOpTypeCmpLessThan:            return "<";
        case BinOpTypeCmpGreaterThan:         return ">";
        case BinOpTypeCmpLessOrEq:            return "<=";
        case BinOpTypeCmpGreaterOrEq:         return ">=";
        case BinOpTypeBinOr:                  return "|";
        case BinOpTypeBinXor:                 return "^";
        case BinOpTypeBinAnd:                 return "&";
        case BinOpTypeBitShiftLeft:           return "<<";
        case BinOpTypeBitShiftLeftWrap:       return "<<%";
        case BinOpTypeBitShiftRight:          return ">>";
        case BinOpTypeAdd:                    return "+";
        case BinOpTypeAddWrap:                return "+%";
        case BinOpTypeSub:                    return "-";
        case BinOpTypeSubWrap:                return "-%";
        case BinOpTypeMult:                   return "*";
        case BinOpTypeMultWrap:               return "*%";
        case BinOpTypeDiv:                    return "/";
        case BinOpTypeMod:                    return "%";
        case BinOpTypeAssign:                 return "=";
        case BinOpTypeAssignTimes:            return "*=";
        case BinOpTypeAssignTimesWrap:        return "*%=";
        case BinOpTypeAssignDiv:              return "/=";
        case BinOpTypeAssignMod:              return "%=";
        case BinOpTypeAssignPlus:             return "+=";
        case BinOpTypeAssignPlusWrap:         return "+%=";
        case BinOpTypeAssignMinus:            return "-=";
        case BinOpTypeAssignMinusWrap:        return "-%=";
        case BinOpTypeAssignBitShiftLeft:     return "<<=";
        case BinOpTypeAssignBitShiftLeftWrap: return "<<%=";
        case BinOpTypeAssignBitShiftRight:    return ">>=";
        case BinOpTypeAssignBitAnd:           return "&=";
        case BinOpTypeAssignBitXor:           return "^=";
        case BinOpTypeAssignBitOr:            return "|=";
        case BinOpTypeAssignBoolAnd:          return "&&=";
        case BinOpTypeAssignBoolOr:           return "||=";
        case BinOpTypeUnwrapMaybe:            return "??";
        case BinOpTypeArrayCat:               return "++";
        case BinOpTypeArrayMult:              return "**";
    }
    zig_unreachable();
}

static const char *prefix_op_str(PrefixOp prefix_op) {
    switch (prefix_op) {
        case PrefixOpInvalid: return "(invalid)";
        case PrefixOpNegation: return "-";
        case PrefixOpNegationWrap: return "-%";
        case PrefixOpBoolNot: return "!";
        case PrefixOpBinNot: return "~";
        case PrefixOpAddressOf: return "&";
        case PrefixOpConstAddressOf: return "&const ";
        case PrefixOpDereference: return "*";
        case PrefixOpMaybe: return "?";
        case PrefixOpError: return "%";
        case PrefixOpUnwrapError: return "%%";
        case PrefixOpUnwrapMaybe: return "??";
    }
    zig_unreachable();
}

static const char *visib_mod_string(VisibMod mod) {
    switch (mod) {
        case VisibModPub: return "pub ";
        case VisibModPrivate: return "";
        case VisibModExport: return "export ";
    }
    zig_unreachable();
}

static const char *return_string(ReturnKind kind) {
    switch (kind) {
        case ReturnKindUnconditional: return "return";
        case ReturnKindError: return "%return";
        case ReturnKindMaybe: return "?return";
    }
    zig_unreachable();
}

static const char *defer_string(ReturnKind kind) {
    switch (kind) {
        case ReturnKindUnconditional: return "defer";
        case ReturnKindError: return "%defer";
        case ReturnKindMaybe: return "?defer";
    }
    zig_unreachable();
}

static const char *extern_string(bool is_extern) {
    return is_extern ? "extern " : "";
}

static const char *inline_string(bool is_inline) {
    return is_inline ? "inline " : "";
}

static const char *const_or_var_string(bool is_const) {
    return is_const ? "const" : "var";
}

static const char *container_string(ContainerKind kind) {
    switch (kind) {
        case ContainerKindEnum: return "enum";
        case ContainerKindStruct: return "struct";
        case ContainerKindUnion: return "union";
    }
    zig_unreachable();
}

static const char *node_type_str(NodeType node_type) {
    switch (node_type) {
        case NodeTypeRoot:
            return "Root";
        case NodeTypeFnDef:
            return "FnDef";
        case NodeTypeFnDecl:
            return "FnDecl";
        case NodeTypeFnProto:
            return "FnProto";
        case NodeTypeParamDecl:
            return "ParamDecl";
        case NodeTypeBlock:
            return "Block";
        case NodeTypeBinOpExpr:
            return "BinOpExpr";
        case NodeTypeUnwrapErrorExpr:
            return "UnwrapErrorExpr";
        case NodeTypeFnCallExpr:
            return "FnCallExpr";
        case NodeTypeArrayAccessExpr:
            return "ArrayAccessExpr";
        case NodeTypeSliceExpr:
            return "SliceExpr";
        case NodeTypeReturnExpr:
            return "ReturnExpr";
        case NodeTypeDefer:
            return "Defer";
        case NodeTypeVariableDeclaration:
            return "VariableDeclaration";
        case NodeTypeTypeDecl:
            return "TypeDecl";
        case NodeTypeErrorValueDecl:
            return "ErrorValueDecl";
        case NodeTypeNumberLiteral:
            return "NumberLiteral";
        case NodeTypeStringLiteral:
            return "StringLiteral";
        case NodeTypeCharLiteral:
            return "CharLiteral";
        case NodeTypeSymbol:
            return "Symbol";
        case NodeTypePrefixOpExpr:
            return "PrefixOpExpr";
        case NodeTypeUse:
            return "Use";
        case NodeTypeBoolLiteral:
            return "BoolLiteral";
        case NodeTypeNullLiteral:
            return "NullLiteral";
        case NodeTypeUndefinedLiteral:
            return "UndefinedLiteral";
        case NodeTypeZeroesLiteral:
            return "ZeroesLiteral";
        case NodeTypeThisLiteral:
            return "ThisLiteral";
        case NodeTypeIfBoolExpr:
            return "IfBoolExpr";
        case NodeTypeIfVarExpr:
            return "IfVarExpr";
        case NodeTypeWhileExpr:
            return "WhileExpr";
        case NodeTypeForExpr:
            return "ForExpr";
        case NodeTypeSwitchExpr:
            return "SwitchExpr";
        case NodeTypeSwitchProng:
            return "SwitchProng";
        case NodeTypeSwitchRange:
            return "SwitchRange";
        case NodeTypeLabel:
            return "Label";
        case NodeTypeGoto:
            return "Goto";
        case NodeTypeBreak:
            return "Break";
        case NodeTypeContinue:
            return "Continue";
        case NodeTypeAsmExpr:
            return "AsmExpr";
        case NodeTypeFieldAccessExpr:
            return "FieldAccessExpr";
        case NodeTypeContainerDecl:
            return "ContainerDecl";
        case NodeTypeStructField:
            return "StructField";
        case NodeTypeStructValueField:
            return "StructValueField";
        case NodeTypeContainerInitExpr:
            return "ContainerInitExpr";
        case NodeTypeArrayType:
            return "ArrayType";
        case NodeTypeErrorType:
            return "ErrorType";
        case NodeTypeTypeLiteral:
            return "TypeLiteral";
        case NodeTypeVarLiteral:
            return "VarLiteral";
    }
    zig_unreachable();
}

struct AstPrint {
    int indent;
    FILE *f;
};

static void ast_print_visit(AstNode **node_ptr, void *context) {
    AstNode *node = *node_ptr;
    AstPrint *ap = (AstPrint *)context;

    for (int i = 0; i < ap->indent; i += 1) {
        fprintf(ap->f, " ");
    }

    fprintf(ap->f, "%s\n", node_type_str(node->type));

    AstPrint new_ap;
    new_ap.indent = ap->indent + 2;
    new_ap.f = ap->f;

    ast_visit_node_children(node, ast_print_visit, &new_ap);
}

void ast_print(FILE *f, AstNode *node, int indent) {
    AstPrint ap;
    ap.indent = indent;
    ap.f = f;
    ast_visit_node_children(node, ast_print_visit, &ap);
}


struct AstRender {
    int indent;
    int indent_size;
    FILE *f;
};

static void print_indent(AstRender *ar) {
    for (int i = 0; i < ar->indent; i += 1) {
        fprintf(ar->f, " ");
    }
}

static bool is_alpha_under(uint8_t c) {
    return (c >= 'a' && c <= 'z') ||
        (c >= 'A' && c <= 'Z') || c == '_';
}

static bool is_digit(uint8_t c) {
    return (c >= '0' && c <= '9');
}

static bool is_printable(uint8_t c) {
    static const uint8_t printables[] =
        " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.~`!@#$%^&*()_-+=\\{}[];'\"?/<>,";
    for (size_t i = 0; i < array_length(printables); i += 1) {
        if (c == printables[i]) return true;
    }
    return false;
}

static void string_literal_escape(Buf *source, Buf *dest) {
    buf_resize(dest, 0);
    for (size_t i = 0; i < buf_len(source); i += 1) {
        uint8_t c = *((uint8_t*)buf_ptr(source) + i);
        if (is_printable(c)) {
            buf_append_char(dest, c);
        } else if (c == '\'') {
            buf_append_str(dest, "\\'");
        } else if (c == '"') {
            buf_append_str(dest, "\\\"");
        } else if (c == '\\') {
            buf_append_str(dest, "\\\\");
        } else if (c == '\a') {
            buf_append_str(dest, "\\a");
        } else if (c == '\b') {
            buf_append_str(dest, "\\b");
        } else if (c == '\f') {
            buf_append_str(dest, "\\f");
        } else if (c == '\n') {
            buf_append_str(dest, "\\n");
        } else if (c == '\r') {
            buf_append_str(dest, "\\r");
        } else if (c == '\t') {
            buf_append_str(dest, "\\t");
        } else if (c == '\v') {
            buf_append_str(dest, "\\v");
        } else {
            buf_appendf(dest, "\\x%x", (int)c);
        }
    }
}

static bool is_valid_bare_symbol(Buf *symbol) {
    if (buf_len(symbol) == 0) {
        return false;
    }
    uint8_t first_char = *buf_ptr(symbol);
    if (!is_alpha_under(first_char)) {
        return false;
    }
    for (size_t i = 1; i < buf_len(symbol); i += 1) {
        uint8_t c = *((uint8_t*)buf_ptr(symbol) + i);
        if (!is_alpha_under(c) && !is_digit(c)) {
            return false;
        }
    }
    return true;
}

static void print_symbol(AstRender *ar, Buf *symbol) {
    if (is_zig_keyword(symbol)) {
        fprintf(ar->f, "@\"%s\"", buf_ptr(symbol));
        return;
    }
    if (is_valid_bare_symbol(symbol)) {
        fprintf(ar->f, "%s", buf_ptr(symbol));
        return;
    }
    Buf escaped = BUF_INIT;
    string_literal_escape(symbol, &escaped);
    fprintf(ar->f, "@\"%s\"", buf_ptr(&escaped));
}

static void render_node(AstRender *ar, AstNode *node) {
    switch (node->type) {
        case NodeTypeRoot:
            for (size_t i = 0; i < node->data.root.top_level_decls.length; i += 1) {
                AstNode *child = node->data.root.top_level_decls.at(i);
                print_indent(ar);
                render_node(ar, child);

                if (child->type == NodeTypeUse ||
                    child->type == NodeTypeVariableDeclaration ||
                    child->type == NodeTypeTypeDecl ||
                    child->type == NodeTypeErrorValueDecl ||
                    child->type == NodeTypeFnProto)
                {
                    fprintf(ar->f, ";");
                }
                fprintf(ar->f, "\n");
            }
            break;
        case NodeTypeFnProto:
            {
                const char *pub_str = visib_mod_string(node->data.fn_proto.top_level_decl.visib_mod);
                const char *extern_str = extern_string(node->data.fn_proto.is_extern);
                const char *inline_str = inline_string(node->data.fn_proto.is_inline);
                fprintf(ar->f, "%s%s%sfn ", pub_str, inline_str, extern_str);
                print_symbol(ar, node->data.fn_proto.name);
                fprintf(ar->f, "(");
                int arg_count = node->data.fn_proto.params.length;
                bool is_var_args = node->data.fn_proto.is_var_args;
                for (int arg_i = 0; arg_i < arg_count; arg_i += 1) {
                    AstNode *param_decl = node->data.fn_proto.params.at(arg_i);
                    assert(param_decl->type == NodeTypeParamDecl);
                    if (buf_len(param_decl->data.param_decl.name) > 0) {
                        const char *noalias_str = param_decl->data.param_decl.is_noalias ? "noalias " : "";
                        const char *inline_str = param_decl->data.param_decl.is_inline ? "inline  " : "";
                        fprintf(ar->f, "%s%s", noalias_str, inline_str);
                        print_symbol(ar, param_decl->data.param_decl.name);
                        fprintf(ar->f, ": ");
                    }
                    render_node(ar, param_decl->data.param_decl.type);

                    if (arg_i + 1 < arg_count || is_var_args) {
                        fprintf(ar->f, ", ");
                    }
                }
                if (is_var_args) {
                    fprintf(ar->f, "...");
                }
                fprintf(ar->f, ")");

                AstNode *return_type_node = node->data.fn_proto.return_type;
                fprintf(ar->f, " -> ");
                render_node(ar, return_type_node);
                break;
            }
        case NodeTypeFnDef:
            {
                render_node(ar, node->data.fn_def.fn_proto);
                fprintf(ar->f, " ");
                render_node(ar, node->data.fn_def.body);
                break;
            }
        case NodeTypeBlock:
            if (node->data.block.statements.length == 0) {
                fprintf(ar->f, "{}");
                break;
            }
            fprintf(ar->f, "{\n");
            ar->indent += ar->indent_size;
            for (size_t i = 0; i < node->data.block.statements.length; i += 1) {
                AstNode *statement = node->data.block.statements.at(i);
                print_indent(ar);
                render_node(ar, statement);
                if (i != node->data.block.statements.length - 1)
                    fprintf(ar->f, ";");
                fprintf(ar->f, "\n");
            }
            ar->indent -= ar->indent_size;
            print_indent(ar);
            fprintf(ar->f, "}");
            break;
        case NodeTypeReturnExpr:
            {
                const char *return_str = return_string(node->data.return_expr.kind);
                fprintf(ar->f, "%s ", return_str);
                render_node(ar, node->data.return_expr.expr);
                break;
            }
        case NodeTypeDefer:
            {
                const char *defer_str = defer_string(node->data.defer.kind);
                fprintf(ar->f, "%s ", defer_str);
                render_node(ar, node->data.return_expr.expr);
                break;
            }
        case NodeTypeVariableDeclaration:
            {
                const char *pub_str = visib_mod_string(node->data.variable_declaration.top_level_decl.visib_mod);
                const char *extern_str = extern_string(node->data.variable_declaration.is_extern);
                const char *const_or_var = const_or_var_string(node->data.variable_declaration.is_const);
                fprintf(ar->f, "%s%s%s ", pub_str, extern_str, const_or_var);
                print_symbol(ar, node->data.variable_declaration.symbol);

                if (node->data.variable_declaration.type) {
                    fprintf(ar->f, ": ");
                    render_node(ar, node->data.variable_declaration.type);
                }
                if (node->data.variable_declaration.expr) {
                    fprintf(ar->f, " = ");
                    render_node(ar, node->data.variable_declaration.expr);
                }
                break;
            }
        case NodeTypeTypeDecl:
            {
                const char *pub_str = visib_mod_string(node->data.type_decl.top_level_decl.visib_mod);
                const char *var_name = buf_ptr(node->data.type_decl.symbol);
                fprintf(ar->f, "%stype %s = ", pub_str, var_name);
                render_node(ar, node->data.type_decl.child_type);
                break;
            }
        case NodeTypeBinOpExpr:
            fprintf(ar->f, "(");
            render_node(ar, node->data.bin_op_expr.op1);
            fprintf(ar->f, " %s ", bin_op_str(node->data.bin_op_expr.bin_op));
            render_node(ar, node->data.bin_op_expr.op2);
            fprintf(ar->f, ")");
            break;
        case NodeTypeNumberLiteral:
            switch (node->data.number_literal.bignum->kind) {
                case BigNumKindInt:
                    {
                        const char *negative_str = node->data.number_literal.bignum->is_negative ? "-" : "";
                        fprintf(ar->f, "%s%llu", negative_str, node->data.number_literal.bignum->data.x_uint);
                    }
                    break;
                case BigNumKindFloat:
                    fprintf(ar->f, "%f", node->data.number_literal.bignum->data.x_float);
                    break;
            }
            break;
        case NodeTypeStringLiteral:
            {
                if (node->data.string_literal.c) {
                    fprintf(ar->f, "c");
                }
                Buf tmp_buf = BUF_INIT;
                string_literal_escape(node->data.string_literal.buf, &tmp_buf);
                fprintf(ar->f, "\"%s\"", buf_ptr(&tmp_buf));
            }
            break;
        case NodeTypeCharLiteral:
            {
                uint8_t c = node->data.char_literal.value;
                if (is_printable(c)) {
                    fprintf(ar->f, "'%c'", c);
                } else {
                    fprintf(ar->f, "'\\x%x'", (int)c);
                }
                break;
            }
        case NodeTypeSymbol:
            print_symbol(ar, node->data.symbol_expr.symbol);
            break;
        case NodeTypePrefixOpExpr:
            {
                PrefixOp op = node->data.prefix_op_expr.prefix_op;
                fprintf(ar->f, "%s", prefix_op_str(op));

                render_node(ar, node->data.prefix_op_expr.primary_expr);
                break;
            }
        case NodeTypeFnCallExpr:
            if (node->data.fn_call_expr.is_builtin) {
                fprintf(ar->f, "@");
            } else {
                fprintf(ar->f, "(");
            }
            render_node(ar, node->data.fn_call_expr.fn_ref_expr);
            if (!node->data.fn_call_expr.is_builtin) {
                fprintf(ar->f, ")");
            }
            fprintf(ar->f, "(");
            for (size_t i = 0; i < node->data.fn_call_expr.params.length; i += 1) {
                AstNode *param = node->data.fn_call_expr.params.at(i);
                if (i != 0) {
                    fprintf(ar->f, ", ");
                }
                render_node(ar, param);
            }
            fprintf(ar->f, ")");
            break;
        case NodeTypeArrayAccessExpr:
            render_node(ar, node->data.array_access_expr.array_ref_expr);
            fprintf(ar->f, "[");
            render_node(ar, node->data.array_access_expr.subscript);
            fprintf(ar->f, "]");
            break;
        case NodeTypeFieldAccessExpr:
            {
                AstNode *lhs = node->data.field_access_expr.struct_expr;
                Buf *rhs = node->data.field_access_expr.field_name;
                render_node(ar, lhs);
                fprintf(ar->f, ".");
                print_symbol(ar, rhs);
                break;
            }
        case NodeTypeUndefinedLiteral:
            fprintf(ar->f, "undefined");
            break;
        case NodeTypeContainerDecl:
            {
                const char *struct_name = buf_ptr(node->data.struct_decl.name);
                const char *pub_str = visib_mod_string(node->data.struct_decl.top_level_decl.visib_mod);
                const char *container_str = container_string(node->data.struct_decl.kind);
                fprintf(ar->f, "%s%s %s {\n", pub_str, container_str, struct_name);
                ar->indent += ar->indent_size;
                for (size_t field_i = 0; field_i < node->data.struct_decl.fields.length; field_i += 1) {
                    AstNode *field_node = node->data.struct_decl.fields.at(field_i);
                    assert(field_node->type == NodeTypeStructField);
                    print_indent(ar);
                    print_symbol(ar, field_node->data.struct_field.name);
                    fprintf(ar->f, ": ");
                    render_node(ar, field_node->data.struct_field.type);
                    fprintf(ar->f, ",\n");
                }

                ar->indent -= ar->indent_size;
                fprintf(ar->f, "}");
                break;
            }
        case NodeTypeContainerInitExpr:
            fprintf(ar->f, "(");
            render_node(ar, node->data.container_init_expr.type);
            fprintf(ar->f, "){");
            assert(node->data.container_init_expr.entries.length == 0);
            fprintf(ar->f, "}");
            break;
        case NodeTypeArrayType:
            {
                fprintf(ar->f, "[");
                if (node->data.array_type.size) {
                    render_node(ar, node->data.array_type.size);
                }
                fprintf(ar->f, "]");
                if (node->data.array_type.is_const) {
                    fprintf(ar->f, "const ");
                }
                render_node(ar, node->data.array_type.child_type);
                break;
            }
        case NodeTypeErrorType:
            fprintf(ar->f, "error");
            break;
        case NodeTypeTypeLiteral:
            fprintf(ar->f, "type");
            break;
        case NodeTypeVarLiteral:
            fprintf(ar->f, "var");
            break;
        case NodeTypeAsmExpr:
            {
                AstNodeAsmExpr *asm_expr = &node->data.asm_expr;
                const char *volatile_str = asm_expr->is_volatile ? " volatile" : "";
                fprintf(ar->f, "asm%s (\"%s\"\n", volatile_str, buf_ptr(asm_expr->asm_template));
                print_indent(ar);
                fprintf(ar->f, ": ");
                for (size_t i = 0; i < asm_expr->output_list.length; i += 1) {
                    AsmOutput *asm_output = asm_expr->output_list.at(i);

                    if (i != 0) {
                        fprintf(ar->f, ",\n");
                        print_indent(ar);
                    }

                    fprintf(ar->f, "[%s] \"%s\" (",
                            buf_ptr(asm_output->asm_symbolic_name),
                            buf_ptr(asm_output->constraint));
                    if (asm_output->return_type) {
                        fprintf(ar->f, "-> ");
                        render_node(ar, asm_output->return_type);
                    } else {
                        fprintf(ar->f, "%s", buf_ptr(asm_output->variable_name));
                    }
                    fprintf(ar->f, ")");
                }
                fprintf(ar->f, "\n");
                print_indent(ar);
                fprintf(ar->f, ": ");
                for (size_t i = 0; i < asm_expr->input_list.length; i += 1) {
                    AsmInput *asm_input = asm_expr->input_list.at(i);

                    if (i != 0) {
                        fprintf(ar->f, ",\n");
                        print_indent(ar);
                    }

                    fprintf(ar->f, "[%s] \"%s\" (",
                            buf_ptr(asm_input->asm_symbolic_name),
                            buf_ptr(asm_input->constraint));
                    render_node(ar, asm_input->expr);
                    fprintf(ar->f, ")");
                }
                fprintf(ar->f, "\n");
                print_indent(ar);
                fprintf(ar->f, ": ");
                for (size_t i = 0; i < asm_expr->clobber_list.length; i += 1) {
                    Buf *reg_name = asm_expr->clobber_list.at(i);
                    if (i != 0) fprintf(ar->f, ", ");
                    fprintf(ar->f, "\"%s\"", buf_ptr(reg_name));
                }
                fprintf(ar->f, ")");
                break;
            }
        case NodeTypeWhileExpr:
            {
                const char *inline_str = node->data.while_expr.is_inline ? "inline " : "";
                fprintf(ar->f, "%swhile (", inline_str);
                render_node(ar, node->data.while_expr.condition);
                if (node->data.while_expr.continue_expr) {
                    fprintf(ar->f, "; ");
                    render_node(ar, node->data.while_expr.continue_expr);
                }
                fprintf(ar->f, ") ");
                render_node(ar, node->data.while_expr.body);
                break;
            }
        case NodeTypeFnDecl:
        case NodeTypeParamDecl:
        case NodeTypeErrorValueDecl:
        case NodeTypeUnwrapErrorExpr:
        case NodeTypeSliceExpr:
        case NodeTypeStructField:
        case NodeTypeStructValueField:
        case NodeTypeUse:
        case NodeTypeBoolLiteral:
        case NodeTypeNullLiteral:
        case NodeTypeZeroesLiteral:
        case NodeTypeThisLiteral:
        case NodeTypeIfBoolExpr:
        case NodeTypeIfVarExpr:
        case NodeTypeForExpr:
        case NodeTypeSwitchExpr:
        case NodeTypeSwitchProng:
        case NodeTypeSwitchRange:
        case NodeTypeLabel:
        case NodeTypeGoto:
        case NodeTypeBreak:
        case NodeTypeContinue:
            zig_panic("TODO more ast rendering");
    }
}


void ast_render(FILE *f, AstNode *node, int indent_size) {
    AstRender ar = {0};
    ar.f = f;
    ar.indent_size = indent_size;
    ar.indent = 0;

    render_node(&ar, node);
}
