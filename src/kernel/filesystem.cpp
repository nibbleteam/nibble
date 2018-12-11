#include <kernel/filesystem.hpp>
#include <stack>
#include <functional>

#ifdef WIN32
#include <windows.h>
#include <io.h>
#else
#define _stat stat
#endif

Path::Terminal::Terminal (string value) {
	this->value = value;
}

string Path::Terminal::getValue () {
	if (value[value.size()-1] == '/') {
		return value.substr(0, value.size()-1);
	} else
		return value;
}

string Path::Terminal::getLiteralValue () {
	if (value[value.size()-1] == '/') {
		return value;
	} else
		return value+'/';
}

Path::Path (string _path):
	oPath(_path) {
	setPath (_path);
}

Path::~Path () {

}

Path Path::resolve(Path _path) {
	string self = getPath();
	string other = _path.getPath();

	if ((self.back() == '\\' || self.back() == '/') &&
		(other.front() == '\\' || other.front() == '/')) {
		other = string(other.begin() + 1, other.end());
	}
	else if ((self.back() != '\\' && self.back() != '/') &&
		(other.front() != '\\' && other.front() != '/')) {
		self += '/';
	}

	return Path(self + other);
}

Path Path::resolve(const string _path) {
	string self = getPath();
	string other = _path;

	if ((self.back() == '\\' || self.back() == '/') &&
		(other.front() == '\\' || other.front() == '/')) {
		other = string(other.begin() + 1, other.end());
	}
	else if ((self.back() != '\\' && self.back() != '/') &&
		(other.front() != '\\' && other.front() != '/')) {
		self += '/';
	}

	return Path(self + other);
}

void Path::setPath (string _path) {
#ifdef WIN32
	setWindowsPath (_path);
#else
	setLinuxPath (_path);
#endif
}

bool Path::isEqual (Path _path) {
	if (_path.getOriginalPath() == getOriginalPath())
		return true;
	return false;
}

string Path::getOriginalPath () {
	return oPath;
}

void Path::setWindowsPath (string _path) {
	for_each (_path.begin(),_path.end(),[=] (char &c)  -> void {
		if (c == '\\' || c == '/')
			c = '\\';
	});

	path = _path;
}

void Path::setLinuxPath (string _path) {
	for_each (_path.begin(),_path.end(),[=] (char &c)  -> void {
		if (c == '\\' || c == '/')
			c = '/';
	});

	path = _path;
}

string Path::getPath () {
	return path;
}

string Path::getExtension () {
	string extension;
	int i;
	for (i =path.length()-1;path[i] != '.' && i >= 0;i--) {
		extension += path[i];
	}

	if (i==0)
		return ""; // No extension found
	else {
		reverse(extension.begin(),extension.end());
		return extension;
	}
}

string Path::getName () {
	string name;
	int i;
	for (i =path.length()-1;path[i] != '\\' && path[i] != '/' && i >= 0;i--) {
		name += path[i];
	}

	if (i==0)
		return ""; // No name found
	else {
		reverse(name.begin(),name.end());
		return name;
	}	
}

void Path::normalize() {
	vector <Terminal> tpath;
	stack <Terminal> fpath;
	stack <Terminal> reverse;
	string buffer;
	string final;
	
	for (auto c :oPath) {
		if (c == '/') {
			tpath.push_back(Terminal(buffer+c));
			buffer = "";
		} else {
			buffer += c;
		}
	}

	if (buffer != "")
		tpath.push_back(Terminal(buffer));

	if (tpath.size() > 1 && tpath[0].getValue() == ".") {
		tpath.erase(tpath.begin());
	}

	for (auto t :tpath) {
		if (t.getValue() == "..") {
			if (fpath.size() > 0 && fpath.top().getValue() != "..")
				fpath.pop();
			else
				fpath.push(t);
		} else {
			fpath.push(t);
		}
	}

	while (fpath.size() > 0) {
		reverse.push(fpath.top());
		fpath.pop();
	}
	while (reverse.size() > 0) {
		final += reverse.top().getLiteralValue();
		reverse.pop();
	}

	if (final == "") {
		final = "./";
	}

	oPath = final;
	setPath(final);
}

vector<Path> Path::getTree() {
	vector <Path> tree;
	string buffer;
	
	for (auto c :oPath) {
        buffer += c;

		if (c == '/') {
			tree.push_back(Path(buffer));
		}
    }

    return tree;
}

fs::fs () {

}

fs::~fs () {

}

bool fs::touchFile (Path &_path) {
    for (auto &directory: _path.getTree()) {
        if (!fs::createDirectory(directory)) {
            return false;
        }
    }

    return fs::createFile(_path);
}

bool fs::createDirectory(Path &_path) {
#ifdef _WIN32
    CreateDirectory(_path.getPath().c_str(), NULL);
    return true;
#else
    return mkdir(_path.getPath().c_str(), 0777) == 0;
#endif
}

bool fs::fileExists (Path _path) {
	struct _stat info;
	return !(bool)_stat (_path.getPath().c_str(),&info);
}


