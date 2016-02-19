
(**
   A generic hash module to make *comparisons faster.*
   This version uses a state for hash-consing.

   Table-based hashing.

   A basic table for adding a hash code to every element.
   Nothing else is done, so comparisons are still slow.

   This table is safe to marshal.

   Items are represented by their indexes into a table.

   This is the fastest implementation, but it is not safe to marshal
   unless you also marshal the table.

   If you need a version that is safe to marshal, consider using the
   HashMarshal below.  
 *)
module Make (Arg : sig
   type t

   (* For debugging *)
   val debug : string

   (** The client needs to provide hash and comparison functions *)
   val hash : t -> int
   val compare : t -> t -> int
end
)
: sig
   type state
   type t

   (** States *)
   val create_state : unit -> state
   val length : state -> int

   (** Normal creation *)

   val create : state ->  Arg.t -> t
   val get : state -> t ->  Arg.t

   (** Hash code *)
   val hash : t -> int

   (** Comparison *)
   val compare : t -> t -> int

   (** Map over an array of hash codes *)
   val map_array : (t -> Arg.t(* elt *) -> 'a) -> state -> 'a array

   (** Fold over all of the items *)
   val fold : ('a -> t -> 'a) -> 'a -> state -> 'a
end
