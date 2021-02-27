import sys, os, shutil
sys.path.append(os.path.join(os.path.dirname(__file__), '..',))

import cythondb as db

DB_PATH = '~/Desktop/testdb'

def main():
    testdb = db.DB(DB_PATH)
    testdb.put('alice', '123')
    testdb.put('bob', '234')
    testdb.put('charlie', '456')
    assert testdb.get('bob') == '234'
    testdb.delete('alice')
    assert testdb.get('alice') is None
    
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