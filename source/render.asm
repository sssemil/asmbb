



proc StrCatTemplate, .hString, .strTemplateID, .sql_statement, .p_special
begin
        pushad

        stdcall StrDupMem, "templates/"
        stdcall StrCat, eax, [.strTemplateID]
        stdcall StrCharCat, eax, ".tpl"
        push    eax

        stdcall LoadBinaryFile, eax
        stdcall StrDel ; from the stack
        jc      .finish

        mov     esi, eax
        and     dword [eax+ecx], 0

        stdcall __DoProcessTemplate2, esi, [.sql_statement], [.p_special], TRUE

        stdcall StrCat, [.hString], eax
        stdcall StrDel, eax
        stdcall FreeMem, esi

.finish:
        popad
        return
endp






proc __DoProcessTemplate2, .hTemplate, .sql_stmt, .pSpecial, .fHTML
  .stmt dd ?
begin
        pushad

        stdcall StrNew
        mov     edi, eax

        stdcall StrPtr, [.hTemplate]
        mov     esi, eax

        xor     edx, edx

.outer:
        mov     ebx, esi

.inner:
        mov     cl, [esi]
        inc     esi

        test    cl, cl
        jz      .found

        cmp     cl, '['
        jne     .inner

.found:
        mov     eax, esi
        sub     eax, ebx
        dec     eax

        stdcall StrCatMem, edi, ebx, eax

        test    cl, cl
        jz      .end_of_template

        mov     ebx, esi

.varname:
        mov     cl, [esi]
        inc     esi

        test    cl, cl
        jz      .end_of_template       ; ignore the not ended macros.

        cmp     cl, "["
        jne     .nested_ok

        inc     edx
        jmp     .varname

.nested_ok:
        cmp     cl, ']'
        jne     .varname

        test    edx, edx
        jz      .found_var

        dec     edx
        jmp     .varname


.end_of_template:
        mov     [esp+4*regEAX], edi
        popad
        return



.found_var:
        pushad

        mov     ecx, esi
        sub     ecx, ebx
        dec     ecx

        stdcall StrNew
        stdcall StrCatMem, eax, ebx, ecx
        stdcall StrClipSpacesR, eax
        stdcall StrClipSpacesL, eax
        mov     edi, eax        ; the macro text

        mov     esi, [.pSpecial]

; get the value of the macro


; first check for special names

        stdcall StrMatchPatternNoCase, "special:*", edi
        jc      .process_special

        stdcall StrMatchPatternNoCase, "minimag:*", edi
        jc      .process_minimag

        stdcall StrMatchPatternNoCase, "case:*", edi
        jc      .process_case

        stdcall StrMatchPatternNoCase, "and:*", edi
        jc      .process_and

        stdcall StrMatchPatternNoCase, "sql:*", edi
        jc      .process_sql

        cmp     [.sql_stmt], 0
        je      .return_original                ; ignore all database fields, because there is no statement.


        cinvoke sqliteColumnCount, [.sql_stmt]
        mov     ebx, eax

; search the column index

.loop_columns:
        dec     ebx
        jns     .check_name


.return_original:

        stdcall StrNew                          ; return the original string.
        stdcall StrCharCat, eax, "["
        stdcall StrCat, eax, edi
        stdcall StrCharCat, eax, "]"
        jmp     .return_value


.check_name:
        cinvoke sqliteColumnName, [.sql_stmt], ebx
        stdcall StrCompNoCase, eax, edi
        jnc     .loop_columns

; column has been found

        cinvoke sqliteColumnText, [.sql_stmt], ebx


.return_encoded:

        test    eax, eax
        jz      .return_value

        cmp     [.fHTML], 0
        jne     .encode

        stdcall StrDup, eax
        jmp     .return_value


.encode:

        stdcall StrEncodeHTML, eax


.return_value:
        stdcall StrDel, edi
        mov     [esp+4*regEAX], eax
        popad

; the value has been computed.

        test    eax, eax
        jz      .outer

        stdcall StrCat, edi, eax
        stdcall StrDel, eax

        jmp     .outer


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


