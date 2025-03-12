try:
    import matplotlib
    try:
        matplotlib.use('module://matplotlib-backend-kitty')
    except:
        print('Something went wrong with the kitty backend')
except:
    print('Something went wrong with matplotlib')


