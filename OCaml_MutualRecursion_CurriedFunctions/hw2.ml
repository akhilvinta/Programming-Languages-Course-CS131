(* 
Akhil Vinta
HW 2
405288527 *)

type ('nonterminal, 'terminal) symbol =
| N of 'nonterminal
| T of 'terminal;;

type ('nonterminal, 'terminal) parse_tree =
| Node of 'nonterminal * ('nonterminal, 'terminal) parse_tree list
| Leaf of 'terminal;;

let accept_all string = Some string;;

let accept_empty_suffix = function
    | _::_ -> None
    | x -> Some x;; 

let can_be_parsed_entirely_acceptor suffix = match suffix with 
| [] -> Some []
| head::tail -> None;;

(* type awksub_nonterminals =
| Expr | Lvalue | Incrop | Binop | Num | Term;; 


let awksub_rules =
[
    Expr, [T"("; T")"];
    Expr, [N Num];
    Expr, [N Binop; N Num; N Expr; N Lvalue];
    Lvalue, [T"$"; N Num];  
    Incrop, [T"++"; N Binop; N Num];
    Lvalue, [N Incrop];
    Incrop, [T"--"];
    Binop, [T"+"];
    Binop, [T"-"];
    Num, [T"0"];
    Num, [T"1"];
] 

let awkish_grammar =
(Expr,
function
    | Expr ->
        [[N Term; N Binop; N Expr];
        [N Term]]
    | Term ->
        [[N Num];
        [N Lvalue];
        [N Incrop; N Lvalue];
        [N Lvalue; N Incrop];
        [T"("; N Expr; T")"]]
    | Lvalue ->
        [[T"$"; N Expr]]
    | Incrop ->
        [[T"++"];
        [T"--"]]
    | Binop ->
        [[T"+"];
        [T"-"]]
    | Num ->
        [[T"0"]; [T"1"]; [T"2"]; [T"3"]; [T"4"];
        [T"5"]; [T"6"]; [T"7"]; [T"8"]; [T"9"]]);;
*)


(* Problem 1 *)

let rec get_list_for_nonterminal nonterm rules  = match rules with
| [] -> []
| head::tail -> if (N (fst head)) = nonterm
    then (snd head)::(get_list_for_nonterminal nonterm tail)
    else get_list_for_nonterminal nonterm tail;;

let convert_grammar grammar nonterm =
    let start_symbol = fst grammar in
    let rules = snd grammar in 
    (start_symbol,get_list_for_nonterminal (N nonterm) rules);;

(* Problem 2 *)

let rec parse_tree_leaves parse_tree = match parse_tree with
    | Leaf leaf -> [leaf]
    | Node (node,rest_of_list) -> parse_list rest_of_list
and parse_list mylist = match mylist with
    | []-> []   
    | head::tail -> 
        let left_recur = parse_tree_leaves head in 
        let right_recur = parse_list tail in
        left_recur@right_recur;;

(* Problem 3 *)
(*will match current term being evaluated with the head of string. If nonterminal, acquire new acceptor and call iterate_over_set_of_cur_rules
on whatever that terminal maps to*)
let rec dfs_into_each_individual_rule initial_string grammar_params acceptor cur_string = 
    match grammar_params with (cur_rule, func_grammar) -> match cur_rule with 
        | [] -> (acceptor cur_string)
        | head::tail -> if cur_string = [] 
            then None
            else match cur_rule with
                |[] -> None
                |(N cur_nonterminal)::rest_of_rules -> (*if nonterminal, then iterate over that nonterminals set of rules with corresponding acceptor*)
                    let cur_nonterminal_rules = (func_grammar cur_nonterminal) in 
                    let acceptor_for_remaining_rules = (dfs_into_each_individual_rule initial_string (rest_of_rules,func_grammar) acceptor) in
                    helper_func_for_nonterminal_from_dfs initial_string cur_nonterminal_rules func_grammar acceptor_for_remaining_rules cur_string
                    (*if terminal, check if terminal matchs with first element of string, and if it does, remove first element from string and make new call *)
                |(T cur_terminal)::rest_of_rules -> helper_func_for_terminal_from_dfs (List.hd cur_string) cur_terminal initial_string rest_of_rules func_grammar acceptor (List.tl cur_string)
    (*helper functions to simplify main code control flow*)
and helper_func_for_terminal_from_dfs cur_string_head cur_terminal initial_string rest_of_rules func_grammar acceptor tail_string = 
    if cur_string_head<>cur_terminal then None
    else (dfs_into_each_individual_rule initial_string (rest_of_rules, func_grammar) acceptor tail_string) 
and helper_func_for_nonterminal_from_dfs initial_string cur_rule func_grammar acceptor cur_string =
    iterate_over_set_of_cur_rules initial_string (cur_rule, func_grammar) acceptor cur_string
