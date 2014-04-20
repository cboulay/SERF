from eerfd.models import *
from django.contrib import admin

class SubjectAdmin(admin.ModelAdmin):
    fieldsets = [
                 (None, {'fields': ['name','id']}),
                 ('Descriptors', {'fields': ['weight','height','birthday','headsize','sex','handedness']}),
                 ('Health', {'fields': ['smoking','alcohol_abuse','drug_abuse','medication','visual_impairment','heart_impairment']}),
                 ]
    
admin.site.register(Subject, SubjectAdmin)

admin.site.register(SubjectLog)
admin.site.register(DetailType)
admin.site.register(FeatureType)