(* Helper Module for Z3 SMT Solver *)

exception Error = Z3.Error

let z3Timeout = 30 (* seconds *)

(******************************************************************************)
(******************************************************************************)
(* Constant Value                                                             *)
(******************************************************************************)
(******************************************************************************)

module CONST = struct
  (* String - Name prefix for dummy variable *)
  let _name_dummy : string = "DUMMY"
end

(******************************************************************************)
(******************************************************************************)
(* Context                                                                    *)
(******************************************************************************)
(******************************************************************************)

module Ctx = struct
  type body = string * string
  type t = Z3.context
  type t_ref = t option Stdlib.ref

  let _t_obj : t_ref = Stdlib.ref None

  let body_timeout : unit -> body =
    fun () ->
    (* body_timeout function start *)
    let budget_ms = z3Timeout * 1000 in
    "timeout", budget_ms |> string_of_int
  ;;

  (* body_timeout function end *)

  let create : unit -> unit =
    fun () ->
    (* create function start *)
    let ctx = [ body_timeout () ] in
    _t_obj := ctx |> Z3.mk_context |> Option.some
  ;;

  (* create function end *)

  let read : unit -> t =
    fun () ->
    (* read function start *)
    let _ = if Option.is_none !_t_obj then create () in
    !_t_obj |> Option.get
  ;;
  (* read function end *)
end

(******************************************************************************)
(******************************************************************************)
(* Symbol                                                                     *)
(******************************************************************************)
(******************************************************************************)

module Symbol = struct
  type t = Z3.Symbol.symbol

  let _name_dummy : string = CONST._name_dummy
  let _count_dummy : int Stdlib.ref = Stdlib.ref 0

  let create : string -> t =
    fun name ->
    (* create function start *)
    name |> Z3.Symbol.mk_string (Ctx.read ())
  ;;

  (* create function end *)

  let create_dummy : unit -> t =
    fun () ->
    (* create_dummy function start *)
    let _ = _count_dummy |> Stdlib.incr in
    let name = _name_dummy ^ (!_count_dummy |> string_of_int) in
    name |> Z3.Symbol.mk_string (Ctx.read ())
  ;;

  (* create_dummy function end *)

  let to_string : t -> string =
    fun t ->
    (* to_string function start *)
    Z3.Symbol.to_string t
  ;;
  (* to_string function end *)
end

(******************************************************************************)
(******************************************************************************)
(* Sort                                                                       *)
(******************************************************************************)
(******************************************************************************)

module Sort = struct
  type t = Z3.Sort.sort

  let create_dummy : unit -> t =
    fun () ->
    (* create_dummy function start *)
    () |> Symbol.create_dummy |> Z3.Sort.mk_uninterpreted (Ctx.read ())
  ;;

  (* create_dummy function end *)

  let to_string : t -> string =
    fun t ->
    (* to_string function start *)
    Z3.Sort.to_string t
  ;;
  (* to_string function end *)
end

(******************************************************************************)
(******************************************************************************)
(* Expression                                                                 *)
(******************************************************************************)
(******************************************************************************)

