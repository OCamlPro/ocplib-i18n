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

(* A page is some piece of context for translations. *)
type page

(* [get_page page_name] query or create a page by name *)
val get_page : string -> page

val page_name : page -> string

(* The default page is used when none is provided. Its page name is
   "Default". *)
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

(* Add translations for a particular language.
   Note that an empty translation (i.e. "") is understood as not found.
   If a translation is not found in the page required, a lookup is
   performed in the default_page.
 *)
val add_translations : string -> ?page:page -> (string * string) list -> unit

(* [declare ~page s] declares that a translation is needed for the string [s].
   If [save_lang] or [extract_lang] is used, the string will be included. *)
val declare : ?page:page -> string -> string

val same : string -> string * string

(* [add_translations_files File2string.files] can be used to add translations
   from embedded files *)
val add_translation_files : (string * string) list -> unit
(* [add_translation_files ?lang filename] reads translations from a
   file. If the [lang] argument is not provided, the extension
   of the file is used (i.e. "toto.fr" -> "fr"). *)
val add_translation_file : ?lang:string -> string -> unit
(* [add_translation_file_content ~lang content] add translations
   by providing the content of a file. *)
val add_translation_file_content : lang:string -> string -> unit

(* This function is called whenever an error occurs when reading a
   translation file. By default, prints a warning. *)
val parse_error : (?filename:string -> int -> unit) ref

(* This function is called to parse a file. By default, it uses the syntax:
  page "Page1"
  "key1" = "translation1"
  "key2" = "translation2"
  page "Page2"
  "key3" = "translation3"
  "key4" = "translation4"
*)
val parse_file_content :
  (?filename:string ->
   string -> (page * (string * string) list) list) ref

(* Print helpers *)
val print : ?page:page -> string -> (string * string) list -> unit
val println : ?page:page -> string -> (string * string) list -> unit
val eprint : ?page:page -> string -> (string * string) list -> unit
val eprintln : ?page:page -> string -> (string * string) list -> unit

(* [save_lang ~lang filename] save the known translations for a particular
   language, together with known missing translations. *)
val save_lang : lang:string -> string -> unit

val extract_lang : lang:string -> (page * (string * string) list) list