bool fs::deleteFile (Path _path) {
	if (fileExists (_path)) {
		unlink (_path.getPath().c_str());
	}
	return false;
}

bool fs::createFile (Path _path) {
	if (fileExists(_path))
		return false;

#ifdef WIN32
	int fd = ::open(_path.getPath().c_str(), O_CREAT);
#else
	int fd = open(_path.getPath().c_str(), O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
#endif

	if (fd < 0)
		return false;

	close (fd);

	return true;
}

bool fs::renameFile (Path _pathA,Path _pathB) {
	if (fileExists (_pathA) && !fileExists(_pathB)) {
		if (rename (_pathA.getPath().c_str(),_pathB.getPath().c_str()) < 0)
			return false;
		return true;
	}
	return false;
}

bool fs::copyFile (Path _pathA, Path _pathB, bool _overwrite) {
	if (fileExists (_pathA) && (!fileExists(_pathB) || _overwrite)) {
		if (!fileExists(_pathB))
			if (!createFile (_pathB))
				return false;

		int fdA,fdB;
		// Open file A for reading only B for writing only
		if ((fdA = open(_pathA.getPath().c_str(), O_RDONLY)) < 0)
			return false;
		if ((fdB = open (_pathB.getPath().c_str(), O_WRONLY)) < 0)
			return false;

		function <void (int,int,char*)> cleanup = [] (int fdA,int fdB, char *fileBuffer) -> void {
			delete[] fileBuffer;
			close (fdA);
			close (fdB);
		};

		char *fileBuffer = new char [bufferSize];
		int nr,nw;

		do {
			nr = read (fdA,fileBuffer,bufferSize);
			nw = write (fdB,fileBuffer,nr);

			if (nr != nw) { // Error writing!
				cleanup (fdA,fdB,fileBuffer);
				return false;
			}
		} while (nr > 0); // While we have bytes to copy

		cleanup (fdA,fdB,fileBuffer);
		return true;
	}
	return false;
}

char* fs::getFileData (Path _path) {
	if (fileExists(_path)) {
		size_t fileSize = getFileSize (_path);
		int bufferSize = 128;
		char* data = new char [fileSize+1];
        char* buffer = new char [bufferSize];
		int fd;
		int nr = -1;
        size_t rs = 0;

        fd = open (_path.getPath().c_str(), O_RDONLY);

        while (nr != 0) {
            nr = read (fd,buffer,bufferSize);
            if (nr < 0) {
                delete[] data;
                return NULL;
            }
            memcpy (data+rs, buffer, nr);
            rs += nr;
        }

		close (fd);

        delete[] buffer;
		return data;
	}

	return NULL;
}

bool fs::setFileData (Path _path, const char* _data, size_t _size) {
	if (!fileExists (_path))
		if (!createFile(_path))
			return false;

	int fd, nr;

	fd = open (_path.getPath().c_str(), O_WRONLY |  O_TRUNC);
	nr = write (fd, _data, _size);
	close (fd);

	if ((unsigned int)nr < _size)
		return false;

	return true;
}

size_t fs::getFileSize (Path _path) {
	if (fileExists(_path)) {
#ifdef WIN32
		int fd = open(_path.getPath().c_str(), O_RDONLY);
		int size;
		int readb;

		do {
			readb = read(fd, NULL, 1024);
			size += readb;
		} while (readb > 0);

		return size;
#else
		struct _stat info;
		if (_stat (_path.getPath().c_str(),&info) < 0) {
			return -1;
		}

		return info.st_size;
#endif
	}

	return -1;
}

vector <Path> fs::listDirectory (Path _path, bool &_success) {
    vector <Path> dir;
    _success = true;

    if (isDir(_path)) {
#ifdef _WIN32
        string lig = _path.getOriginalPath()[_path.getOriginalPath().size()-1] != '/'?"\\":"";

        WIN32_FIND_DATA file;
        HANDLE foundFile;

        if ((foundFile = FindFirstFile((_path.getPath()+lig+"*").c_str(), &file)) != INVALID_HANDLE_VALUE) {
            do {
                dir.push_back(Path(string(_path.getPath()+lig+file.cFileName)));
            } while (FindNextFile(foundFile, &file) != 0);
        }
#else
        string lig = _path.getOriginalPath()[_path.getOriginalPath().size()-1] != '/'?"/":"";

        DIR *d;
        struct dirent *entry;

        d = opendir(_path.getPath().c_str());

        if (d) {
            while ((entry = readdir(d)) != NULL) {
                dir.push_back (Path(_path.getOriginalPath()+lig+string(entry->d_name)));
            }

            closedir(d);
        } else {
            _success = false;
        }
#endif
    } else {
        _success = false;
    }

	return dir;
}

bool fs::isDir(Path _path) {
#ifdef _WIN32
	return GetFileAttributes(_path.getPath().c_str())&FILE_ATTRIBUTE_DIRECTORY;
#else
	struct _stat info;
	_stat (_path.getPath().c_str(),&info);
	return S_ISDIR(info.st_mode);
#endif
}
