class FeatureBase:
    name = "FeatureBase"
    desc = """ Base class for all features. """
    category = "Base"

    def __init__(self, db_id):
        self.db_id = db_id

    def run(self, data):
        """
            Needs to be defined in sub-class.
        """
        return None
