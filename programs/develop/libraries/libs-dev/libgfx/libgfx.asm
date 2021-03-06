;;================================================================================================;;
;;//// libgfx.asm //// (c) mike.dld, 2006-2008 ///////////////////////////////////////////////////;;
;;================================================================================================;;
;;                                                                                                ;;
;; This file is part of Common development libraries (Libs-Dev).                                  ;;
;;                                                                                                ;;
;; Libs-Dev is free software: you can redistribute it and/or modify it under the terms of the GNU ;;
;; Lesser General Public License as published by the Free Software Foundation, either version 2.1 ;;
;; of the License, or (at your option) any later version.                                         ;;
;;                                                                                                ;;
;; Libs-Dev is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without  ;;
;; even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU  ;;
;; Lesser General Public License for more details.                                                ;;
;;                                                                                                ;;
;; You should have received a copy of the GNU Lesser General Public License along with Libs-Dev.  ;;
;; If not, see <http://www.gnu.org/licenses/>.                                                    ;;
;;                                                                                                ;;
;;================================================================================================;;


format MS COFF

public @EXPORT as 'EXPORTS'

include '../../../../proc32.inc'
include '../../../../macros.inc'
purge section;mov,add,sub

include 'libgfx_p.inc'

section '.flat' code readable align 16

mem.alloc   dd ?
mem.free    dd ?
mem.realloc dd ?
dll.load    dd ?

;;================================================================================================;;
proc lib_init ;///////////////////////////////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? Library entry point (called after library load)                                                ;;
;;------------------------------------------------------------------------------------------------;;
;> eax = pointer to memory allocation routine                                                     ;;
;> ebx = pointer to memory freeing routine                                                        ;;
;> ecx = pointer to memory reallocation routine                                                   ;;
;> edx = pointer to library loading routine                                                       ;;
;;------------------------------------------------------------------------------------------------;;
;< eax = 1 (fail) / 0 (ok) (library initialization result)                                        ;;
;;================================================================================================;;
	mov	[mem.alloc], eax
	mov	[mem.free], ebx
	mov	[mem.realloc], ecx
	mov	[dll.load], edx
	xor	eax,eax
	ret
endp

;;================================================================================================;;
proc gfx.open _open? ;////////////////////////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	push	ebx ecx
	xor	ecx, ecx
	cmp	byte[_open?], 0
	je	.lp1
	mov	eax, 12
	mov	ebx, 1
	int	0x40
	jmp	@f
  .lp1: or	ecx, GFX_FLAG_DONT_CLOSE
    @@: invoke	mem.alloc, sizeof.AGfxContext
	xor	ebx,ebx
	mov	[eax + AGfxContext.Flags], ecx
	mov	[eax + AGfxContext.NullPoint.X], ebx
	mov	[eax + AGfxContext.NullPoint.Y], ebx
	mov	[eax + AGfxContext.Caret.X], ebx
	mov	[eax + AGfxContext.Caret.Y], ebx
	mov	[eax + AGfxContext.Pen.Color], ebx
	mov	[eax + AGfxContext.Brush.Color], 0x00FFFFFF
	pop	ecx ebx
	ret
endp

;;================================================================================================;;
proc gfx.close _ctx ;/////////////////////////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	push	eax ebx
	mov	ebx, [_ctx]
	mov	ebx, [ebx + AGfxContext.Flags]
	invoke	mem.free, [_ctx]
	test	ebx, GFX_FLAG_DONT_CLOSE
	jnz	@f
	mov	eax, 12
	mov	ebx, 2
	int	0x40
    @@: pop	ebx eax
	ret
endp

;;================================================================================================;;
proc gfx.pen.color _ctx, _color ;/////////////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	push	eax
	mov	eax, [_ctx]
	push	[_color]
	pop	[eax + AGfxContext.Pen.Color]
	pop	eax
	ret
endp

;;================================================================================================;;
proc gfx.brush.color _ctx, _color ;///////////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	push	eax
	mov	eax, [_ctx]
	push	[_color]
	pop	[eax + AGfxContext.Brush.Color]
	pop	eax
	ret
endp

;;================================================================================================;;
proc gfx.pixel _ctx, _x, _y ;/////////////////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	push	eax ebx ecx edx
	mov	eax, 1
	mov	ebx, [_x]
	mov	ecx, [_y]
	mov	edx, [_ctx]
	mov	edx, [edx + AGfxContext.Pen.Color]
	int	0x40
	pop	edx ecx ebx eax
	ret
endp

;;================================================================================================;;
proc gfx.move.to _ctx, _x, _y ;///////////////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	push	eax
	mov	eax, [_ctx]
	push	[_x] [_y]
	pop	[eax + AGfxContext.Caret.Y] [eax+AGfxContext.Caret.X]
	pop	eax
	ret
endp

;;================================================================================================;;
proc gfx.line.to _ctx, _x, _y ;///////////////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	push	eax
	mov	eax, [_ctx]
	stdcall gfx.line, eax, [eax + AGfxContext.Caret.X], [eax + AGfxContext.Caret.Y], [_x], [_y]
	pop	eax
	stdcall gfx.move.to, [_ctx], [_x], [_y]
	ret
endp

;;================================================================================================;;
proc gfx.line _ctx, _x1, _y1, _x2, _y2 ;//////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	push	eax ebx ecx edx
	mov	eax, 38
	mov	ebx, [_x1 - 2]
	mov	bx, word[_x2]
	mov	ecx, [_y1 - 2]
	mov	cx, word[_y2]
	mov	edx, [_ctx]
	mov	edx, [edx + AGfxContext.Pen.Color]
	int	0x40
	pop	edx ecx ebx eax
	stdcall gfx.move.to, [_ctx], [_x2], [_y2]
	ret
