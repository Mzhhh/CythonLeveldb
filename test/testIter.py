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
    assert ' '.join((key for key, _ in testdb)) == 'alice bob charlie dave eve francis gary hamilton'

    # iter with snapshot
    option = db.ReadOptions()
    option.register_snapshot(snapshot)
    assert ' '.join(key for key, _ in testdb.get_iterator(option)) == 'alice bob charlie dave eve'

    # seek methods
    it = iter(testdb)
    it.seek('d')
    assert ' '.join((key for key, _ in it)) == 'dave eve francis gary hamilton'
    del it

    # reversed iter
    assert ' '.join((key for key, _ in testdb.get_iterator(reversed=True))) == \
           'hamilton gary francis eve dave charlie bob alice'

    # reversed iter & seek
   
    it = testdb.get_iterator(reversed=True)
    it.seek('d')
    assert ' '.join((key for key, _ in it)) == 'charlie bob alice'
    del it
    
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