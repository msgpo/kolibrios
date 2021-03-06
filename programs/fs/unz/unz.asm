;unz - �ᯠ���騪, �ᯮ����騩 archiver.obj. �����ন���� zip � 7z.

;unz [-o output path] [-f file for unpack] [-f ...] [-h] file.zip
;-h - hide GUI. If params is empty - do exit.

;unz -o /hd0/1/arci -f text1.txt file.zip -unpack in folder only file text1.txt
;or
;unz -o "/hd0/1/arci" -f "text1.txt" text2.txt "file.zip" -unpack in folder only file text1.txt and text2.txt


;�� ������������
;unz -n "namezone" "file.zip"  - open packed file, write list files of main folder in namezone
;namezone:
;dd 0 - �᫨ ����������� ���� �����, � 1
;dd cmd - 0 ��� �������
;         1 ������� ᯨ᮪ 䠩���
;         2 ������� 䠩�
;         3 ��⠭����� ⥪�訩 ��⠫�� � ��娢�
;         4 �������� ࠡ���
;data - �����, ������ �� ��������
; 1 ������� ᯨ᮪ 䠩���
; input
;   none
; output
;   dd numfiles - ������⢮ 䠩��� � ����� � ⥪�饬 ��⠫���
;   strz file1...fileN - ᯨ᮪ ��ப, ࠧ������ 0
; 2 ������� 䠩�
; input
;   dd num bytes
;   strz filename (file1.txt of /fold1/file1.txt)
; output
;   dd num bytes
;   data

use32
org    0
db     'MENUET01'
dd     1, start, init_end, end_mem, stack_top, params,	0


include 'lang.inc'
include '../../macros.inc'
include '../../proc32.inc'
include '../../develop/libraries/box_lib/trunk/box_lib.mac'
include '../../dll.inc'
include 'debug.inc'

version equ '0.65'
version_dword equ 0*10000h + 65

WIN_W = 400

SIZE_COPY_BUF = 1024*1024*2

virtual at 0
kfar_info_struc:
.lStructSize	dd	?
.kfar_ver	dd	?
.open		dd	?
.open2		dd	?
.read		dd	?
.write		dd	?
.seek		dd	?
.tell		dd	?
.flush		dd	?
.filesize	dd	?
.close		dd	?
.pgalloc	dd	?
.pgrealloc	dd	?
.pgfree 	dd	?
.getfreemem	dd	?
.pgalloc2	dd	?
.pgrealloc2	dd	?
.pgfree2	dd	?
.menu		dd	?
.menu_centered_in dd	?
.DialogBox	dd	?
.SayErr 	dd	?
.Message	dd	?
.cur_console_size dd	?
end virtual





include 'parse.inc'
include 'fs.inc'

;--  CODE  -------------------------------------------------------------------


start:
	mcall	68, 11
	mcall	40, 100111b + 0C0000000h
	stdcall dll.Load, IMPORTS
	test	eax, eax
	jnz	exit
	mov	[pathOut],0

;stdcall SayErr,strErrorExc
;mcall -1
;----------------------------
	;1. find input file, clear
	;2. find -o, copy data, clear
	;3. find -f, add pointer, copy data, clear
	;4. find -c, check variable, clear
;1.
	call	getLastParam
	test	eax, eax
	je	wm_redraw
	dec	eax
	je	.arbeit
	jmp	errorParsing

.arbeit:
;2.
	call	getParam2
	cmp	eax, 2
	je	errorParsing

;3.

   @@:
	mov	eax, [iFiles]
	shl	eax, 2
	add	eax, files
	m2m	dword[eax], dword[endPointer]
	stdcall getParam, '-f'
	cmp	eax, 2
	je	errorParsing
	inc	[iFiles]
	cmp	eax, 1
	je	@b

;4.
	mov	edi, params
	mov	ax,'-h'
@@:	cmp	word [edi], ax
	je	.check
	inc	edi
	cmp	edi, params+1024
	je	@f
	cmp	byte[edi],0
	je	@f
	jmp	@b
