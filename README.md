# ocplib-i18n

This repository contains a small PPX + library for handling internationalisation
of projects. The PPX can be used to replace the strings to be translated with
calls to the library, as well as to extract them and generate a `.pot` gettext
file.

In the current version, translations for all supported languages should be
present in `translations/LANG.po` files, and are hard-coded by the PPX. However,
it is planned to have a version with a larger library where we can dynamically
register translations.

## Usage

### From the OCaml code

Two expansions are provided:
- `[%i"text"]` is the translated version or `"text"`, for the currently selected
  language
- `[%if"text"]` is similar, exept that `"text"` is assumed to be a format-string

And the function `Ocplib_i18n.set_lang` can be used to select the currently
active language.

### Managing translations

A translation, identified by it's two-letter ISO code `LANG`, is assumed to be
present as soon as a `translations/LANG.po` exists. To extract all expected
sentences, recompile the project with the environment variable `DUMP_POT` set.

This will generate a `translations/LANG.pot` file. It may contain duplicates, so
it's recommended to first run `msguniq` (from the `gettext` tools) on it.

When the code has changed, the existing translation file and expected sentences
may get out of sync. The PPX will print warnings when that happens. To fix it,
we can again use the `gettext` tools: first generate an up-to-date
`translations/LANG.pot` file as seen above, then run:
```
msgmerge -U translations/LANG.po translations/LANG.pot
```

You can now remove the `LANG.pot` file, and edit the `LANG.po` file to complete the missing translations.

Sample `Makefile` extract:
```Makefile
LANGS = $(patsubst translations/%.po,%,$(wildcard translations/*.po))

translations/$(LANGS:=.pot):
    @for f in $(LANGS); do echo >> translations/$$f.po; done
	@rm -f translations/*.pot
	@DUMP_POT=1 ocp-build -j 1
	@for f in $(LANGS); do \
	  mv translations/$$f.pot translations/$$f.pot.bak; \
	  msguniq translations/$$f.pot.bak > translations/$$f.pot; \
	  rm translations/$$f.pot.bak; \
	done

update-%-translation: translations/%.pot
	@msgmerge -U translations/$*.po translations/$*.pot
    @rm -f translations/$*.pot
```

### Compilation

With `ocp-build`, compile the files needing translation with:
```
comp_requires = "ppx_ocplib_i18n:asm"
requires = "ocplib_i18n"
 files = [
    "foo.ml" ( comp = [ "-ppx" %asm_exe( p = "ppx_ocplib_i18n" ) ] )
  ]
```

With the `ppx` embedded in the source, it is convenient to declare a dependency
of the `ppx` towards the `.po` files themselves: while not strictly true, it
ensures that any files using the `ppx` will get recompiled as soon as the
translations change. You can do it by adding `( more_deps = [ <po_files> ] )` in
its `files=` definition.
