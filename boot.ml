(* Build omake-boot.exe *)
#directory "/usr/lib/ocaml/stublibs" ;;
#load "str.cma" ;;

let _ =
  let cmd s =
    print_endline s;
    let x = Sys.command s in
    (if x <> 0 then
      exit (-1)) in
  (if Sys.file_exists "boot" then
    (match Sys.argv with
      | [| _; "-f" |] ->
          (match Sys.os_type with
            | "Unix" | "Cygwin" -> cmd "rm -rf boot"
            | "Win32" -> cmd "rd /s /q boot"
            | _ -> exit (-1))
      | _ ->
        print_endline "./boot already exists. Aborting.";
        print_endline "(If it is okay to remove ./boot at start, please run \"ocaml boot.ml -f\".)";
        exit(-1)));
  cmd "mkdir boot";
  Sys.chdir "boot";
  let ocamlc_config =
    cmd "ocamlc -config >ocamlc-config.txt";
    let f = open_in_bin "ocamlc-config.txt" in
    let s = really_input_string f (in_channel_length f) in
    close_in f;
    s in
  let ocamlopt =
    "ocamlopt -w +a-4-32-30-42-40-41 -g -thread" ^
    (match Sys.os_type with
      | "Cygwin" ->  " -nostdlib -I /usr/lib/ocaml -I /usr/lib/ocaml/threads"
      | _ -> "") in
  let cc =
    ignore (Str.search_forward (Str.regexp "native_c_compiler: \\([^\r\n]*\\)") ocamlc_config 0);
    Str.matched_group 1 ocamlc_config in
  let ccinc =
    (match Sys.os_type with
      | "Unix" | "Win32" ->
          ignore (Str.search_forward (Str.regexp "standard_library: \\([^\r\n]*\\)") ocamlc_config 0);
          " -I" ^  (Str.matched_group 1 ocamlc_config)
      | "Cygwin" -> " -I /usr/lib/ocaml"
      | _ -> exit (-1)) ^ " -I../src/clib" in
  let ar =
    match Sys.os_type with
      | "Unix" | "Cygwin" -> "ar" 
      | "Win32" ->
          ignore (Str.search_forward (Str.regexp "ranlib: \\([^\r\n]*\\)-ranlib") ocamlc_config 0);
          (Str.matched_group 1 ocamlc_config) ^ "-ar" 
      | _ -> exit (-1) in
  let re_slash = Str.regexp "/" in
  let cp src dst =
    match Sys.os_type with
      | "Unix" | "Cygwin" ->
          cmd ("cp " ^ src ^ " " ^ dst)
      | "Win32" ->
          let src = Str.global_replace re_slash "\\\\" src in
          let dst = Str.global_replace re_slash "\\\\" dst in
          cmd ("copy " ^ src ^ " " ^ dst)
      | _ -> exit (-1) in
  let dotslash =
    match Sys.os_type with
      | "Unix" | "Cygwin" -> "./"
      | "Win32" -> ""
      | _ -> exit (-1) in
  let copy_to_boot ?dstname path =
    let dstname =
      match dstname with
        | Some name -> name
        | None ->
            try
              let i = String.rindex path '/' + 1 in
              String.sub path i (String.length path - i)
            with
              Not_found -> path in
    cp ("../" ^ path) dstname in
  let cmi_of_mli mli = cmd (ocamlopt ^ " -c " ^ mli) in
  let cmx_of_ml ml = cmd (ocamlopt ^ " -c " ^ ml) in
  let co_of_c c = cmd (cc ^ ccinc ^ " -o " ^ (c ^ "o") ^ " -c " ^ c) in
  copy_to_boot "src/clib/lm_heap.c" ~dstname:"c_lm_heap.c";
  copy_to_boot "src/clib/lm_channel.c" ~dstname:"c_lm_channel.c";
  copy_to_boot "src/clib/lm_printf.c" ~dstname:"c_lm_printf.c";
  copy_to_boot "src/clib/lm_ctype.c" ~dstname:"c_lm_ctype.c";
  copy_to_boot "src/clib/lm_uname_ext.c" ~dstname:"c_lm_uname_ext.c";
  copy_to_boot "src/clib/lm_unix_cutil.c" ~dstname:"c_lm_unix_cutil.c";
  copy_to_boot "src/clib/lm_compat_win32.c" ~dstname:"c_lm_compat_win32.c";
  copy_to_boot "src/clib/readline.c" ~dstname:"c_readline.c";
  copy_to_boot "src/clib/omake_shell_sys.c" ~dstname:"c_omake_shell_sys.c";
  copy_to_boot "src/clib/omake_shell_spawn.c" ~dstname:"c_omake_shell_spawn.c";
  copy_to_boot "src/clib/fam_win32.c" ~dstname:"c_fam_win32.c";
  copy_to_boot "src/clib/fam_kqueue.c" ~dstname:"c_fam_kqueue.c";
  copy_to_boot "src/clib/fam_inotify.c" ~dstname:"c_fam_inotify.c";
  copy_to_boot "src/clib/lm_notify.c" ~dstname:"c_lm_notify.c";
  copy_to_boot "src/clib/lm_termsize.c" ~dstname:"c_lm_termsize.c";
  copy_to_boot "src/clib/lm_terminfo.c" ~dstname:"c_lm_terminfo.c";
  copy_to_boot "src/clib/lm_fs_case_sensitive.c" ~dstname:"c_lm_fs_case_sensitive.c";
  copy_to_boot "src/libmojave/lm_arg.ml";
  copy_to_boot "src/libmojave/lm_arg.mli";
  copy_to_boot "src/libmojave/lm_array_util.ml";
  copy_to_boot "src/libmojave/lm_array_util.mli";
  copy_to_boot "src/libmojave/lm_bitset.ml";
  copy_to_boot "src/libmojave/lm_bitset.mli";
  copy_to_boot "src/libmojave/lm_channel.ml";
  copy_to_boot "src/libmojave/lm_channel.mli";
  copy_to_boot "src/libmojave/lm_db.ml";
  copy_to_boot "src/libmojave/lm_db.mli";
  copy_to_boot "src/libmojave/lm_debug.ml";
  copy_to_boot "src/libmojave/lm_debug.mli";
  copy_to_boot "src/libmojave/lm_filename_util.ml";
  copy_to_boot "src/libmojave/lm_filename_util.mli";
  copy_to_boot "src/libmojave/lm_fs_case_sensitive.ml";
  copy_to_boot "src/libmojave/lm_fs_case_sensitive.mli";
  copy_to_boot "src/libmojave/lm_handle_table.ml";
  copy_to_boot "src/libmojave/lm_handle_table.mli";
  copy_to_boot "src/libmojave/lm_hash.ml";
  copy_to_boot "src/libmojave/lm_hash.mli";
  copy_to_boot "src/libmojave/lm_hash_code.ml";
  copy_to_boot "src/libmojave/lm_hash_code.mli";
  copy_to_boot "src/libmojave/lm_heap.ml";
  copy_to_boot "src/libmojave/lm_heap.mli";
  copy_to_boot "src/libmojave/lm_index.ml";
  copy_to_boot "src/libmojave/lm_index.mli";
  copy_to_boot "src/libmojave/lm_instrument.ml";
  copy_to_boot "src/libmojave/lm_instrument.mli";
  copy_to_boot "src/libmojave/lm_int_handle_table.ml";
  copy_to_boot "src/libmojave/lm_int_handle_table.mli";
  copy_to_boot "src/libmojave/lm_int_set.ml";
  copy_to_boot "src/libmojave/lm_int_set.mli";
  copy_to_boot "src/libmojave/lm_list_util.ml";
  copy_to_boot "src/libmojave/lm_list_util.mli";
  copy_to_boot "src/libmojave/lm_location.ml";
  copy_to_boot "src/libmojave/lm_location.mli";
  copy_to_boot "src/libmojave/lm_map.ml";
  copy_to_boot "src/libmojave/lm_map.mli";
  copy_to_boot "src/libmojave/lm_map_sig.ml";
  copy_to_boot "src/libmojave/lm_marshal.ml";
  copy_to_boot "src/libmojave/lm_marshal.mli";
  copy_to_boot "src/libmojave/lm_notify.ml";
  copy_to_boot "src/libmojave/lm_notify.mli";
  copy_to_boot "src/libmojave/lm_position.ml";
  copy_to_boot "src/libmojave/lm_position.mli";
  copy_to_boot "src/libmojave/lm_printf.ml";
  copy_to_boot "src/libmojave/lm_printf.mli";
  copy_to_boot "src/libmojave/lm_readline.ml";
  copy_to_boot "src/libmojave/lm_readline.mli";
  copy_to_boot "src/libmojave/lm_set.ml";
  copy_to_boot "src/libmojave/lm_set.mli";
  copy_to_boot "src/libmojave/lm_set_sig.ml";
  copy_to_boot "src/libmojave/lm_string_set.ml";
  copy_to_boot "src/libmojave/lm_string_set.mli";
  copy_to_boot "src/libmojave/lm_string_util.ml";
  copy_to_boot "src/libmojave/lm_string_util.mli";
  copy_to_boot "src/libmojave/lm_symbol.ml";
  copy_to_boot "src/libmojave/lm_symbol.mli";
  copy_to_boot "src/libmojave/lm_terminfo.ml";
  copy_to_boot "src/libmojave/lm_terminfo.mli";
  copy_to_boot "src/libmojave/lm_termsize.ml";
  copy_to_boot "src/libmojave/lm_termsize.mli";
  copy_to_boot "src/libmojave/lm_thread.ml";
  copy_to_boot "src/libmojave/lm_thread.mli";
  copy_to_boot "src/libmojave/lm_thread_core.mli";
  copy_to_boot "src/libmojave/lm_thread_pool.mli";
  copy_to_boot "src/libmojave/lm_thread_sig.ml";
  copy_to_boot "src/libmojave/lm_uname.ml";
  copy_to_boot "src/libmojave/lm_uname.mli";
  copy_to_boot "src/libmojave/lm_unix_util.ml";
  copy_to_boot "src/libmojave/lm_unix_util.mli";
  copy_to_boot "src/libmojave/lm_wild.ml";
  copy_to_boot "src/libmojave/lm_wild.mli";
  copy_to_boot "src/libmojave/lm_thread_pool_system.ml" ~dstname:"lm_thread_pool.ml";
  copy_to_boot "src/libmojave/lm_thread_core_system.ml" ~dstname:"lm_thread_core.ml";
  copy_to_boot "src/front/lm_glob.ml";
  copy_to_boot "src/front/lm_glob.mli";
  copy_to_boot "src/front/lm_hash_cons.ml";
  copy_to_boot "src/front/lm_hash_cons.mli";
  copy_to_boot "src/front/lm_lexer.ml";
  copy_to_boot "src/front/lm_lexer.mli";
  copy_to_boot "src/front/lm_parser.ml";
  copy_to_boot "src/front/lm_parser.mli";
  copy_to_boot "src/magic/omake_gen_magic.ml";
  copy_to_boot "src/ir/omake_cache.ml";
  copy_to_boot "src/ir/omake_cache.mli";
  copy_to_boot "src/ir/omake_cache_type.ml";
  copy_to_boot "src/ir/omake_command.ml";
  copy_to_boot "src/ir/omake_command.mli";
  copy_to_boot "src/ir/omake_command_type.ml";
  copy_to_boot "src/ir/omake_command_type.mli";
  copy_to_boot "src/ir/omake_install.ml";
  copy_to_boot "src/ir/omake_install.mli";
  copy_to_boot "src/ir/omake_ir.ml";
  copy_to_boot "src/ir/omake_ir_free_vars.ml";
  copy_to_boot "src/ir/omake_ir_free_vars.mli";
  copy_to_boot "src/ir/omake_ir_print.ml";
  copy_to_boot "src/ir/omake_ir_print.mli";
  copy_to_boot "src/ir/omake_ir_util.ml";
  copy_to_boot "src/ir/omake_lexer.ml";
  copy_to_boot "src/ir/omake_node.ml";
  copy_to_boot "src/ir/omake_node.mli";
  copy_to_boot "src/ir/omake_node_sig.ml";
  copy_to_boot "src/ir/omake_node_type.ml";
  copy_to_boot "src/ir/omake_options.ml";
  copy_to_boot "src/ir/omake_options.mli";
  copy_to_boot "src/ir/omake_parser.ml";
  copy_to_boot "src/ir/omake_pos.ml";
  copy_to_boot "src/ir/omake_pos.mli";
  copy_to_boot "src/ir/omake_shell_type.ml";
  copy_to_boot "src/ir/omake_state.ml";
  copy_to_boot "src/ir/omake_state.mli";
  copy_to_boot "src/ir/omake_symbol.ml";
  copy_to_boot "src/ir/omake_value_print.ml";
  copy_to_boot "src/ir/omake_value_print.mli";
  copy_to_boot "src/ir/omake_value_type.ml";
  copy_to_boot "src/ir/omake_value_util.ml";
  copy_to_boot "src/ir/omake_value_util.mli";
  copy_to_boot "src/ir/omake_var.ml";
  copy_to_boot "src/ir/omake_var.mli";
  copy_to_boot "src/exec/omake_exec.ml";
  copy_to_boot "src/exec/omake_exec.mli";
  copy_to_boot "src/exec/omake_exec_id.ml";
  copy_to_boot "src/exec/omake_exec_id.mli";
  copy_to_boot "src/exec/omake_exec_local.ml";
  copy_to_boot "src/exec/omake_exec_local.mli";
  copy_to_boot "src/exec/omake_exec_notify.ml";
  copy_to_boot "src/exec/omake_exec_notify.mli";
  copy_to_boot "src/exec/omake_exec_print.ml";
  copy_to_boot "src/exec/omake_exec_print.mli";
  copy_to_boot "src/exec/omake_exec_remote.ml";
  copy_to_boot "src/exec/omake_exec_remote.mli";
  copy_to_boot "src/exec/omake_exec_type.ml";
  copy_to_boot "src/exec/omake_exec_util.ml";
  copy_to_boot "src/exec/omake_exec_util.mli";
  copy_to_boot "src/ast/omake_ast.ml";
  copy_to_boot "src/ast/omake_ast_print.ml";
  copy_to_boot "src/ast/omake_ast_print.mli";
  copy_to_boot "src/ast/omake_ast_util.ml";
  copy_to_boot "src/ast/omake_ast_util.mli";
  copy_to_boot "src/env/omake_ast_lex.mli";
  copy_to_boot "src/env/omake_command_digest.ml";
  copy_to_boot "src/env/omake_command_digest.mli";
  copy_to_boot "src/env/omake_env.ml";
  copy_to_boot "src/env/omake_env.mli";
  copy_to_boot "src/env/omake_exn_print.ml";
  copy_to_boot "src/env/omake_exn_print.mli";
  copy_to_boot "src/env/omake_exp_lex.ml";
  copy_to_boot "src/env/omake_exp_lex.mli";
  copy_to_boot "src/env/omake_gen_parse.ml";
  copy_to_boot "src/env/omake_ir_ast.ml";
  copy_to_boot "src/env/omake_ir_ast.mli";
  copy_to_boot "src/env/omake_ir_semant.ml";
  copy_to_boot "src/env/omake_ir_semant.mli";
  copy_to_boot "src/env/omake_ast_lex.mll";
  copy_to_boot "src/env/omake_ast_parse.input";
  copy_to_boot "src/env/omake_exp_parse.mly";
  copy_to_boot "src/shell/omake_shell_completion.ml";
  copy_to_boot "src/shell/omake_shell_completion.mli";
  copy_to_boot "src/shell/omake_shell_job.ml";
  copy_to_boot "src/shell/omake_shell_job.mli";
  copy_to_boot "src/shell/omake_shell_lex.ml";
  copy_to_boot "src/shell/omake_shell_lex.mli";
  copy_to_boot "src/shell/omake_shell_spawn.ml";
  copy_to_boot "src/shell/omake_shell_spawn.mli";
  copy_to_boot "src/shell/omake_shell_sys.mli";
  copy_to_boot "src/shell/omake_shell_sys_type.ml";
  copy_to_boot "src/shell/omake_shell_parse.mly";
  copy_to_boot ("src/shell/omake_shell_sys_" ^ (match Sys.os_type with "Unix" | "Cygwin" -> "unix" | "Win32" -> "win32" | _ -> exit (-1)) ^ ".ml") ~dstname:"omake_shell_sys.ml";
  copy_to_boot "src/eval/omake_eval.ml";
  copy_to_boot "src/eval/omake_eval.mli";
  copy_to_boot "src/eval/omake_value.ml";
  copy_to_boot "src/eval/omake_value.mli";
  copy_to_boot "src/build/omake_build.ml";
  copy_to_boot "src/build/omake_build.mli";
  copy_to_boot "src/build/omake_build_tee.ml";
  copy_to_boot "src/build/omake_build_tee.mli";
  copy_to_boot "src/build/omake_build_type.ml";
  copy_to_boot "src/build/omake_build_util.ml";
  copy_to_boot "src/build/omake_build_util.mli";
  copy_to_boot "src/build/omake_builtin.ml";
  copy_to_boot "src/build/omake_builtin.mli";
  copy_to_boot "src/build/omake_builtin_type.ml";
  copy_to_boot "src/build/omake_rule.ml";
  copy_to_boot "src/build/omake_rule.mli";
  copy_to_boot "src/build/omake_target.ml";
  copy_to_boot "src/build/omake_target.mli";
  copy_to_boot "src/builtin/omake_builtin_arith.ml";
  copy_to_boot "src/builtin/omake_builtin_arith.mli";
  copy_to_boot "src/builtin/omake_builtin_base.ml";
  copy_to_boot "src/builtin/omake_builtin_base.mli";
  copy_to_boot "src/builtin/omake_builtin_file.ml";
  copy_to_boot "src/builtin/omake_builtin_file.mli";
  copy_to_boot "src/builtin/omake_builtin_fun.ml";
  copy_to_boot "src/builtin/omake_builtin_fun.mli";
  copy_to_boot "src/builtin/omake_builtin_io.ml";
  copy_to_boot "src/builtin/omake_builtin_io.mli";
  copy_to_boot "src/builtin/omake_builtin_io_fun.ml";
  copy_to_boot "src/builtin/omake_builtin_io_fun.mli";
  copy_to_boot "src/builtin/omake_builtin_object.ml";
  copy_to_boot "src/builtin/omake_builtin_object.mli";
  copy_to_boot "src/builtin/omake_builtin_ocamldep.ml";
  copy_to_boot "src/builtin/omake_builtin_rule.ml";
  copy_to_boot "src/builtin/omake_builtin_rule.mli";
  copy_to_boot "src/builtin/omake_builtin_shell.ml";
  copy_to_boot "src/builtin/omake_builtin_shell.mli";
  copy_to_boot "src/builtin/omake_builtin_sys.ml";
  copy_to_boot "src/builtin/omake_builtin_sys.mli";
  copy_to_boot "src/builtin/omake_builtin_target.ml";
  copy_to_boot "src/builtin/omake_builtin_target.mli";
  copy_to_boot "src/builtin/omake_builtin_test.ml";
  copy_to_boot "src/builtin/omake_builtin_test.mli";
  copy_to_boot "src/builtin/omake_builtin_util.ml";
  copy_to_boot "src/builtin/omake_builtin_util.mli";
  copy_to_boot "src/builtin/omake_printf.ml";
  copy_to_boot "src/builtin/omake_printf.mli";
  copy_to_boot "src/main/omake_main.ml";
  copy_to_boot "src/main/omake_main.mli";
  copy_to_boot "src/main/omake_main_util.ml";
  copy_to_boot "src/main/omake_shell.ml";
  copy_to_boot "src/main/omake_shell.mli";
  copy_to_boot "version.txt";
  cmd "ocamllex omake_ast_lex.mll";
  cmx_of_ml "omake_gen_parse.ml";
  cmd (ocamlopt ^ " -o omake_gen_parse.opt.exe  unix.cmxa threads.cmxa  omake_gen_parse.cmx");
  cp "omake_gen_parse.opt.exe" "omake_gen_parse.exe";
  cmd (dotslash ^ "omake_gen_parse.exe -o omake_ast_parse.mly omake_ast_parse.input");
  cmd "ocamlyacc omake_ast_parse.mly";
  cmd "ocamlyacc omake_exp_parse.mly";
  cmd "ocamlyacc omake_shell_parse.mly";
  cmi_of_mli "lm_debug.mli";
  cmx_of_ml "lm_debug.ml";
  cmi_of_mli "lm_string_util.mli";
  cmx_of_ml "lm_string_util.ml";
  cmx_of_ml "omake_gen_magic.ml";
  cmi_of_mli "lm_printf.mli";
  cmx_of_ml "lm_printf.ml";
  cmi_of_mli "lm_heap.mli";
  cmx_of_ml "lm_heap.ml";
  cmi_of_mli "lm_list_util.mli";
  cmx_of_ml "lm_list_util.ml";
  cmi_of_mli "lm_array_util.mli";
  cmx_of_ml "lm_array_util.ml";
  cmx_of_ml "lm_set_sig.ml";
  cmi_of_mli "lm_set_sig.ml";
  cmi_of_mli "lm_set.mli";
  cmx_of_ml "lm_set.ml";
  cmx_of_ml "lm_map_sig.ml";
  cmi_of_mli "lm_map_sig.ml";
  cmi_of_mli "lm_map.mli";
  cmx_of_ml "lm_map.ml";
  cmi_of_mli "lm_int_set.mli";
  cmx_of_ml "lm_int_set.ml";
  cmi_of_mli "lm_termsize.mli";
  cmx_of_ml "lm_termsize.ml";
  cmi_of_mli "lm_terminfo.mli";
  cmx_of_ml "lm_terminfo.ml";
  cmi_of_mli "lm_arg.mli";
  cmx_of_ml "lm_arg.ml";
  cmi_of_mli "lm_index.mli";
  cmx_of_ml "lm_index.ml";
  cmx_of_ml "lm_thread_sig.ml";
  cmi_of_mli "lm_thread_sig.ml";
  cmi_of_mli "lm_thread_core.mli";
  cmx_of_ml "lm_thread_core.ml";
  cmi_of_mli "lm_thread.mli";
  cmx_of_ml "lm_thread.ml";
  cmi_of_mli "lm_string_set.mli";
  cmx_of_ml "lm_string_set.ml";
  cmi_of_mli "lm_hash.mli";
  cmx_of_ml "lm_hash.ml";
  cmi_of_mli "lm_hash_code.mli";
  cmx_of_ml "lm_hash_code.ml";
  cmi_of_mli "lm_symbol.mli";
  cmx_of_ml "lm_symbol.ml";
  cmi_of_mli "lm_location.mli";
  cmx_of_ml "lm_location.ml";
  cmi_of_mli "lm_position.mli";
  cmx_of_ml "lm_position.ml";
  cmi_of_mli "lm_filename_util.mli";
  cmx_of_ml "lm_filename_util.ml";
  cmi_of_mli "lm_uname.mli";
  cmx_of_ml "lm_uname.ml";
  cmi_of_mli "lm_thread_pool.mli";
  cmx_of_ml "lm_thread_pool.ml";
  cmi_of_mli "lm_channel.mli";
  cmx_of_ml "lm_channel.ml";
  cmi_of_mli "lm_unix_util.mli";
  cmx_of_ml "lm_unix_util.ml";
  cmi_of_mli "lm_db.mli";
  cmx_of_ml "lm_db.ml";
  cmi_of_mli "lm_notify.mli";
  cmx_of_ml "lm_notify.ml";
  cmi_of_mli "lm_fs_case_sensitive.mli";
  cmx_of_ml "lm_fs_case_sensitive.ml";
  cmi_of_mli "lm_wild.mli";
  cmx_of_ml "lm_wild.ml";
  cmi_of_mli "lm_readline.mli";
  cmx_of_ml "lm_readline.ml";
  cmi_of_mli "lm_marshal.mli";
  cmx_of_ml "lm_marshal.ml";
  cmi_of_mli "lm_handle_table.mli";
  cmx_of_ml "lm_handle_table.ml";
  cmi_of_mli "lm_int_handle_table.mli";
  cmx_of_ml "lm_int_handle_table.ml";
  cmi_of_mli "lm_bitset.mli";
  cmx_of_ml "lm_bitset.ml";
  cmi_of_mli "lm_instrument.mli";
  cmx_of_ml "lm_instrument.ml";
  cmd (ocamlopt ^ " -a -o lm.cmxa lm_printf.cmx lm_debug.cmx lm_heap.cmx lm_list_util.cmx lm_array_util.cmx lm_set_sig.cmx lm_set.cmx lm_map_sig.cmx lm_map.cmx lm_int_set.cmx lm_termsize.cmx lm_terminfo.cmx lm_arg.cmx lm_index.cmx lm_thread_sig.cmx lm_thread_core.cmx lm_thread.cmx lm_string_util.cmx lm_string_set.cmx lm_hash.cmx lm_hash_code.cmx lm_symbol.cmx lm_location.cmx lm_position.cmx lm_filename_util.cmx lm_uname.cmx lm_thread_pool.cmx lm_channel.cmx lm_unix_util.cmx lm_db.cmx lm_notify.cmx lm_fs_case_sensitive.cmx lm_wild.cmx lm_readline.cmx lm_marshal.cmx lm_handle_table.cmx lm_int_handle_table.cmx lm_bitset.cmx lm_instrument.cmx");
  cmi_of_mli "lm_hash_cons.mli";
  cmx_of_ml "lm_hash_cons.ml";
  cmi_of_mli "lm_lexer.mli";
  cmx_of_ml "lm_lexer.ml";
  cmi_of_mli "lm_parser.mli";
  cmx_of_ml "lm_parser.ml";
  cmi_of_mli "lm_glob.mli";
  cmx_of_ml "lm_glob.ml";
  cmd (ocamlopt ^ " -a -o frt.cmxa lm_hash_cons.cmx lm_lexer.cmx lm_parser.cmx lm_glob.cmx");
  co_of_c "c_lm_heap.c";
  co_of_c "c_lm_channel.c";
  co_of_c "c_lm_printf.c";
  co_of_c "c_lm_ctype.c";
  co_of_c "c_lm_uname_ext.c";
  co_of_c "c_lm_unix_cutil.c";
  co_of_c "c_lm_compat_win32.c";
  co_of_c "c_readline.c";
  co_of_c "c_omake_shell_sys.c";
  co_of_c "c_omake_shell_spawn.c";
  co_of_c "c_fam_win32.c";
  co_of_c "c_fam_kqueue.c";
  co_of_c "c_fam_inotify.c";
  co_of_c "c_lm_notify.c";
  co_of_c "c_lm_termsize.c";
  co_of_c "c_lm_terminfo.c";
  co_of_c "c_lm_fs_case_sensitive.c";
  cmd (ar ^ " cq clib.a c_lm_heap.co c_lm_channel.co c_lm_printf.co c_lm_ctype.co c_lm_uname_ext.co c_lm_unix_cutil.co c_lm_compat_win32.co c_readline.co c_omake_shell_sys.co c_omake_shell_spawn.co c_fam_win32.co c_fam_kqueue.co c_fam_inotify.co c_lm_notify.co c_lm_termsize.co c_lm_terminfo.co c_lm_fs_case_sensitive.co");
  cmd (ocamlopt ^ " -o omake_gen_magic.opt.exe -cclib clib.a unix.cmxa threads.cmxa lm.cmxa frt.cmxa omake_gen_magic.cmx");
  cp "omake_gen_magic.opt.exe" "omake_gen_magic.exe";
  cmd (dotslash ^ "omake_gen_magic.exe -o omake_magic.ml --version version.txt --var \"omake_cc=" ^ cc ^ "\" --var \"omake_cflags=\"  --var \"omake_ccomptype=cc\" --magic --cache-files lm_filename_util.ml lm_hash.ml lm_location.ml lm_map.ml lm_position.ml lm_set.ml lm_symbol.ml omake_value_type.ml omake_cache.ml omake_cache_type.ml omake_node.ml omake_command_digest.ml --omc-files lm_filename_util.ml lm_hash.ml lm_location.ml lm_symbol.ml lm_map.ml lm_set.ml omake_node.ml omake_ir.ml --omo-files lm_filename_util.ml lm_hash.ml lm_lexer.ml lm_location.ml lm_map.ml lm_parser.ml lm_position.ml lm_set.ml lm_symbol.ml omake_value_type.ml omake_cache_type.ml omake_ir.ml omake_node.ml omake_env.ml");
  cmx_of_ml "omake_magic.ml";
  cmd (ocamlopt ^ " -a -o magic.cmxa omake_magic.cmx");
  cmx_of_ml "omake_symbol.ml";
  cmx_of_ml "omake_node_sig.ml";
  cmi_of_mli "omake_state.mli";
  cmx_of_ml "omake_state.ml";
  cmi_of_mli "omake_node_sig.ml";
  cmi_of_mli "omake_node.mli";
  cmx_of_ml "omake_node.ml";
  cmx_of_ml "omake_ir.ml";
  cmi_of_mli "omake_ir.ml";
  cmi_of_mli "omake_var.mli";
  cmx_of_ml "omake_var.ml";
  cmx_of_ml "omake_lexer.ml";
  cmx_of_ml "omake_parser.ml";
  cmx_of_ml "omake_ir_util.ml";
  cmi_of_mli "omake_ir_util.ml";
  cmi_of_mli "omake_ir_free_vars.mli";
  cmx_of_ml "omake_ir_free_vars.ml";
  cmx_of_ml "omake_ast.ml";
  cmx_of_ml "omake_value_type.ml";
  cmi_of_mli "omake_symbol.ml";
  cmi_of_mli "omake_lexer.ml";
  cmi_of_mli "omake_parser.ml";
  cmi_of_mli "omake_ast.ml";
  cmi_of_mli "omake_value_type.ml";
  cmi_of_mli "omake_value_util.mli";
  cmx_of_ml "omake_value_util.ml";
  cmi_of_mli "omake_ast_util.mli";
  cmx_of_ml "omake_ast_util.ml";
  cmi_of_mli "omake_ast_print.mli";
  cmx_of_ml "omake_ast_print.ml";
  cmi_of_mli "omake_ir_print.mli";
  cmx_of_ml "omake_ir_print.ml";
  cmi_of_mli "omake_command_type.mli";
  cmx_of_ml "omake_command_type.ml";
  cmi_of_mli "omake_value_print.mli";
  cmx_of_ml "omake_value_print.ml";
  cmi_of_mli "omake_pos.mli";
  cmx_of_ml "omake_pos.ml";
  cmx_of_ml "omake_shell_type.ml";
  cmi_of_mli "omake_options.mli";
  cmx_of_ml "omake_options.ml";
  cmi_of_mli "omake_exec_id.mli";
  cmx_of_ml "omake_exec_id.ml";
  cmx_of_ml "omake_exec_type.ml";
  cmi_of_mli "omake_exec_type.ml";
  cmi_of_mli "omake_exec_print.mli";
  cmx_of_ml "omake_exec_print.ml";
  cmi_of_mli "omake_exec_util.mli";
  cmx_of_ml "omake_exec_util.ml";
  cmi_of_mli "omake_exec_local.mli";
  cmx_of_ml "omake_exec_local.ml";
  cmi_of_mli "omake_exec_remote.mli";
  cmx_of_ml "omake_exec_remote.ml";
  cmi_of_mli "omake_exec_notify.mli";
  cmx_of_ml "omake_exec_notify.ml";
  cmi_of_mli "omake_exec.mli";
  cmx_of_ml "omake_exec.ml";
  cmx_of_ml "omake_cache_type.ml";
  cmi_of_mli "omake_cache_type.ml";
  cmi_of_mli "omake_cache.mli";
  cmx_of_ml "omake_cache.ml";
  cmi_of_mli "omake_shell_type.ml";
  cmi_of_mli "omake_env.mli";
  cmx_of_ml "omake_env.ml";
  cmi_of_mli "omake_ir_semant.mli";
  cmx_of_ml "omake_ir_semant.ml";
  cmi_of_mli "omake_ir_ast.mli";
  cmx_of_ml "omake_ir_ast.ml";
  cmi_of_mli "omake_exp_parse.mli";
  cmx_of_ml "omake_exp_parse.ml";
  cmi_of_mli "omake_exp_lex.mli";
  cmx_of_ml "omake_exp_lex.ml";
  cmi_of_mli "omake_command_digest.mli";
  cmx_of_ml "omake_command_digest.ml";
  cmi_of_mli "omake_command.mli";
  cmx_of_ml "omake_command.ml";
  cmi_of_mli "omake_ast_lex.mli";
  cmi_of_mli "omake_exn_print.mli";
  cmx_of_ml "omake_exn_print.ml";
  cmi_of_mli "omake_ast_parse.mli";
  cmx_of_ml "omake_ast_parse.ml";
  cmx_of_ml "omake_ast_lex.ml";
  cmi_of_mli "omake_eval.mli";
  cmx_of_ml "omake_eval.ml";
  cmi_of_mli "omake_value.mli";
  cmx_of_ml "omake_value.ml";
  cmi_of_mli "omake_shell_parse.mli";
  cmx_of_ml "omake_shell_parse.ml";
  cmi_of_mli "omake_shell_lex.mli";
  cmx_of_ml "omake_shell_lex.ml";
  cmx_of_ml "omake_shell_sys_type.ml";
  cmi_of_mli "omake_shell_sys_type.ml";
  cmi_of_mli "omake_shell_spawn.mli";
  cmx_of_ml "omake_shell_spawn.ml";
  cmi_of_mli "omake_shell_sys.mli";
  cmx_of_ml "omake_shell_sys.ml";
  cmi_of_mli "omake_shell_job.mli";
  cmx_of_ml "omake_shell_job.ml";
  cmi_of_mli "omake_rule.mli";
  cmx_of_ml "omake_rule.ml";
  cmx_of_ml "omake_build_type.ml";
  cmx_of_ml "omake_builtin_type.ml";
  cmi_of_mli "omake_build_type.ml";
  cmi_of_mli "omake_build_tee.mli";
  cmx_of_ml "omake_build_tee.ml";
  cmi_of_mli "omake_build_util.mli";
  cmx_of_ml "omake_build_util.ml";
  cmi_of_mli "omake_builtin_type.ml";
  cmi_of_mli "omake_builtin.mli";
  cmx_of_ml "omake_builtin.ml";
  cmx_of_ml "omake_main_util.ml";
  cmi_of_mli "omake_shell_completion.mli";
  cmx_of_ml "omake_shell_completion.ml";
  cmi_of_mli "omake_shell.mli";
  cmx_of_ml "omake_shell.ml";
  cmi_of_mli "omake_install.mli";
  cmx_of_ml "omake_install.ml";
  cmi_of_mli "omake_builtin_util.mli";
  cmx_of_ml "omake_builtin_util.ml";
  cmi_of_mli "omake_builtin_io_fun.mli";
  cmx_of_ml "omake_builtin_io_fun.ml";
  cmi_of_mli "omake_target.mli";
  cmx_of_ml "omake_target.ml";
  cmi_of_mli "omake_build.mli";
  cmx_of_ml "omake_build.ml";
  cmi_of_mli "omake_main.mli";
  cmx_of_ml "omake_main.ml";
  cmd (ocamlopt ^ " -a -o ast.cmxa omake_ast.cmx omake_ast_util.cmx omake_ast_print.cmx");
  cmx_of_ml "omake_node_type.ml";
  cmd (ocamlopt ^ " -a -o ir.cmxa omake_options.cmx omake_symbol.cmx omake_state.cmx omake_node_type.cmx omake_node_sig.cmx omake_node.cmx omake_install.cmx omake_ir.cmx omake_var.cmx omake_ir_util.cmx omake_ir_print.cmx omake_ir_free_vars.cmx omake_lexer.cmx omake_parser.cmx omake_value_type.cmx omake_command_type.cmx omake_value_util.cmx omake_value_print.cmx omake_pos.cmx omake_shell_type.cmx omake_command.cmx omake_cache_type.cmx omake_cache.cmx");
  cmd (ocamlopt ^ " -a -o env.cmxa omake_env.cmx omake_exn_print.cmx omake_ast_parse.cmx omake_ast_lex.cmx omake_exp_parse.cmx omake_exp_lex.cmx omake_ir_ast.cmx omake_ir_semant.cmx omake_command_digest.cmx");
  cmd (ocamlopt ^ " -a -o exec.cmxa omake_exec_id.cmx omake_exec_type.cmx omake_exec_print.cmx omake_exec_util.cmx omake_exec_local.cmx omake_exec_remote.cmx omake_exec_notify.cmx omake_exec.cmx");
  cmd (ocamlopt ^ " -a -o eval.cmxa omake_eval.cmx omake_value.cmx");
  cmd (ocamlopt ^ " -a -o shell.cmxa omake_shell_parse.cmx omake_shell_lex.cmx omake_shell_spawn.cmx omake_shell_sys_type.cmx omake_shell_sys.cmx omake_shell_job.cmx omake_shell_completion.cmx");
  cmd (ocamlopt ^ " -a -o build.cmxa omake_rule.cmx omake_build_type.cmx omake_build_tee.cmx omake_build_util.cmx omake_builtin_type.cmx omake_target.cmx omake_builtin.cmx omake_build.cmx");
  cmi_of_mli "omake_printf.mli";
  cmx_of_ml "omake_printf.ml";
  cmi_of_mli "omake_builtin_base.mli";
  cmx_of_ml "omake_builtin_base.ml";
  cmi_of_mli "omake_builtin_arith.mli";
  cmx_of_ml "omake_builtin_arith.ml";
  cmi_of_mli "omake_builtin_file.mli";
  cmx_of_ml "omake_builtin_file.ml";
  cmi_of_mli "omake_builtin_fun.mli";
  cmx_of_ml "omake_builtin_fun.ml";
  cmi_of_mli "omake_builtin_io.mli";
  cmx_of_ml "omake_builtin_io.ml";
  cmi_of_mli "omake_builtin_sys.mli";
  cmx_of_ml "omake_builtin_sys.ml";
  cmi_of_mli "omake_builtin_target.mli";
  cmx_of_ml "omake_builtin_target.ml";
  cmi_of_mli "omake_builtin_shell.mli";
  cmx_of_ml "omake_builtin_shell.ml";
  cmi_of_mli "omake_builtin_rule.mli";
  cmx_of_ml "omake_builtin_rule.ml";
  cmi_of_mli "omake_builtin_object.mli";
  cmx_of_ml "omake_builtin_object.ml";
  cmi_of_mli "omake_builtin_test.mli";
  cmx_of_ml "omake_builtin_test.ml";
  cmx_of_ml "omake_builtin_ocamldep.ml";
  cmd (ocamlopt ^ " -linkall -a -o builtin.cmxa omake_printf.cmx omake_builtin_util.cmx omake_builtin_base.cmx omake_builtin_arith.cmx omake_builtin_file.cmx omake_builtin_fun.cmx omake_builtin_io.cmx omake_builtin_io_fun.cmx omake_builtin_sys.cmx omake_builtin_target.cmx omake_builtin_shell.cmx omake_builtin_rule.cmx omake_builtin_object.cmx omake_builtin_test.cmx omake_builtin_ocamldep.cmx");
  cmd (ocamlopt ^ " -o omake.opt.exe -cclib clib.a unix.cmxa threads.cmxa lm.cmxa frt.cmxa magic.cmxa ast.cmxa ir.cmxa env.cmxa exec.cmxa eval.cmxa shell.cmxa build.cmxa builtin.cmxa omake_main_util.cmx omake_shell.cmx omake_main.cmx");
  cp "omake.opt.exe" "omake.exe";
  cp "omake.exe" "../omake-boot.exe";
  print_endline "done"
