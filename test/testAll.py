import os

def main():
    current_dir = os.path.dirname(__file__)
    current_file = os.path.basename(__file__)
    files = os.listdir(current_dir)
    for f in files:
        if f == current_file:
            continue
        f_path = os.path.join(current_dir, f)
        script_name = os.path.splitext(f)[0]
        
        print(f'Running: {script_name}')
        try:
            os.system(f'python {f_path}')
        except:
            print('>>> An exception has occurred!')
        finally:
            print('')
        

if __name__ == '__main__':
    main()