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
	string oPath; // non plataform-specific string
	
	class Terminal {
		string value;
	public:
		Terminal(string);
		string getValue();
		string getLiteralValue();
	};
public:
	Path (string="");
	~Path ();

	void setPath(string);   // set path in non-plataform-specific way (using '/' )
	string getPath(); // get plataform specific path
	string getExtension();
	string getName();
	string getOriginalPath();
	bool isEqual(Path);
	void normalize();
	Path resolve(Path);
	Path resolve(const string);
    vector<Path> getTree();
private:
	void setWindowsPath(string);
	void setLinuxPath(string);
	//setMacOsPath();
	//setAndroidPath();
	//setiOSPath();
};

class fs {
	static const int bufferSize = 4096; // 4 K of memory
public:
	fs ();
	~fs	 ();

    static bool touchFile (Path&);
	static bool fileExists (Path);
	static bool copyFile (Path,Path,bool);
	static bool renameFile (Path,Path);
	static bool deleteFile (Path);
	static bool createFile (Path);
    static bool createDirectory (Path&);
	static bool isDir (Path);
	static size_t getFileSize (Path);
	static char* getFileData (Path);
	static bool setFileData(Path, const char*, size_t);
	static vector <Path> listDirectory (Path,bool&);
};
#endif /* BAZINGA_FILESYSTEM_H */
