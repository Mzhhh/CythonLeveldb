#include <iostream>
#include "pycomparator.h"

PyComparator::PyComparator(PyObject* py_func, std::string name):
    name(std::move(name)), comp(py_func) {
    Py_INCREF(py_func);
}

PyComparator::~PyComparator() {
    Py_DECREF(comp);
}

const char* PyComparator::Name() const {
    return name.data();
}

int PyComparator::Compare(const leveldb::Slice& a, const leveldb::Slice& b) const {
    PyObject *a_str, *b_str;
    PyObject *result;
    long c_result;
    int overflow;

    a_str = PyUnicode_FromStringAndSize(a.data(), a.size());
    b_str = PyUnicode_FromStringAndSize(b.data(), b.size());
    if ((a_str == nullptr) || (b_str == nullptr)) { 
        Abort("Unable to convert keys to python strings.");
    }

    result = PyObject_CallFunctionObjArgs(comp, a_str, b_str, NULL);
    if (result == nullptr) {
        Abort("Python comparator function error.");
    }

    c_result = PyLong_AsLongAndOverflow(result, &overflow);
    if (PyErr_Occurred()) {
        Abort("Cannot convert comparator result to C++ type");
    }

    Py_DECREF(result);
    Py_DECREF(a_str);
    Py_DECREF(b_str);

    if ((overflow == 1) || (c_result > 0)) { 
        return 1; 
    } else if ((overflow == -1) || (c_result < 0)) {
        return -1;
    } else {
        return 0;
    }
}

void PyComparator::Abort(const char* message) const{
    PyErr_Print();
    std::cerr << "FATAL ERROR: "  << message << std::endl;
    std::cerr << "Program aborted." << std::endl;
}

PyComparator* PyComparator_FromPyFunction(PyObject* obj, std::string name) {
    PyComparator* ret = new PyComparator(obj, name);
    return ret;
}