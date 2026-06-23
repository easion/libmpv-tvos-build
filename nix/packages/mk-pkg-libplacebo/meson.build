# https://mesonbuild.com/External-Project-module.html

project('libplacebo', 'c')

mod = import('unstable-external_project')

p = mod.add_project('configure',
    configure_options : [
        '--prefix=@PREFIX@',
        '--disable-static',
        '-Ddemos=false',
	'-Dlcms=enabled', 
	'-Dshaderc=disabled',
        '--with-pic',
        '--with-aix-soname=aix',
        '--without-gnu-ld',
    ],
    verbose: true,
)

libplacebo_dep = p.dependency('libplacebo')
meson.override_dependency('libplacebo', libplacebo_dep)