.process_special:

        stdcall StrSplit, edi, 8
        stdcall StrDel, edi
        stdcall StrClipSpacesL, eax
        mov     edi, eax

        stdcall GetQueryItem, edi, "avatar=", 0
        test    eax, eax
        jnz     .get_avatar

        stdcall StrCompNoCase, edi, "version"
        jc      .get_version

        stdcall StrCompNoCase, edi, "timestamp"
        jc      .get_timestamp

        stdcall StrCompNoCase, edi, "title"
        jc      .get_title

        stdcall StrCompNoCase, edi, "username"
        jc      .get_username

        stdcall StrCompNoCase, edi, "userid"
        jc      .get_userid

        stdcall StrCompNoCase, edi, txt "page"
        jc      .get_page

        stdcall StrCompNoCase, edi, txt "dir"
        jc      .get_dir

        stdcall StrCompNoCase, edi, txt "thread"
        jc      .get_thread

        stdcall StrCompNoCase, edi, "permissions"
        jc      .get_permissions

        stdcall StrCompNoCase, edi, "isadmin"
        jc      .is_admin

        stdcall StrCompNoCase, edi, "canlogin"
        jc      .can_login

        stdcall StrCompNoCase, edi, "canpost"
        jc      .can_post

        stdcall StrCompNoCase, edi, "canstart"
        jc      .can_start

        stdcall StrCompNoCase, edi, "canedit"
        jc      .can_edit

        stdcall StrCompNoCase, edi, "candel"
        jc      .can_del

        stdcall StrCompNoCase, edi, "referer"
        jc      .get_referer

        stdcall StrCompNoCase, edi, "alltags"
        jc      .get_all_tags

        stdcall StrCompNoCase, edi, "setupmode"
        jc      .get_setupmode

        stdcall StrCompNoCase, edi, "search"
        jc      .get_search

        stdcall GetQueryItem, edi, "posters=", 0
        test    eax, eax
        jnz     .get_thread_posters

        stdcall GetQueryItem, edi, "threadtags=", 0
        test    eax, eax
        jnz     .get_thread_tags


if defined options.DebugWeb & options.DebugWeb

        stdcall StrCompNoCase, edi, "environment"
        jc      .get_environment

end if

        xor     eax, eax
        jmp     .return_value



;..................................................................


.get_timestamp:

        stdcall GetFineTimestamp
        sub     eax, [esi+TSpecialParams.start_time]

        stdcall NumToStr, eax, ntsDec or ntsUnsigned
        mov     edx, eax

        stdcall StrLen, eax
        sub     eax, 3
        jg      .point_ok

        neg     eax
        inc     eax

.zero_loop:
        stdcall StrCharInsert, edx, "0", 0
        dec     eax
        jnz     .zero_loop

        inc     eax

.point_ok:
        stdcall StrCharInsert, edx, ".", eax

        mov     eax, edx
        jmp     .return_value

;..................................................................
.get_version:

        mov     eax, cVersion
        jmp     .return_value

;..................................................................

.get_title:
        mov     eax, [esi+TSpecialParams.page_title]
        jmp     .return_encoded

;..................................................................


.get_username:

        mov     eax, [esi+TSpecialParams.userName]
        jmp     .return_encoded


;..................................................................


.get_userid:

        stdcall NumToStr, [esi+TSpecialParams.userID], ntsDec or ntsUnsigned
        jmp     .return_value


;..................................................................

.get_page:

        stdcall NumToStr, [esi+TSpecialParams.page_num], ntsDec or ntsUnsigned
        jmp     .return_value


;..................................................................

.get_thread:
        mov     eax, [esi+TSpecialParams.thread]
        jmp     .return_encoded

.get_dir:
        mov     eax, [esi+TSpecialParams.dir]
        jmp     .return_encoded

;..................................................................


.get_permissions:

        stdcall NumToStr, [esi+TSpecialParams.userStatus], ntsDec or ntsUnsigned
        jmp     .return_value

;..................................................................

.is_admin:

        mov     ecx, permAdmin
        jmp     .check_one_permission

.can_login:

        mov     ecx, permLogin
        jmp     .check_one_permission

.can_post:

        mov     ecx, permPost
        jmp     .check_one_permission

.can_start:

        mov     ecx, permThreadStart
        jmp     .check_one_permission


.check_one_permission:

        stdcall StrDupMem, txt "1"

        test    [esi+TSpecialParams.userStatus], ecx
        jnz     .return_value

        mov     ebx, eax
        stdcall StrPtr, eax
        mov     byte [eax], "0"
        mov     eax, ebx

.perm_ok:
        jmp     .return_value


locals
  .permOwn dd ?
  .permAll dd ?