module Expr = struct
  type t = Z3.Expr.expr

  let sort_of_int : unit -> Sort.t = fun () -> Z3.Arithmetic.Integer.mk_sort (Ctx.read ())
  let sort_of_real : unit -> Sort.t = fun () -> Z3.Arithmetic.Real.mk_sort (Ctx.read ())
  let sort_of_bool : unit -> Sort.t = fun () -> Z3.Boolean.mk_sort (Ctx.read ())

  let sort_of_bitvector : int -> Sort.t =
    fun bits -> Z3.BitVector.mk_sort (Ctx.read ()) bits
  ;;

  let sort_of_arr : Sort.t -> Sort.t =
    fun value_sort ->
    (* sort_of_arr function start *)
    let index_sort = sort_of_int () in
    Z3.Z3Array.mk_sort (Ctx.read ()) index_sort value_sort
  ;;

  (* sort_of_arr function end *)

  let of_int : int -> t =
    fun n1 ->
    (* of_int function start *)
    n1 |> Z3.Arithmetic.Integer.mk_numeral_i (Ctx.read ())
  ;;

  (* of_int function end *)

  let of_bool : bool -> t =
    fun b1 ->
    (* of_bool function start *)
    b1 |> Z3.Boolean.mk_val (Ctx.read ())
  ;;

  (* of_bool function end *)

  let zero_ : unit -> t =
    fun () ->
    (* zero_ function start *)
    of_int 0
  ;;

  (* zero_ function end *)

  let one_ : unit -> t =
    fun () ->
    (* one_ function start *)
    of_int 1
  ;;

  (* one_ function end *)

  let true_ : unit -> t =
    fun () ->
    (* true_ function start *)
    of_bool true
  ;;

  (* true_ function end *)

  let false_ : unit -> t =
    fun () ->
    (* false_ function start *)
    of_bool false
  ;;

  (* false_ function end *)

  let read_sort : t -> Sort.t =
    fun e ->
    (* read_sort function start *)
    Z3.Expr.get_sort e
  ;;

  (* read_sort function end *)

  let create_var : Sort.t -> name:string -> t =
    fun sort ~name ->
    (* create_var function start *)
    let symbol = name |> Symbol.create in
    Z3.Expr.mk_const (Ctx.read ()) symbol sort
  ;;

  (* create_var function end *)

  let create_dummy : Sort.t -> t =
    fun sort ->
    (* create_dummy function start *)
    let symbol = Symbol.create_dummy () in
    Z3.Expr.mk_const (Ctx.read ()) symbol sort
  ;;

  (* create_dummy function end *)

  let create_arr : Sort.t -> t =
    fun value_sort ->
    (* create_arr function start *)
    let index_sort = sort_of_int () in
    if value_sort = sort_of_int ()
    then Z3.Z3Array.mk_const_array (Ctx.read ()) index_sort (zero_ ())
    else if value_sort = sort_of_bool ()
    then Z3.Z3Array.mk_const_array (Ctx.read ()) index_sort (false_ ())
    else Error "wrong type of array" |> Stdlib.raise
  ;;

  (* create_arr function end *)

  let read_arr : t -> idx:t -> t =
    fun e1 ~idx ->
    (* read_arr function start *)
    Z3.Z3Array.mk_select (Ctx.read ()) e1 idx
  ;;

  (* read_arr function end *)

  let update_arr : t -> idx:t -> value:t -> t =
    fun e1 ~idx ~value ->
    (* update_arr function start *)
    Z3.Z3Array.mk_store (Ctx.read ()) e1 idx value
  ;;

  (* update_arr function end *)

  let create_add : t -> t -> t =
    fun e1 e2 ->
    (* create_add function start *)
    Z3.Arithmetic.mk_add (Ctx.read ()) [ e1; e2 ]
  ;;

  (* create_add function end *)

  let create_sub : t -> t -> t =
    fun e1 e2 ->
    (* create_sub function start *)
    Z3.Arithmetic.mk_sub (Ctx.read ()) [ e1; e2 ]
  ;;

  (* create_sub function end *)

  let create_mul : t -> t -> t =
    fun e1 e2 ->
    (* create_mul function start *)
    Z3.Arithmetic.mk_mul (Ctx.read ()) [ e1; e2 ]
  ;;

  (* create_mul function end *)

  let create_div : t -> t -> t =
    fun e1 e2 ->
    (* create_div function start *)
    Z3.Arithmetic.mk_div (Ctx.read ()) e1 e2
  ;;

  (* create_div function end *)

  let create_power : t -> t -> t = fun e1 e2 -> Z3.Arithmetic.mk_power (Ctx.read ()) e1 e2
  let create_land : t -> t -> t = fun e1 e2 -> Z3.BitVector.mk_and (Ctx.read ()) e1 e2
  let create_shl : t -> t -> t = fun e1 e2 -> Z3.BitVector.mk_shl (Ctx.read ()) e1 e2
  let create_bvsub : t -> t -> t = fun e1 e2 -> Z3.BitVector.mk_sub (Ctx.read ()) e1 e2
  let create_bvand : t -> t -> t = fun e1 e2 -> Z3.BitVector.mk_and (Ctx.read ()) e1 e2

  let create_bv_numeral : string -> int -> t =
    fun str bits -> Z3.BitVector.mk_numeral (Ctx.read ()) str bits
  ;;

  let create_neg : t -> t =
    fun e1 ->
    (* create_neg function start *)
    Z3.Arithmetic.mk_unary_minus (Ctx.read ()) e1
  ;;

  (* create_neg function end *)

  let create_not : t -> t =
    fun e1 ->
    (* create_not function start *)
    Z3.Boolean.mk_not (Ctx.read ()) e1
  ;;

  (* create_not function end *)

  let create_eq : t -> t -> t =
    fun e1 e2 ->
    (* create_eq function start *)
    Z3.Boolean.mk_eq (Ctx.read ()) e1 e2
  ;;

  (* create_eq function end *)

  let create_neq : t -> t -> t =
    fun e1 e2 ->
    (* create_neq function start *)
    create_eq e1 e2 |> create_not
  ;;

  (* create_neq function end *)

  let create_lt : t -> t -> t =
    fun e1 e2 ->
    (* create_lt function start *)
    Z3.Arithmetic.mk_lt (Ctx.read ()) e1 e2
  ;;

  (* create_lt function end *)

  let create_gt : t -> t -> t =
    fun e1 e2 ->
    (* create_gt function start *)
    Z3.Arithmetic.mk_gt (Ctx.read ()) e1 e2
  ;;

  (* create_gt function end *)

  let create_le : t -> t -> t =
    fun e1 e2 ->
    (* create_le function start *)
    Z3.Arithmetic.mk_le (Ctx.read ()) e1 e2
  ;;

  (* create_le function end *)

  let create_ge : t -> t -> t =
    fun e1 e2 ->
    (* create_ge function start *)
    Z3.Arithmetic.mk_ge (Ctx.read ()) e1 e2
  ;;

  (* create_ge function end *)

  let create_ite : t -> t:t -> f:t -> t =
    fun cond ~t ~f ->
    (* create_ite function start *)
    Z3.Boolean.mk_ite (Ctx.read ()) cond t f
  ;;

  (* create_ite function end *)

  let to_string : t -> string =
    fun e1 ->
    (* to_string function start *)
    Z3.Expr.to_string e1
  ;;
  (* to_string function end *)
