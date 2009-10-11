;
;   PROCESS MANAGEMENT
;
;   VTurjanmaa
;   additions by M.Lisovin lisovin@26.ru
;   Compile with FASM for Menuet
;

  use32
  org    0x0
STACK_SIZE=1024
  db     'MENUET01'              ; 8 byte id
  dd     0x01                    ; header version
  dd     START                   ; start of code
  dd     I_END                   ; size of image
  dd     U_END+STACK_SIZE        ; memory for app
  dd     U_END+STACK_SIZE        ; esp
  dd     0x0 , 0x0               ; I_Param , I_Icon

include 'lang.inc'
include '..\..\..\macros.inc'
display_processes=32            ; number of processes to show
align 4
START:                          ; start of execution
; calculate window position
; at the center of the screen
    call calculate_window_pos
    
;main loop when process name isn't edited.    
align 4
red:    
	xor	ebp,ebp
	inc	ebp
;    mov  ebp,1
    call draw_window            ; redraw all window
align 4
still:
    mov  eax,23                 ; wait here for event
    mov  ebx,200                ; 2 sec.
    mcall

    dec  eax                  ; redraw request ?
    jz   red
    dec  eax                  ; key in buffer ?
    jz   key
    dec  eax                  ; button in buffer ?
    jz   button
align 4
still_end:    
    xor  ebp,ebp                ; draw new state of processes
    call draw_window
    jmp  still

align 4
  key:                          ; key
    mov  eax,2                  
    mcall
    cmp  ah,184                 ; PageUp
    je   pgdn
    cmp  ah,183
    je   pgup                   ; PageDown
    cmp  ah,27
    je   close                  ; Esc
    jmp  still_end
align 4
  button:                       
; get button id  
    mov  eax,17                 
    mcall
    shr  eax,8                  

;id in [10,50] corresponds to terminate buttons.
    cmp  eax,10
    jb   noterm                 
    cmp  eax,50
    jg   noterm

;calculate button index        
    sub  eax,11
    
;calculate process slot    
    mov  ecx,[tasklist+4*eax]
    
;ignore empty buttons
    test ecx,ecx
    jle  still_end
;terminate application    
    mov  eax,18
    mov  ebx,2
    mcall
    jmp  still_end 
align 4
  noterm:

;special buttons
    dec  eax
    jz   close

    sub  eax,50
    jz   pgdn
    dec  eax
    jz   pgup
    dec  eax
    jz   read_string
    dec  eax
    jz   program_start
    dec  eax
    jz   reboot
    jmp  still_end
    
;buttons handlers    
align 4
  pgdn:
    sub  [list_start],display_processes
;    cmp  [list_start],0
    jge  still_end  
    mov  [list_start],0
    jmp  still_end  
align 4
  pgup:
    mov  eax,[list_add]  ;maximal displayed process slot
    mov  [list_start],eax
    jmp  still_end  
align 4    
  program_start:    
    mov  eax,70
    mov  ebx,file_start
    mcall
    jmp  still_end
align 4    
  reboot:    
    mov  eax,70
    mov  ebx,sys_reboot
    mcall
;close program if we going to reboot
align 4
  close:
    or   eax,-1                 ; close this program
    mcall
align 4
draw_next_process:
;input:
;  edi - current slot
;  [curposy] - y position
;output:
;  edi - next slot (or -1 if no next slot)
;registers corrupted!
    
;create button
    test  ebp,ebp
    jnz   .nodelete
;delete old button
    mov   eax,8
    mov   edx,[index]
    add   edx,(1 shl 31)+11
    mcall
align 4
.nodelete:
;create terminate process button
    mov   eax,8
    mov   ebx,15*65536+100
    mov   ecx,[curposy]
    shl   ecx,16
    mov   cx,10
    mov   edx,[index]
    add   edx,11
    mov   esi,0xaabbcc
;contrast    
    test  dword [index],1
    jz    .change_color_button
    mov   esi,0x8899aa
align 4
.change_color_button:
    mcall
    
