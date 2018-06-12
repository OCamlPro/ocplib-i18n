
open I18n.OP

let page = I18n.get_page "Test"

let () =
  I18n.set_lang "fr";
  I18n.add_translation_files Trans.files;
  Printf.eprintf "%s !\n%!" (s_ "Hello World");
  Printf.eprintf "%s !\n%!" (s_ ~page "Hello World");
  Printf.eprintf "%s\n%!" (t_ "My name is ${name}" ~args:["name", "Joe"]);
  I18n.set_lang "en";
  Printf.eprintf "%s !\n%!" (s_ "Hello World");
  I18n.eprintln ~page "Hello World !" [];

  let file =  "translations.fr" in
  let msg = I18n.declare "Translations saved in ${file}" in
  I18n.save_lang ~lang:"fr" file;
  I18n.set_lang "fr";
  I18n.eprintln msg ["file", file ];
  ()