.check:
	call	startUnpack
	mcall	-1
@@:
	stdcall [OpenDialog_Init],OpenDialog_data

;init edit fields  --------------
	xor	al,al
	mov	edi,fInp
	mov	ecx,1024
	repne	scasb
	inc	ecx
	mov	eax,1024
	sub	eax,ecx
	mov	dword[edtPack.size],eax
	mov	dword[edtPack.pos],eax

	xor	al, al
	mov	edi, pathOut
	mov	ecx, 1024
	repne	scasb
	inc	ecx
	mov	eax, 1024
	sub	eax, ecx
	mov	dword[edtUnpPath.size], eax
	mov	dword[edtUnpPath.pos], eax


;main loop --------------------
wm_redraw:
	call winRedraw

still:
	mcall	10
	cmp	eax, 1
	je	wm_redraw
	cmp	eax, 2
	je	wm_key
	cmp	eax, 3
	je	wm_button
	cmp	eax, 6
	je	wm_mouse

	jmp	still

wm_key:
	mcall	2
	cmp	[bWinChild],0
	jne	still

	stdcall [edit_box_key],edtPack
	stdcall [edit_box_key],edtUnpPath

	jmp	still


wm_button:
	mcall	17
	cmp	[bWinChild],0
	jne	still

	cmp	ah, 3
	jne	@f
	call selectInput
	jmp	wm_redraw
    @@:
	cmp	ah, 4
	jne	@f
	call selectOutFold
	jmp	wm_redraw
    @@:

	cmp	ah, 2
	jne	@f
	;mcall   51,1,startUnpack,stackUnpack
	;mov     [bWinChild],1
	call   startUnpack
	jmp	wm_redraw
    @@:

	cmp	ah, 1
	je	exit
	jmp	still

wm_mouse:
	cmp	[bWinChild],0
	jne	still
	stdcall [edit_box_mouse],edtPack
	stdcall [edit_box_mouse],edtUnpPath

	jmp	still

exit:
	mcall	-1

errorParsing:
	dps 'errorParsing'
	mcall	-1

;--- functions ------------------------------------------------------------------

proc winRedraw
	mcall 12, 1
	mcall 48, 3, sc, sizeof.system_colors
	mov   edx, [sc.work]
	or	  edx, 0x34000000
	mcall 0, <200,WIN_W>, <200,130>, , , title
	mcall 8, <100,100>,<65,25>,2,[sc.work_button]
	mcall 8, <(WIN_W-52),33>,<10,20>,3,[sc.work_button]
	mcall 8, <(WIN_W-52),33>,<35,20>,4,[sc.work_button]

	edit_boxes_set_sys_color edtPack,endEdits,sc
	stdcall [edit_box_draw],edtPack
	stdcall [edit_box_draw],edtUnpPath

	; plain window labels
	cmp	[redInput],0
	jne	@f
	mov	ecx,[sc.work_text]
	or	ecx,90000000h
	jmp	.l1
      @@:
	mov	 ecx,90FF0000h
     .l1:
	mcall 4, <15,16>, , strInp
	mov	ecx,[sc.work_text]
	or	ecx,90000000h
	mcall 4, <15,37>, , strPath
	
	; text on buttons
	mov	ecx,[sc.work_button_text]
	or	ecx,90000000h
if lang eq ru
	mcall 4, <107,70>, , strGo
else
	mcall 4, <127,70>, , strGo
end if
	mcall 4, <(WIN_W-47),12>, , strDots
	mcall 4, <(WIN_W-47),37>, , strDots	

	mcall 12, 2
	ret
endp

;region
selectInput:
	mov	[OpenDialog_data.type],0
	stdcall [OpenDialog_Start],OpenDialog_data
	mov	edi,ODAreaPath
	xor	al,al
	or	ecx,-1
	repne	scasb
	sub	edi,ODAreaPath
	dec	edi
	mov	dword[edtPack+12*4],edi
	mov	ecx,edi
	inc	ecx
	mov	edi,fInp
	mov	esi,ODAreaPath
	rep	movsb
	mov	[redInput],0
	ret
