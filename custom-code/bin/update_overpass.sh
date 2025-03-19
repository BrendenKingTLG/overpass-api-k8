#!/bin/bash

LATEST_SEQUENCE=$(curl -sL "${OVERPASS_DIFF_URL}/state.txt" | grep -m1 sequenceNumber | cut -d'=' -f2 | tr -d '[:space:]')
CURRENT_SEQUENCE=$(cat /app/db/replicate_id)

if [[ "$LATEST_SEQUENCE" -le "$CURRENT_SEQUENCE" ]]; then
    echo "No new osm updates available. Current: $CURRENT_SEQUENCE, Latest: $LATEST_SEQUENCE"
    exit 0
fi
rm /app/db/*shadow.lock

DIFF_FILE=/app/db/diffs/changes.osc

OVERPASS_META=${OVERPASS_META:-no}
OVERPASS_COMPRESSION=${OVERPASS_COMPRESSION:-gz}
OVERPASS_FLUSH_SIZE=${OVERPASS_FLUSH_SIZE:-16}

if [ -z "$OVERPASS_DIFF_URL" ]; then
	echo "No OVERPASS_DIFF_URL set. Skipping update."
	exit 0
fi

(
	set -e
	UPDATE_ARGS=("--flush-size=${OVERPASS_FLUSH_SIZE}")
	if [[ "${OVERPASS_META}" == "attic" ]]; then
		UPDATE_ARGS+=("--keep-attic")
	elif [[ "${OVERPASS_META}" == "yes" ]]; then
		UPDATE_ARGS+=("--meta")
	fi

	if [[ ! -d /app/db/diffs ]]; then
		mkdir /app/db/diffs
	fi

	if /app/bin/dispatcher --show-dir | grep -q File_Error; then
		UPDATE_ARGS+=("--db-dir=/app/db")
	fi

	while true; do
		# if DIFF_FILE doesn't exit, try fetch new data
		if [[ ! -e ${DIFF_FILE} ]]; then
			# if /app/db/replicate_id exists, do not pass $1 arg (which could contain -O arg pointing to planet file
			if [[ ! -f /app/db/replicate_id ]]; then
				cp -f /app/db/replicate_id /app/db/replicate_id.backup
				set +e
				/app/venv/bin/pyosmium-get-changes -vvv --server "${OVERPASS_DIFF_URL}" -o "${DIFF_FILE}" -f /app/db/replicate_id
				OSMIUM_STATUS=$?
				set -e
			else
				set +e
				/app/venv/bin/pyosmium-get-changes -vvv "$@" --server "${OVERPASS_DIFF_URL}" -o "${DIFF_FILE}" -f /app/db/replicate_id
				OSMIUM_STATUS=$?
				set -e
			fi
		else
			echo "${DIFF_FILE} exists. Trying to apply again."
		fi

		# if DIFF_FILE is non-empty, try to process it
		if [[ -s ${DIFF_FILE} ]]; then
			VERSION=$(osmium fileinfo -e -g data.timestamp.last "${DIFF_FILE}" || (cp -f /app/db/replicate_id.backup /db/diffs/changes.osc && echo "Broken file" && cat "${DIFF_FILE}" && rm -f "${DIFF_FILE}" && exit 1))
			if [[ -n "${VERSION// /}" ]]; then
				echo /app/bin/update_from_dir --osc-dir="$(dirname ${DIFF_FILE})" --version="${VERSION}" "${UPDATE_ARGS[@]}"
                /app/bin/update_from_dir --osc-dir="$(dirname ${DIFF_FILE})" --version="${VERSION}" "${UPDATE_ARGS[@]}" >> /app/db/apply_updates.log 2>&1
			else
				echo "Empty version, skipping file"
				cat "${DIFF_FILE}"
			fi
		fi

		# processed successfuly, remove
		rm "${DIFF_FILE}"

		if [[ "${OSMIUM_STATUS}" -eq 3 ]]; then
			echo "OSM Update finished with status code: ${OSMIUM_STATUS}"
			break
		else
			echo "There are still some OSM updates remaining"
			continue
		fi
		break
	done
) 2>&1 | tee -a /db/changes.log
