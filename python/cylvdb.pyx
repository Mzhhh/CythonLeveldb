# cython: language_level=3

from os.path import abspath, expanduser

from cpython cimport bool as py_bool
from libc.stdlib cimport malloc, free
from libc.string cimport const_char
from libc.stdint cimport uint64_t
from libcpp cimport bool as c_bool
from libcpp.string cimport string

cimport leveldb
from pycomparator cimport PyComparator_FromPyFunction

from weakref import ref as weak_ref

# status handling

class NotFoundError(Exception):
    pass

class CorruptionError(Exception):
    pass

class IOError(Exception):
    pass

class NotSupportedError(Exception):
    pass

class InvalidArgumentError(Exception):
    pass

cdef int check_status(leveldb.Status& st) except -1:
    if st.ok():
        return 0
    elif st.IsNotFound():
        raise NotFoundError(st.ToString().decode('UTF-8'))
    elif st.IsCorruption():
        raise CorruptionError(st.ToString().decode('UTF-8'))
    elif st.IsIOError():
        raise IOError(st.ToString().decode('UTF-8'))
    elif st.IsNotSupportedError():
        raise NotSupportedError(st.ToString().decode('UTF-8'))
    elif st.IsInvalidArgument():
        raise InvalidArgumentError(st.ToString().decode('UTF-8'))
    return -1


# Option wrapper

cdef class Options:

    cdef leveldb.Options _options
    
    def __cinit__(self, compare_function=None, py_bool create_if_missing=True, 
                   py_bool error_if_exists=None, py_bool paranoid_checks=None,
                   write_buffer_size=None, max_open_files=None,
                   block_restart_interval=None, max_file_size=None,
                   compression=None):

        if compare_function is None:
            self._options.comparator = leveldb.BytewiseComparator()
        else:
            self._options.comparator = PyComparator_FromPyFunction(
                                        compare_function, compare_function.__name__.encode('UTF-8')
                                      )
        if create_if_missing is not None:
            self._options.create_if_missing = create_if_missing
        if error_if_exists is not None:
            self._options.error_if_exists = error_if_exists
        if paranoid_checks is not None:
            self._options.paranoid_checks = paranoid_checks
        if write_buffer_size is not None:
            self._options.write_buffer_size = write_buffer_size
        if max_open_files is not None:
            self._options.max_open_files = max_open_files
        if block_restart_interval is not None:
            self._options.write_buffer_size = write_buffer_size
        if max_file_size is not None:
            self._options.max_file_size = max_file_size

        if compression is None:
            compression = leveldb.CompressionType.kNoCompression
        elif compression in (leveldb.CompressionType.kNoCompression, leveldb.CompressionType.kSnappyCompression):
            self._options.compression = compression
        elif isinstance(compression, bytes):
            compression_str = compression.decode('UTF-8')
            if compression_str == u'snappy':
                self._options.compression = leveldb.CompressionType.kSnappyCompression
        else:
            raise RuntimeError(f'Unknown compression type {compression}')


cdef class WriteOptions:

    cdef leveldb.WriteOptions _writeOptions

    def __cinit__(self, py_bool sync=None):
        if sync is not None:
            self._writeOptions.sync = sync


cdef class ReadOptions:

    cdef leveldb.ReadOptions _readOptions
    cdef Snapshot _snapshot_handler

    def __cinit__(self, py_bool verify_checksums=None, py_bool fill_cache=None):
        if verify_checksums is not None:
            self._readOptions.verify_checksums = verify_checksums
        if fill_cache is not None:
            self._readOption.fill_cache = fill_cache

    def register_snapshot(self, Snapshot snapshot not None):
        self._readOptions.snapshot = snapshot._snapshot_ptr
        self._snapshot_handler = snapshot

    def release_snapshot(self):
        if self._readOptions.snapshot != NULL:
            self._readOptions.snapshot = NULL
            self._snapshot_handler = None


cdef class Snapshot:

    cdef DB _db_handler
    cdef const leveldb.Snapshot* _snapshot_ptr

    def __cinit__(self):
        pass

    cdef _set(self, DB db, const leveldb.Snapshot* snapshot):
        self._db_handler = db
        self._snapshot_ptr = snapshot

    cdef _close(self):
        if self._snapshot_ptr == NULL or self._db_handler.closed:
            return 
        self._db_handler._db.ReleaseSnapshot(self._snapshot_ptr)
        self._snapshot_ptr = NULL
        self._db_handler = None

    def __dealloc__(self):
        self._close()        

# Write batch wrapper

cdef class WriteBatch:

    cdef leveldb.WriteBatch _batch
    
    def __cinit__(self):
        pass

    def put(self, str key not None,  str value not None):
        cdef string keyEncoded = key.encode('UTF-8')
        cdef string valueEncoded = value.encode('UTF-8')
        self._batch.Put(leveldb.Slice(keyEncoded), leveldb.Slice(valueEncoded))

    def delete(self, str key not None):
        cdef string keyEncoded = key.encode('UTF-8')
        self._batch.Delete(leveldb.Slice(keyEncoded))

    def clear(self):
        self._batch.Clear()

    def size(self):
        return self._batch.ApproximateSize()

    def append(self, WriteBatch other):
        self._batch.Append(other._batch)


# DB iterator wrapper

cdef class Iterator:

    cdef leveldb.Iterator* _iter_ptr
    cdef c_bool reversed

    cdef _set_iter(self, leveldb.Iterator* iter, py_bool reversed):
        self._iter_ptr = iter
        self.reversed = reversed
        if not reversed:
            self._iter_ptr.SeekToFirst()
        else:
            self._iter_ptr.SeekToLast()

    def __next__(self):
        if not self._iter_ptr.Valid():
            raise StopIteration
        cdef str key = self._iter_ptr.key().ToString().decode('UTF-8')
        cdef str value = self._iter_ptr.value().ToString().decode('UTF-8')
        if not self.reversed:
            self._iter_ptr.Next()
        else:
            self._iter_ptr.Prev()
        cdef leveldb.Status st = self._iter_ptr.status()
        check_status(st)
        return key, value

    def seek(self, str key not None, py_bool sanity_check=False):
        cdef string keyEncoded = key.encode('UTF-8')
        cdef leveldb.Slice keySlice = leveldb.Slice(keyEncoded)
        cdef leveldb.Slice seeked
        self._iter_ptr.Seek(keySlice)
        if self.reversed:
            seeked = self._iter_ptr.key()
            if seeked.compare(keySlice) != 0:
                self._iter_ptr.Prev()
        cdef leveldb.Status st
        if sanity_check:
            st = self._iter_ptr.status()
            check_status(st)

    def seek_first(self, py_bool sanity_check=False):
        if not self.reversed:
            self._iter_ptr.SeekToFirst()
        else:
            self._iter_ptr.SeekToLast()
        cdef leveldb.Status st
        if sanity_check:
            st = self._iter_ptr.status()
            check_status(st)

    def seek_last(self, py_bool sanity_check=False):
        if not self.reversed:
            self._iter_ptr.SeekToLast()
        else:
            self._iter_ptr.SeekToFirst()
        cdef leveldb.Status st
        if sanity_check:
            st = self._iter_ptr.status()
            check_status(st)
            
    def move_forward(self, py_bool sanity_check=False):
        if not self.reversed:
            self._iter_ptr.Next()
        else:
            self._iter_ptr.Prev()
        cdef leveldb.Status st
        if sanity_check:
            st = self._iter_ptr.status()
            check_status(st)

    def move_backward(self, py_bool sanity_check=False):
        if not self.reversed:
            self._iter_ptr.Prev()
        else:
            self._iter_ptr.Next()
        cdef leveldb.Status st
        if sanity_check:
            st = self._iter_ptr.status()
            check_status(st)

    def __iter__(self):
        return self

    cdef _close(self):
        if self._iter_ptr != NULL:
            del self._iter_ptr
            self._iter_ptr = NULL

    def __dealloc__(self):
        self._close()

# DB wrapper