;endregion

;region
selectOutFold:
	mov	[OpenDialog_data.type],2
	stdcall [OpenDialog_Start],OpenDialog_data
	mov	edi,ODAreaPath
	xor	al,al
	or	ecx,-1
	repne	scasb
	sub	edi,ODAreaPath
	dec	edi
	mov	dword[edtUnpPath+12*4],edi
	mov	ecx,edi
	inc	ecx
	mov	edi,pathOut
	mov	esi,ODAreaPath
	rep	movsb
	ret
;endregion


;-------------------------------------------------------------------------------

allfiles dd 0
succfiles dd 0
numbytes dd 0

proc startUnpack
locals
  paramUnp	rd 1
  sizeUnpack	rd 1
  hFile rd 1
  hFileZip rd 1
  hPlugin rd 1
  pathFold rb 256
endl
;if input not corrected
	cmp	[fInp],byte 0
	je	.errNullInp

    ;    mcall   68, 24, Exception, 0FFFFFFFFh ;??
;init plugin
	push	ebp
	stdcall [aPluginLoad],kfar_info
	pop	ebp


;set current directory, create folder
	cmp	[pathOut],0
	jne	@f
	lea	eax,[pathFold]
	stdcall cpLastName, fInp, eax
	lea	eax,[pathFold]
	mov	[fsNewDir.path],eax
	mcall	70, fsNewDir
	mov	ecx, [fsNewDir.path]

	mcall	30,4,,1
	jmp	.n
@@:
	mcall	30,4,pathOut,1
.n:

;open and read first 1KB
	stdcall open, fInp, O_READ
	mov	[hFileZip], eax
	mcall	70,fsZip
	test	eax,eax
	jnz	.errNotFound
	mcall	70,fsZipRead


;open pack
	push	ebp
	stdcall [aOpenFilePlugin],[hFileZip],bdvkPack,filedata_buffer,filedata_buffer_size ,0 ,0 , fInp
	pop	ebp

	test	eax,eax
	jnz	@f
	cmp	ebx,0		;;/ �������!!!!
	je	 .errNotFound	;;���祭�� ebx ����祭� ����� ����.
	cmp	ebx,400h	;;��� ��� �㤥� ࠡ���� � ��㣨�� ����ﬨ
	je	 .errNotSupp	;;������⥪� - �� �᭮!
      @@:
	mov	[hPlugin],eax

;get num of all files
;        stdcall calcSizeArch,[hPlugin]
;        push    ebp
;        stdcall [aReadFolder], [hPlugin]
;        pop     ebp



;        push    ebp
;        stdcall [aOpen], [hPlugin], .str1, O_READ
;        pop     ebp
;
;        push    ebp
;        stdcall [aSetpos],[hPlugin],0,POSEND
;        pop     ebp
;        add     [numbytes],eax



;unpack
;       void __stdcall GetFiles(HANDLE hPlugin, int NumItems, void* items[], void* addfile, void* adddir);
	push	ebp
	stdcall [aGetFiles], [hPlugin], -1, 0, myAddFile, myAddDir
	pop	ebp

;jmp @f
;   .str1 db '/LICENSE.txt',0
;@@:

;HANDLE __stdcall open(HANDLE hPlugin, const char* filename, int mode);
;������ 䠩� filename. ��ࠬ��� mode ��१�ࢨ஢�� � � ⥪�饩 ���ᨨ kfar �ᥣ�� ࠢ�� 1.
 ;       push    ebp
 ;       stdcall [aOpen], [hPlugin], .str1, O_READ
 ;       pop     ebp

 ;       mov     [hFile],eax
