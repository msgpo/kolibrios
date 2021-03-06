_ini ini = { "/sys/settings/txtread.ini", "Config" };

void LoadIniSettings()
{
	kfont.size.pt = ini.GetInt("FontSize", 14); 
	encoding      = ini.GetInt("Encoding", CH_CP866);
	Form.left     = ini.GetInt("WinX", 150); 
	Form.top      = ini.GetInt("WinY", 50); 
	Form.width    = ini.GetInt("WinW", 640); 
	Form.height   = ini.GetInt("WinH", 560); 
}

void SaveIniSettings()
{
	ini.SetInt("FontSize", kfont.size.pt);
	ini.SetInt("Encoding", encoding);
	ini.SetInt("WinX", Form.left);
	ini.SetInt("WinY", Form.top);
	ini.SetInt("WinW", Form.width);
	ini.SetInt("WinH", Form.height);
}