end

(******************************************************************************)
(******************************************************************************)
(* Formula                                                                    *)
(******************************************************************************)
(******************************************************************************)

module Fmla = struct
  type t = Expr.t

  let sort : unit -> Sort.t =
    fun () ->
    (* sort function start *)
    Z3.Boolean.mk_sort (Ctx.read ())
  ;;

  (* sort function end *)

  let true_ : unit -> t =
    fun () ->
    (* true_ function start *)
    Z3.Boolean.mk_true (Ctx.read ())
  ;;

  (* true_ function end *)

  let false_ : unit -> t =
    fun () ->
    (* false_ function start *)
    Z3.Boolean.mk_false (Ctx.read ())
  ;;

  (* false_ function end *)

  let uninterpreted_ : unit -> t =
    fun () ->
    (* uninterpreted_ function start *)
    () |> Symbol.create_dummy |> Z3.Boolean.mk_const (Ctx.read ())
  ;;

  (* uninterpreted_ function end *)

  let create_exp : Expr.t -> t =
    fun e1 ->
    (* create_exp function start *)
    e1
  ;;

  (* create_exp function end *)

  let create_not : t -> t =
    fun f1 ->
    (* create_not function start *)
    Z3.Boolean.mk_not (Ctx.read ()) f1
  ;;

  (* create_not function end *)

  let create_and : t list -> t =
    fun fl1 ->
    (* create_and function start *)
    Z3.Boolean.mk_and (Ctx.read ()) fl1
  ;;

  (* create_and function end *)

  let create_or : t list -> t =
    fun fl1 ->
    (* create_or function start *)
    Z3.Boolean.mk_or (Ctx.read ()) fl1
  ;;

  (* create_or function end *)

  let create_imply : t -> t -> t =
    fun f1 f2 ->
    (* create_imply function start *)
    Z3.Boolean.mk_implies (Ctx.read ()) f1 f2
  ;;

  (* create_imply function end *)

  let create_iff : t -> t -> t =
    fun f1 f2 ->
    (* create_iff function start *)
    Z3.Boolean.mk_iff (Ctx.read ()) f1 f2
  ;;

  (* create_iff function end *)

  let create_forall : Expr.t -> t -> t =
    fun e1 f2 ->
    (* create_forall function start *)
    Z3.Quantifier.mk_forall_const (Ctx.read ()) [ e1 ] f2 None [] [] None None
    |> Z3.Quantifier.expr_of_quantifier
  ;;

  (* create_forall function end *)

  let create_exists : Expr.t -> t -> t =
    fun e1 f2 ->
    (* create_exists function start *)
    Z3.Quantifier.mk_exists_const (Ctx.read ()) [ e1 ] f2 None [] [] None None
    |> Z3.Quantifier.expr_of_quantifier
  ;;

  (* create_exists function end *)

  let to_string : t -> string =
    fun f1 ->
    (* to_string function start *)
    Z3.Expr.to_string f1
  ;;
  (* to_string function end *)
