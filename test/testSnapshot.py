import sys, os, shutil
sys.path.append(os.path.join(os.path.dirname(__file__), '..',))

import cythondb as db

DB_PATH = '~/Desktop/testdb'

def main():
    testdb = db.DB(DB_PATH)
    testdb.put('alice', '123')
    testdb.put('bob', '234')
    snapshot = testdb.get_snapshot()
    testdb.delete('bob')
    testdb.put('charlie', '456')
    read_option = db.ReadOptions()
    read_option.register_snapshot(snapshot)
    assert testdb.get('alice', read_option) == '123'
    assert testdb.get('bob', read_option) == '234'
    assert testdb.get('charlie', read_option) is None
    read_option.release_snapshot()

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