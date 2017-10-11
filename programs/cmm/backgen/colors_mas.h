struct _colors
{
	int x,y;
	unsigned rows, columns;
	unsigned cell_size;
	dword mas[MAX_COLORS*MAX_COLORS];
	dword image;
	void set_default_values();
	void set_color();
	dword get_color();
	dword get_image();
	void draw_cell();
	void draw_all_cells();
} colors;

void _colors::set_default_values()
{
	columns = 2;
	rows = 2;
	cell_size = 20;

	set_color(0,0, 0x66b2ff); 
	set_color(0,1, 0x000066); 

	set_color(1,0, 0x000066);
	set_color(1,1, 0x66b2ff);
}

void _colors::set_color(int _r, _c, _color)
{
	debugval("_r", _r);
	debugval("_c", _c);
	mas[MAX_COLORS*_r + _c] = _color;
}

dword _colors::get_color(int _r, _c)
{
	return mas[MAX_COLORS*_r + _c];
}

dword _colors::get_image()
{
	int r=0, c=0;
	dword i;

	free(image);
	i = image = malloc(rows*columns*3);

	for (r = 0; r < rows; r++)
	{
		for (c = 0; c < columns; c++)
		{
			rgb.DwordToRgb(get_color(r,c));
			ESBYTE[i] = rgb.b;
			ESBYTE[i+1] = rgb.g;
			ESBYTE[i+2] = rgb.r;
			i += 3;
		}
	}
	return image;
}

void _colors::draw_cell(int _x, _y, _color)
{
	DrawRectangle(_x, _y, cell_size, cell_size, 0xA7B2BA);
	DrawBar(_x+1, _y+1, cell_size-1, cell_size-1, _color);
}

void _colors::draw_all_cells()
{
	int r, c, i;
	for (i=300; i<MAX_COLORS*MAX_COLORS+300; i++) DeleteButton(i);
	for (r = 0; r < rows; r++)
	{
		for (c = 0; c < columns; c++)
		{
			draw_cell(c*cell_size + x, r*cell_size + y, get_color(r, c));
			DefineHiddenButton(c*cell_size + x, r*cell_size + y, cell_size, cell_size, r*columns+c+300);
		}
	}
}

