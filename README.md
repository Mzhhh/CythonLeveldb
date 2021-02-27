# Cython-Leveldb

Wrap of basic [leveldb](https://github.com/google/leveldb) APIs using Cython.

Author: MZH (zihanmao@outlook.com)

## Compilation

Getting the source:
```
git clone https://github.com/Mzhhh/CythonLeveldb.git
```

Place your **compiled leveldb library** into `include/` (see [leveldb](https://github.com/google/leveldb) for how to compile the library):
```
cd CythonLeveldb
cp LEVELDB_BUILD_DIR/libleveldb.a ./include/libleveldb.a
```

Compile python extension module with the provided makefile:
```
make ext
```

## Usage

### Opening and closing a database

e.g., create a database in Desktop and close it

```python
import cythondb as db

DB_PATH = '~/Desktop/testdb'
testdb = db.DB(DB_PATH) 
del testdb
```

### Basic read & write operations

Use `put` for inserting a (key, value) pair, `delete` for deleting an existing key, and `get` for getting the value of the privided key.

```python
options = Option(error_if_exists=False)  # allows opening existing database
testdb = db.DB(DB_PATH, options)

testdb.put('alice', '123')
testdb.put('bob', '234')
testdb.put('charlie', '456')

testdb.get('bob')  # '234'

testdb.delete('bob')
testdb.get('bob') # None
```

The implementation of `DB` also support `__getitem__` and `__setitem__` special methods. So the following codes are equivalent:
```python
# equivalent ways of querying
testdb.get('bob') 
testdb['bob']

# equivalent ways of inserting
testdb.put('bob', '234')
testdb['bob'] = '234'

# equivalent ways of deletion
testdb.delete('bob')
testdb['bob'] = None
```

### Batch update with `write_batch`

To use `write_batch`, you first need to create a `WriteBatch` object and write to that object.

```python
batch = db.WriteBatch()
batch.delete('alice')
batch.put('bob', '234')
batch.put('charlie', '456')
testdb.write_batch(batch)
```

### Snapshots

Snapshot allows you to save a state of the database and query form that state.

```python
before_insertion = testdb.get_snapshot()
testdb.put('dave', '789')
testdb.get('dave')  # '789'

read_options = ReadOptions()
read_options.register_snapshot(before_insertion)
testdb.get('dave', read_options)  # None
```

### Iterator

Iterator of the database can be acquired using `get_iterator` method (or `iter()` which returns the default iterator).

```python
forward_iter = iter(testdb)
reverse_iter = testdb.get_iterator(reversed=True)

for key, value in forward_iter:
    # do something
    pass
```

Iterator also supports various `seek` methods, which allows them to be positioned at specific keys.

### Custom comparator

User specified comparator is supported to be used as the underlying comparator of the database. The comparator must be a python callable object which can be called with two python strings:

```python
fun(str a, str b) -> int
```

The returned value is 0 if `a` and `b` are equal, greater than 0 is `a` should positioned after `b`, and less than 0 if otherwise. 

If no custom comparator is specified, then the database will use the built-in bytewise comparator.

To open a databse with custom specified comparator, one have to pass the callable function to the `Option` used when opening the database.

```python
# e.g., reversed comparator
def reverse_comparator(a, b):
    if a == b:
        return 0
    elif a > b:
        return -1
    else:
        return 1

option = db.Options(compare_function=reverse_comparator)

testdb = db.DB(DB_PATH, option)
```

## Limitations

No support for concurrency or multiprocessing. 