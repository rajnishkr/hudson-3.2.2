#! /bin/bash

set -e

# Copy files from /usr/share/hudson/ref into /var/hudson_home
# So the initial hudson-HOME is set with expected content. 
# Don't override, as this is just a reference setup, and use from UI 
# can then change this, upgrade plugins, etc.
copy_reference_file() {
	f=${1%/} 
	echo "$f" >> $COPY_REFERENCE_FILE_LOG
    rel=${f:23}
    dir=$(dirname ${f})
    echo " $f -> $rel" >> $COPY_REFERENCE_FILE_LOG
	if [[ ! -e /var/hudson_home/${rel} ]] 
	then
		echo "copy $rel to hudson_home" >> $COPY_REFERENCE_FILE_LOG
		mkdir -p /var/hudson_home/${dir:23}
		cp -r /usr/share/huson/ref/${rel} /var/hudson_home/${rel};
		# pin plugins on initial copy
		[[ ${rel} == plugins/*.jpi ]] && touch /var/hudson_home/${rel}.pinned
	fi; 
}
export -f copy_reference_file
echo "--- Copying files at $(date)" >> $COPY_REFERENCE_FILE_LOG
find /usr/share/hudson/ref/ -type f -exec bash -c "copy_reference_file '{}'" \;

# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
   exec java $JAVA_OPTS -jar /usr/share/hudson/hudson.war $Hudson_OPTS "$@"
fi

# As argument is not jenkins, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"

