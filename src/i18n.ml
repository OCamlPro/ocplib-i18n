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
open StringCompat

let same s = s,s

let current_lang = ref None
let dictionaries = ref StringMap.empty
let current_dict = ref None

let set_lang_hook = ref (fun _lang -> ())
let no_translation_hook = ref (fun _lang _s -> ())

let get_dict lang =
  try
    StringMap.find lang !dictionaries
  with Not_found ->
    let dict = Hashtbl.create 133 in
    dictionaries := StringMap.add lang dict !dictionaries;
    dict

let set_lang lang =
  current_lang := Some lang;
  current_dict := Some (get_dict lang);
  !set_lang_hook lang

let add_translations lang ?id list =
  let dict = get_dict lang in
  List.iter (fun (s1, s2) -> Hashtbl.add dict (s1,id) s2) list

let s_ ?id s =
  match !current_dict with
  | None -> s
  | Some dict ->
    try
      Hashtbl.find dict (s, id)
    with Not_found ->
      let lang =
        match !current_lang with
        | None -> "<none>"
        | Some lang -> lang
      in
      !no_translation_hook lang (s, id);
      try
        Hashtbl.find dict (s, None)
      with Not_found -> s

let t_ ?id ?(args=[]) s =
  let s = s_ ?id s in
  if args = [] then
    s
  else
    let len = String.length s in
    let b = Buffer.create (2 * len) in
    try
      Buffer.add_substitute b (fun s ->
          try List.assoc s args with Not_found -> Printf.sprintf "${%s}" s) s;
      Buffer.contents b
    with Not_found -> s

let s_ s = s_ s

let get_lang () = !current_lang
let get_langs () =
  let list = ref [] in
  StringMap.iter (fun lang _dict -> list := lang :: !list) !dictionaries;
  !list