;draw background for proccess information
    mov   eax,13
    mov   ebx,115*65536+395
    ;ecx was already set
    mov   edx,0x88ff88
;contrast
    test  dword [index],1
    jz    .change_color_info
    mov   edx,0xddffdd
align 4
.change_color_info:
    mcall
    
;nothing else should be done
;if there is no process for this button    
    test  edi,edi
    jl    .ret
    
;find process
    inc   edi
;more comfortable register for next loop    
    mov   ecx,edi
;precacluate pointer to process buffer    
    mov   ebx,process_info_buffer
    
;find process loop
align 4
.find_loop:
    cmp   ecx,256
    jge   .no_processes
    
;load process information in buffer
    mov   eax,9
;    mov   ebx,process_info_buffer
    mcall
    
;if current slot greater than maximal slot,
;there is no more proccesses.    
    cmp   ecx,eax
    jg    .no_processes
    
;if slot state is equal to 9, it is empty.    
    cmp   [process_info_buffer+process_information.slot_state],9
    jnz   .process_found
    
    inc   ecx
    jmp   .find_loop
align 4    
.no_processes:
    mov   edi,-1
    ret
align 4    
.process_found:
    mov  edi,ecx
    mov  [list_add],ecx
    
;get processor cpeed    
;for percent calculating
    mov  eax,18
    mov  ebx,5
    mcall
    
    xor  edx,edx
    mov  ebx,100
    div ebx
    
;eax = number of operation for 1% now
;calculate process cpu usage percent
    mov  ebx,eax
    mov  eax,[process_info_buffer+process_information.cpu_usage]
;    cdq
    xor edx,edx ; for CPU more 2 GHz - mike.dld 
 
    div  ebx
    mov  [cpu_percent],eax
    
;set text color to display process information
;([tcolor] variable)
;0%      : black    
;1-80%   : green
;81-100% : red
    test eax,eax
    jg   .no_black
    mov  [tcolor],eax
    jmp  .color_set
align 4
.no_black:   
    cmp  eax,80
    ja   .no_green
    mov  dword [tcolor],0x107a30
    jmp  .color_set
align 4
.no_green:
    mov  dword [tcolor],0xac0000
.color_set:

;show slot number
    mov  eax,47                
    mov  ebx,2*65536+1*256
;ecx haven't changed since .process_found    
;    mov  ecx,edi
    mov  edx,[curposy]
    add  edx,20*65536+1
    mov  esi,[tcolor]
    mcall
    
;show process name
    mov  eax,4
    mov  ebx,[curposy]
    add  ebx,50*65536+1
    mov  ecx,[tcolor]
    mov  edx,process_info_buffer.process_name
    mov  esi,11
    mcall
    
;show pid
    mov  eax,47
    mov  ebx,8*65536+1*256
    mov  ecx,[process_info_buffer.PID]
    mov  edx,[curposy]
    add  edx,130*65536+1
    mov  esi,[tcolor]
    mcall
    
;show cpu usage
    mov  ecx,[process_info_buffer.cpu_usage]
    add  edx,60*65536
    mcall
    
;show cpu percent
    mov  ebx,3*65536+0*256
    mov  ecx,[cpu_percent]
    add  edx,60*65536
    mcall
    
;show memory start - obsolete
    mov  ebx,8*65536+1*256
    mov  ecx,[process_info_buffer.memory_start]
    add  edx,30*65536
    mcall
    
;show memory usage
    mov  ecx,[process_info_buffer.used_memory]
    inc  ecx
    add  edx,60*65536
    mcall
    
;show window stack and value
    mov  ecx,dword [process_info_buffer.window_stack_position]
    add  edx,60*65536
    mcall
    
;show window xy size
    mov  ecx,[process_info_buffer.box.left]
    shl  ecx,16
    add  ecx,[process_info_buffer.box.top]
    add  edx,60*65536
    mcall    
align 4            
.ret:
;build index->slot map for terminating processes.
    mov  eax,[index]
    mov  [tasklist+4*eax],edi        
    ret