endl


.can_edit:
        mov     [.permOwn], permEditOwn
        mov     [.permAll], permEditAll
        jmp     .complex_perm


.can_del:
        mov     [.permOwn], permDelOwn
        mov     [.permAll], permDelAll


.complex_perm:

        stdcall StrDupMem, txt "1"

        mov     ecx, [esi+TSpecialParams.userStatus]
        test    ecx, [.permAll]
        jnz     .return_value

        push    eax

        cinvoke sqliteColumnCount, [.sql_stmt]
        mov     ebx, eax

; search the column index for "userid"

.loop_columns2:
        dec     ebx
        js      .edit_no        ; the userid for the author of the post has not be found.

        cinvoke sqliteColumnName, [.sql_stmt], ebx
        stdcall StrCompNoCase, eax, txt "userid"
        jnc     .loop_columns2

        cinvoke sqliteColumnInt, [.sql_stmt], ebx

        cmp     eax, [esi+TSpecialParams.userID]
        jne     .edit_no

        mov     eax, [esi+TSpecialParams.userStatus]
        test    eax, [.permOwn]
        jnz     .edit_ok

.edit_no:
        stdcall StrPtr, [esp]
        mov     byte [eax], "0"

.edit_ok:
        pop     eax
        jmp     .return_value



;..................................................................

.get_referer:

        stdcall GetBackLink, esi
        jmp     .return_value

;..................................................................


.get_setupmode:
        stdcall NumToStr, [esi+TSpecialParams.setupmode], ntsDec or ntsUnsigned

        jmp     .return_value


;..................................................................

.get_search:

        xor     eax, eax
        stdcall ValueByName, [esi+TSpecialParams.params], "QUERY_STRING"
        jc      .return_value

        stdcall GetQueryItem, eax, txt "s=", 0
        jmp     .return_value


;..................................................................


.scale   db 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 32, 33, 35, 37, 38
         db 40, 41, 43, 44, 46, 47, 48, 50, 51, 52, 53, 55, 56, 57, 58, 59, 60, 62, 63, 64
         db 65, 66, 67, 68, 69, 70, 70, 71, 72, 73, 74, 75, 76, 76, 77, 78, 79, 79, 80, 81
         db 82, 82, 83, 83, 84, 85, 85, 86, 87, 87, 88, 88, 89, 89, 90, 90, 91, 91, 92, 92
         db 93, 93, 94, 94, 95, 95, 95, 96, 96, 97, 97, 97, 98, 98, 98, 99, 99, 99, 100,100


.get_all_tags:

sqlGetMaxTagUsed text "select count(Tag) as cnt from ThreadTags group by tag order by cnt desc limit 1"
sqlGetAllTags    text "select TT.tag, count(TT.tag) as cnt, T.Description from ThreadTags TT left join Tags T on TT.tag=T.tag group by TT.tag order by TT.tag"

locals
  .max   dd ?
  .cnt   dd ?
endl

        stdcall StrNew
        mov     ebx, eax

        lea     eax, [.stmt]
        cinvoke sqlitePrepare_v2, [hMainDatabase], sqlGetMaxTagUsed, sqlGetMaxTagUsed.length, eax, 0
        cinvoke sqliteStep, [.stmt]
        cmp     eax, SQLITE_ROW
        jne     .end_tags

        cinvoke sqliteColumnInt, [.stmt], 0
        test    eax, eax
        jz      .end_tags

        mov     [.max], eax

        cinvoke sqliteFinalize, [.stmt]


        lea     eax, [.stmt]
        cinvoke sqlitePrepare_v2, [hMainDatabase], sqlGetAllTags, sqlGetAllTags.length, eax, 0

.tag_loop:
        cinvoke sqliteStep, [.stmt]

        cmp     eax, SQLITE_ROW
        jne     .end_tags

        cinvoke sqliteColumnInt, [.stmt], 1     ; the count used
        mov     [.cnt], eax
        mov     ecx, 100
        mul     ecx
        div     [.max]
        test    eax, eax
        jz      .tag_loop

        cmp     eax, ecx
        cmova   eax, ecx

        movzx   eax, [.scale+eax-1]
        test    eax, eax
        jz      .tag_loop

        push    eax

        stdcall StrCat, ebx, '<a class="taglink'

        cmp     [esi+TSpecialParams.dir], 0
        je      .current_ok

        cinvoke sqliteColumnText, [.stmt], 0
        stdcall StrCompNoCase, eax, [esi+TSpecialParams.dir]
        jnc     .current_ok

        stdcall StrCat, ebx, ' current_tag'

