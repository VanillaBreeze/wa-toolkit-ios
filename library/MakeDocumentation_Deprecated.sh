#!/bin/sh
#
# Running this script creates the Windows Azure iOS Tookit documentation so that it
# can be integrated with Xcode. It requires Doxygen to be installed.
#
# See also:
# http://developer.apple.com/tools/creatingdocsetswithdoxygen.html
#

set -x

VERSION=$(agvtool mvers -terse1)
TMPDIR=$(mktemp -d /tmp/$(basename $0).XXXXXX) || exit 1
DOCDIR=../docs
DOXYFILE=$DOCDIR/doxygen.config
DOXYGEN=/Applications/Doxygen.app/Contents/Resources/doxygen
#PROJECT=$(echo *.xcodeproj | cut -d. -f1)
PROJECT=WAToolkit

if ! test -x $DOXYGEN ; then
	echo "*** Install Doxygen to get documentation generated for you automatically ***"
	exit 1
fi

# Create a doxygen configuration file with only the settings we care
# about
$DOXYGEN -g - > $DOXYFILE

cat <<EOF >> $DOXYFILE

PROJECT_NAME           = $PROJECT
PROJECT_NUMBER         = $VERSION
OUTPUT_DIRECTORY       = $DOCDIR
INPUT                  = ../library/Library
FILE_PATTERNS          = *.h *.m
RECURSIVE              = YES
HIDE_UNDOC_MEMBERS     = YES
HIDE_UNDOC_CLASSES     = YES
HIDE_UNDOC_RELATIONS   = YES
REPEAT_BRIEF           = NO
CASE_SENSE_NAMES       = YES
INLINE_INHERITED_MEMB  = YES
SHOW_FILES             = NO
SHOW_INCLUDE_FILES     = NO
GENERATE_LATEX         = NO
SEARCHENGINE           = NO
GENERATE_HTML          = YES
GENERATE_DOCSET        = YES
DOCSET_FEEDNAME        = "$PROJECT API Documentation"
DOCSET_BUNDLE_ID       = com.microsoft.$PROJECT

EOF

#  Run doxygen on the updated config file.
#  doxygen creates a Makefile that does most of the heavy lifting.
$DOXYGEN $DOXYFILE

#  make will invoke docsetutil. Take a look at the Makefile to see how this is done.
make -C $DOCDIR/html install

#  Construct a temporary applescript file to tell Xcode to load a
#  docset.
cat <<EOF > $TMPDIR/loadDocSet.scpt
	tell application "Xcode"
		load documentation set with path "/Users/$USER/Library/Developer/Shared/Documentation/DocSets/com.microsoft.${PROJECT}.docset/"
	end tell 
EOF

# Run the load-docset applescript command.
osascript $TMPDIR/loadDocSet.scpt