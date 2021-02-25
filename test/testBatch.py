import sys, os, shutil
sys.path.append(os.path.join(os.path.dirname(__file__), '..',))

import cythondb as db

DB_PATH = '~/Desktop/testdb'

def main():
    testdb = db.DB(DB_PATH)
    testdb.put('alice', '123')
    batch = db.WriteBatch()
    batch.delete('alice')
    batch.put('bob', '234')
    batch.put('charlie', '456')
    testdb.write_batch(batch)
    print(testdb.get('bob'))
    print(testdb.get('alice'))
    
    testdb.close()
    assert testdb.closed



if __name__ == '__main__':
    try:
        main()
    finally:
        shutil.rmtree(os.path.abspath(os.path.expanduser(DB_PATH)))