.current_ok:

        pop     eax

        stdcall StrCat, ebx, '" style="font-size:'
        stdcall NumToStr, eax, ntsDec or ntsUnsigned

        stdcall StrCat, ebx, eax
        stdcall StrDel, eax

        stdcall StrCat, ebx, txt '%;" title="'

        cinvoke sqliteColumnText, [.stmt], 2
        test    eax, eax
        jz      .title_ok

        stdcall StrEncodeHTML, eax
        stdcall StrCat, ebx, eax
        stdcall StrCharCat, ebx, "; "
        stdcall StrDel, eax

.title_ok:

        stdcall NumToStr, [.cnt], ntsDec or ntsUnsigned
        stdcall StrCat, ebx, eax
        stdcall StrDel, eax

        stdcall StrCat, ebx, ' thread'
        cmp     [.cnt], 1
        je      .plural_ok

        stdcall StrCharCat, ebx, 's'

.plural_ok:

        stdcall StrCat, ebx, '." href="/'
        cinvoke sqliteColumnText, [.stmt], 0
        stdcall StrEncodeHTML, eax

        stdcall StrCat, ebx, eax
        stdcall StrCat, ebx, txt '/">'
        stdcall StrCat, ebx, eax
        stdcall StrCat, ebx, txt '</a>'
        stdcall StrDel, eax

        jmp     .tag_loop


.end_tags:
        cinvoke sqliteFinalize, [.stmt]

        mov     eax, ebx
        jmp     .return_value

;..................................................................

.get_thread_tags:

sqlGetThreadTags    text "select TT.tag, T.Description from ThreadTags TT left join Tags T on TT.tag=T.tag where TT.threadID=? order by TT.tag"

locals
  .threadID dd ?
endl

        mov     ecx, eax

        stdcall StrNew
        mov     ebx, eax

        stdcall __DoProcessTemplate2, ecx, [.sql_stmt], [.pSpecial], FALSE
        stdcall StrDel, ecx

        push    eax
        stdcall StrToNumEx, eax
        stdcall StrDel ; from the stack
        jc      .end_thread_tags2

        mov     [.threadID], eax

        lea     eax, [.stmt]
        cinvoke sqlitePrepare_v2, [hMainDatabase], sqlGetThreadTags, sqlGetAllTags.length, eax, 0
        cinvoke sqliteBindInt, [.stmt], 1, [.threadID]

.thread_tag_loop:

        cinvoke sqliteStep, [.stmt]
        cmp     eax, SQLITE_ROW
        jne     .end_thread_tags

        cmp     [.threadID], 0
        jne     .comma_ok

        stdcall StrCharCat, ebx, ', '

.comma_ok:
        mov     [.threadID], 0
        stdcall StrCat, ebx, '<a class="ttlink" '

        cinvoke sqliteColumnText, [.stmt], 1
        test    eax, eax
        jz      .link_title_ok

        stdcall StrEncodeHTML, eax

        stdcall StrCat, ebx, 'title="'
        stdcall StrCat, ebx, eax
        stdcall StrCharCat, ebx, '" '
        stdcall StrDel, eax

.link_title_ok:

        stdcall StrCat, ebx, 'href="/'

        cinvoke sqliteColumnText, [.stmt], 0
        stdcall StrEncodeHTML, eax

        stdcall StrCat, ebx, eax
        stdcall StrCat, ebx, txt '/">'
        stdcall StrCat, ebx, eax
        stdcall StrCat, ebx, txt '</a>'
        stdcall StrDel, eax

        jmp     .thread_tag_loop

.end_thread_tags:

        cinvoke sqliteFinalize, [.stmt]

.end_thread_tags2:
        mov     eax, ebx
        jmp     .return_value

;..................................................................

.get_avatar:
        mov     ecx, eax

        stdcall __DoProcessTemplate2, ecx, [.sql_stmt], [.pSpecial], FALSE
        stdcall StrDel, ecx

        push    eax
        stdcall StrToNumEx, eax
        stdcall StrDel ; from the stack
        jc      .end_avatar

        stdcall GetUserAvatar, eax
        jc      .end_avatar

        jmp     .return_encoded

