#!/usr/bin/awk -f
####################################################################
# LogDissector - a format-independent logfile analysis tool.
#
# Author:  Paul Reiber - paul at reiber dot org
# URL: http://reiber.org/Code/logDissector
####################################################################
# PLATFORMS:
#     should work on most Linux implementations - mawk compatible
#
# USAGE EXAMPLES:
#     awk -v skip="1,3,5" -v collect="2,4,6" -f logdissector.awk any.logfile
#     tail -1000000 /var/log/messages | awk -f logdissector.awk
#     awk -v ext=_syslog_`date +%j` -f logdissector.awk /var/log/syslog
#

# if you encounter problems it may be related to how your awk understands FS
# BEGIN { FS="\t\]\[| " } # fields are separated by space tab pipe open-bracket or close-bracket
BEGIN { print "FS=[" FS "]" } # fields are separated by space tab pipe open-bracket or close-bracket

# for every input line...
 { line=""; for( word=1; word<=NF; word=word+1){ # initialize line and loop over all fields setting "word" to the field number
                #print "in[" word "]=" $(word)
                if      ("," $(word) "," !~ /^,,$/)                     { words[$(word)]++; } # all non-null word gets counted
                if      (index("," skip    "," , "," word ",")>0)       { line=line " <skipped-field>" } # honor skip on commandline
                else if (index("," collect "," , "," word ",")>0)       { line=line " <collected-field>"; collection[$(word)]++ } # honor collect too
                else if ("," $(word) "," ~ /^,,$/)                      { line=line " <empty>" } # empty fields (happens because of our FS)
                else if ($(word) ~ /^[0-9]?[0-9]:[0-9][0-9](:[0-9][0-9])?$/)
                                                                        { line=line " <time>" } # time formats - NN:NN or NN:NN:NN
                else if ($(word) ~ /^([Jj]an(uary)?|[Ff]eb(ruary)?|[Mm]ar(ch)?|[Aa]pr(il)?|[Mm]ay|[Jj]un(e)?|[Jj]ul(y)?|[Aa]ug(ust)?|[Ss]ep(t|tember)?|[Oo]ct(ober)?|[Nn]ov(ember)?|[Dd]ec(ember)?)$/)
                                                                        { line=line " <month>" } # months and abbreviated months
                else if ($(word) ~ /^[0-9][0-9]\/([Jj]an(uary)?|[Ff]eb(ruary)?|[Mm]ar(ch)?|[Aa]pr(il)?|[Mm]ay|[Jj]un(e)?|[Jj]ul(y)?|[Aa]ug(ust)?|[Ss]ep(t|tember)?|[Oo]ct(ober)?|[Nn]ov(ember)?|[Dd]ec(ember)?)\/[0-9:]+$/)
                                                                        { line=line " <datetimestamp>";     dates[$(word)]++ } # date-and-time-stamps
                else if ($(word) ~ /^([Mm]on(day)?|[Tt]ue(s|sday)?|[Ww]ed(s|nesday)?|[Tt]hu(r|rs|rsday)?|[Ff]ri(day)?|[Ss]at(urday)?|[Ss]un(day)?)$/)
                                                                        { line=line " <weekday>" } # weekdays and abbreviated weekdays
                else if ($(word) ~ /^[+]?[0-9.,]+$/)                    { line=line " <number-or-ip>";      numbers[$(word)]++ } #numbers
                else if ($(word) ~ /^\([+]?[0-9.,]+$/)                  { line=line " (<number-or-ip>"; gsub("[^0-9.]","",$(word));  numbers[$(word)]++ } #numbers
                else if ($(word) ~ /^[+]?[0-9.,]+\)$/)                  { line=line " <number-or-ip>)"; gsub("[^0-9.]","",$(word));  numbers[$(word)]++ } #numbers
                else if ($(word) ~ /^HTTP\/.*$/)                        { line=line " " $(word); } #guard so this doesnt match paths
                else if ($(word) ~ /^\/?([^\/]+\/[^\/]+)*\/?$/)         { line=line " <path>";              paths[$(word)]++ } #paths
                else if ($(word) ~ /^\/[^\/]+(\/[^\/]+)*\/?$/)          { line=line " <path>";              paths[$(word)]++ } #paths
                else if ($(word) ~ /^[0-9\/]+(,)?$/)                    { line=line " <date-or-fraction>";  dates[$(word)]++ } #dates
                else if ($(word) ~ /^http(s)?:\/\//)                    { line=line " <url>";               urls[$(word)]++ } #urls
                else if ($(word) ~ /^.+\.[a-zA-Z][a-zA-Z][a-zA-Z]\.?$/) { line=line " <file-or-host-name>"; names[$(word)]++ } #names
                else if ($(word) ~ /^.*\[[0-9.]+\].*$/)                 { gsub("\[[0-9.]+\]", "[<n>]", $(word)); line=line " " $(word); arrays[$(word)]++ } #numericarrays
                else                                                    { line=line " " $(word) } # append unrecognized words to the pattern
        }
        patterns[line]++; printf("."); # bump the count of lines matching the pattern "line", and print a dot for a progress meter.
}

END {   # after all input lines have been handled...
        if ("," ext "," ~ /^,,$/) ext=".logdissector" # all of our results files will end in this extension
        print " done."; print "Parsed " NR " lines; please review the results in these files:"
        # people say associative arrays cant be sorted in awk - but they can if you pipe to a sort subprocess!
        for(j in patterns)   { print patterns[j],j   | "sort -rn > patterns" ext};   close("sort -rn > patterns" ext);
        for(j in collection) { print collection[j],j | "sort -rn > collected" ext};  close("sort -rn > collected" ext);
        for(j in numbers)    { print numbers[j],j    | "sort -rn > numbers" ext};    close("sort -rn > numbers" ext);
        for(j in dates)      { print dates[j],j      | "sort -rn > dates" ext};      close("sort -rn > dates" ext);
        for(j in names)      { print names[j],j      | "sort -rn > names" ext};      close("sort -rn > names" ext);
        for(j in paths)      { print paths[j],j      | "sort -rn > paths" ext};      close("sort -rn > paths" ext);
        for(j in urls)       { print urls[j],j       | "sort -rn > urls" ext};       close("sort -rn > urls" ext);
        for(j in words)      { print words[j],j      | "sort -rn > words" ext};      close("sort -rn > words" ext);
        for(j in arrays)     { print arrays[j],j     | "sort -rn > arrays" ext};     close("sort -rn > arrays" ext);
        system("ls -l *" ext);
}
