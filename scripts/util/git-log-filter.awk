#!/bin/awk -f
BEGIN{ FS="|"; }
{
    # commit hash - hyperlink to meld directly
    printf "\x1b]8;;gc://%s+%s++\x07%s\x1b]8;;\x07", path, $1, $1;

    # commit hash - hyperlink to expand
    printf "\x1b]8;;gct://%s+%s++yes\x07%s\x1b]8;;\x07", path, $1, " + ";

    # author and date
    printf "%-20s %s", $2, $3;

    # subject - hyperlink to AMD swdev database
    # extract SWDEV id
    match($4, "SWDEV-[0-9]+");
    if (RLENGTH > 0) {
        addr=substr($4,RSTART,RLENGTH);
        printf " \x1b]8;;https://ontrack-internal.amd.com/browse/%s\x07%s\x1b]8;;\x07\n", addr, $4;
    }
    else
        printf " %s\n", $4
}