end

(*****************************************************************************)
(*****************************************************************************)
(* Model                                                                     *)
(*****************************************************************************)
(*****************************************************************************)

module Model = struct
  type t = Z3.Model.model

  let eval : Expr.t -> model:t -> Expr.t option =
    fun e1 ~model ->
    (* eval function start *)
    Z3.Model.eval model e1 true
  ;;

  (* eval function end *)

  let to_string : t -> string =
    fun m1 ->
    (* to_string function start *)
    Z3.Model.to_string m1
  ;;
  (* to_string function end *)
end

(*****************************************************************************)
(*****************************************************************************)
(* Solver                                                                    *)
(*****************************************************************************)
(*****************************************************************************)

module Solver = struct
  type t = Z3.Solver.solver

  type validity =
    | VAL
    | INVAL
    | UNKNOWN

  type satisfiability =
    | SAT
    | UNSAT
    | UNKNOWN

  let _create : unit -> t = fun () -> Z3.Solver.mk_solver (Ctx.read ()) None
  let _formula_add : t -> Fmla.t list -> unit = fun s1 fl2 -> Z3.Solver.add s1 fl2

  let check_satisfiability : Fmla.t list -> satisfiability * Model.t option =
    fun fl1 ->
    let solver = _create () in
    let res : satisfiability * Model.t option =
      match Z3.Solver.check solver fl1 with
      | UNKNOWN -> UNKNOWN, None
      | UNSATISFIABLE -> UNSAT, None
      | SATISFIABLE -> SAT, solver |> Z3.Solver.get_model
    in
    res
  ;;

  let check_validity : Fmla.t list -> validity * Model.t option =
    fun fl1 ->
    let solver = _create () in
    let fmla = fl1 |> Fmla.create_and |> Fmla.create_not in
    let res : validity * Model.t option =
      match Z3.Solver.check solver [ fmla ] with
      | UNKNOWN -> UNKNOWN, None
      | UNSATISFIABLE -> VAL, None
      | SATISFIABLE -> INVAL, solver |> Z3.Solver.get_model
    in
    res
  ;;

  let is_unknown_sat : satisfiability -> bool =
    fun s1 ->
    (* is_unknown_sat function start *)
    s1 = UNKNOWN
  ;;

  (* is_unknown_sat function end *)

  let is_sat : satisfiability -> bool =
    fun s1 ->
    (* is_sat function start *)
    s1 = SAT
  ;;

  (* is_sat function end *)

  let is_unsat : satisfiability -> bool =
    fun s1 ->
    (* is_unsat function start *)
    s1 = UNSAT
  ;;

  (* is_unsat function end *)

  let is_unknown_val : validity -> bool =
    fun v1 ->
    (* is_unknown_val function start *)
    v1 = UNKNOWN
  ;;

  (* is_unknown_val function end *)

  let is_valid : validity -> bool =
    fun v1 ->
    (* is_valid function start *)
    v1 = VAL
  ;;

  (* is_valid function end *)

  let is_invalid : validity -> bool =
    fun v1 ->
    (* is_invalid function start *)
    v1 = INVAL
  ;;

  (* is_invalid function end *)

  let to_string : t -> string =
    fun s1 ->
    (* to_string function start *)
    Z3.Solver.to_string s1
  ;;

  (* to_string function end *)

  let string_of_satisfiability : satisfiability -> string =
    fun s ->
    (* string_of_satisfiability function start *)
    match s with
    | UNKNOWN -> "UNKNOWN"
    | SAT -> "SAT"
    | UNSAT -> "UNSAT"
  ;;

  (* string_of_satisfiability function end *)

  let string_of_validity : validity -> string =
    fun s ->
    (* string_of_validity function start *)
    match s with
    | UNKNOWN -> "UNKNOWN"
    | VAL -> "VALID"
    | INVAL -> "INVALID"
  ;;
  (* string_of_validity function end *)
end
