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

(* Returns the current language or None *)
val get_lang : unit -> string option

(* set the current language. Never fails. *)
val set_lang : string -> unit

(* Current list of known languages *)
val get_langs : unit -> string list

(* [s_] and [t_] never fail, even if no translation is available *)
(* Return the basic translation *)
val s_ : string -> string
(* Returns the translation, using a possible identifier, and substitutes
    variables if available *)
val t_ : ?id:string -> ?args:(string * string) list -> string -> string

(* Hook called at the end of [set_lang] *)
val set_lang_hook : (string -> unit) ref

(* Hook called when a translation is not found *)
val no_translation_hook : (string -> string * string option -> unit) ref

(* Add translations for a particular language *)
val add_translations : string -> ?id:string -> (string * string) list -> unit

val same : string -> string * string
