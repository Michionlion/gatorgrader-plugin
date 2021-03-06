#!/bin/sh

# TODO: add error checking and error return

# colors for output
red="\033[1;31m"
grn="\033[1;32m"
yel="\033[0;33m"
cyn="\033[0;36m"
end="\033[0m"

# functions
require_clean_work_tree () {
    # Update the index
    git update-index -q --ignore-submodules --refresh
    err=0

    # check for unstaged changes in the working tree
    if ! git diff-files --quiet --ignore-submodules --
    then
        #shellcheck disable=SC2059
        printf >&2 "%b" "${red}Can't publish javadoc: you have unstaged changes:${yel}\n\n"
        git diff-files --name-status -r --ignore-submodules -- >&2
        err=1
    fi

    # check for uncommitted changes in the index
    if ! git diff-index --cached --quiet HEAD --ignore-submodules --
    then
        #shellcheck disable=SC2059
        printf >&2 "%b" "${red}Can't publish javadoc: your index contains uncommitted changes:${yel}\n\n"
        git diff-index --cached --name-status -r --ignore-submodules HEAD -- >&2
        err=1
    fi

    if [ $err = 1 ]
    then
        #shellcheck disable=SC2059
        printf >&2 "%b" "\n${grn} - - - - - - - - \n\n${cyn}Please commit or stash your local changes!${end}\n\n"
        exit 1
    fi
}


# constants

DOC_BADGE="docs/docs-status-badge.svg"
VERSION_DATA_FILE="_data/versions.csv"

PAGES_BRANCH="gh-pages"

# parse command args

# these are examples of what args there should be

DOC_FOLDER="docs/unknown"
DOC_STATUS="unknown"
DOC_VERSION="unknown"
BUILD_NUMBER="-1"
DOC_DATE="unknown"

DOC_FOLDER="$1"
DOC_STATUS="$2"
DOC_VERSION="$3"
BUILD_NUMBER="$4"
DOC_DATE="$5"


# while [ $# -gt 0 ]; do
#     arg="$1"
#     shift;
#     case $arg in
#         -f|--doc-folder )
#             DOC_FOLDER="$1"
#             shift;
#             ;;
#         -s|--status )
#             DOC_STATUS="$1"
#             shift;
#             ;;
#         -v|--version )
#             DOC_VERSION="$1"
#             shift;
#             ;;
#         -d|--date )
#             DOC_DATE="$1"
#             shift;
#             ;;
#         * )
#             #shellcheck disable=SC2059
#             printf "%b" "${red}Unrecognized argument ${arg}${end}\n"
#             exit 1;
#             ;;
#     esac
# done

# check for local changes and exit if there are any
require_clean_work_tree "publish javadoc"


echo "-----------------------------"
echo "DOC_FOLDER:   $DOC_FOLDER"
echo "DOC_STATUS:   $DOC_STATUS"
echo "DOC_VERSION:  $DOC_VERSION"
echo "BUILD_NUMBER: $BUILD_NUMBER"
echo "DOC_DATE:     $DOC_DATE"
echo "-----------------------------"


# save current branch
currentBranch=$(git rev-parse --abbrev-ref HEAD)

# switch to gh-pages branch
git checkout "$PAGES_BRANCH"

# update local copy of branch
git fetch --all
git pull origin "$PAGES_BRANCH"

# update data file
echo "\"$BUILD_NUMBER\",\"$DOC_VERSION\",\"$DOC_DATE\",\"$DOC_FOLDER\"" >> $VERSION_DATA_FILE

# update README.md
git checkout master README.md

# copy doc badge over
command cp "images/docs-$DOC_STATUS.svg" "$DOC_BADGE"

# add doc folder and badge
git add "$DOC_FOLDER" "$DOC_BADGE" "$VERSION_DATA_FILE" "README.md"
git commit -m "autopublish javadoc for version $DOC_VERSION - $BUILD_NUMBER: $DOC_STATUS"
git push origin "$PAGES_BRANCH"

# switch back to old branch
git checkout "$currentBranch"

#shellcheck disable=SC2059
printf "%b" "\n${grn} Finished publishing javadoc!${end}\n\n"

exit 0
