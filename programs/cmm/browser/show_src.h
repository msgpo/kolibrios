enum { TAG, OPTION_VALUE, TEXT, COMMENT };

//you are butifull, you are butifull
dword ShowSource()
{
	dword new_buf, new_buf_start, i;
	byte ww, mode;

	if (souce_mode) return;
	souce_mode = true;
	new_buf = malloc(bufsize*5);
	new_buf_start = new_buf;
	header[strrchr(#header, '-')-2]=0;
	sprintf(new_buf,"<html><head><title>Source: %s</title><body><pre>",#header);
	new_buf += strlen(new_buf);
	for (i=bufpointer; i<bufpointer+bufsize; i++) 
	{
		ww = ESBYTE[i];
		switch (ww)
		{
			case '<':
				if (mode == COMMENT)
				{
					strcpy(new_buf, "&lt;");
					new_buf+=4;
					break;
				}
				if (ESBYTE[i+1]=='!') && (ESBYTE[i+2]=='-') && (ESBYTE[i+3]=='-')
				{
					strcpy(new_buf, "<font color=#bbb>&lt;");
					new_buf+=21;
					mode = COMMENT;
					break;
				}
				if (mode != COMMENT)
				{
					strcpy(new_buf, "<font color=#00f>&lt;");
					new_buf+=21;
					mode = TAG;
					break;
				}
				break;
			case '>':
				if (mode == OPTION_VALUE) //fix non-closed quote in TAG
				{
					strcpy(new_buf, "&quot;</font>");
					new_buf+=13;					
					mode = TAG;
					break;
				}
				if (mode == COMMENT) && (ESBYTE[i-1]=='-') && (ESBYTE[i-2]=='-')
				{
					strcpy(new_buf, "&gt;</font>");
					new_buf+=11;
					mode = TEXT;
					break;
				}
				if (mode == COMMENT) 
				{
					strcpy(new_buf, "&gt;");
					new_buf+=4;
					break;					
				}
				if (mode == TAG)
				{
					strcpy(new_buf, "&gt;</font>");
					new_buf+=11;
					mode = TEXT;
					break;
				}
				break;
			case '\"':
			case '\'':
				if (mode == TAG)
				{
					strcpy(new_buf, "<font color=#f0f>&#39;");
					new_buf+=22;
					mode = OPTION_VALUE;
					break;
				}
				if (mode == OPTION_VALUE)
				{
					strcpy(new_buf, "&#39;</font>");
					new_buf+=12;
					mode = TAG;
					break;
				}
			default:
				ESBYTE[new_buf] = ww;
				new_buf++;
		}
	}
	ESBYTE[new_buf] = 0;
	bufsize = new_buf - new_buf_start;
	free(bufpointer);
	bufpointer = new_buf_start;
}