align 4
read_string:

;clean string
    mov  edi,start_application
    xor  eax,eax
    mov  ecx,60
    cld
    rep  stosb
    call print_text

    mov  edi,start_application
;edi now contains pointer to last symbol       
    jmp  still1

;read string main loop
align 4
  f11:
;full update  
    push edi
    mov  ebp,1
    call draw_window
    pop  edi
align 4
  still1:  
;wait for message  
    mov  eax,23
    mov  ebx,100
    mcall
    cmp  eax,1
    je   f11
;if no message - update process information    
    cmp  eax,0
    jnz  .message_received
    push edi                ;edi should be saved since draw_window
    xor  ebp,ebp            ;corrupt registers
    call draw_window
    pop  edi
    jmp  still1
align 4    
.message_received:
    cmp  eax,2
    jne  read_done          ;buttons message
;read char    
    mov  eax,2
    mcall
    shr  eax,8
    
;if enter pressed, exit read string loop    
    cmp  eax,13
    je   read_done
;if backslash pressed?    
    cmp  eax,8
    jnz  nobsl
;decrease pointer to last symbol    
    cmp  edi,start_application
    jz   still1
    dec  edi
;fill last symbol with space because
;print_text show all symbols    
    mov  [edi],byte 32
    call print_text
    jmp  still1
align 4    
  nobsl:
;write new symbol  
    mov  [edi],al
;display new text
    call print_text
;increment pointer to last symbol
    inc  edi
;compare with end of string    
    mov  esi,start_application
    add  esi,60
    cmp  esi,edi
    jnz  still1

;exiting from read string loop
align 4
  read_done:
;terminate string for file functions
    mov  [edi],byte 0

    call print_text
    jmp  still

align 4
print_text:
;display start_application string

    pushad
    
;display text background
    mov  eax,13
    mov  ebx,64*65536+62*6
    mov  ecx,400*65536+12
    mov  edx,0xffffcc  ;0xeeeeee
    mcall
    
;display text    
    mov  eax,4                  
    mov  edx,start_application  ;from start_application string
    mov  ebx,70*65536+402       ;text center-aligned
    xor  ecx,ecx                ;black text
    mov  esi,60                 ;60 symbols
    mcall

    popad
    ret

window_x_size=524
window_y_size=430
align 4
calculate_window_pos:
;set window size and position for 0 function
;to [winxpos] and [winypos] variables

;get screen size
    mov  eax,14
    mcall
    mov  ebx,eax
    
;calculate (x_screen-window_x_size)/2    
    shr  ebx,16+1
    sub  ebx,window_x_size/2
    shl  ebx,16
    mov  bx,window_x_size
;winxpos=xcoord*65536+xsize    
    mov  [winxpos],ebx
    
;calculate (y_screen-window_y_size)/2    
    and  eax,0xffff
    shr  eax,1
    sub  eax,window_y_size/2
    shl  eax,16
    mov  ax,window_y_size
;winypos=ycoord*65536+ysize    
    mov  [winypos],eax
    
    ret

;   *********************************************
;   *******  WINDOW DEFINITIONS AND DRAW ********
;   *********************************************

align 4
draw_window:
;ebp=1 - redraw all
;ebp=0 - redraw only process information

    test ebp,ebp
    jz   .show_process_info
    
    mov  eax,12                    ; function 12:tell os about windowdraw
;    mov  ebx,1                     ; 1, start of draw
    xor	 ebx,ebx
    inc  ebx
    mcall                      

                                   ; DRAW WINDOW
    xor  eax,eax                   ; function 0 : define and draw window
    mov  ebx,[winxpos]             ; [x start] *65536 + [x size]
    mov  ecx,[winypos]             ; [y start] *65536 + [y size]
    mov  edx,0x14ddffdd  ;ffffff   ; color of work area RRGGBB,8->color
    mov  edi,title                ; WINDOW CAPTION;
    mcall

                                   
    mov  eax,4                     ; function 4 : write text to window
    mov  ebx,22*65536+35           ; draw info text with function 4
    xor  ecx,ecx
    mov  edx,text
    mov  esi,text_len
    mcall
