let builddir = Top_config.builddir

let include_dirs = let (//) = Filename.concat in [
	builddir // "src"// "ast" ; 
	builddir // "src"// "build" ; 	
	builddir // "src"// "util" ; 	
	builddir // "src"// "builtin" ; 	
	builddir // "src"// "clib" ; 	
	builddir // "src"// "env" ; 		
	builddir // "src"// "eval" ; 		
	builddir // "src"// "exec" ; 		
	builddir // "src"// "ir" ; 		
	builddir // "src"// "libmojave" ; 		
	builddir // "src"// "magic" ; 		
	builddir // "src"// "main" ; 		
	builddir // "src"// "shell" ; 		
]

let eval_exn str =
  let lexbuf = Lexing.from_string str in
  let phrase = !Toploop.parse_toplevel_phrase lexbuf in
  Toploop.execute_phrase false Format.err_formatter phrase

let _ = 
  begin
    List.iter (fun dir ->
      ignore (eval_exn (Printf.sprintf {s|#directory {|%s|};;|s} dir))) include_dirs;
    ignore (eval_exn {s|#install_printer Lm_symbol.dump_symbol;;|s})
  end
