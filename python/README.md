Please see the [parent README](../README.md) for information about SERF.

This is a Python package of SERF including a Django app and some helper modules.

## Usage

```python
import serf
serf.boot_django()
from serf.models import *


print(Subject.objects.get_or_create(name='Test')[0])
# ft = ('HR_aaa', 'H-reflex avg abs amp')
# myFT = FeatureType.objects.filter(name=ft[0])
```
