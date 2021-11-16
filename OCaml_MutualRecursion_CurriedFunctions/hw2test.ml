(* Problem 5 *)

type food_nonterminals =
| Menu | Only_Appetizer | Appetizer | Only_Entree | Entree | Pizza | Pasta | Topping | Add_Topping | Nonveg | Veg;; 


let food_grammar = (Menu,
function
    | Menu -> [[N Only_Appetizer];
                [N Only_Entree];
                [N Appetizer; N Entree]]               
    | Only_Appetizer -> [[N Appetizer]]
    | Appetizer -> [[N Nonveg];
                    [N Veg]]
    | Only_Entree -> [[N Entree]]
    | Entree -> [[T"Entree 1:"; N Pizza];
                    [T"Entree 2:"; N Pasta]]
    | Pizza  -> [[T"Hot"; N Pizza];
                    [T"Savory"; N Pizza];
                    [T"Greasy"; N Pizza];
                    [T"Pizza"; N Topping];
                    [T"Pizza"]]
    | Pasta  -> [[T"Marinara"; N Pasta];
                    [T"Bolognese"; N Pasta];
                    [T"Pasta"; N Topping]];
    | Topping -> [[T"with"; N Add_Topping]]
    | Add_Topping -> [[T"extra cheese and"; N Add_Topping];
                        [T"extra sauce and"; N Add_Topping];
                        [T"extra meat and"; N Add_Topping];
                        [T"straight up sauce"]]
    | Nonveg  ->  [[T"Chicken"];
                    [T"Beef"];
                    [T"Fish"]]
    | Veg -> [[T"No veg here"];
                [N Nonveg]]);;

let matcher_test =
((make_matcher food_grammar accept_all
    ["Entree 1:"; "Pizza"; "with"; "straight up sauce"; "nonsense"])
= Some ["nonsense"]);;

(*This test case tests if the matcher is able to follow the input string through various nonterminal nodes.
It also tests if the matcher can filter out the suffix of the string that does not match and return that with our option variable.*)

(* Problem 6 *)
let parser_test = (make_parser food_grammar ["Entree 1:"; "Pizza"; "with"; "straight up sauce"])
    = Some
    (Node (Menu,
        [Node (Only_Entree,
        [Node (Entree,
            [Leaf "Entree 1:";
            Node (Pizza,
            [Leaf "Pizza";
                Node (Topping,
                [Leaf "with"; Node (Add_Topping, [Leaf "straight up sauce"])])])])])]));;

(*This test case is the reverse of the test_matcher case. Simply ensures that the matcher, and therefore parser, is taking 
the right steps toward the solution, in a dfs manner*)



