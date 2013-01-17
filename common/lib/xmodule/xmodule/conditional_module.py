import logging

from xmodule.x_module import XModule
from xmodule.modulestore import Location
from xmodule.seq_module import SequenceDescriptor

log = logging.getLogger('mitx.' + __name__)

class ConditionalModule(XModule):
    '''
    Blocks child module from showing unless certain conditions are met.

    Example:
        
        <conditional condition="require_completed" required="tag/url_name1&tag/url_name2">
            <video url_name="secret_video" />
        </conditional>

    '''

    def __init__(self, system, location, definition, descriptor, instance_state=None, shared_state=None, **kwargs):
        """
        In addition to the normal XModule init, provide:
        
            self.required_module_list = list of (tag, url_name) tuples of modules required by this one.
            self.condition            = string describing condition required

        """
        XModule.__init__(self, system, location, definition, descriptor, instance_state, shared_state, **kwargs)
        self.contents = None
        self.required_modules_list = [tuple(x.split('/',1)) for x in self.metadata.get('required','').split('&')]
        self.condition = self.metadata.get('condition','')
        log.debug('conditional module required=%s' % self.required_modules_list)

    def _get_required_modules(self):
        self.required_modules = []
        for (tag, name) in self.required_modules_list:
            loc = self.location.dict()
            loc['category'] = tag
            loc['name'] = name
            module = self.system.get_module(loc)
            self.required_modules.append(module)
        log.debug('required_modules=%s' % (self.required_modules))

    def is_condition_satisfied(self):
        self._get_required_modules()

        if self.condition=='require_completed':
            # all required modules must be completed, as determined by
            # the modules .is_completed() method
            for module in self.required_modules:
                if not hasattr(module, 'is_completed'):
                    raise Exception('Error in conditional module: required module %s has no .is_completed() method' % module)
                if not module.is_completed():
                    log.debug('condition module: %s not completed' % module)
                    return False
                else:
                    log.debug('condition module: %s IS completed' % module)
            return True
        else:
            raise Exception('Error in conditional module: unknown condition "%s"' % self.condition)

        return True

    def get_html(self):
        if not self.is_condition_satisfied():
            context = {'module': self,
                      }
            return self.system.render_template('conditional_module.html', context)

        if self.contents is None:
            self.contents = [child.get_html() for child in self.get_display_items()]

        # for now, just deal with one child
        html = self.contents[0]
        
        log.debug('rendered conditional module %s' % str(self.location))

        return html

class ConditionalDescriptor(SequenceDescriptor):
    module_class = ConditionalModule

    filename_extension = "xml"

    stores_state = True
    has_score = False
    