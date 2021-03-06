(DEFINE-PARSER *C11-PARSER*

  (:START-SYMBOL |translation_unit|)

  (:TERMINALS (
               |identifier| |typedef_name| |func_name| |string_literal|
               |i_constant| |f_constant| |enum_name|

               |alignas| |alignof| |atomic| |generic| |noreturn| |static_assert|
               |thread_local| |case| |default| |if| |else| |switch| |while| |do|
               |for| |goto| |continue| |break| |return| |struct| |union| |enum|
               |...| |complex| |imaginary| |bool| |char| |short| |int| |long|
               |signed| |unsigned| |float| |double| |void| |const| |restrict|
               |volatile| |typedef| |extern| |static| |auto| |register| |inline|
               |sizeof|

               ^= \|= -= <<= >>= &= && |\|\|| *= /= %= += -> ++ -- << >>
               <= >= == !=))


  ;; renaming terminals:

  (IDENTIFIER |identifier|)
  (TYPEDEF_NAME |typedef_name|)
  (FUNC_NAME |func_name|)

  (STRING_LITERAL |string_literal|)
  (I_CONSTANT     |i_constant|)
  (F_CONSTANT     |f_constant|)

  (|constant| I_CONSTANT F_CONSTANT ) ;ENUMERATION_CONSTANT
  (|string| STRING_LITERAL FUNC_NAME)



  (ALIGNAS |alignas|)
  (ALIGNOF |alignof|)
  (ATOMIC |atomic|)
  (GENERIC |generic|)
  (NORETURN |noreturn|)
  (STATIC_ASSERT |static_assert|)
  (THREAD_LOCAL |thread_local|)
  (CASE |case|)
  (DEFAULT |default|)
  (IF |if|)
  (ELSE |else|)
  (SWITCH |switch|)
  (WHILE |while|)
  (DO |do|)
  (FOR |for|)
  (GOTO |goto|)
  (CONTINUE |continue|)
  (BREAK |break|)
  (RETURN |return|)
  (STRUCT |struct|)
  (UNION |union|)
  (ENUM |enum|)
  (ELLIPSIS |...|)
  (COMPLEX |complex|)
  (IMAGINARY |imaginary|)
  (BOOL |bool|)
  (CHAR |char|)
  (SHORT |short|)
  (INT |int|)
  (LONG |long|)
  (SIGNED |signed|)
  (UNSIGNED |unsigned|)
  (FLOAT |float|)
  (DOUBLE |double|)
  (VOID |void|)
  (CONST |const|)
  (RESTRICT |restrict|)
  (VOLATILE |volatile|)
  (TYPEDEF |typedef|)
  (EXTERN |extern|)
  (STATIC |static|)
  (AUTO |auto|)
  (REGISTER |register|)
  (INLINE |inline|)
  (SIZEOF |sizeof|)


  (XOR_ASSIGN  |^=|)
  (OR_ASSIGN   \|=)
  (SUB_ASSIGN  |-=|)
  (LEFT_ASSIGN |<<=|)
  (RIGHT_ASSIGN |>>=|)
  (AND_ASSIGN |&=|)
  (AND_OP |&&|)
  (OR_OP \|\|)
  (MUL_ASSIGN |*=|)
  (DIV_ASSIGN |/=|)
  (MOD_ASSIGN |%=|)
  (ADD_ASSIGN |+=|)
  (PTR_OP |->|)
  (INC_OP |++|)
  (DEC_OP |--|)
  (LEFT_OP |<<|)
  (RIGHT_OP |>>|)
  (LE_OP |<=|)
  (GE_OP |>=|)
  (EQ_OP |==|)
  (NE_OP |!=|)

  ;; productions:

  (|primary_expression|
   IDENTIFIER
   |constant|
   |string|
   (\( |expression| \))
   |generic_selection|)

  (|generic_selection|
   (GENERIC \( |assignment_expression| \, |generic_assoc_list| \)))

  (|generic_assoc_list|
   |generic_association|
   (|generic_assoc_list| \, |generic_association|))

  (|generic_association|
   (|type_name| \: |assignment_expression|)
   (DEFAULT \: |assignment_expression|))

  (|postfix_expression|
   |primary_expression|
   (|postfix_expression| [ |expression| ])
   (|postfix_expression| \( \))
   (|postfix_expression| \( |argument_expression_list| \))
   (|postfix_expression| |.| IDENTIFIER)
   (|postfix_expression| PTR_OP IDENTIFIER)
   (|postfix_expression| INC_OP)
   (|postfix_expression| DEC_OP)
   (\( |type_name| \) { |initializer_list| })
   (\( |type_name| \) { |initializer_list| \, }))

  (|argument_expression_list|
   |assignment_expression|
   (|argument_expression_list| \, |assignment_expression|))

  (|unary_expression|
   |postfix_expression|
   (INC_OP |unary_expression|)
   (DEC_OP |unary_expression|)
   (|unary_operator| |cast_expression|)
   (SIZEOF |unary_expression|)
   (SIZEOF \( |type_name| \))
   (ALIGNOF \( |type_name| \)))

  (|unary_operator|
   &
   *
   +
   -
   ~
   !)

  (|cast_expression|
   |unary_expression|
   (\( |type_name| \) |cast_expression|))

  (|multiplicative_expression|
   |cast_expression|
   (|multiplicative_expression| * |cast_expression|)
   (|multiplicative_expression| / |cast_expression|)
   (|multiplicative_expression| % |cast_expression|))

  (|additive_expression|
   |multiplicative_expression|
   (|additive_expression| + |multiplicative_expression|)
   (|additive_expression| - |multiplicative_expression|))

  (|shift_expression|
   |additive_expression|
   (|shift_expression| LEFT_OP |additive_expression|)
   (|shift_expression| RIGHT_OP |additive_expression|))

  (|relational_expression|
   |shift_expression|
   (|relational_expression| < |shift_expression|)
   (|relational_expression| > |shift_expression|)
   (|relational_expression| LE_OP |shift_expression|)
   (|relational_expression| GE_OP |shift_expression|))

  (|equality_expression|
   |relational_expression|
   (|equality_expression| EQ_OP |relational_expression|)
   (|equality_expression| NE_OP |relational_expression|))

  (|and_expression|
   |equality_expression|
   (|and_expression| & |equality_expression|))

  (|exclusive_or_expression|
   |and_expression|
   (|exclusive_or_expression| ^ |and_expression|))

  (|inclusive_or_expression|
   |exclusive_or_expression|
   (|inclusive_or_expression| \| |exclusive_or_expression|))

  (|logical_and_expression|
   |inclusive_or_expression|
   (|logical_and_expression| AND_OP |inclusive_or_expression|))

  (|logical_or_expression|
   |logical_and_expression|
   (|logical_or_expression| OR_OP |logical_and_expression|))

  (|conditional_expression|
   |logical_or_expression|
   (|logical_or_expression| ? |expression| \: |conditional_expression|))

  (|assignment_expression|
   |conditional_expression|
   (|unary_expression| |assignment_operator| |assignment_expression|))

  (|assignment_operator|
   =
   MUL_ASSIGN
   DIV_ASSIGN
   MOD_ASSIGN
   ADD_ASSIGN
   SUB_ASSIGN
   LEFT_ASSIGN
   RIGHT_ASSIGN
   AND_ASSIGN
   XOR_ASSIGN
   OR_ASSIGN)

  (|expression|
   |assignment_expression|
   (|expression| \, |assignment_expression|))

  (|constant_expression|
   |conditional_expression|)

  (|declaration|
   (|declaration_specifiers| \;)
   (|declaration_specifiers| |init_declarator_list| \;)
   |static_assert_declaration|)

  (|declaration_specifiers|
   (|storage_class_specifier| |declaration_specifiers|)
   |storage_class_specifier|
   (|type_specifier| |declaration_specifiers|)
   |type_specifier|
   (|type_qualifier| |declaration_specifiers|)
   |type_qualifier|
   (|function_specifier| |declaration_specifiers|)
   |function_specifier|
   (|alignment_specifier| |declaration_specifiers|)
   |alignment_specifier|)

  (|init_declarator_list|
   |init_declarator|
   (|init_declarator_list| \, |init_declarator|))

  (|init_declarator|
   (|declarator| = |initializer|)
   |declarator|)

  (|storage_class_specifier|
   TYPEDEF
   EXTERN
   STATIC
   THREAD_LOCAL
   AUTO
   REGISTER)

  (|type_specifier|
   VOID
   CHAR
   SHORT
   INT
   LONG
   FLOAT
   DOUBLE
   SIGNED
   UNSIGNED
   BOOL
   COMPLEX
   IMAGINARY
   |atomic_type_specifier|
   |struct_or_union_specifier|
   |enum_specifier|
   TYPEDEF_NAME)

  (|struct_or_union_specifier|
   (|struct_or_union| { |struct_declaration_list| })
   (|struct_or_union| IDENTIFIER { |struct_declaration_list| })
   (|struct_or_union| IDENTIFIER))

  (|struct_or_union|
   STRUCT
   UNION)

  (|struct_declaration_list|
   |struct_declaration|
   (|struct_declaration_list| |struct_declaration|))

  (|struct_declaration|
   (|specifier_qualifier_list| \;)
   (|specifier_qualifier_list| |struct_declarator_list| \;)
   |static_assert_declaration|)

  (|specifier_qualifier_list|
   (|type_specifier| |specifier_qualifier_list|)
   |type_specifier|
   (|type_qualifier| |specifier_qualifier_list|)
   |type_qualifier|)

  (|struct_declarator_list|
   |struct_declarator|
   (|struct_declarator_list| \, |struct_declarator|))

  (|struct_declarator|
   (\: |constant_expression|)
   (|declarator| \: |constant_expression|)
   |declarator|)

  (|enum_specifier|
   (ENUM { |enumerator_list| })
   (ENUM { |enumerator_list| \, })
   (ENUM IDENTIFIER { |enumerator_list| })
   (ENUM IDENTIFIER { |enumerator_list| \, })
   (ENUM IDENTIFIER))

  (|enumerator_list|
   |enumerator|
   (|enumerator_list| \, |enumerator|))

  (|enumeration_constant|
   IDENTIFIER)

  (|enumerator|
   (|enumeration_constant| = |constant_expression|)
   |enumeration_constant|)

    (|declarator|
   (|pointer| |direct_declarator|)
   |direct_declarator|)

  (|direct_declarator|
   IDENTIFIER
   (\( |declarator| \))
   (|direct_declarator| [ ])
   (|direct_declarator| [ * ])
   (|direct_declarator| [ STATIC |type_qualifier_list| |assignment_expression| ])
   (|direct_declarator| [ STATIC |assignment_expression| ])
   (|direct_declarator| [ |type_qualifier_list| * ])
   (|direct_declarator| [ |type_qualifier_list| STATIC |assignment_expression| ])
   (|direct_declarator| [ |type_qualifier_list| |assignment_expression| ])
   (|direct_declarator| [ |type_qualifier_list| ])
   (|direct_declarator| [ |assignment_expression| ])
   (|direct_declarator| \( |parameter_type_list| \))
   (|direct_declarator| \( \))
   (|direct_declarator| \( |identifier_list| \)))

  (|pointer|
   (* |type_qualifier_list| |pointer|)
   (* |type_qualifier_list|)
   (* |pointer|)
   *)

  (|type_qualifier_list|
   |type_qualifier|
   (|type_qualifier_list| |type_qualifier|))

  (|parameter_type_list|
   (|parameter_list| \, ELLIPSIS)
   |parameter_list|)

  (|parameter_list|
   |parameter_declaration|
   (|parameter_list| \, |parameter_declaration|))

  (|parameter_declaration|
   (|declaration_specifiers| |declarator|)
   (|declaration_specifiers| |abstract_declarator|)
   |declaration_specifiers|)

  (|identifier_list|
   IDENTIFIER
   (|identifier_list| \, IDENTIFIER))

  (|type_name|
   (|specifier_qualifier_list| |abstract_declarator|)
   |specifier_qualifier_list|)

  (|abstract_declarator|
   (|pointer| |direct_abstract_declarator|)
   |pointer|
   |direct_abstract_declarator|)

  (|direct_abstract_declarator|
   (\( |abstract_declarator| \))
   ([ ])
   ([ * ])
   ([ STATIC |type_qualifier_list| |assignment_expression| ])
   ([ STATIC |assignment_expression| ])
   ([ |type_qualifier_list| STATIC |assignment_expression| ])
   ([ |type_qualifier_list| |assignment_expression| ])
   ([ |type_qualifier_list| ])
   ([ |assignment_expression| ])
   (|direct_abstract_declarator| [ ])
   (|direct_abstract_declarator| [ * ])
   (|direct_abstract_declarator| [ STATIC |type_qualifier_list| |assignment_expression| ])
   (|direct_abstract_declarator| [ STATIC |assignment_expression| ])
   (|direct_abstract_declarator| [ |type_qualifier_list| |assignment_expression| ])
   (|direct_abstract_declarator| [ |type_qualifier_list| STATIC |assignment_expression| ])
   (|direct_abstract_declarator| [ |type_qualifier_list| ])
   (|direct_abstract_declarator| [ |assignment_expression| ])
   (\( \))
   (\( |parameter_type_list| \))
   (|direct_abstract_declarator| \( \))
   (|direct_abstract_declarator| \( |parameter_type_list| \)))

  (|initializer|
   ({ |initializer_list| })
   ({ |initializer_list| \, })
   |assignment_expression|)

  (|initializer_list|
   (|designation| |initializer|)
   |initializer|
   (|initializer_list| \, |designation| |initializer|)
   (|initializer_list| \, |initializer|))

  (|designation|
   (|designator_list| =))

  (|designator_list|
   |designator|
   (|designator_list| |designator|))

  (|designator|
   ([ |constant_expression| ])
   (|.| IDENTIFIER))

  (|static_assert_declaration|
   (STATIC_ASSERT \( |constant_expression| \, STRING_LITERAL \) \;))

  (|statement|
   |labeled_statement|
   |compound_statement|
   |expression_statement|
   |selection_statement|
   |iteration_statement|
   |jump_statement|)

  (|labeled_statement|
   (IDENTIFIER \: |statement|)
   (CASE |constant_expression| \: |statement|)
   (DEFAULT \: |statement|))

  (|compound_statement|
   ({ })
   ({ |block_item_list| }))

  (|block_item_list|
   |block_item|
   (|block_item_list| |block_item|))

  (|block_item|
   |declaration|
   |statement|)

  (|expression_statement|
   \;
   (|expression| \;))

  (|selection_statement|
   (IF \( |expression| \) |statement| ELSE |statement|)
   (IF \( |expression| \) |statement|)
   (SWITCH \( |expression| \) |statement|))

  (|iteration_statement|
   (WHILE \( |expression| \) |statement|)
   (DO |statement| WHILE \( |expression| \) \;)
   (FOR \( |expression_statement| |expression_statement|              \) |statement|)
   (FOR \( |expression_statement| |expression_statement| |expression| \) |statement|)
   (FOR \( |declaration| |expression_statement|              \) |statement|)
   (FOR \( |declaration| |expression_statement| |expression| \) |statement|))

  (|jump_statement|
   (GOTO IDENTIFIER \;)
   (CONTINUE \;)
   (BREAK \;)
   (RETURN \;)
   (RETURN |expression| \;))

  (|translation_unit|
   |external_declaration|
   (|translation_unit| |external_declaration|))

  (|external_declaration|
   |function_definition|
   |declaration|)

  (|function_definition|
   (|declaration_specifiers| |declarator| |declaration_list| |compound_statement|)
   (|declaration_specifiers| |declarator|                    |compound_statement|))

  (|declaration_list|
   |declaration|
   (|declaration_list| |declaration|))


  )


#-(and)
(let ((*PRINT-PRETTY*   nil)
      (*PRINT-LEVEL*   nil)
      (*PRINT-LENGTH*   nil)
      (*PRINT-CIRCLE*   nil)
      (*PRINT-CASE*   :upcase)
      (*PRINT-READABLY*)
      (*PRINT-GENSYM*   T)
      (*PRINT-BASE*   10 )
      (*PRINT-RADIX*   nil)
      (*PRINT-ARRAY*   T)
      (*PRINT-LINES*   nil)
      (*PRINT-ESCAPE*   T)
      (*PRINT-RIGHT-MARGIN*   110))
 (pprint
  (mapcar (lambda (prod)
            `(--> ,(first prod)
                  ,(case (length (rest prod))
                     ((0) '(seq))
                     ((1) (if (listp (second prod))
                              `(seq ,@(second prod))
                              (second prod)))
                     (otherwise
                      `(alt ,@(mapcar (lambda (rhs)
                                        (if (listp rhs)
                                            `(seq ,@rhs)
                                            rhs))
                                      (rest prod)))))))
          '())))