;unsigned __stdcall read(HANDLE hFile, void* buf, unsigned size);
;�⥭�� size ���� � ���� buf �� 䠩�� hFile, ࠭�� ����⮣� �१ open.
;size ��⥭ 512 ����
;�����頥��� ���祭��: �᫮ ���⠭��� ����, -1 �� �訡��.
 ;       push    ebp
 ;       stdcall [aRead], [hFile], copy_buf, SIZE_COPY_BUF
 ;       pop     ebp
 ;
;        mcall   70, fsWrite
;void __stdcall close(HANDLE hFile);
	push	ebp
	stdcall [aClose], [hFile]
	mov	[bWinChild],0
	pop	ebp

	push	ebp
	stdcall [aClosePlugin], [hPlugin]
	mov	[bWinChild],0

	mov	[fsRunNotifyOK.param],strUnpackOk
	mcall	70,fsRunNotifyOK
	pop	ebp
	ret		;SUCCESS


.errNotFound:
;        stdcall SimpleSayErr,strNotFound
	mov	[bWinChild],0
	mov	[fsRunNotifyOK.param],strUnpackFault
	mcall	70,fsRunNotifyOK
	ret

.errNotSupp:
	mov	eax,[fsNewDir.path]
	mov	[fsDelDir.path],eax
	mcall	70, fsDelDir

	mov	[bWinChild],0
	mov	[fsRunNotifyOK.param],strUnpackFault
	mcall	70,fsRunNotifyOK
	ret

.errNullInp:
	mov	[redInput],1
	mov	[bWinChild],0
	ret
endp


proc Exception param1:dword
	stdcall SimpleSayErr,strErrorExc
	ret
endp

proc debugInt3
	dps '������!!!!!!!!!!!!!!!!!!!!!!!!!'
	dnl
	int3
	ret
endp


proc calcSizeArch hPlugin:dword
locals
  bdwk rb 560
endl
;int __stdcall ReadFolder(HANDLE hPlugin, unsigned dirinfo_start,
;        unsigned dirinfo_size, void* dirdata);
int3
	push	ebp
	lea	eax,[bdwk]
	stdcall [aReadFolder], [hPlugin],1,560,eax
	pop	ebp

	ret
endp
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

;SayErr  int num_strings, const char* strings[],
;                      int num_buttons, const char* buttons[]);

proc SayErr num_strings:dword, strings:dword,num_buttons:dword, buttons:dword
	pushad
	cmp	[num_strings],1
	je	@f
	m2m	[errmess0], strErrorExc
	jmp	.l1
       @@:
	mov	ebx,[strings]
	m2m	[errmess0], dword [ebx]
       .l1:

	m2m	[fsRunNotifyOK.param],[errmess0]
	mcall	70,fsRunNotifyOK

	popad
	mov	eax,1
	ret
endp

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
    ; "enter password" dialog for KFar
;password_dlg:
;        dd      1       ; use standard dialog colors
;        dd      -1      ; center window by x
;        dd      -1      ; center window by y
;.width  dd      ?       ; width (will be filled according to current console width)
;        dd      2       ; height
;        dd      4, 2    ; border size
;        dd      aEnterPasswordTitle     ; title
;        dd      ?       ; colors (will be set by KFar)
;        dd      0       ; used internally by dialog manager, ignored
;        dd      0, 0    ; reserved for DlgProc
;        dd      2       ; 2 controls
;; the string "enter password"
;        dd      1       ; type: static
;        dd      1,0     ; upper-left position
;.width1 dd      ?,0     ; bottom-right position
;        dd      aEnterPassword  ; data
;        dd      0       ; flags
;; editbox for password
;        dd      3       ; type: edit
;        dd      1,1     ; upper-left position
;.width2 dd      ?,0     ; bottom-right position
;        dd      password_data   ; data
;        dd      2Ch     ; flags



proc DialogBox dlgInfo:dword
	pushad
	mov	ebx,[dlgInfo]
	mov	eax,[ebx+19*4]
	mov	[forpassword],eax
	mov	byte[eax], 0
	mov	[stateDlg], 0
	mcall	51,1,threadDialogBox,stackDlg

	;wait thread...
    @@: cmp	[stateDlg],0
	jne	@f
	mcall	5,1
	jmp	@b
     @@:
	popad
	cmp	[stateDlg], 1
	jne	@f
	xor	eax, eax
	ret
    @@:
	or	eax, -1
	ret
