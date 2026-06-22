import os

application = defines.get('app', 'SayIt.app')
bg          = defines.get('background', '')

appname = os.path.basename(application)

size = None
files = [application]
symlinks = {'Applications': '/Applications'}

icon_locations = {
    appname:        (175, 240),
    'Applications': (485, 240),
}

background = bg

show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False

window_rect = ((0, 0), (660, 420))
default_view = 'icon-view'
show_icon_preview = False

icon_size = 120
text_size = 13
