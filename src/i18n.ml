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

type dictionary = (string * int, string) Hashtbl.t

type page = {
  page_name : string;
  page_id : int;
  mutable page_keys : StringSet.t;
}

type dict = {
  dict : dictionary ;
  mutable prepare : (dictionary -> unit) list;
}

let same s = s,s

let current_lang = ref None
let dictionaries = ref StringMap.empty
let current_dict = ref None

let set_lang_hook = ref (fun _lang -> ())
let no_translation_hook = ref (fun _lang _page _s -> ())

let pages = Hashtbl.create 11

let page_name page = page.page_name
let get_page =
  let id = ref 0 in
  fun page_name ->
    try
      Hashtbl.find pages page_name
    with Not_found ->
      let page_id = !id in
      incr id;
      let page = { page_name; page_id; page_keys = StringSet.empty } in
      Hashtbl.add pages page_name page;
      page

let default_page = get_page "Default"

let get_dict lang =
  try
    StringMap.find lang !dictionaries
  with Not_found ->
    let dict = Hashtbl.create 133 in
    let dict = { dict ; prepare = [] } in
    dictionaries := StringMap.add lang dict !dictionaries;
    dict

let set_lang lang =
  current_lang := Some lang;
  current_dict := Some (get_dict lang);
  !set_lang_hook lang

let add_prepare ~lang f =
  let dict = get_dict lang in
  dict.prepare <- f :: dict.prepare

let add_page_translation dict page (s1,s2) =
  page.page_keys <- StringSet.add s1 page.page_keys;
  Hashtbl.add dict (s1,page.page_id) s2

let add_translations lang ?(page=default_page) list =
  add_prepare ~lang (fun dict ->
      List.iter (add_page_translation dict page) list
    )

let prepare_dict dict =
  match dict.prepare with
  | [] -> ()
  | list ->
    List.iter (fun f -> f dict.dict) (List.rev list);
    dict.prepare <- []

module OP = struct

  let s_ ?(page=default_page) s =
    match !current_dict with
    | None -> s
    | Some dict ->
      prepare_dict dict;
      let dict = dict.dict in
      try
        Hashtbl.find dict (s, page.page_id)
      with Not_found ->
        let lang =
          match !current_lang with
          | None -> "<none>"
          | Some lang -> lang
        in
        if not (StringSet.mem s page.page_keys) then
          page.page_keys <- StringSet.add s page.page_keys;
        !no_translation_hook lang page s;
        try
          Hashtbl.find dict (s, default_page.page_id)
        with Not_found -> s

  let t_ ?(page=default_page) ?(args=[]) s =
    let s = s_ ~page s in
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

end

let get_lang () = !current_lang
let get_langs () =
  let list = ref [] in
  StringMap.iter (fun lang _dict -> list := lang :: !list) !dictionaries;
  !list

let parse_error = ref (fun ?(filename="<content>") pos ->
    Printf.eprintf "I18n: error at %s:%d\n%!" filename pos
  )

open Genlex

let lexer = Genlex.make_lexer [ "page"; "=" ]

let parse_file_content ?filename content =
  let char_stream = Stream.of_string content  in
  let token_stream = lexer char_stream in
  let tokens = ref [] in
  Stream.iter (fun token ->
      tokens := (token, Stream.count char_stream) :: !tokens) token_stream;
  let tokens = List.rev !tokens in

  let rec iter page page_translations translations tokens =
    match tokens with
    | (Kwd "page",_) :: (String page_name,_) :: tokens ->
      let translations = (page, page_translations) :: translations in
      let page = get_page page_name in
      iter page [] translations tokens
    | (String s1,_) :: (Kwd "=", _) :: (String "",_) :: tokens ->
      iter page ( (s1,s1) :: page_translations ) translations tokens
    | (String s1,_) :: (Kwd "=", _) :: (String s2,_) :: tokens ->
      iter page ( (s1,s2) :: page_translations ) translations tokens
    | (_, pos) :: _ ->
      !parse_error ?filename pos;
      (page, page_translations) :: translations
    | [] ->
      (page, page_translations) :: translations
  in
  iter default_page [] [] tokens


let parse_file_content = ref parse_file_content

let add_file_content ?filename content dict =
  let translations = !parse_file_content ?filename content in
  List.iter (fun (page, translations) ->
      List.iter (add_page_translation dict page) translations
    ) translations

let add_translation_file_content ~lang content =
  add_prepare ~lang (add_file_content content)

let lang_of_filename filename =
  let basename = String.lowercase (Filename.basename filename) in
  match FileString.last_extension basename with
  | Some ext -> ext
  | None -> basename

let add_translation_file ?lang filename =
  let lang = match lang with
    | Some lang -> lang
    | None -> lang_of_filename filename
  in
  add_prepare ~lang (fun dict ->
      let content = FileString.read_file filename in
      add_file_content ~filename content dict)

let add_translation_files files =
  List.iter (fun (filename, content) ->
      let lang = lang_of_filename filename in
      add_prepare ~lang (add_file_content ~filename content)
    ) files


open OP

let println ?page s args =
  Printf.printf "%s\n%!" (t_ ?page s ~args)

let eprintln ?page s args =
  Printf.eprintf "%s\n%!" (t_ ?page s ~args)

let print ?page s args =
  Printf.printf "%s%!" (t_ ?page s ~args)

let eprint ?page s args =
  Printf.printf "%s%!" (t_ ?page s ~args)

let save_lang ~lang filename =
  StringMap.iter (fun _ dict ->
      prepare_dict dict
    ) !dictionaries;
  let dict = get_dict lang in
  let oc = open_out filename in
  Hashtbl.iter (fun _ page ->
      Printf.fprintf oc "\n(*******************************)\n";
      Printf.fprintf oc "\n     page %S\n" page.page_name;
      Printf.fprintf oc "\n(*******************************)\n\n";
      StringSet.iter (fun key ->
          let v = try Hashtbl.find dict.dict (key, page.page_id)
            with Not_found -> "" in
          let v = if v = key then "" else v in
          Printf.fprintf oc "%S = %S\n" key v
        ) page.page_keys;
    ) pages;
  Printf.fprintf oc "\n";
  close_out oc;
  ()
