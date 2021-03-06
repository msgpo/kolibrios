/*
 * Decode Intra_16x16 macroblock
 * Copyright © <2010>, Intel Corporation.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sub license, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice (including the
 * next paragraph) shall be included in all copies or substantial portions
 * of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT.
 * IN NO EVENT SHALL PRECISION INSIGHT AND/OR ITS SUPPLIERS BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * This file was originally licensed under the following license
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
// Kernel name: Intra_16x16.asm
//
// Decoding of Intra_16x16 macroblock
//
//  $Revision: 8 $
//  $Date: 10/18/06 4:10p $
//

// ----------------------------------------------------
//  Main: Intra_16x16
// ----------------------------------------------------

#define	INTRA_16X16

.kernel Intra_16x16
INTRA_16x16:

#ifdef _DEBUG
// WA for FULSIM so we'll know which kernel is being debugged
mov (1) acc0:ud 0x00aa55a5:ud
#endif

#include "SetupForHWMC.asm"

#ifdef SW_SCOREBOARD    
    CALL(scoreboard_start_intra,1)
#endif

#ifdef SW_SCOREBOARD 
	wait	n0:ud		//	Now wait for scoreboard to response
#endif

//
//  Decode Y blocks
//
//	Load reference data from neighboring macroblocks
    CALL(load_Intra_Ref_Y,1)

//	Intra predict Intra_16x16 luma block
	#include "intra_pred_16x16_Y.asm"

//	Add error data to predicted intra data
	#include "add_Error_16x16_Y.asm"

//	Save decoded Y picture
	CALL(save_16x16_Y,1)
//
//  Decode U/V blocks
//
//	Note: The decoding for chroma blocks will be the same for all intra prediction mode
//
	CALL(decode_Chroma_Intra,1)

#ifdef SW_SCOREBOARD
    #include "scoreboard_update.asm"
#endif

// Terminate the thread
//
    #include "EndIntraThread.asm"

// End of Intra_16x16
