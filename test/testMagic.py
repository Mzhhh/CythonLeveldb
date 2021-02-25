import sys, os, shutil
sys.path.append(os.path.join(os.path.dirname(__file__), '..',))

import cythondb as db

DB_PATH = '~/Desktop/testdb'

def main():
    testdb = db.DB(DB_PATH)
    testdb['alice'] = '123'
    testdb['bob'] = '234'
    testdb['charlie'] = '456'
    print(testdb['bob'])
    testdb['alice'] = None
    print(testdb['alice'])
    
    testdb.close()
    assert testdb.closed

if __name__ == '__main__':
    try:
        main()
    finally:
        shutil.rmtree(os.path.abspath(os.path.expanduser(DB_PATH)))