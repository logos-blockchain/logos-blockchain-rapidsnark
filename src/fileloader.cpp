#ifdef _WIN32
#include <windows.h>
#else
#include <sys/mman.h>
#include <unistd.h>
#endif
#include <sys/stat.h>
#include <fcntl.h>
#include <system_error>
#include <stdexcept>

#include "fileloader.hpp"

namespace BinFileUtils {

FileLoader::FileLoader()
    : fd(-1)
{
}

FileLoader::FileLoader(const std::string& fileName)
    : fd(-1)
{
    load(fileName);
}

#ifdef _WIN32

// Windows has no mmap; a read-only file mapping is the direct equivalent.
// `fd` stays the loaded/not-loaded sentinel.
void FileLoader::load(const std::string& fileName)
{
    if (fd != -1) {
        throw std::invalid_argument("file already loaded");
    }

    HANDLE file = CreateFileA(fileName.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
                              OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, nullptr);
    if (file == INVALID_HANDLE_VALUE)
        throw std::system_error(GetLastError(), std::system_category(), "CreateFile");

    LARGE_INTEGER fileSize;
    if (!GetFileSizeEx(file, &fileSize)) {
        CloseHandle(file);
        throw std::system_error(GetLastError(), std::system_category(), "GetFileSizeEx");
    }
    size = static_cast<size_t>(fileSize.QuadPart);

    HANDLE mapping = CreateFileMappingA(file, nullptr, PAGE_READONLY, 0, 0, nullptr);
    if (mapping == nullptr) {
        CloseHandle(file);
        throw std::system_error(GetLastError(), std::system_category(), "CreateFileMapping");
    }

    addr = MapViewOfFile(mapping, FILE_MAP_READ, 0, 0, 0);
    if (addr == nullptr) {
        CloseHandle(mapping);
        CloseHandle(file);
        throw std::system_error(GetLastError(), std::system_category(), "MapViewOfFile");
    }

    fileHandle = file;
    mappingHandle = mapping;
    fd = 0;
}

FileLoader::~FileLoader()
{
    if (fd != -1) {
        UnmapViewOfFile(addr);
        CloseHandle(mappingHandle);
        CloseHandle(fileHandle);
    }
}

#else

void FileLoader::load(const std::string& fileName)
{
    if (fd != -1) {
        throw std::invalid_argument("file already loaded");
    }

    struct stat sb;

    fd = open(fileName.c_str(), O_RDONLY);
    if (fd == -1)
        throw std::system_error(errno, std::generic_category(), "open");


    if (fstat(fd, &sb) == -1) {          /* To obtain file size */
        close(fd);
        throw std::system_error(errno, std::generic_category(), "fstat");
    }

    size = sb.st_size;

    addr = mmap(nullptr, size, PROT_READ, MAP_PRIVATE, fd, 0);

    if (addr == MAP_FAILED) {
        close(fd);
        throw std::system_error(errno, std::generic_category(), "mmap failed");
    }

    madvise(addr, size, MADV_SEQUENTIAL);
}

FileLoader::~FileLoader()
{
    if (fd != -1) {
        munmap(addr, size);
        close(fd);
    }
}

#endif

} // Namespace
