"""
Any features can be added to the list, as long as they are defined as a class with the model:
class ClassName:
    name = "ClassName"
    desc = "Class description"
    category = "DBS", "DL", or any custom value

    def __init__(self):
        self.db_id = None  # feature id within the db. populated at instantiation

    @staticmethod
    def run(data):
        return data, x_vec

"""

from . import stn_features
from . import dl_features
from . import lfp_features
from . import spike_features

__all__ = ['stn_features.py', 'dl_features', 'lfp_features', 'spike_features']
