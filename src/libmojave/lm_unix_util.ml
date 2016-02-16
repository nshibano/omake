type registry_hkey =
  | HKEY_CLASSES_ROOT
  | HKEY_CURRENT_CONFIG
  | HKEY_CURRENT_USER
  | HKEY_LOCAL_MACHINE
  | HKEY_USERS

external print_stack_pointer : unit -> unit = "lm_print_stack_pointer"
external registry_find   : registry_hkey -> string -> string -> string = "caml_registry_find"
external getpwents : unit -> Unix.passwd_entry list = "lm_getpwents"

external moncontrol : bool -> unit = "lm_moncontrol"


let pp_time buf secs =
  if secs < 60. then
    Format.fprintf buf "%0.2f sec" secs
  else
    let subsec, sec = modf secs in
    let sec = int_of_float sec in
    let h = sec / 3600 in
    let m = (sec / 60) mod 60 in
    let s = sec mod 60 in
    if h > 0 then
      Format.fprintf buf "%d hrs %02d min %05.2f sec" h m (float s +. subsec)
    else
      Format.fprintf buf "%d min %05.2f sec" m (float s +. subsec)

(*
 * Read the exact amount.
 *)
let rec really_read fd (buf : bytes) off len =
   if len <> 0 then
      let amount = Unix.read fd buf off len in
      if amount = 0 then
        failwith "really_read"
      else 
        really_read fd buf (off + amount) (len - amount)


let rec complete_write fd buf off len =
   let count = Unix.write fd buf off len in
   if count < len then
     complete_write fd buf (off + count) (len - count)

let rec copy_file_fd (buffer : bytes) from_fd to_fd =
  let count = Unix.read from_fd buffer 0 (Bytes.length buffer) in
  if count > 0 then
    begin
      complete_write to_fd buffer 0 count;
      copy_file_fd buffer from_fd to_fd
    end

let finally x f  action = 
  match f x with 
  | exception e -> action x; raise e 
  | v -> action x; v 


let with_file_fmt (file : string) (action : Format.formatter -> 'a) : 'a =
  let outx =
    Pervasives.open_out_gen [Open_wronly; Open_binary; Open_creat; Open_append]
      0o600 file in
  let buf = Format.formatter_of_out_channel outx in
  match action buf with 
  | exception e -> close_out outx ; raise e 
  | v -> close_out outx ; v 


let need_close fd f = 
  match f fd with 
  | exception e -> Unix.close fd ; raise e 
  | v -> v 

let copy_file from_name to_name mode =
   let from_fd = Unix.openfile from_name [O_RDONLY] 0o666 in
   need_close from_fd 
     (function from_fd -> 
       let to_fd = Unix.openfile to_name [O_WRONLY; O_CREAT; O_TRUNC] 0o600 in
       need_close to_fd 
         (function to_fd ->
           copy_file_fd (Bytes.create 8192) from_fd to_fd; 
           if Sys.os_type <> "Win32" then
             Unix.fchmod to_fd mode
           else
             Unix.chmod to_name mode
         )  )


(*
 * Make a directory hierarchy.
 *)
let mkdirhier name =
  let rec mkdir head path =
    match path with
    | dir :: rest ->
      let filename = Filename.concat head dir in

      (* If it is already a directory, keep it *)
      let is_dir =
        try (Unix.LargeFile.stat filename).Unix.LargeFile.st_kind = Unix.S_DIR with
          Unix.Unix_error _ ->
          false
      in
      if not is_dir then
        Unix.mkdir filename 0o777;
      mkdir filename rest
    | [] ->
      ()
  in
  let head =
    if String.length name = 0 || name.[0] <> '/' then
      "."
    else
      "/"
  in
  let path = Lm_filename_util.split_path name in
  let path = Lm_filename_util.simplify_path path in
  mkdir head path

(*
 * Compatibility initializer.
 *)
external init : unit -> unit = "lm_compat_init"

let () = init ()

(*
 * Get the pid of the process holding the lock
 *)
external lm_getlk : Unix.file_descr -> Unix.lock_command -> int = "lm_getlk"

let getlk fd cmd =
   let res = lm_getlk fd cmd in
   if res = 0 then None else Some res

(*
 * Convert a fd to an integer (for debugging).
 *)
external int_of_fd : Unix.file_descr -> int = "int_of_fd"

(*
 * Win32 functions.
 *)
external home_win32       : unit -> string = "home_win32"
external lockf_win32      : Unix.file_descr -> Unix.lock_command -> int -> unit = "lockf_win32"
external ftruncate_win32  : Unix.file_descr -> unit = "ftruncate_win32"

(*
 * Try to figure out the home directory as best as possible.
 *)
let find_home_dir () =
   try Sys.getenv "HOME" with
      Not_found ->
         let home =
            try (Unix.getpwnam (Unix.getlogin ())).Unix.pw_dir with
               Not_found
             | Unix.Unix_error _ ->
                 Format.eprintf "!!! Lm_unix_util.find_home_dir:@.";
                 Format.eprintf "!!! You have no home directory.@.";
                 Format.eprintf "!!! Please set the HOME environment variable to a suitable directory.@.";
                 raise (Invalid_argument "Lm_unix_util.find_home_dir")
         in
            Unix.putenv "HOME" home;
            home

let application_dir =
   if Sys.os_type = "Win32" then
      try home_win32 () with
         Failure _ ->
            find_home_dir ()
   else
      find_home_dir ()

let home_dir =
   if Sys.os_type = "Win32" then
      try Sys.getenv "HOME" with
         Not_found ->
            let home = application_dir in
               Unix.putenv "HOME" home;
               home
   else
      application_dir

let lockf =
   if Sys.os_type = "Win32" then
      (fun fd cmd off ->
         try lockf_win32 fd cmd off with
            Failure "lockf_win32: already locked" ->
               raise (Unix.Unix_error(Unix.EAGAIN, "lockf", ""))
          | Failure "lockf_win32: possible deadlock" ->
               raise (Unix.Unix_error(Unix.EDEADLK, "lockf", "")))
   else
      Unix.lockf

let ftruncate =
   if Sys.os_type = "Win32" then
      ftruncate_win32
   else
      (fun fd -> Unix.ftruncate fd (Unix.lseek fd 0 Unix.SEEK_CUR))

type flock_command =
   LOCK_UN
 | LOCK_SH
 | LOCK_EX
 | LOCK_TSH
 | LOCK_TEX

external flock : Unix.file_descr -> flock_command -> unit = "lm_flock"

(*
 * Open a file descriptor.
 * This hook is here so you can add print statements to
 * help find file descriptor leaks.
 *)
let openfile = Unix.openfile


(*
 * Directory listing.
 *)
let  list_directory dir =
  let dirx =
    try Some (Unix.opendir dir) with
      Unix.Unix_error _ ->
      None
  in
  match dirx with
    None ->
    []
  | Some dirx ->
    let rec list entries =
      let name =
        try Some (Unix.readdir dirx) with
          Unix.Unix_error _
        | End_of_file ->
          None
      in
      match name with
        Some "."
      | Some ".." ->
        list entries
      | Some name ->
        list (Filename.concat dir name :: entries)
      | None ->
        entries
    in
    let entries = list [] in
    Unix.closedir dirx;
    entries

(**  Unlink a file, no errors. *)
let try_unlink_file  filename =
  try Unix.unlink filename with
    Unix.Unix_error _ -> ()