.end_avatar:
        xor     eax, eax
        jmp     .return_value

;..................................................................

;<span class="small">starter: <a href="/userinfo/[StarterID][special:urltag]">[StarterName]</a></span>

.get_thread_posters:

sqlGetThreadPosters  text "select U.nick from Posts P left join Users U on U.id = P.userID where P.threadID = ?1 order by P.id limit 20;"

locals
  .list  dd ?
  .fMore dd ?
endl

        mov     ecx, eax

        stdcall StrNew
        mov     ebx, eax

        stdcall __DoProcessTemplate2, ecx, [.sql_stmt], [.pSpecial], FALSE
        stdcall StrDel, ecx

        push    eax
        stdcall StrToNumEx, eax
        stdcall StrDel ; from the stack
        jc      .finish_thread_posters

        push    eax

        stdcall CreateArray, 4
        mov     [.list], eax

        lea     eax, [.stmt]
        cinvoke sqlitePrepare_v2, [hMainDatabase], sqlGetThreadPosters, sqlGetThreadPosters.length, eax, 0

        pop     eax
        cinvoke sqliteBindInt, [.stmt], 1, eax

        and     [.fMore], 0

.thread_posters_loop:

        cinvoke sqliteStep, [.stmt]

        cmp     eax, SQLITE_ROW
        jne     .end_thread_posters

        cinvoke sqliteColumnText, [.stmt], 0

        mov     edx, [.list]
        cmp     [edx+TArray.count], 5
        je      .end_thread_posters_more

        stdcall ListAddDistinct, [.list], eax
        mov     [.list], edx

        jmp     .thread_posters_loop

.end_thread_posters_more:

        inc     [.fMore]

.end_thread_posters:

        cinvoke sqliteFinalize, [.stmt]

        mov     edx, [.list]
        xor     ecx, ecx

.add_posters_loop:
        cmp     ecx, [edx+TArray.count]
        jae     .end_add_posters

        cmp     ecx, 0
        jne     .not_first

        stdcall StrCat, ebx, 'started by: <b>'
        jmp     .add_user

.not_first:
        cmp     ecx, 1
        jne     .not_second

        stdcall StrCat, ebx, '<br>joined: '
        jmp     .add_user

.not_second:

        stdcall StrCat, ebx, txt ", "

.add_user:
        stdcall StrCat, ebx, '<a href="/!userinfo/'
        stdcall StrCat, ebx, [edx+TArray.array+4*ecx]
        stdcall StrCat, ebx, txt '">'
        stdcall StrCat, ebx, [edx+TArray.array+4*ecx]
        stdcall StrCat, ebx, txt '</a>'

        test    ecx, ecx
        jnz     @f
        stdcall StrCat, ebx, txt '</b>'
@@:
        inc     ecx
        jmp     .add_posters_loop


.end_add_posters:

        cmp     [.fMore], 0
        je      @f
        stdcall StrCat, ebx, " and more..."
@@:

        stdcall ListFree, [.list], StrDel

.finish_thread_posters:

        mov     eax, ebx
        jmp     .return_value

;..................................................................




if defined options.DebugWeb & options.DebugWeb

.get_environment:

        stdcall StrDupMem, <"<pre>", 13, 10>
        mov     ebx, eax

        mov     edx, [esi+TSpecialParams.params]
        xor     ecx, ecx

.loop_env:
        cmp     ecx, [edx+TArray.count]
        jae     .show_post

        stdcall StrEncodeHTML, [edx+TArray.array+8*ecx]
        stdcall StrCat, ebx, eax
        stdcall StrDel, eax

        stdcall StrCharCat, ebx, " = "

        stdcall StrEncodeHTML, [edx+TArray.array+8*ecx+4]
        stdcall StrCat, ebx, eax
        stdcall StrDel, eax
        stdcall StrCharCat, ebx, $0a0d

        inc     ecx
        jmp     .loop_env


.show_post:
        mov     eax, [esi+TSpecialParams.post]
        test    eax, eax
        jz      .end_env

        stdcall StrCat, ebx, <13, 10, 13, 10, "<<<<< Follows the POST data: >>>>>", 13, 10>
        stdcall StrCat, ebx, [esi+TSpecialParams.post]
        stdcall StrCat, ebx, <13, 10, "<<<<< Here ends the post data >>>>>", 13, 10>