endp

;;================================================================================================;;
proc gfx.polyline _ctx, _points, _count ;/////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	push	eax ecx
	mov	eax, [_points]
	stdcall gfx.move.to, [_ctx], [eax + 0], [eax + 4]
	mov	ecx, [_count]
	dec	ecx
	add	eax, 8
	stdcall gfx.polyline.to, [_ctx], eax, ecx
	pop	ecx eax
	ret
endp

;;================================================================================================;;
proc gfx.polyline.to _ctx, _points, _count ;//////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	push	eax ecx
	mov	eax, [_points]
	mov	ecx, [_count]
    @@: stdcall gfx.line.to, [_ctx], [eax + 0], [eax + 4]
	add	eax, 8
	loop	@b
	pop	ecx eax
	ret
endp

;;================================================================================================;;
proc gfx.fillrect _ctx, _x1, _y1, _x2, _y2 ;//////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	push	eax ebx ecx edx
	mov	eax, 13
	mov	ebx, [_x1 - 2]
	mov	bx, word[_x2]
	sub	bx, word[_x1]
	inc	bx
	mov	ecx, [_y1 - 2]
	mov	cx, word[_y2]
	sub	cx, word[_y1]
	inc	cx
	mov	edx, [_ctx]
	mov	edx, [edx + AGfxContext.Brush.Color]
	int	0x40
	pop	edx ecx ebx eax
	ret
endp

;;================================================================================================;;
proc gfx.fillrect.ex _ctx, _rect ;////////////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	push	eax
	mov	eax, [_rect]
	stdcall gfx.fillrect, [_ctx], [eax + ARect.Left], [eax + ARect.Top], \
			      [eax + ARect.Right], [eax + ARect.Bottom]
	pop	eax
	ret
endp

;;================================================================================================;;
proc gfx.framerect _ctx, _x1, _y1, _x2, _y2 ;/////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	stdcall gfx.move.to, [_ctx], [_x1], [_y1]
	stdcall gfx.line.to, [_ctx], [_x2], [_y1]
	stdcall gfx.line.to, [_ctx], [_x2], [_y2]
	stdcall gfx.line.to, [_ctx], [_x1], [_y2]
	stdcall gfx.line.to, [_ctx], [_x1], [_y1]
	pop	edx ecx ebx eax
	ret
endp

;;================================================================================================;;
proc gfx.framerect.ex _ctx, _rect ;///////////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	push	eax
	mov	eax, [_rect]
	stdcall gfx.framerect, [_ctx], [eax + ARect.Left], [eax + ARect.Top], \
			       [eax + ARect.Right], [eax + ARect.Bottom]
	pop	eax
	ret
endp

;;================================================================================================;;
proc gfx.rectangle _ctx, _x1, _y1, _x2, _y2 ;/////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	stdcall gfx.framerect, [_ctx], [_x1], [_y1], [_x2], [_y2]
	push	[_y2] [_x2] [_y1] [_x1]
	inc	dword[esp + 0x00]
	inc	dword[esp + 0x04]
	dec	dword[esp + 0x08]
	dec	dword[esp + 0x0C]
	stdcall gfx.fillrect, [_ctx]
	ret
endp

;;================================================================================================;;
proc gfx.rectangle.ex _ctx, _rect ;///////////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	push	eax
	mov	eax, [_rect]
	stdcall gfx.rectangle, [_ctx], [eax + ARect.Left], [eax + ARect.Top], \
			       [eax + ARect.Right], [eax + ARect.Bottom]
	pop	eax
	ret
endp

;;================================================================================================;;
proc gfx.text _ctx, _text, _len, _x, _y ;/////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	ret
endp

;;================================================================================================;;
proc gfx.text.width _ctx, _text, _len ;///////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	ret
endp

;;================================================================================================;;
proc gfx.text.height _ctx, _text, _len ;//////////////////////////////////////////////////////////;;
;;------------------------------------------------------------------------------------------------;;
;? --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;> --- TBD ---                                                                                    ;;
;;------------------------------------------------------------------------------------------------;;
;< --- TBD ---                                                                                    ;;
;;================================================================================================;;
	ret
endp


;;================================================================================================;;
;;////////////////////////////////////////////////////////////////////////////////////////////////;;
;;================================================================================================;;
;! Exported functions section                                                                     ;;
;;================================================================================================;;
;;////////////////////////////////////////////////////////////////////////////////////////////////;;
;;================================================================================================;;


align 16
@EXPORT:

export						\
	lib_init	 , 'lib_init'	      , \
	0x00020002	 , 'version'	      , \
	gfx.open	 , 'gfx_open'	      , \
	gfx.close	 , 'gfx_close'	      , \
	gfx.pen.color	 , 'gfx_pen_color'    , \
	gfx.brush.color  , 'gfx_brush_color'  , \
	gfx.pixel	 , 'gfx_pixel'	      , \
	gfx.move.to	 , 'gfx_move_to'      , \
	gfx.line.to	 , 'gfx_line_to'      , \
	gfx.line	 , 'gfx_line'	      , \
	gfx.polyline	 , 'gfx_polyline'     , \
	gfx.polyline.to  , 'gfx_polyline_to'  , \
	gfx.fillrect	 , 'gfx_fillrect'     , \
	gfx.fillrect.ex  , 'gfx_fillrect_ex'  , \
	gfx.framerect	 , 'gfx_framerect'    , \
	gfx.framerect.ex , 'gfx_framerect_ex' , \
	gfx.rectangle	 , 'gfx_rectangle'    , \
	gfx.rectangle.ex , 'gfx_rectangle_ex'
