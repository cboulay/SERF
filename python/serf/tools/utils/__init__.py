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

from . import misc_functions

__all__ = ['misc_functions']
