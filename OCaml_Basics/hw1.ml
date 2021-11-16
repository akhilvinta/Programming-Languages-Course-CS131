open Printf

let print_list l = 
    List.iter (fun x->(printf "%d" x)) l;;

(*Problem 1*)
let rec ainlistb a b = match b with
| [] -> false
| head::rest -> head=a || (ainlistb a rest);;

let subset a b = 
    List.for_all (fun x -> ainlistb x b) a;;

(*Problem 2*)
 let rec equal_sets a b = 
    subset a b && subset b a;;

(*Problem 3*)
let rec set_union a b =
    let c = (List.append a b) in
    List.sort_uniq compare c;;

(*Problem 4*)
let set_all_union a =
    List.fold_left set_union [] a;;


let rec all_unions a = match a with
| [] -> []
| head::tail -> set_union head (all_unions tail);;

(* Problem 5 *)
let self_member s = 
    false;;

(*Explanation: A set is represented as a container of an object of a specific type. In Ocaml, this is specifically represented as 'type->list. 
The issue here, however, is that the set itself is not represented in this manner, and therefore it is impossible to represent a set as a member of itself.*)

(*Problem 6*)
let rec computed_fixed_point eq f x =
    if eq (f x) x then 
        x
    else
        computed_fixed_point eq f (f x);;

(*Problem 7*)
type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal;;

let is_terminal_token cur = match cur with
| T a -> true
| N a -> false;;

type awksub_nonterminals =
  | Expr | Lvalue | Incrop | Binop | Num;;

let awksub_rules =
[Expr, [T"("; N Expr; T")"];
    Expr, [N Num];
    Expr, [N Expr; N Binop; N Expr];
    Expr, [N Lvalue];
    Expr, [N Incrop; N Lvalue];
    Expr, [N Lvalue; N Incrop];
    Lvalue, [T"$"; N Expr];
    Incrop, [T"++"];
    Incrop, [T"--"];
    Binop, [T"+"];
    Binop, [T"-"];
    Num, [T"0"];
    Num, [T"1"];
    Num, [T"2"];
    Num, [T"3"];
    Num, [T"4"];
    Num, [T"5"];
    Num, [T"6"];
    Num, [T"7"];
    Num, [T"8"];
    Num, [T"9"]];;

let awksub_grammar = Expr, awksub_rules;;


let get_nonterminals_in_single_terminal_expression cur = 
    List.filter (fun x -> not (is_terminal_token x)) cur;;

let rec gysms gram = match gram with (start,gram_rules) -> 
    match gram_rules with
        | [] -> []
        | head::tail -> set_union [fst head] (gysms ((fst gram),tail));;

let rec get_all_direct_nonterminals_reached_by_single_nonterminal start rules = match rules with
| [] -> []
| head::tail -> if (N (fst head)) = start then
        let direct_for_this_rule = (get_nonterminals_in_single_terminal_expression (snd head)) in
        set_union direct_for_this_rule (get_all_direct_nonterminals_reached_by_single_nonterminal start tail)
    else
        get_all_direct_nonterminals_reached_by_single_nonterminal start tail;;

let rec get_all_direct_nonterminals_reached_by_list_of_nonterminals cur rules = match cur with
| [] -> []
| head::tail -> 
    let temp = set_union cur (get_all_direct_nonterminals_reached_by_single_nonterminal head rules) in
    set_union temp (get_all_direct_nonterminals_reached_by_list_of_nonterminals tail rules);;

let rec get_all_reachable_nonterminals cur rules = match cur with
| [] -> []
| _  -> 
    let temp = (get_all_direct_nonterminals_reached_by_list_of_nonterminals cur rules) in
    if (equal_sets temp cur) then 
        cur
    else
        get_all_reachable_nonterminals (set_union cur temp) rules;; 

let filter_reachable_nonterminals_from_rules reachable_nonterminals rules =
    List.filter (fun x -> (List.mem (N (fst x)) reachable_nonterminals)) rules;;

let filter_reachable g = 
    let start_symbol = fst g in
    let rules = snd g in
    let all_reachable_nonterminals = get_all_reachable_nonterminals [N start_symbol] rules in
    let filtered_list_of_reachable_nonterminals = filter_reachable_nonterminals_from_rules all_reachable_nonterminals rules in
    (start_symbol, filtered_list_of_reachable_nonterminals);;




let is_terminal_token cur = match cur with
| T a -> true
| N a -> false;;

let filter_out_nonterminals cur = 
    List.filter (fun x -> not (is_terminal_token x)) cur;;

let rec can_return_to_symbol rules = function
| [] -> []
| head::tail -> match head with
    | N head_without_N -> set_union (gysms (filter_reachable (head_without_N,rules))) (can_return_to_symbol rules tail);;

let rec all_nonterms_direct cur_nonterm = function
| [] -> []
| head::tail -> if cur_nonterm = (N (fst head)) then
    let only_nonterminals_in_rule = (filter_out_nonterminals (snd head)) in
    set_union (all_nonterms_direct cur_nonterm tail) only_nonterminals_in_rule
    else all_nonterms_direct cur_nonterm tail;;

let rec filter_nonterms rules = function
| [] -> []
| head::tail -> let all_direct_nonterms = all_nonterms_direct (N head) rules in
    if (List.mem head (can_return_to_symbol rules all_direct_nonterms)) 
    then head::(filter_nonterms rules tail)
    else filter_nonterms rules tail;;

let rec grecsyms grammar = 
    let nonterms = gysms grammar in
    filter_nonterms (snd grammar) nonterms;; 