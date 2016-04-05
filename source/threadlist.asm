


sqlSelectThreads text "select ",                                                                                                                                \
                                                                                                                                                                \
                        "T.id, ",                                                                                                                               \
                        "T.Slug, ",                                                                                                                             \
                        "Caption, ",                                                                                                                            \
                        "strftime('%d.%m.%Y %H:%M:%S', LastChanged, 'unixepoch') as TimeChanged, ",                                                             \
                        "(select count() from posts where threadid = T.id) as PostCount, ",                                                                     \
                        "(select count() from posts P, UnreadPosts U where P.id = U.PostID and P.threadID = T.id and U.userID = ?3 ) as Unread, ",              \
                        "T.Pinned ",                                                                                                                            \
                                                                                                                                                                \
                      "from Threads T ",                                                                                                                        \
                                                                                                                                                                \
                      "where ?4 is null or ?4 in (select tag from threadtags tt where tt.threadid = t.id) ",                                                    \
                      "order by Pinned desc, T.LastChanged desc ",                                                                                              \
                                                                                                                                                                \
                      "limit  ?1 ",                                                                                                                             \
                      "offset ?2 "

sqlThreadsCount  text "select count(1) from Threads t where ?1 is null or ?1 in (select tag from threadtags tt where tt.threadid = t.id)"


proc ListThreads, .start, .pSpecial

.stmt  dd ?
.list  dd ?

begin
        pushad

        mov     esi, [.pSpecial]

        stdcall StrNew
        mov     edi, eax

        stdcall StrCat, edi, '<div class="threads_list">'

; navigation tool bar

        stdcall StrCatTemplate, edi, "nav_list", 0, esi


; links to the pages.
        lea     eax, [.stmt]
        cinvoke sqlitePrepare_v2, [hMainDatabase], sqlThreadsCount, -1, eax, 0

        cmp     [esi+TSpecialParams.tag], 0
        je      .tag_ok

        stdcall StrPtr, [esi+TSpecialParams.tag]
        cinvoke sqliteBindText, [.stmt], 1, eax, [eax+string.len], SQLITE_STATIC

.tag_ok:
        cinvoke sqliteStep, [.stmt]
        cinvoke sqliteColumnInt, [.stmt], 0
        mov     ebx, eax
        cinvoke sqliteFinalize, [.stmt]

        stdcall CreatePagesLinks, txt "/list/", 0, [.start], ebx
        mov     [.list], eax

        stdcall StrCat, edi, eax

; now append the list itself.

        lea     eax, [.stmt]
        cinvoke sqlitePrepare_v2, [hMainDatabase], sqlSelectThreads, -1, eax, 0

        cinvoke sqliteBindInt, [.stmt], 1, PAGE_LENGTH

        mov     eax, [.start]
        imul    eax, PAGE_LENGTH
        cinvoke sqliteBindInt, [.stmt], 2, eax

        cinvoke sqliteBindInt, [.stmt], 3, [esi+TSpecialParams.userID]

        xor     ebx, ebx

        cmp     [esi+TSpecialParams.tag], 0
        je      .loop

        stdcall StrPtr, [esi+TSpecialParams.tag]
        cinvoke sqliteBindText, [.stmt], 4, eax, [eax+string.len], SQLITE_STATIC


.loop:
        cinvoke sqliteStep, [.stmt]
        cmp     eax, SQLITE_ROW
        jne     .finish

        inc     ebx                     ; post count

        stdcall StrCatTemplate, edi, "thread_info", [.stmt], esi

        jmp     .loop


.finish:
        cmp     ebx, 5
        jbe     .back_navigation_ok

        stdcall StrCat, edi, [.list]
        stdcall StrCatTemplate, edi, "nav_list", 0, esi

.back_navigation_ok:
        stdcall StrCat, edi, "</div>"   ; div.threads_list

        stdcall StrDel, [.list]
        cinvoke sqliteFinalize, [.stmt]

        mov     [esp+4*regEAX], edi
        popad
        return
endp


