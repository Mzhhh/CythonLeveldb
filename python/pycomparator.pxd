# distutils: language = c++

from libcpp.string cimport string
from leveldb cimport Comparator

cdef extern from "pycomparator.h":

    Comparator* PyComparator_FromPyFunction(object obj, string name)    


