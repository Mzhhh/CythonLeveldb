import sys, os, shutil
sys.path.append(os.path.join(os.path.dirname(__file__), '..',))

import cythondb as db

DB_PATH = '~/Desktop/testdb'

def reverse_comparator(a, b):
    if a == b:
        return 0
    elif a > b:
        return -1
    else:
        return 1


def main():
    option = db.Options(compare_function=reverse_comparator)
    testdb = db.DB(DB_PATH, option)
    testdb.put('alice', '123')
    testdb.put('bob', '234')
    testdb.put('charlie', '456')
    
    assert ' '.join(key for key, _ in testdb) == 'charlie bob alice'

    testdb.close()
    assert testdb.closed

    print('Test finished.')

if __name__ == '__main__':
    try:
        main()
    finally:
        path = os.path.abspath(os.path.expanduser(DB_PATH))
        if os.path.exists(path):
            shutil.rmtree(path)
        print("Done!")