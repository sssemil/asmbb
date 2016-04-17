; _______________________________________________________________________________________
;|                                                                                       |
;| ..:: Fresh IDE ::..  template project.                                                |
;|_______________________________________________________________________________________|
;
;  Description: AsmBoard is assembly written message board engine working over FastCGI
;
;  Target OS: Any, supported by FreshLib
;
;  Dependencies: FreshLib
;
;  Notes:
;_________________________________________________________________________________________

include "%lib%/freshlib.inc"

LINUX_INTERPRETER equ './ld-musl-i386.so'

@BinaryType console, compact

options.ShowSkipped = 0
options.ShowSizes = 0

options.DebugMode = 0
options.AlignCode = 0
options.ShowImported = 0

options.DebugWeb = 1
options.DebugSQLite = 0

;HeapManager  equ ASM
;LinuxThreads equ native


include "%lib%/freshlib.asm"


uses sqlite3:"%TargetOS%/sqlite3.inc"

include "sqlite3.asm"   ; sqlite utility functions.
include "http.asm"
include "timeproc.asm"  ; date/time utility procedures.
include "commands.asm"
include "render.asm"
include "fcgi.asm"
include "post_data.asm"
include "threadlist.asm"
include "showthread.asm"
include "search.asm"
include "post.asm"
include "edit.asm"
include "delete.asm"
include "userinfo.asm"
include "accounts.asm"
include "settings.asm"
include "sqlite_console.asm"
include "messages.asm"
include "version.asm"
include "memcache.asm"

include "postdebug.asm"


iglobal
  sqlCreateDB StripText 'create.sql', SQL
              dd   0

  cDatabaseFilename text "./board.sqlite"
endg

uglobal
  hMainDatabase dd ?
  ProcessID     dd ?
  ProcessStart  dd ?
  fOwnSocket    dd ?
endg


rb 73

start:
        InitializeAll

        if ~( defined options.DebugSQLite & options.DebugSQLite )
          mov   eax, [_sqlitePrepare_v2]
          mov   ecx, [_sqliteFinalize]
          mov   [sqlitePrepare_v2], eax
          mov   [sqliteFinalize], ecx
        end if

        stdcall SetSegmentationFaultHandler, OnForcedTerminate

        stdcall SetForcedTerminateHandler, OnForcedTerminate

        cinvoke sqliteConfig, SQLITE_CONFIG_SERIALIZED
        cinvoke sqliteInitialize

        stdcall OpenOrCreate, cDatabaseFilename, hMainDatabase, sqlCreateDB
        jc      .finish

        cinvoke sqliteBusyTimeout, [hMainDatabase], 5000
        cinvoke sqliteExec, [hMainDatabase], "PRAGMA journal_mode = WAL", 0, 0, 0
        cinvoke sqliteExec, [hMainDatabase], "PRAGMA foreign_keys = TRUE", 0, 0, 0
        cinvoke sqliteExec, [hMainDatabase], "PRAGMA synchronous = OFF", 0, 0, 0
        cinvoke sqliteExec, [hMainDatabase], "PRAGMA threads = 2", 0, 0, 0
        cinvoke sqliteExec, [hMainDatabase], "PRAGMA secure_delete = FALSE", 0, 0, 0

        cinvoke sqliteExec, [hMainDatabase], "insert into ProcessID(id) values (NULL)", 0, 0, 0

        cinvoke sqliteLastInsertRowID, [hMainDatabase]
        mov     [ProcessID], eax
        cinvoke sqliteExec, [hMainDatabase], "delete from ProcessID", 0, 0, 0

        stdcall GetTimestamp
        mov     [ProcessStart], eax

        stdcall CreateMemoryCache, AvatarCache


        stdcall LogEvent, "ScriptStart", logNULL, 0, 0


        stdcall Listen


; close the database

.terminate:

        stdcall GetTimestamp
        sub     eax, [ProcessStart]

        stdcall LogEvent, "ScriptEnd", logNULL, 0, eax

        mov     ebx, 300        ; 300x10ms = 3000ms

.wait_close:
        cinvoke sqliteClose, [hMainDatabase]
        cmp     eax, SQLITE_BUSY
        jne     .database_closed

        stdcall Sleep, 10
        dec     ebx
        jnz     .wait_close

        push    eax
        stdcall FileWriteString, [STDERR], <"The database remained open! Check for not finished SQLite statements!", 13, 10>
        pop     eax

.database_closed:
        OutputValue "Result of sqliteClose:", eax, 10, -1

        cinvoke sqliteShutdown

.finish:
        FinalizeAll
        stdcall TerminateAll, 0



proc OnForcedTerminate as procForcedTerminateHandler
begin

        DebugMsg "OnForcedTerminate"

        cmp     [fOwnSocket], 0
        je      start.terminate

        stdcall SocketClose, [STDIN]
        stdcall FileDelete, pathMySocket

        jmp     start.terminate         ; the stack is not important here!
endp








; debug replacement for sqlitePrepare_v2 and sqliteFinalize !!!

if defined options.DebugSQLite & options.DebugSQLite
  sqlitePrepare_v2 dd my_sqlitePrepare_v2
  sqliteFinalize   dd my_sqliteFinalize
else
  sqlitePrepare_v2 dd 0
  sqliteFinalize   dd 0
end if


proc my_sqlitePrepare_v2, .ptrDB, .ptrSQL, .lenSQL, .ptrVarStmt, .ptrVarNext
begin
        cinvoke  _sqlitePrepare_v2, [.ptrDB], [.ptrSQL], [.lenSQL], [.ptrVarStmt], [.ptrVarNext]

        pushad

        stdcall FileWriteString, [STDERR], "SQL statement prepared:   $"

        mov     eax, [.ptrVarStmt]
        stdcall NumToStr, [eax], ntsHex or ntsUnsigned or ntsFixedWidth + 8
        push    eax
        stdcall FileWriteString, [STDERR], eax
        stdcall StrDel ; from the stack;

        stdcall FileWriteString, [STDERR], txt " call from $"
        stdcall NumToStr, [ebp+4], ntsHex or ntsUnsigned or ntsFixedWidth + 8
        push    eax
        stdcall FileWriteString, [STDERR], eax
        stdcall StrDel ; from the stack;
        stdcall FileWriteString, [STDERR], <txt 13, 10>

        popad

        cret
endp


proc my_sqliteFinalize, .stmt
begin
        pushad

        stdcall FileWriteString, [STDERR], "SQL statement finalizing: $"

        stdcall NumToStr, [.stmt], ntsHex or ntsUnsigned or ntsFixedWidth + 8
        push    eax
        stdcall FileWriteString, [STDERR], eax
        stdcall StrDel ; from the stack;

        stdcall FileWriteString, [STDERR], txt " call from $"
        stdcall NumToStr, [ebp+4], ntsHex or ntsUnsigned or ntsFixedWidth + 8
        push    eax
        stdcall FileWriteString, [STDERR], eax
        stdcall StrDel ; from the stack;

        stdcall FileWriteString, [STDERR], <txt 13, 10, 13, 10>

        popad

        cinvoke _sqliteFinalize, [.stmt]

        cret
endp