endp

proc threadDialogBox

	mcall	40, 100111b+0C000000h
	mov	eax,[forpassword]
	mov	[edtPassword+4*9],eax
	xor	eax,eax
	mov	dword[edtPassword.size], eax
	mov	dword[edtPassword.pos], eax

.wm_redraw:
	mcall	12, 1
	mcall	48, 3, sc, sizeof.system_colors
	mov	edx, [sc.work]
	or	edx, 0x33000000
	mcall	0, <200,320>, <200,140>, , , title

	edit_boxes_set_sys_color edtPack,endEdits,sc
	stdcall [edit_box_draw],edtPassword


	mov	ecx,[sc.work_text]
	or	ecx,90000000h
	mcall 4, <56,12>, , strGetPass

	mcall 8, <70,80>,<74,22>,2,[sc.work_button]
	mov	ecx,[sc.work_button_text]
	or	ecx,90000000h
	mcall 4, <103,79>, , strOk

	mcall 8, <165,80>,<74,22>,1,[sc.work_button]
	mov	ecx,[sc.work_button_text]
	or	ecx,90000000h
	mcall 4, <182,79>, , strCancel


	mcall 12, 2

.still:
	mcall	10
	cmp	eax, 1
	je	.wm_redraw
	cmp	eax, 2
	je	.wm_key
	cmp	eax, 3
	je	.wm_button
	cmp	eax, 6
	je	.wm_mouse

	jmp	.still

.wm_key:
	mcall	2
	stdcall [edit_box_key],edtPassword
	jmp	.still


.wm_button:
	mcall	17

	cmp	ah, 2		;OK
	jne	@f
	mov	[stateDlg],1
	jmp	.exit
    @@:

	cmp	ah, 1		;Close window or Cancel
	jne	 .still
	mov	[stateDlg],2
	jmp	.exit

.wm_mouse:
	stdcall [edit_box_mouse],edtPassword


	jmp	.still

.exit:
	mcall	-1
endp


;--  DATA  -------------------------------------------------------------------



sc system_colors


bWinChild db 0	;1 - ���୥� ���� ����, ������� ���� �� ������ ॠ��஢���
redInput  db 0	;1 - ���ᢥ��� ���� �������

if lang eq ru
 title db 'uNZ v0.12 - ��ᯠ���騪 Zip � 7z',0
 strGo db '��ᯠ������',0
 strInp db  '    ��娢',0
 strPath db '������� �',0
 strError db '�訡��',0
 strErrorExc db '������������ �訡��',0
 strOk	db 'OK',0
 strGetPass db '��஫�',0
 strCancel  db '�⬥��',0
 strUnpackOk  db "'�ᯥ譮 �ᯠ������' -O",0
 strUnpackFault  db "'�訡�� �ᯠ�����' -E",0
 strNotSupport db "'�������ন����� �ଠ� ��娢�' -E",0
 strNotFound db "'���� �� ������' -E",0
else if lang eq es
 title db 'uNZ v0.12 - Desarchivador para Zip y 7z',0
 strGo db 'Desarchivar',0
 strInp db 'Archivar',0
 strPath db 'Extraer en',0
 strError db 'Error',0
 strErrorExc db 'Error desconocido',0
 strOk db 'OK',0
 strGetPass db 'Contrasena',0
 strCancel db 'Cancelar',0
 strUnpackOk db "'Extracion exitosa' -O",0
 strUnpackFault db "'Fallo al extraer' -E",0
 strNotSupport db "'El formato del archivo no es soportado' -E",0
 strNotFound db "'Archivo no encontrado' -E",0