(*takes any one set of rules that is mapped to by a nonterminal, and calls dfs_into_each_individual_rule on each term in that set of rules*)
and iterate_over_set_of_cur_rules initial_string grammar_params acceptor cur_string = 
    match grammar_params with (cur_rule, func_grammar) -> match cur_rule with
    | [] -> None 
    | head::tail -> 
        (* call dfs_into_each_individual_rule on given rule *)
        let result_of_checking_set_of_rules_on_cur_nonterminal = dfs_into_each_individual_rule initial_string (head,func_grammar) acceptor cur_string in
        if result_of_checking_set_of_rules_on_cur_nonterminal <> None 
        then result_of_checking_set_of_rules_on_cur_nonterminal
        else iterate_over_set_of_cur_rules initial_string (tail, func_grammar) acceptor cur_string;;
        
let make_matcher grammar acceptor initial_string = 
    let start_symbol = (fst grammar) in
    let func_grammar = (snd grammar) in 
    let all_terms_pointed_to_by_start_symbol = (func_grammar start_symbol) in
    iterate_over_set_of_cur_rules initial_string (all_terms_pointed_to_by_start_symbol,func_grammar) acceptor initial_string;;

(* Problem 4 *)

(*nothing changes for this helper function between matcher and parser*)
let rec dfs_into_each_individual_rule_parser initial_string grammar_params acceptor cur_string = 
    match grammar_params with (cur_rule, func_grammar) -> match cur_rule with 
        | [] -> (acceptor cur_string)
        | head::tail -> if cur_string = [] 
            then None
            else match cur_rule with
                |[] -> None
                |(N cur_nonterminal)::rest_of_rules -> 
                    let cur_nonterminal_rules = (func_grammar cur_nonterminal) in 
                    let acceptor_for_remaining_rules = (dfs_into_each_individual_rule_parser initial_string (rest_of_rules,func_grammar) acceptor) in
                    helper_func_for_nonterminal_from_dfs_parser cur_nonterminal initial_string cur_nonterminal_rules func_grammar acceptor_for_remaining_rules cur_string
                |(T cur_terminal)::rest_of_rules -> helper_func_for_terminal_from_dfs_parser (List.hd cur_string) cur_terminal initial_string rest_of_rules func_grammar acceptor (List.tl cur_string)
and helper_func_for_terminal_from_dfs_parser cur_string_head cur_terminal initial_string rest_of_rules func_grammar acceptor tail_string = 
    if cur_string_head<>cur_terminal then None
    else (dfs_into_each_individual_rule_parser initial_string (rest_of_rules, func_grammar) acceptor tail_string) 
and helper_func_for_nonterminal_from_dfs_parser locator initial_string cur_rule func_grammar acceptor cur_string =
    iterate_over_set_of_cur_rules_parser locator initial_string (cur_rule, func_grammar) acceptor cur_string
(*implemented idea of locator, to be able to trace any rule back to the nonterminal it came from*)
and iterate_over_set_of_cur_rules_parser locator initial_string grammar_params acceptor cur_string = 
    match grammar_params with (cur_rule, func_grammar) -> match cur_rule with
    | [] -> None 
    | head::tail -> 
        let result_of_checking_set_of_rules_on_cur_nonterminal = dfs_into_each_individual_rule_parser initial_string (head,func_grammar) acceptor cur_string in
        if result_of_checking_set_of_rules_on_cur_nonterminal <> None 
        then match result_of_checking_set_of_rules_on_cur_nonterminal with
            (*changed functionality from number 3. Add a tuple of nonterminal mapper to rule mapped in output list if terminal matching is a success*)
            | Some s -> Some ((locator,head)::s)
        else iterate_over_set_of_cur_rules_parser locator initial_string (tail, func_grammar) acceptor cur_string;;

(* take input set from previous function call and construct a tree from it. very similar to problem 2*)
let rec recur_right cur_parse_tree_list = function
| [] -> (cur_parse_tree_list, [])
(* if current is a terminal, call simply call recur_right on the tail, creating a leaf *)
| (T cur_terminal)::tail -> ((fst (recur_right cur_parse_tree_list tail)), (Leaf cur_terminal)::(snd (recur_right cur_parse_tree_list tail))) 
(* if current is a nonterminal, call recur on tail and call create_parse_tree to add a node to our output tree *)
| (N cur_nonterminal)::tail -> let (remaining, subtrees) = (recur_right (fst (create_parse_tree_from_parse_list cur_parse_tree_list)) tail) in 
        (remaining,(snd (create_parse_tree_from_parse_list cur_parse_tree_list))::subtrees) 
and create_parse_tree_from_parse_list = function
(* the input to this function will never be empty. *)
| [] -> failwith "not possible"
| head::tail -> ((fst (recur_right tail (snd head))), Node ((fst head),(snd (recur_right tail (snd head)))));;

let make_parser grammar initial_string = 
    let start_symbol = (fst grammar) in
    let func_grammar = (snd grammar) in 
    let all_terms_pointed_to_by_start_symbol = (func_grammar start_symbol) in
    let ret = (iterate_over_set_of_cur_rules_parser start_symbol initial_string (all_terms_pointed_to_by_start_symbol,func_grammar) can_be_parsed_entirely_acceptor initial_string) in
    match ret with 
    | None -> None
    | Some x -> Some (snd (create_parse_tree_from_parse_list x));;