.end_env:
        stdcall StrCat, ebx, "13, 10, </pre>"
        mov     eax, ebx
        jmp     .return_value

end if

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


.process_minimag:

        stdcall StrSplit, edi, 8
        stdcall StrDel, edi
        stdcall StrClipSpacesL, eax
        mov     edi, eax

        stdcall __DoProcessTemplate2, edi, [.sql_stmt], [.pSpecial], FALSE

        stdcall FormatPostText, eax
        jmp     .return_value



;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


.process_case:

        stdcall StrSplit, edi, 5
        stdcall StrDel, edi
        mov     edi, eax

        stdcall __DoProcessTemplate2, edi, [.sql_stmt], [.pSpecial], TRUE
        stdcall StrDel, edi
        mov     edi, eax

        stdcall StrSplitList, edi, '|', TRUE
        mov     esi, eax

        cmp     [esi+TArray.count], 2
        jae     .get_case_value

        xor     eax, eax
        jmp     .end_case

.get_case_value:

        stdcall StrToNumEx, [esi+TArray.array]          ; the case number
        jnc     .check_it

        stdcall StrLenUtf8, [esi+TArray.array], -1      ; the length of the string if not a number.

.check_it:
        mov     ecx, [esi+TArray.count]
        sub     ecx, 2

        cmp     eax, ecx
        cmova   eax, ecx

        stdcall StrDup, [esi+TArray.array+4*eax+4]

.end_case:
        stdcall ListFree, esi, StrDel
        jmp     .return_value



;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


.process_and:

        stdcall StrSplit, edi, 4
        stdcall StrDel, edi
        mov     edi, eax

        stdcall __DoProcessTemplate2, edi, [.sql_stmt], [.pSpecial], TRUE
        stdcall StrDel, edi
        mov     edi, eax

        stdcall StrSplitList, edi, '|', FALSE
        mov     esi, eax

        cmp     [esi+TArray.count], 2
        jae     .get_and_value

        xor     eax, eax
        jmp     .end_if

.get_and_value:

        stdcall StrToNumEx, [esi+TArray.array]          ; the first operand
        mov     ecx, eax

        stdcall StrToNumEx, [esi+TArray.array+4]        ; the second operand
        and     eax, ecx

.end_if:
        stdcall NumToStr, eax, ntsDec or ntsUnsigned
        stdcall ListFree, esi, StrDel
        jmp     .return_value



;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



.process_sql:

        stdcall StrSplit, edi, 4
        stdcall StrDel, edi
        mov     edi, eax

        stdcall __DoProcessTemplate2, edi, [.sql_stmt], [.pSpecial], TRUE
        stdcall StrDel, edi
        mov     edi, eax

        stdcall StrSplitList, edi, "|", FALSE
        mov     esi, eax

        stdcall StrDel, edi
        stdcall StrNew
        mov     edi, eax

        cmp     [esi+TArray.count], 0
        je      .end_sql


        stdcall StrPtr, [esi+TArray.array]

        lea     edx, [.stmt]
        cinvoke sqlitePrepare_v2, [hMainDatabase], eax, [eax+string.len], edx, 0
        cmp     eax, SQLITE_OK
        jne     .end_sql

        xor     ebx, ebx

.bind_loop:
        inc     ebx
        cmp     ebx, [esi+TArray.count]
        jae     .end_bind

        stdcall StrPtr, [esi+TArray.array+4*ebx]

        cinvoke sqliteBindText, [.stmt], ebx, eax, [eax+string.len], SQLITE_STATIC
        cmp     eax, SQLITE_OK
        je      .bind_loop

        cmp     eax, SQLITE_RANGE
        jne     .finalize_sql

.end_bind:

        cinvoke sqliteStep, [.stmt]
        cmp     eax, SQLITE_ROW
        jne     .finalize_sql

.col_loop:

        cinvoke sqliteColumnText, [.stmt], 0
        test    eax, eax
        jz      .finalize_sql

        stdcall StrCat, edi, eax

.finalize_sql:

        cinvoke sqliteFinalize, [.stmt]

.end_sql:
        stdcall ListFree, esi, StrDel

        mov     eax, edi
        xor     edi, edi
        jmp     .return_value


endp






proc FormatPostText, .hText

.result TMarkdownResults