else
 title db 'uNZ v0.12 - Unarchiver of Zip and 7z',0
 strGo db   'Unpack',0
 strInp db  'Archive',0
 strPath db 'Extract to',0
 strError db 'Error',0
 strErrorExc db 'Unrecognized error',0
 strOk	db 'OK',0
 strGetPass db 'Password',0
 strCancel  db 'Cancel',0
 strUnpackOk  db "'Unpacked successfuly' -O",0
 strUnpackFault  db "'Unprack failed' -E",0
 strNotSupport db "'Archive format is not supported' -E",0
 strNotFound db "'File not found' -E",0
end if

strNull db 0
strDots db '...',0

;--------
; int __stdcall SayErr(int num_strings, const char* strings[],
;                      int num_buttons, const char* buttons[]);
; int __stdcall DialogBox(DLGDATA* dlg);

forpassword rd 1
stateDlg dd 0 ;0 - in process, 1 - button ok, 2 - button cancel
errmess0 dd strErrorExc


kfar_info:
	dd	.size
	dd	version_dword
	dd	open
	dd	open2
	dd	read
	dd	-1	; write: to be implemented
	dd	seek
	dd	tell
	dd	-1	; flush: to be implemented
	dd	filesize
	dd	close
	dd	xpgalloc
	dd	xpgrealloc
	dd	pgfree
	dd	getfreemem
	dd	debugInt3;libini_alloc
	dd	debugInt3;libini_realloc
	dd	debugInt3;libini_free
	dd	debugInt3;menu
	dd	debugInt3;menu_centered_in
	dd	DialogBox;DialogBox
	dd	SayErr	 ;SayErr
	dd	debugInt3;Message
	dd	0	;cur_width
.size = $ - kfar_info
;--------


iFiles dd 0	;������⢮ ���㦠���� 䠩���
endPointer dd buffer


fsZip:
.cmd	dd 5
	dd 0
	dd 0
.size	dd 0
.buf	dd bdvkPack
	db 0
	dd fInp

fsZipRead:
.cmd	dd 0
	dd 0
	dd 0
.size	dd 1024
.buf	dd filedata_buffer
	db 0
	dd fInp


fsWrite:
.cmd	dd 2	;2 rewrite, 3 - write
.pos	dd 0
.hpos	dd 0
.size	dd SIZE_COPY_BUF
.buf	dd copy_buf
	db 0
.path	dd 0


fsNewDir:
.cmd	dd 9
	dd 0
	dd 0
	dd 0
	dd 0
	db 0
.path	dd 0

fsDelDir:
.cmd	dd 8
	dd 0
	dd 0
	dd 0
	dd 0
	db 0
.path	dd 0



fsRunNotifyOK:
.cmd	dd 7
	dd 0
.param	dd strUnpackOk
.size	dd 0
.buf	dd 0
	db '/sys/@notify',0



edtPack     edit_box (WIN_W-100-60),100,10,0FFFFFFh,0xff,0x80ff,0h,0x90000000,\
            255, fInp, mouse_dd,0,0,0
edtUnpPath  edit_box (WIN_W-100-60),100,35,0FFFFFFh,0xff,0x80ff,0h,0x90000000,\
            255, pathOut, mouse_dd,0,0,0
edtPassword edit_box 200,56,70,0FFFFFFh,0xff,0x80ff,0h,0x90000000,255,\
		password, mouse_dd,0,0,0
endEdits:

;-------------------------------------------------------------------------------
OpenDialog_data:
.type			dd 0	;0-open, 1-save, 2-select folder
.procinfo		dd RBProcInfo	    ;+4
.com_area_name		dd communication_area_name	;+8
.com_area		dd 0	;+12
.opendir_pach		dd temp_dir_pach	;+16
.dir_default_pach	dd communication_area_default_pach	;+20
.start_path		dd open_dialog_path	;+24
.draw_window		dd winRedraw		   ;+28
.status 		dd 0	;+32
.openfile_pach		dd ODAreaPath;   ;+36
.filename_area		dd 0;        ;+40
.filter_area		dd Filter
.x:
.x_size 		dw 420 ;+48 ; Window X size
.x_start		dw 100 ;+50 ; Window X position
.y:
.y_size 		dw 320 ;+52 ; Window y size
.y_start		dw 100 ;+54 ; Window Y position

