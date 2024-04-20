Please see the [main SERF README](https://github.com/cboulay/SERF/blob/master/README.md) for information about SERF.

This is a Python package of SERF which includes a Django app and some helper modules.

## Installation

This package is not on pypi. It is best installed with pip referencing the GitHub URL directly.

* `pip install git+https://github.com/cboulay/SERF.git@master#subdirectory=python`

Append [features] and wrap in quotes to get additional dependencies used for segment feature extraction.

* `pip install "git+https://github.com/cboulay/SERF.git@master#subdirectory=python[features]"` 

## Usage

```python
import serf
serf.boot_django()
from serf.models import *


print(Subject.objects.get_or_create(name='Test')[0])
# ft = ('HR_aaa', 'H-reflex avg abs amp')
# myFT = FeatureType.objects.filter(name=ft[0])
```
