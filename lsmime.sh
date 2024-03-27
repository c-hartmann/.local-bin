#!/bin/sh

# my personal all mime type getter

for f in "$@"; do

	echo `file --mime-type  "$f"` '(file)'

	echo `mimetype --all --separator=: --magic-only "$f" 2>/dev/null` '(mimetype)'

	echo "$f:" `xdg-mime query 'filetype'  "$f"` '(xdg-mime)'

done