communication_area_name:
	db 'FFFFFFFF_open_dialog',0
open_dialog_path:
	db '/sys/File managers/opendial',0

communication_area_default_pach:
	db '/sys',0

Filter	dd 0


; int __stdcall         ReadFolder(HANDLE hPlugin,
;       unsigned dirinfo_start, unsigned dirinfo_size, void* dirdata);
; void __stdcall        ClosePlugin(HANDLE hPlugin);
; bool __stdcall        SetFolder(HANDLE hPlugin,
;       const char* relative_path, const char* absolute_path);
; void __stdcall        GetOpenPluginInfo(HANDLE hPlugin, OpenPluginInfo* info);
; void __stdcall        GetFiles(HANDLE hPlugin, int NumItems, void* items[],
;       void* addfile, void* adddir);
;       bool __stdcall addfile(const char* name, void* bdfe_info, HANDLE hFile);
;       bool __stdcall adddir(const char* name, void* bdfe_info);
; int __stdcall         getattr(HANDLE hPlugin, const char* filename, void* info);
; HANDLE __stdcall      open(HANDLE hPlugin, const char* filename, int mode);
; void __stdcall        setpos(HANDLE hFile, __int64 pos);
; unsigned __stdcall    read(HANDLE hFile, void* buf, unsigned size);
; void __stdcall        close(HANDLE hFile);
IMPORTS:
library archiver, 'archiver.obj',\
	box_lib ,'box_lib.obj',\
	proc_lib,'proc_lib.obj'

import	archiver,\
	aPluginLoad	,      'plugin_load',\
	aOpenFilePlugin ,      'OpenFilePlugin',\
	aClosePlugin	,      'ClosePlugin',\
	aReadFolder	,      'ReadFolder',\
	aSetFolder	,      'SetFolder',\
	aGetFiles	,      'GetFiles',\
	aGetOpenPluginInfo ,   'GetOpenPluginInfo',\
	aGetattr	,      'getattr',\
	aOpen		,      'open',\
	aRead		,      'read',\
	aSetpos 	,      'setpos',\
	aClose		,      'close',\
	aDeflateUnpack	,      'deflate_unpack',\
	aDeflateUnpack2 ,      'deflate_unpack2'

import	proc_lib,\
	OpenDialog_Init 	,'OpenDialog_init',\
	OpenDialog_Start	,'OpenDialog_start'
import	box_lib,\
	edit_box_draw		,'edit_box',\
	edit_box_key		,'edit_box_key',\
	edit_box_mouse		,'edit_box_mouse'


IncludeIGlobals

;--  UDATA  -----------------------------------------------------------------------------
init_end:
align 16
IncludeUGlobals


;params db 'unz -o "fil epar1" -f "arch1.txt" -f "ar ch2.txt" file1',0
;params db 'unz -o "fil epar1" -f arch1.txt -f "ar ch2.txt" file1',0
;params db '/hd0/1/unz/xboot-1-0-build-14-en-win.zip',0
;rb 4096

fInp	rb 1024
pathOut rb 1024
files	rd 256
password	rb 256

fZipInfo	 rb 40

mouse_dd	rd 1
RBProcInfo	rb 1024
temp_dir_pach	rb 1024
ODAreaPath	rb 1024



;--------

copy_buf rb SIZE_COPY_BUF

execdata rb	1024
execdataend:

filedata_buffer_size = 1024
filedata_buffer rb	filedata_buffer_size

CopyDestEditBuf 	rb	12+512+1
.length = $ - CopyDestEditBuf - 13

bdvkPack rb 560

;--------

buffer	rb 4096 ;for string of file name or extract
params rb 4096

	rb 1024
stackUnpack:

	rb 1024
stackDlg:

	rb 1024
stack_top:

end_mem:


