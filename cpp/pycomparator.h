#ifndef PY_COMPARATOR_H
#define PY_COMPARATOR_H

#include <string>
#include <Python.h>
#include <leveldb/comparator.h>
#include <leveldb/slice.h>

class PyComparator: public leveldb::Comparator {
  
  public:
    PyComparator(PyObject* py_func, std::string name);
    ~PyComparator();
    int Compare(const leveldb::Slice& a, const leveldb::Slice& b) const;
    const char* Name() const;
    void FindShortestSeparator(std::string* start, const leveldb::Slice& limit) const {};
    void FindShortSuccessor(std::string* key) const {};

  private:
    std::string name;
    PyObject* comp;
    void Abort(const char* message) const;
};


PyComparator* PyComparator_FromPyFunction(PyObject* obj, std::string name);

#endif  // #ifndef PY_COMPARATOR_H