align 4
.show_process_info:
    mov  edi,[list_start]
    mov  [list_add],edi
    mov  dword [index],0
    mov  dword [curposy],54
align 4
.loop_draw:
    call draw_next_process
    inc  dword [index]
    add  dword [curposy],10
    cmp  [index],display_processes
    jl   .loop_draw
    
    test ebp,ebp
    jz   .end_redraw
    mov  eax,8
    mov  esi,0xaabbcc
                                    
; previous page button
    mov  ebx,30*65536+96
    mov  ecx,380*65536+10
    mov  edx,51
    mcall
                                    
; next page button
    mov  ebx,130*65536+96
    inc  edx
    mcall
                              
; ">" (text enter) button
    mov  ebx,30*65536+20
    add  ecx,20 shl 16
    inc  edx
    mcall
                                    
; run button
    mov  ebx,456*65536+50
    inc  edx
    mcall

; reboot button    
    sub  ebx,120*65536              
    add  ebx,60
    sub  ecx,20 shl 16
    inc  edx
    mcall
    
;"PREV PAGE", "NEXT PAGE" and "REBOOT" labels
    mov  eax,4
    mov  ebx,50*65536+382
    xor  ecx,ecx
    mov  edx,tbts
    mov  esi,tbte-tbts
    mcall

;">" labels
    mov  eax,4
    mov  ebx,40*65536+402
    xor  ecx,ecx
    mov  edx,tbts_2
    mov  esi,1
    mcall

;"RUN" labels
    mov  eax,4
    mov  ebx,475*65536+402
    xor  ecx,ecx
    mov  edx,tbts_3
    mov  esi,tbte_2-tbts_3
    mcall

;print application name in text box
    call print_text

    mov  eax,12                    ; function 12:tell os about windowdraw
    mov  ebx,2                     ; 2, end of draw
    mcall
align 4    
.end_redraw:
    ret


; DATA AREA
list_start  dd 0

file_start: dd 7
            dd 0,0,0,0

start_application: db '/sys/LAUNCHER',0
                   times 60 db 32

sys_reboot:
            dd 7
            dd 0
            dd 0
            dd 0
            dd 0
            db '/sys/end',0

if lang eq de
text:
  db ' NAME/BEENDEN       PID     CPU-LAST   % '
  db 'SPEICHER START/NUTZUNG  W-STACK  W-SIZE'
text_len = $-text

tbts:   db  'SEITE ZURUECK       SEITE VOR                      REBOOT SYSTEM'
tbte:
tbts_2  db  '>'
tbts_3  db  'START'
tbte_2:

title  db   'Prozesse  - Ctrl/Alt/Del',0

else if lang eq et
text:
  db ' NIMI/L�PETA        PID    CPU-KASUTUS %   '
  db 'M�LU ALGUS/KASUTUS  W-PUHVER  W-SUURUS'
text_len = $-text

tbts:	db  'EELMINE LEHT   J�RGMINE LEHT                     REBOODI S�STEEM'
tbte:
tbts_2	db  '>'
tbts_3	db  'START'
tbte_2:

title  db   'Protsessid - Ctrl/Alt/Del',0

else
text:
  db ' NAME/TERMINATE     PID     CPU-USAGE  %   '
  db 'MEMORY START/USAGE  W-STACK   W-SIZE'
text_len = $-text

tbts:   db  'PREV PAGE       NEXT PAGE                         REBOOT SYSTEM'
tbte:
tbts_2  db  '>'
tbts_3  db  'RUN'
tbte_2:

title  db   'Processes - Ctrl/Alt/Del',0

end if

I_END:

winxpos  rd 1
winypos  rd 1

cpu_percent rd 1
tcolor      rd 1
list_add    rd 1
curposy     rd 1
index       rd 1
tasklist    rd display_processes
process_info_buffer process_information
U_END:
