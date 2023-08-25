################################################################################
# Template functions for html generation
################################################################################

# constants
WEBSITE_NAME="Syscalls"
WEBSITE_AUTHOR="Yoann Foreau"
LICENSE='GNU General Public License v3'
LICENSE_URL='https://www.gnu.org/licenses/gpl-3.0.html#license-text'
START_YEAR='2023'
CURRENT_YEAR="$(date +%Y)"

# copyright years
copyright_years() {
	if [ "${START_YEAR}" = "${CURRENT_YEAR}" ]; then
		echo "${START_YEAR}"
	else
		echo "${START_YEAR}-${CURRENT_YEAR}"
	fi
}

# print head of file
print_head() {
	local PAGE_TITLE="${1}"
	local STYLE_PATH="${2}"
	local INCLUDE_ARCH_CSS="${3}"

    cat <<EOF
<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8">
		<meta name="author" content="${WEBSITE_AUTHOR}">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<title>${WEBSITE_NAME} - ${PAGE_TITLE}</title>
EOF
	if [ -n "${INCLUDE_ARCH_CSS}" ]; then
		cat <<EOF
		<link rel="stylesheet" href="${STYLE_PATH}/arch.css">
EOF
	fi

	cat <<EOF
		<link rel="stylesheet" href="${STYLE_PATH}/global.css">
	</head>
	<body>
		<header>
			<p>
				<a id="app-name" href="/">${WEBSITE_NAME}</a>
				- ${PAGE_TITLE}
			</p>
			<p>Last update: $(date -R)</p>
		</header>
EOF
}

# print tail of file
print_tail() {
    cat <<EOF
		<footer>
			<p class="footer-text">
				©
				<span id="years">$(copyright_years)</span>
				<span id="author">${WEBSITE_AUTHOR}</span>
				--
				<a id="license" href="${LICENSE_URL}">${LICENSE}</a>
			</p>
		</footer>
	</body>
</html>
EOF
}
