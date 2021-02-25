import sys, os, shutil
sys.path.append(os.path.join(os.path.dirname(__file__), '..',))

import cythondb as db

DB_PATH = '~/Desktop/testdb'

def main():
    
    testdb = db.DB(DB_PATH)
    testdb.put('alice', '123')
    testdb.put('bob', '234')
    testdb.put('charlie', '456')
    testdb.put('dave', '789')
    testdb.put('eve', '666')
    snapshot = testdb.get_snapshot()
    testdb.put('francis', '777')
    testdb.put('gary', '888')
    testdb.put('hamilton', '999')
    
    # iter
    print(' '.join((key for key, _ in testdb)))

    # iter with snapshot
    option = db.ReadOptions()
    option.register_snapshot(snapshot)
    print(' '.join(key for key, _ in testdb.get_iterator(option)))

    # seek methods
    it = iter(testdb)
    it.seek('d')
    print(' '.join((key for key, _ in it)))

    # reversed iter
    print(' '.join((key for key, _ in testdb.get_iterator(reversed=True))))

    # reversed iter & seek
    del it
    it = testdb.get_iterator(reversed=True)
    it.seek('d')
    print(' '.join((key for key, _ in it)))
    
    testdb.close()
    assert testdb.closed
    

if __name__ == '__main__':
    try:
        main()
    finally:
        shutil.rmtree(os.path.abspath(os.path.expanduser(DB_PATH)))