begin
        stdcall StrCatTemplate, [.hText], "minimag_suffix", 0, 0

        lea     eax, [.result]
        stdcall TranslateMarkdown, [.hText], FixMiniMagLink, 0, eax

        stdcall StrDel, [.hText]
        stdcall StrDel, [.result.hIndex]
        stdcall StrDel, [.result.hKeywords]
        stdcall StrDel, [.result.hDescription]

        mov     eax, [.result.hContent]
        return
endp



proc FixMiniMagLink, .ptrLink, .ptrBuffer
begin
        pushad

        mov     edi, [.ptrBuffer]
        mov     esi, [.ptrLink]
        cmp     byte [esi], '#'
        je      .finish         ; it is internal link

.start_loop:
        lodsb
        cmp     al, $0d
        je      .not_absolute
        cmp     al, $0a
        je      .not_absolute
        cmp     al, ']'
        je      .not_absolute
        test    al,al
        jz      .not_absolute

        cmp     al, 'A'
        jb      .found
        cmp     al, 'Z'
        jbe     .start_loop

        cmp     al, 'a'
        jb      .found
        cmp     al, 'z'
        jb      .start_loop

.found:
        cmp     al, ':'
        jne     .not_absolute

        mov     ecx, [.ptrLink]
        sub     ecx, esi

        cmp     ecx, -11
        jne     .not_js

        cmp     dword [esi+ecx], "java"
        jne     .not_js

        cmp     dword [esi+ecx+4], "scri"
        jne     .not_js

        cmp     word [esi+ecx+8], "pt"
        jne     .not_js

.add_https:
        mov     dword [edi], "http"
        mov     dword [edi+4], "s://"
        lea     edi, [edi+8]
        jmp     .protocol_ok

.not_js:
        cmp     dword [esi+ecx], "http"
        jne     .add_https

.not_absolute:
.protocol_ok:
        mov     esi, [.ptrLink]

; it is absolute URL, exit
.finish:
        mov     [esp+4*regEAX], edi     ; return the end address.
        mov     [esp+4*regEDX], esi     ; return the start of the link.
        popad
        return
endp





proc StrSlugify, .hString
begin
        stdcall Utf8ToAnsi, [.hString], KOI8R
        push    eax
        stdcall StrCyrillicFix, eax
        stdcall StrDel ; from the stack

        stdcall StrMaskBytes, eax, $0, $7f
        stdcall StrLCase2, eax

        stdcall StrConvertWhiteSpace, eax, " "
        stdcall StrConvertPunctuation, eax

        stdcall StrCleanDupSpaces, eax
        stdcall StrClipSpacesR, eax
        stdcall StrClipSpacesL, eax

        stdcall StrConvertWhiteSpace, eax, "-"          ; according to google rules.

        return
endp



proc StrTagify, .hString
begin
        pushad

        mov     ebx, [.hString]

        stdcall StrConvertWhiteSpace, ebx, " "
        stdcall StrConvertPunctuation, ebx

        stdcall StrCleanDupSpaces, ebx
        stdcall StrClipSpacesR, ebx
        stdcall StrClipSpacesL, ebx

        stdcall StrByteUtf8, ebx, 16

        stdcall StrTrim, ebx, eax

        stdcall StrClipSpacesR, ebx
        stdcall StrClipSpacesL, ebx

        stdcall StrConvertWhiteSpace, ebx, "."        ; google don't like underscores.

        popad
        return
endp








proc StrConvertWhiteSpace, .hString, .toChar
begin
        pushad

        stdcall StrLen, [.hString]
        mov     ecx, eax
        jecxz   .finish

        stdcall StrPtr, [.hString]
        mov     esi, eax

        mov     edx, [.toChar]

.loop:
        mov     al, [esi]
        cmp     al, " "
        ja      .next

        mov     [esi], dl

.next:
        inc     esi
        loop    .loop

.finish:
        popad
        return
endp


proc StrConvertPunctuation, .hString
begin
        pushad

        stdcall StrLen, [.hString]
        mov     ecx, eax
        jecxz   .finish

        stdcall StrPtr, [.hString]
        mov     esi, eax

.loop:
        mov     al, [esi]
        cmp     al, $80         ; unicode
        jae     .next
        cmp     al, '_'
        je      .next
        cmp     al, '-'
        je      .next

        or      al, $20
        cmp     al, "a"
        jb      .not_letter
        cmp     al, "z"
        jbe     .next

.not_letter:
        cmp     al, "0"
        jb      .convert
        cmp     al, "9"
        jbe     .next

