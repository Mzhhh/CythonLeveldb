# distutils: language = c++
# distutils: libraries = leveldb

from libc.stdint cimport uint64_t
from libcpp cimport bool
from libcpp.string cimport string

cdef extern from "leveldb/db.h" namespace "leveldb":

    cdef cppclass Snapshot:
        pass

    cdef cppclass Range:
        Range()
        Range(Slice& s, Slice& l)
        Slice start
        Slice limit

    cdef cppclass DB:
        @staticmethod
        Status Open(Options& options, string& name, DB** dbptr)
        DB()
        
        Status Put(WriteOptions& options, Slice& key, Slice& value)
        Status Delete(WriteOptions& options, Slice& key);
        Status Write(WriteOptions& options, WriteBatch* updates)
        Status Get(ReadOptions& options, Slice& key, string* value);

        Iterator* NewIterator(ReadOptions& options)
        Snapshot* GetSnapshot()
        void ReleaseSnapshot(Snapshot* snapshot)

        bool GetProperty(Slice& property, string* value)
        void GetApproximateSizes(Range* range, int n, uint64_t* sizes)
        void CompactRange(Slice* begin, Slice* end)

    Status DestroyDB(string& name, Options& options)
    Status RepairDB(string& name, Options& options)


cdef extern from "leveldb/options.h" namespace "leveldb":
    
    cdef enum CompressionType:
        kNoCompression
        kSnappyCompression

    cdef cppclass Options:
        Options()
        Comparator* comparator
        bool create_if_missing
        bool error_if_exists
        bool paranoid_checks
        size_t write_buffer_size
        int max_open_files
        size_t block_size
        int block_restart_interval
        size_t max_file_size
        CompressionType compression
        FilterPolicy* filter_policy

    cdef cppclass ReadOptions:
        ReadOptions()
        bool verify_checksums
        bool fill_cache
        Snapshot* snapshot

    cdef cppclass WriteOptions:
        WriteOptions()
        bool sync
        

cdef extern from "leveldb/status.h" namespace "leveldb":

    cdef cppclass Status:
        bool ok()
        bool IsNotFound()
        bool IsCorruption()
        bool IsIOError()
        bool IsNotSupportedError()
        bool IsInvalidArgument()
        string ToString()


cdef extern from "leveldb/slice.h" namespace "leveldb":

    cdef cppclass Slice:
        Slice()
        Slice(const char* d, size_t n)
        Slice(const char* s)
        Slice(string& s)
        
        const char* data()
        size_t size()
        bool empty()
        void clear()
        void remove_prefix(size_t n)
        string ToString()
        int compare(Slice& b)
        bool starts_with(Slice&)


cdef extern from "leveldb/write_batch.h" namespace "leveldb":

    cdef cppclass WriteBatch:
       WriteBatch()
       void Put(Slice& key, Slice& value)
       void Delete(Slice& key)
       void Clear()
       size_t ApproximateSize()
       void Append(WriteBatch& source)


cdef extern from "leveldb/iterator.h" namespace "leveldb":

    cdef cppclass Iterator:
        Iterator()
        bool Valid()
        void SeekToFirst()
        void SeekToLast()
        void Seek(Slice& target)
        void Next()
        void Prev()
        Slice key()
        Slice value()
        Status status()


cdef extern from "leveldb/comparator.h" namespace "leveldb":

    cdef cppclass Comparator:
        pass

    Comparator* BytewiseComparator()


cdef extern from "leveldb/filter_policy.h" namespace "leveldb":

    cdef cppclass FilterPolicy:
        pass