cdef class DB:

    cdef leveldb.DB* _db
    cdef list _snapshots
    cdef list _iterators

    def __cinit__(self, str name not None, Options options=None):
        if options is None:
            options = Options()
        cdef leveldb.Status st
        cdef str full_path = abspath(expanduser(name))
        cdef string full_path_encoded = full_path.encode('UTF-8')
        st = leveldb.DB.Open(options._options, full_path_encoded, &self._db)
        check_status(st)
        self._snapshots = list()
        self._iterators = list()

    def __setitem__(self, str key not None, str value):
        if value is None:  # delete
            self.delete(key)
        else:
            self.put(key, value)

    def put(self, str key not None, str value not None, WriteOptions options=None):
        if options is None:
            options = WriteOptions()
        cdef leveldb.Status st
        cdef string keyEncoded = key.encode('UTF-8')
        cdef string valueEncoded = value.encode('UTF-8')
        st = self._db.Put(options._writeOptions, leveldb.Slice(keyEncoded), leveldb.Slice(valueEncoded))
        check_status(st)

    def delete(self, str key not None, WriteOptions options=None):
        if options is None:
            options = WriteOptions()
        cdef string keyEncoded = key.encode('UTF-8')
        cdef leveldb.Status st
        st = self._db.Delete(options._writeOptions, leveldb.Slice(keyEncoded))
        check_status(st)

    def write_batch(self, WriteBatch batch not None, WriteOptions options=None):
        cdef leveldb.Status st
        if options is None:
            options = WriteOptions()
        st = self._db.Write(options._writeOptions, &batch._batch)
        check_status(st)

    def __getitem__(self, str key not None):
        return self.get(key)

    def get(self, str key not None, ReadOptions options=None, str default=None):
        cdef string keyEncoded = key.encode('UTF-8')
        cdef leveldb.Status st
        cdef string result
        if options is None:
            options = ReadOptions()
        st = self._db.Get(options._readOptions, leveldb.Slice(keyEncoded), &result)
        if st.IsNotFound():
            return default
        check_status(st)
        return result.decode('UTF-8')

    def get_iterator(self, ReadOptions options=None, py_bool reversed=False):
        cdef Iterator it = Iterator()
        if options is None:
            options = ReadOptions()
        cdef leveldb.Iterator* it_ptr = self._db.NewIterator(options._readOptions)
        it._set_iter(it_ptr, reversed)  
        self._iterators.append(it)      
        return it

    def __iter__(self):  # default iterator
        return self.get_iterator()

    def get_snapshot(self):
        cdef const leveldb.Snapshot* snapshot = self._db.GetSnapshot()
        cdef Snapshot ret = Snapshot()
        ret._set(self, snapshot)
        self._snapshots.append(ret)
        return ret

    def get_property(self, str property not None):
        cdef string propName = property.encode('UTF-8')
        cdef string result
        cdef c_bool hasProperty = self._db.GetProperty(leveldb.Slice(propName), &result)
        if hasProperty:
            return result.decode('UTF-8')
        else:
            return None

    def get_size(self, str begin not None, str end not None):
        cdef string beginEncoded = begin.encode('UTF-8')
        cdef string endEncoded = end.encode('UTF-8')
        cdef uint64_t* size = <uint64_t*>malloc(sizeof(uint64_t))
        cdef leveldb.Range* range = new leveldb.Range(leveldb.Slice(beginEncoded), leveldb.Slice(endEncoded))
        self._db.GetApproximateSizes(range, 1, size)
        cdef uint64_t ret = size[0]
        free(size)
        return ret

    def compact_range(self, str begin, str end):
        cdef leveldb.Slice *beginSlice
        cdef leveldb.Slice *endSlice
        cdef string beginEncoded, endEncoded
        if begin is not None:
            beginEncoded = begin.encode('UTF-8')
            beginSlice = new leveldb.Slice(beginEncoded)
        else:
            beginSlice = NULL
        if end is not None:
            endEncoded = end.encode('UTF-8')
            endSlice = new leveldb.Slice(endEncoded)
        else:
            endSlice = NULL
        self._db.CompactRange(beginSlice, endSlice)
        del beginSlice, endSlice

    def __dealloc__(self):
        self.close()

    def close(self):
        cdef Snapshot snapshot
        cdef Iterator iterator
        if self._db != NULL:
            for snapshot in self._snapshots:
                snapshot._close()
            for iterator in self._iterators:
                iterator._close()
            del self._db
            self._db = NULL

    @property
    def closed(self):
        return self._db == NULL


# DB static function wrapper
    
def destroy_DB(str name not None, Options options):
    cdef string nameEncoded = name.encode('UTF-8')
    if options is None:
        options = Options()
    leveldb.DestroyDB(nameEncoded, options._options)

def repair_DB(str name not None, Options options):
    cdef string nameEncoded = name.encode('UTF-8')
    if options is None:
        options = Options()
    leveldb.RepairDB(nameEncoded, options._options)
