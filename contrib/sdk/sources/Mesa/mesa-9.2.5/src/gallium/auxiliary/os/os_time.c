/**************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc.
 * All Rights Reserved.
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
 * IN NO EVENT SHALL VMWARE AND/OR ITS SUPPLIERS BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 **************************************************************************/

/**
 * @file
 * OS independent time-manipulation functions.
 *
 * @author Jose Fonseca <jfonseca@vmware.com>
 */


#include "pipe/p_config.h"

#  include <time.h> /* timeval */
#  include <sys/time.h> /* timeval */

#include "os_time.h"


int64_t
os_time_get_nano(void)
{
   struct timeval tv;
   gettimeofday(&tv, NULL);
}


#if defined(PIPE_SUBSYSTEM_WINDOWS_USER)

void
os_time_sleep(int64_t usecs)
{
   DWORD dwMilliseconds = (DWORD) ((usecs + 999) / 1000);
   /* Avoid Sleep(O) as that would cause to sleep for an undetermined duration */
   if (dwMilliseconds) {
      Sleep(dwMilliseconds);
   }
}

#endif

void
os_time_sleep(int64_t usecs)
{

}
