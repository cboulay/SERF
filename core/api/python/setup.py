from distutils.core import setup
dependencies = {
        'numpy': '>=1.6.1',
        'scipy': '>=0.10.1',
        'SQLAlchemy': '>=0.7.6'
}
setup(name='EeratAPI',
      version='1.0.0',
      packages = ['EeratAPI'],
      requires = [('%s (%s)' % (p,v)).replace(' ()','') for p,v in dependencies.items()],  # available in distutils from Python 2.5 onwards
      install_requires = ['%s%s' % (p,v) for p,v in dependencies.items()],
)