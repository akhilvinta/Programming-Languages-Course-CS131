%This is the testcase that is used in my report for comparison of runtime between kenken and plain_kenken.

kenken_testcase(
  4,
  [+(6, [[1|1], [1|2], [2|1]]),
   *(96, [[1|3], [1|4], [2|2], [2|3], [2|4]]),
   -(1, [3|1], [3|2]),
   -(1, [4|1], [4|2]),
   +(8, [[3|3], [4|3], [4|4]]),
   *(2, [[3|4]])
  ]
).

%function from 1B discussion video
all_unique([]).
all_unique([Hd | Tl]) :- 
        member(Hd, Tl), !, fail. 
all_unique([_ | Tl]) :- 
        all_unique(Tl).

%function to transpose matrix
transpose_matrix([[]|_], []).
transpose_matrix(KenKen, [Cur_Row|Remaining_Rows]) :- transpose_cur(KenKen, Cur_Row, Remainder), transpose_matrix(Remainder, Remaining_Rows).
transpose_cur([], [], []).
transpose_cur([[Hd|Tl]|Rows], [Hd|Hd_output], [Tl|Tl_output]) :- transpose_cur(Rows, Hd_output, Tl_output).

%function to get the value of a matrix cell given the corresponding row and column position. 
get_matrix_value(KenKen,Row,Col,Value) :- nth(Row, KenKen, Row_output), nth(Col,Row_output,Value).


%kenken

unordered_range(N, Res) :- length(Res,N), fd_domain(Res,1,N), fd_all_different(Res), fd_labeling(Res).

addition(KenKen,(0,[])).
addition(KenKen,(Sum,[[Row|Col]|Tl])) :- get_matrix_value(KenKen,Row,Col,Value), 
          NewSum #= Sum-Value, addition(KenKen,(NewSum,Tl)).
multiplication(KenKen,(1,[])).
multiplication(KenKen,(Prod,[[Row|Col]|Tl])) :- get_matrix_value(KenKen,Row,Col,Value), 
        NewProd #= Prod/Value, multiplication(KenKen, (NewProd,Tl)).
subtraction(KenKen,(Diff,[Row1|Col1],[Row2|Col2])) :- get_matrix_value(KenKen,Row1,Col1,Value1), get_matrix_value(KenKen,Row2,Col2,Value2), (Diff #= Value1-Value2; Diff #= Value2-Value1).
division(KenKen,/(Quotient,[Row1|Col1],[Row2|Col2])) :- get_matrix_value(KenKen,Row1,Col1,Value1), 
                    get_matrix_value(KenKen,Row2,Col2,Value2), 
                    (Quotient #= Value1/Value2; Quotient #= Value2/Value1).

match_all_rules(_,[]).
match_all_rules(KenKen, [Hd | Tl]) :- 
        match_individual_rule(KenKen, Hd), match_all_rules(KenKen, Tl).
match_individual_rule(KenKen, +(Total,List)) :- addition(KenKen, (Total,List)).
match_individual_rule(KenKen, *(Total,List)) :- multiplication(KenKen, (Total,List)).
match_individual_rule(KenKen, -(Total,L1,L2)) :- subtraction(KenKen, (Total,L1,L2)).
match_individual_rule(KenKen, /(Total,L1,L2)) :- division(KenKen, /(Total,L1,L2)).


create_rows(N,KenKen) :- length(KenKen,N), maplist(create_individual_row(N), KenKen).
create_individual_row(N,Given_row) :- unordered_range(N, Given_row).
kenken(N,C,T) :- match_all_rules(T,C), create_rows(N,T), transpose_matrix(T,Y), create_rows(N,Y).


%plain_kenken

addition_plain(KenKen,(0,[])).
addition_plain(KenKen,(Sum,[[Row|Col]|Tl])) :- get_matrix_value(KenKen,Row,Col,Value), NewSum is Sum-Value, addition_plain(KenKen,(NewSum,Tl)).
multiplication_plain(KenKen,(1.0,[])).
multiplication_plain(KenKen,(Prod,[[Row|Col]|Tl])) :- get_matrix_value(KenKen,Row,Col,Value), NewProd is Prod/Value, multiplication_plain(KenKen, (NewProd,Tl)).
subtraction_plain(KenKen,(Diff,[Row1|Col1],[Row2|Col2])) :- get_matrix_value(KenKen,Row1,Col1,Value1), get_matrix_value(KenKen,Row2,Col2,Value2), (Diff is Value1-Value2; Diff is Value2-Value1).
division_plain(KenKen,/(Quotient,[Row1|Col1],[Row2|Col2])) :- get_matrix_value(KenKen,Row1,Col1,Value1), get_matrix_value(KenKen,Row2,Col2,Value2), 
                    ((Quotient is Value1//Value2, 0 is (Value1 mod Value2)); (Quotient is Value2//Value1, 0 is (Value2 mod Value1))).

match_all_rules_plain(_,[]).
match_all_rules_plain(KenKen, [Hd | Tl]) :- 
        match_individual_rule_plain(KenKen, Hd), match_all_rules_plain(KenKen, Tl).
match_individual_rule_plain(KenKen, +(Total,List)) :- addition_plain(KenKen, (Total,List)).
match_individual_rule_plain(KenKen, *(Total,List)) :- multiplication_plain(KenKen, (Total,List)).
match_individual_rule_plain(KenKen, -(Total,L1,L2)) :- subtraction_plain(KenKen, (Total,L1,L2)).
match_individual_rule_plain(KenKen, /(Total,L1,L2)) :- division_plain(KenKen, /(Total,L1,L2)).

create_rows_plain(N,KenKen) :- length(KenKen,N), maplist(create_individual_row_plain(N), KenKen).
create_individual_row_plain(N,Given_row) :- length(Given_row,N), maplist(between(1,N),Given_row), all_unique(Given_row).
plain_kenken(N,C,T) :- create_rows_plain(N,T), transpose_matrix(T,Y), create_rows_plain(N,Y), match_all_rules_plain(T,C).



kenken_testcase_2(
  4,
  [
   -(1, [3|1], [3|2]),
   /(3, [1|1], [1|2])
  ]
).