(* Copyright (c) 2018 OCamlPro
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software. *)

type page
val get_page : string -> page
val page_name : page -> string
val default_page : page

(* Open this module only, as these functions are seen as combinators *)
module OP : sig
  (* [s_] and [t_] never fail, even if no translation is available *)
  (* Return the basic translation *)
  val s_ : ?page:page -> string -> string
  (* Returns the translation, using a possible identifier, and substitutes
     variables if available *)
  val t_ : ?page:page -> ?args:(string * string) list -> string -> string
end


(* Returns the current language or None *)
val get_lang : unit -> string option

(* set the current language. Never fails. *)
val set_lang : string -> unit

(* Current list of known languages *)
val get_langs : unit -> string list

(* Hook called at the end of [set_lang] *)
val set_lang_hook : (string -> unit) ref

(* Hook called when a translation is not found *)
val no_translation_hook : (string -> page -> string -> unit) ref

(* Add translations for a particular language *)
val add_translations : string -> ?page:page -> (string * string) list -> unit

val same : string -> string * string

val add_translation_files : (string * string) list -> unit
val add_translation_file : ?lang:string -> string -> unit
val add_translation_file_content : lang:string -> string -> unit

val parse_error : (?filename:string -> int -> unit) ref
val parse_file_content :
  (?filename:string ->
   string -> (page * (string * string) list) list) ref
