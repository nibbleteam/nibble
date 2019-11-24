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

string Path::Terminal::get_value () {
	if (value[value.size()-1] == '/') {
		return value.substr(0, value.size()-1);
	} else
		return value;
}

string Path::Terminal::get_literal_value () {
	if (value[value.size()-1] == '/') {
		return value;
	} else
		return value+'/';
}

Path::Path (string _path):
	original_path(_path) {
	set_path (_path);
}

Path::~Path () {

}

Path Path::resolve(Path _path) {
	string self = get_path();
	string other = _path.get_path();

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
	string self = get_path();
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

void Path::set_path (string _path) {
#ifdef WIN32
	set_windows_path (_path);
#else
	set_linux_path (_path);
#endif
}

bool Path::is_equal (Path _path) {
	if (_path.get_original_path() == get_original_path())
		return true;
	return false;
}

string Path::get_original_path () {
	return original_path;
}

void Path::set_windows_path (string _path) {
	for_each (_path.begin(),_path.end(),[=] (char &c) -> void {
		if (c == '\\' || c == '/')
			c = '\\';
	});

	path = _path;
}

void Path::set_linux_path (string _path) {
	for_each (_path.begin(),_path.end(),[=] (char &c) -> void {
		if (c == '\\' || c == '/')
			c = '/';
	});

	path = _path;
}

string Path::get_path () const {
	return path;
}

string Path::get_extension () {
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

string Path::get_name () {
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
	string complete;
	
	for (auto c :original_path) {
		if (c == '/') {
			tpath.push_back(Terminal(buffer+c));
			buffer = "";
		} else {
			buffer += c;
		}
	}

	if (buffer != "")
		tpath.push_back(Terminal(buffer));

	if (tpath.size() > 1 && tpath[0].get_value() == ".") {
		tpath.erase(tpath.begin());
	}

	for (auto t :tpath) {
		if (t.get_value() == "..") {
			if (fpath.size() > 0 && fpath.top().get_value() != "..")
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
		complete += reverse.top().get_literal_value();
		reverse.pop();
	}

	if (complete == "") {
		complete = "./";
	}

	original_path = complete;
	set_path(complete);
}

vector<Path> Path::get_tree() {
	vector <Path> tree;
	string buffer;
	
	for (auto c :original_path) {
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

bool fs::touch_file (Path &_path) {
    for (auto &directory: _path.get_tree()) {
        if (!fs::create_directory(directory)) {
            return false;
        }
    }

    return fs::create_file(_path);
}

bool fs::create_directory(Path &_path) {
#ifdef _WIN32
    CreateDirectory(_path.get_path().c_str(), NULL);
    return true;
#else
    return mkdir(_path.get_path().c_str(), 0777) == 0;
#endif
}

bool fs::file_exists (Path _path) {
	struct _stat info;
	return !(bool)_stat (_path.get_path().c_str(),&info);
}


bool fs::delete_file (Path _path) {
	if (file_exists (_path)) {
		unlink (_path.get_path().c_str());
	}
	return false;
}

bool fs::create_file (Path _path) {
	if (file_exists(_path))
		return false;

#ifdef WIN32
	int fd = ::open(_path.get_path().c_str(), _O_CREAT, _S_IREAD | _S_IWRITE);
#else
	int fd = open(_path.get_path().c_str(), O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
#endif

	if (fd < 0)
		return false;

	close (fd);

	return true;
}

bool fs::rename_file (Path _path_a,Path _path_b) {
	if (file_exists (_path_a) && !file_exists(_path_b)) {
		if (rename (_path_a.get_path().c_str(),_path_b.get_path().c_str()) < 0)
			return false;
		return true;
	}
	return false;
}

bool fs::copy_file (Path _path_a, Path _path_b, bool _overwrite) {
	if (file_exists (_path_a) && (!file_exists(_path_b) || _overwrite)) {
		if (!file_exists(_path_b))
			if (!create_file (_path_b))
				return false;

		int fd_a,fd_b;
		// Open file A for reading only B for writing only
		if ((fd_a = open(_path_a.get_path().c_str(), O_RDONLY)) < 0)
			return false;
		if ((fd_b = open (_path_b.get_path().c_str(), O_WRONLY)) < 0)
			return false;

		function <void (int,int,char*)> cleanup = [] (int fd_a,int fd_b, char *file_buffer) -> void {
			delete[] file_buffer;
			close (fd_a);
			close (fd_b);
		};

		char *file_buffer = new char [buffer_size];
		int nr,nw;

		do {
			nr = read (fd_a,file_buffer,buffer_size);
			nw = write (fd_b,file_buffer,nr);

			if (nr != nw) { // Error writing!
				cleanup (fd_a,fd_b,file_buffer);
				return false;
			}
		} while (nr > 0); // While we have bytes to copy

		cleanup (fd_a,fd_b,file_buffer);
		return true;
	}
	return false;
}

char* fs::get_file_data (Path _path) {
	if (file_exists(_path)) {
		size_t file_size = get_file_size (_path);
		int buffer_size = 128;
		char* data = new char [file_size+1];
        char* buffer = new char [buffer_size];
		int fd;
		int nr = -1;
        size_t rs = 0;

        fd = open (_path.get_path().c_str(), O_RDONLY);

        while (nr != 0) {
            nr = read (fd,buffer,buffer_size);
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

bool fs::set_file_data (Path _path, const char* _data, size_t _size) {
	if (!file_exists (_path))
		if (!create_file(_path))
			return false;

	int fd, nr;

	fd = open (_path.get_path().c_str(), O_WRONLY |  O_TRUNC);
	nr = write (fd, _data, _size);
	close (fd);

	if ((unsigned int)nr < _size)
		return false;

	return true;
}

size_t fs::get_file_size (Path _path) {
	if (file_exists(_path)) {
#ifdef WIN32
		int fd = open(_path.get_path().c_str(), O_RDONLY);
		int size;
		int readb;

		do {
			readb = read(fd, NULL, 1024);
			size += readb;
		} while (readb > 0);

		return size;
#else
		struct _stat info;
		if (_stat (_path.get_path().c_str(),&info) < 0) {
			return -1;
		}

		return info.st_size;
#endif
	}

	return -1;
}

vector <Path> fs::list_directory (Path _path, bool &_success) {
    vector <Path> dir;
    _success = true;

    if (is_dir(_path)) {
#ifdef _WIN32
        string lig = _path.get_original_path()[_path.get_original_path().size()-1] != '/'?"\\":"";

        WIN32_FIND_DATA file;
        HANDLE found_file;

        if ((found_file = FindFirstFile((_path.get_path()+lig+"*").c_str(), &file)) != INVALID_HANDLE_VALUE) {
            do {
                dir.push_back(Path(string(_path.get_path()+lig+file.cFileName)));
            } while (FindNextFile(found_file, &file) != 0);
        }
#else
        string lig = _path.get_original_path()[_path.get_original_path().size()-1] != '/'?"/":"";

        DIR *d;
        struct dirent *entry;

        d = opendir(_path.get_path().c_str());

        if (d) {
            while ((entry = readdir(d)) != NULL) {
                dir.push_back (Path(_path.get_original_path()+lig+string(entry->d_name)));
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

bool fs::is_dir(Path _path) {
#ifdef _WIN32
	return GetFileAttributes(_path.get_path().c_str())&FILE_ATTRIBUTE_DIRECTORY;
#else
	struct _stat info;
	_stat (_path.get_path().c_str(),&info);
	return S_ISDIR(info.st_mode);
#endif
}
