try:
    import matplotlib
    try:
        matplotlib.use('kitcat')
    except:
        print('Something went wrong with the kitty backend')
except:
    print('Something went wrong with matplotlib')