.convert:
        mov     byte [esi], " "

.next:
        inc     esi
        loop    .loop

.finish:
        popad
        return
endp



proc StrMaskBytes, .hString, .orMask, .andMask
begin
        pushad

        stdcall StrLen, [.hString]
        mov     ecx, eax
        jecxz   .finish

        stdcall StrPtr, [.hString]
        mov     esi, eax

        mov     dl, byte [.orMask]
        mov     dh, byte [.andMask]

.loop:
        mov     al, [esi]
        or      al, dl
        and     al, dh
        mov     [esi], al
        inc     esi
        loop    .loop

.finish:
        popad
        return
endp




proc StrCyrillicFix, .hString
begin
        pushad

        stdcall StrNew
        mov     edi, eax

        stdcall StrPtr, [.hString]
        mov     esi, eax

.loop:
        movzx   eax, byte [esi]
        inc     esi

        test    al, al
        jz      .finish

        mov     ebx, eax

        cmp     bl, $e0
        jb      .less

        sub     bl, $20

.less:
        cmp     bl, $c0
        jb      .cat

        sub     bl, $db
        and     bl, $1f
        cmp     bl, 5
        ja      .cat

        mov     eax, [.table+4*ebx]

.cat:
        stdcall StrCharCat, edi, eax
        jmp     .loop


.finish:
        mov     [esp+4*regEAX], edi
        popad
        return

.table  dd      "sh"    ; sh
        dd      "e"
        dd      "sht"
        dd      "ch"
        dd      "a"
        dd      "yu"

endp





proc StrMakeRedirect, .hString, .hWhere
begin
        push    eax

        cmp     [.hString], 0
        jne     @f

        stdcall StrNew
        mov     [esp], eax
        mov     [.hString], eax

@@:
        stdcall StrInsert,  [.hString], <"Status: 302 Found", 13, 10>, 0

        stdcall StrPtr, [.hString]
        add     eax, [eax+string.len]
        cmp     word [eax-2], $0a0d
        je      @f
        stdcall StrCharCat, [.hString], $0a0d
@@:
        stdcall StrCat, [.hString], "Location: "
        stdcall StrCat, [.hString], [.hWhere]
        stdcall StrCharCat, [.hString], $0a0d0a0d

        pop     eax
        return
endp






proc GetBackLink, .pSpecial
begin
        pushad

        mov     esi, [.pSpecial]


        stdcall ValueByName, [esi+TSpecialParams.params], "HTTP_REFERER"
        jc      .root

        mov     ebx, eax

        stdcall ValueByName, [esi+TSpecialParams.params], "HTTP_HOST"
        jc      .root

        push    eax

        stdcall StrLen, eax
        mov     ecx, eax

        stdcall StrPos, ebx     ; pattern from the stack
        test    eax, eax
        jz      .root

        add     ecx, eax

        stdcall StrMatchPatternNoCase, "/!message/*", ecx
        jc      .root

        stdcall StrMatchPatternNoCase, "/!sqlite*", ecx
        jc      .root

        stdcall StrMatchPatternNoCase, "*/!post*", ecx
        jc      .root

        stdcall StrMatchPatternNoCase, "/!register*", ecx
        jc      .root

        stdcall StrMatchPatternNoCase, "*/!edit/*", ecx
        cmp     eax, ecx
        je      .root

        stdcall StrDupMem, ecx
        clc
        jmp     .finish

.root:
        stdcall StrNew
        stdcall StrCharCat, eax, "/"
        stc

.finish:
        push    eax
        stdcall StrEncodeHTML, eax
        stdcall StrDel ; from the stack

        mov     [esp+4*regEAX], eax
        popad
        return
endp




;stdcall ListAddDistinct, [.list], eax


proc ListAddDistinct, .pList, .pString
begin
        pushad

        stdcall StrDupMem, [.pString]
        mov     ebx, eax

        mov     edx, [.pList]
        mov     ecx, [edx+TArray.count]

.loop:
        dec     ecx
        js      .not_found

        stdcall StrCompCase, [edx+TArray.array+4*ecx], ebx
        jnc     .loop

        stdcall StrDel, ebx

.finish:
        mov     [esp+4*regEDX], edx
        popad
        return

.not_found:

        stdcall AddArrayItems, edx, 1
        mov     [eax], ebx

        jmp     .finish
endp