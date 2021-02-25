import sys, os, shutil
sys.path.append(os.path.join(os.path.dirname(__file__), '..',))

import cythondb as db

DB_PATH = '~/Desktop/testdb'

def main():
    testdb = db.DB(DB_PATH)
    testdb.put('alice', '123')
    testdb.put('bob', '234')
    snapshot = testdb.get_snapshot()
    testdb.put('charlie', '456')
    read_option = db.ReadOptions()
    read_option.register_snapshot(snapshot)
    print(testdb.get('alice', read_option))
    print(testdb.get('charlie', read_option))
    read_option.release_snapshot()

    testdb.close()
    assert testdb.closed


if __name__ == '__main__':
    try:
        main()
    finally:
        shutil.rmtree(os.path.abspath(os.path.expanduser(DB_PATH)))