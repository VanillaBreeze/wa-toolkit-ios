#!/bin/sh
#
# Running this script creates the Windows Azure iOS Tookit documentation so that it
# can be integrated with Xcode. It requires appledoc to be installed.
#
# See also:
# http://gentlebytes.com/appledoc/
#

#/usr/local/bin/appledoc \
#--project-name "DTFoundation" \
#--project-company "Cocoanetics" \
#--company-id "com.cocoanetics" \
#--docset-atom-filename "DTFoundation.atom" \
#--docset-feed-url "http://cocoanetics.github.com/DTFoundation/%DOCSETATOMFILENAME" \
#--docset-package-url "http://cocoanetics.github.com/DTFoundation/%DOCSETPACKAGEFILENAME" \
#--docset-fallback-url "http://cocoanetics.github.com/DTFoundation/" \
#--output "~/help" \
#--publish-docset \
#--logformat xcode \
#--keep-undocumented-objects \
#--keep-undocumented-members \
#--keep-intermediate-files \
#--no-repeat-first-par \
#--no-warn-invalid-crossref \
#--ignore "*.m" \
#--ignore "LoadableCategory.h" \
#--index-desc "${PROJECT_DIR}/readme.markdown" \
#"${PROJECT_DIR}"

#project-name, project-company and company_id are standard
#the atom filename and the urls are necessary to let the docset know where it can get an update
#the output directory should be a place outside of your Xcode project. I found that having the generated documentation inside a github project does not make sense.
#publish-docset causes AppleDoc to generate the Atom feed and xar archive file
#logformat-xcode makes the output compatible with Xcode so that you get inline warnings
#keep-intermediate-files is necessary to preserve the original HTML output which you can put on your server for online reading
#no-repeate-first-par is the setting that does not duplicate the first paragraph into the discussion section
#no-warn-invalid-crossref omits the annoying warnings that you get when AppleDoc cannot find a reference to class or method
#we’re ignoring the .m files because otherwise AppleDoc would also try to get comments from these. We only want the comments from headers used also we don’t want the documentation say that a method was defined in the .h and the .m files which is unlike Apple.
#the LoadableCategory.h is another file we explicitly need to ignore, it is a dummy class that forces the linker to also load certain tagged categories. No use having that in the documentation.
#the index-desc is the path to a markdown file which additionally gets injected into the index page

set -x

VERSION=$(agvtool mvers -terse1)
DOCDIR=../docs
APPLEDOC=/usr/local/bin/appledoc
PROJECT=WAToolkit
COMPANY=Microsoft

if ! test -x $APPLEDOC ; then
	echo "*** Install appledoc to get documentation generated for you automatically ***"
	exit 1
fi

/usr/local/bin/appledoc \
--project-name $PROJECT \
--project-company $COMPANY \
--company-id "com.microsoft" \
--project-version $VERSION \
--output $DOCDIR \
--clean-output \
--create-docset \
--logformat xcode \
--keep-intermediate-files \
--no-repeat-first-par \
--no-warn-invalid-crossref \
--ignore "*.m" \
.