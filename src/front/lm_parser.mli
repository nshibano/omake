open! Lm_printf


val debug_parse       : bool ref
val debug_parsegen    : bool ref
val debug_parsetiming : bool ref
val debug_parse_conflict_is_warning : bool ref

(**
 * Associativity and precedence.
 *)
type assoc =
   LeftAssoc
 | RightAssoc
 | NonAssoc
 | NoneAssoc

val pp_print_assoc : assoc Lm_printf.t

module type PrecedenceArg =
sig
   type t
   type precedence

   (** Precedence control *)
   val prec_min       : precedence
   val prec_max       : precedence

   (** Precedence tables *)
   val empty          : t
   val create_prec_lt : t -> precedence -> assoc  -> t * precedence
   val create_prec_gt : t -> precedence -> assoc  -> t * precedence

   (** Print a precedence *)
   val pp_print_prec  : t -> precedence Lm_printf.t 

   (** Comparison *)
   val add_assoc      : t -> precedence -> assoc -> t
   val assoc          : t -> precedence -> assoc
   val compare        : t -> precedence -> precedence -> int

   (** Tables and sets *)
   module PrecTable   : Lm_map_sig.LmMap with type key = precedence
end

(** Default implementation *)
module ParserPrecedence : PrecedenceArg

exception ParseError of Lm_location.t * string

(**
 * The parser is parameterized over symbol and action names.
 *)
module type ParserArg =
sig
   (** Variable names: the names of terminals and nonterminals *)
   type symbol

   (** A symbol to represent eof *)
   val eof : symbol

   (** For debugging *)
   val to_string : symbol -> string
   val pp_print_symbol : symbol Lm_printf.t 

   (** Sets and tables *)
   val hash_symbol : symbol -> int
   val compare_symbol : symbol -> symbol -> int

   (** Names of semantic actions *)
   type action

   (** For debugging *)
   val pp_print_action :  action Lm_printf.t 

   (** For set and table building *)
   val hash_action : action -> int
   val compare_action : action -> action -> int
end

module MakeParser (Arg : ParserArg) (Precedence : PrecedenceArg) :
sig
   open Arg
   open Precedence

   (** Grammar operations *)
   type t
   type ('a, 'b) lexer = 'a -> symbol * Lm_location.t * 'a * 'b
   type ('a, 'b) eval =
      'a ->                     (* The argument *)
      action ->                 (* The name of the action *)
      Lm_location.t ->                    (* Location of the production *)
      'b list ->                (* The arguments to the action *)
      'a * 'b                   (* The result of the semantic action *)

   (** The empty grammar accepts the empty language *)
   val empty          : t

   (**
    * Add a start symbol.  There can be more than one start symbol,
    * but parsing can only be performed for start variables.
    *)
   val add_start      : t -> symbol -> t
   val get_start      : t -> symbol list

   (** Precedence control *)
   val prec_min       : precedence
   val prec_max       : precedence
   val create_prec_lt : t -> precedence -> assoc  -> t * precedence
   val create_prec_gt : t -> precedence -> assoc  -> t * precedence
   val add_assoc      : t -> precedence -> assoc  -> t
   val add_prec       : t -> precedence -> symbol -> t
   val find_prec      : t -> symbol -> precedence

   (** Add a production *)
   val add_production :
      t ->                      (* The initial grammar *)
      action ->                 (* The name of the semantic action *)
      symbol ->                 (* The left-hand-side of the production *)
      symbol list ->            (* The right-hand-side of the production *)
      symbol option ->          (* Optional precedence is the same as that of the symbol *)
      t

   (** Delete a production based on the name of the semantic action *)
   val remove_production :
      t ->                      (* The initial grammar *)
      action ->                 (* The name of the semantic action *)
      t

   (**
    * Take the union of two parsers.
    * Assumes that productions with the same action name are the same.
    *)
   val union : t -> t -> t

   (**
    * Build the parser if it isn't already built.
    * This step is entirely optional.  Call it if you want
    * to check for errors in the current grammar.
    *)
   val compile : t -> unit

   (**
    * Hash code for the parser.
    *)
   val hash : t -> int

   (** Force a parser build, possibly in debug mode *)
   val build : t -> bool -> unit

   (** Print the grammar *)
   val pp_print_parser : t Lm_printf.t 

   (** Now the actual machine *)
   val parse :
      t ->                      (* The machine *)
      symbol ->                 (* The start symbol *)
      ('a, 'b) lexer ->         (* The lexer *)
      ('a, 'b) eval ->          (* The semantic action evaluator *)
      'a ->                     (* The argument *)
      'a * 'b                   (* The result *)
end

