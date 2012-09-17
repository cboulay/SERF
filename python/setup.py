from distutils.core import setup
dependencies = {
        'numpy': '>=1.6.1',
        'scipy': '>=0.10.1',
        #'SQLAlchemy': '>=0.7.6'
}
setup(name='eerf',
      version='1.0.0',
      description='Evoked Electrophysiological Response Feedback',
      author='Chadwick Boulay',
      author_email='chadwick.boulay@gmail.com',
      url='https://github.com/cboulay/EERF',
      packages = ['eerf','eerf.eerfapi','eerf.eerf'],
      requires = [('%s (%s)' % (p,v)).replace(' ()','') for p,v in dependencies.items()]  # available in distutils from Python 2.5 onwards
)