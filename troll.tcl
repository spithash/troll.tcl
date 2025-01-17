#############################################################################################################
# Troll v2.5.1 TCL by spithash@Libera                                                                       #
#############################################################################################################
# Gets troll quotes and makes people suffer!                                                                #
#############################################################################################################
# Version 2.5   (19.11.2021)                                                                                #
#                                                                                                           #
# Changed url because the old one was dead and enabled tls.                                                 #
# tcl-tls is required to be installed on your server.                                                       #
#############################################################################################################
# Version 2.1   (20.03.2012)                                                                                #
#                                                                                                           #
# Added flood protection. More like, throttle control. Special thanks to username.                          #
#                                                                                                           #
# Any official release of troll.tcl will be announced in http://forum.egghelp.org/viewtopic.php?t=17078     #
# Official troll.tcl updates will be in this repo https://github.com/spithash/troll.tcl                     #
#############################################################################################################
# Version 2.0                                                                                               #
#                                                                                                           #
# Version 2.0 is way different since there's no database in the file. It fetches the quotes by a website.   #
# Also, you can ".chanset #channel +troll" to enable it.                                                    #
# I added this just in case you don't want your trolls to be available globally.                            #
#                                                                                                           #
# (Keep it to "puthelp" cause I didn't add any flood protection yet,                                        #
# and it may cause your bot "Excess Flood" quit if it's in "putserv" or "putquick",                         #
# if someone floods the !troll trigger or if the troll quote is too long.)                                  #
#############################################################################################################
# Credits: special thanks to: username, speechles and arfer who helped me with this :)                      #
#############################################################################################################

package require http
package require tls

# Channel flag.
setudef flag troll

# Set the time (in seconds) between commands.
set delay 10

bind pub - !troll parse

proc parse {nick uhost hand chan text} {
    global delay
    variable troll
    if {![channel get $chan troll]} {
        return 0
    }
    if {[info exists troll(lasttime,$chan)] && [expr $troll(lasttime,$chan) + $delay] > [clock seconds]} {
        putserv "NOTICE $nick :You can use only 1 command in $delay seconds. Wait [expr $delay - [expr [clock seconds] - $troll(lasttime,$chan)]] seconds and try again."
        return 0
    }
    http::register https 443 [list ::tls::socket -autoservername true]
    ::http::config -urlencoding utf-8 -useragent "Mozilla/5.0 (X11; U; Linux i686; el-GR; rv:1.8.1) Gecko/2010112223 Firefox/3.6.12"
    set url [::http::geturl "https://fnet.gr/nou/meow.php" -timeout 15000]
    set data [::http::data $url]
    ::http::cleanup $url

    regsub -all -- {\n} $data " " data
    if {[regexp -nocase -- {<p .*?>(.*?)</p>} $data -> info]} {
        regsub -all -- {(<strong[^>]*>)|(</strong>)} $info "\002" info

        while {$info != ""} {
            putserv "PRIVMSG $chan :[string range $info 0 419]"
            set info [string range $info 420 end]
        }
        set troll(lasttime,$chan) [clock seconds]
    } else {
        putserv "NOTICE $nick :Error: No matching data found."
        putlog "DEBUG: Data fetched: $data"
    }
}
putlog "\002troll.tcl\002 v2.5.1 by spithash@Libera iz up and trollin'"
# EOF
