
(*Problem 1 Test Cases*)
let subset_test0 = subset [] []
let subset_test1 = subset [1;1;1;1;2;3] [2;1;3]
let subset_test2 = not (subset [1] [])
let subset_test3 = subset [] [1]
let subset_test4 = not (subset [1;2;3;5;2] [2;2;3])

(*Problem 2 Test Cases*)
let equal_sets_test0 = equal_sets [] []
let equal_sets_test1 = not (equal_sets [1] [])
let equal_sets_test2 = not (equal_sets [] [1])
let equal_sets_test2 = equal_sets [5;5;1;4] [4;4;4;4;4;4;4;5;1;1]

(*Problem 3 Test Cases*)
let set_union_test0 = equal_sets (set_union [] []) []
let set_union_test1 = equal_sets (set_union [1;2;3] [0;1;2]) [0;1;2;3]
let set_union_test2 = equal_sets (set_union [2] [3]) [2;3]

(*Problem 4 Test Cases*)
let set_all_union_test0 = equal_sets (set_all_union [[1]; [2]]) [1;2]
let set_all_union_test0 = equal_sets (set_all_union [[]; []]) []
let set_all_union_test0 = equal_sets (set_all_union [[1;2]; [2;4]; [3;2]]) [1;2;3;4]

(*Problem 5 Test)

(*Problem 6 Test Cases*)
let computed_fixed_point_test0 = computed_fixed_point (=) sqrt 9. = 1.
let computed_fixed_point_test1 = computed_fixed_point (=) (fun x->x*2) 0 = 0

(*Problem 7 Test Cases*)

type awksub_nonterminals =
  | Akh | Neel | Ari | Zz | Arjun | Scrub | Garbage | Vijay;;

let grammar_rules =
   [Akh, [T"goated"];
    Neel, [T"idiot"];
    Ari, [T"overthinks"];
    Zz, [T"very dumb"];
    Arjun, [T"Doctor"; N Scrub];
    Scrub, [N Vijay; T"Sophia"; N Zz];
    Garbage, [N Vijay; N Neel; N Akh; N Ari; N Arjun];
    Garbage, [T"truck"; T"can"];
    Vijay, [T"Trashhhhhhhh"];
   ]

let baller_grammer = Scrub,grammar_rules
let grammar_test0 = not (filter_reachable baller_grammer = baller_grammer)