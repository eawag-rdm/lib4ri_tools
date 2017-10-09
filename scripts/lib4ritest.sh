#!/bin/sh

###
 # Copyright (c) 2017 d-r-p (Lib4RI) <d-r-p@users.noreply.github.com>
 #
 # Permission to use, copy, modify, and distribute this software for any
 # purpose with or without fee is hereby granted, provided that the above
 # copyright notice and this permission notice appear in all copies.
 #
 # THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 # WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 # MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 # ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 # WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 # ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 # OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
###

STATUS=0

echo "***** Wrapper script called *****" >&2

echo "^^^ Creating 'pdf' subdirectory ^^^" >&2
mkdir pdf 1>&2

STATUS=$?

if [ $STATUS -ne 0 ]
then
  echo "^^^ Error: Could not create 'pdf' subdirectory (mkdir exited with $STATUS)" >&2
  exit $STATUS
fi

echo "^^^ done ^^^" >&2

echo "^^^ Extracting PDFs ^^^" >&2

unzip -j PDFs.zip -d pdf 1>&2

STATUS=$?

if [ $STATUS -ne 0 ]
then
  echo "^^^ Error: Could not extract the pdfs to 'pdf' (unzip exited with $STATUS)" >&2
  exit $STATUS
fi

echo "^^^ done ^^^" >&2

echo "^^^ Calling '0_Scopus_Alert.sh' ^^^" >&2

# The following work-around using script is necessary since the
# subscripts write stuff to /dev/tty. Script enables us to re-route
# the output to stderr
sh -c "script -eq -c './0_Scopus_Alert.sh' /dev/null" 1>&2

STATUS=$?

if [ $STATUS -ne 0 ]
then
  echo "^^^ Error: The subscripts returned $STATUS" >&2
  exit $STATUS
fi

echo "^^^ done ^^^" >&2

echo "^^^ Zipping up 'files_to_upload' subdirectory ^^^" >&2

zip -r "$1" files_to_upload 1>&2

STATUS=$?

if [ $STATUS -ne 0 ]
then
  echo "^^^ Error: Could not zip up 'files_to_upload'" >&2
  exit $STATUS
fi

echo "^^^ done ^^^" >&2

echo "^^^ Writing 'output.txt' to stdout ^^^" >&2

cat output.txt >&1

STATUS=$?

if [ $STATUS -ne 0 ]
then
  echo "^^^ Error: Could not print 'output.txt'" >&2
  exit $STATUS
fi

echo "^^^ done ^^^" >&2

echo "***** Wrapper script exits with status $STATUS *****" >&2

exit $STATUS
