#ifndef BAZINGA_FILESYSTEM_H
#define BAZINGA_FILESYSTEM_H

// Macros to detect in what plataform I'm building
#ifdef MINGW32
#define WIN32
#endif
#ifdef __WIN32__
#define WIN32
#endif
#ifdef _WIN32
#define WIN32
#endif

#include <iostream>
#include <fcntl.h>			// Low level file creation
#include <sys/types.h>		// For Linux/Windows
#include <sys/stat.h>		// For Linux/Windows
#include <cstdio>			// Files
#ifndef WIN32
#include <unistd.h>			// Deleting
#include <dirent.h>			// Directory listing
#endif
#include <cstring>			// Memcpy
#include <algorithm>
#include <vector>
using namespace std;

class Path {
	string path; // plataform-specific string
	string original_path; // non plataform-specific string
	
	class Terminal {
		string value;
	public:
		Terminal(string);
		string get_value();
		string get_literal_value();
	};
public:
	Path (string="");
	~Path ();

	void set_path(string);   // set path in non-plataform-specific way (using '/' )
	string get_path(); // get plataform specific path
	string get_extension();
	string get_name();
	string get_original_path();
	bool is_equal(Path);
	void normalize();
	Path resolve(Path);
	Path resolve(const string);
    vector<Path> get_tree();
private:
	void set_windows_path(string);
	void set_linux_path(string);
	//set_mac_os_path();
	//set_android_path();
	//set_ios_path();
};

class fs {
	static const int buffer_size = 4096; // 4 K of memory
public:
	fs ();
	~fs	 ();

    static bool touch_file (Path&);
	static bool file_exists (Path);
	static bool copy_file (Path,Path,bool);
	static bool rename_file (Path,Path);
	static bool delete_file (Path);
	static bool create_file (Path);
    static bool create_directory (Path&);
	static bool is_dir (Path);
	static size_t get_file_size (Path);
	static char* get_file_data (Path);
	static bool set_file_data(Path, const char*, size_t);
	static vector <Path> list_directory (Path, bool&);
};
#endif /* BAZINGA_FILESYSTEM_H */
