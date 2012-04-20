from distutils.core import setup
dependencies = {
        'Tkinter': '>=0.1',
        'matplotlib': '>=0.1',
        'EeratAPI': '>=0.1'
}
setup(name='MyGUIs',
      version='1.0.0',
      packages = ['MyGUIs'],
      requires = [('%s (%s)' % (p,v)).replace(' ()','') for p,v in dependencies.items()],  # available in distutils from Python 2.5 onwards
      install_requires = ['%s%s' % (p,v) for p,v in dependencies.items()],
)