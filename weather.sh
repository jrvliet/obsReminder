#!/usr/bin/env tclsh

package require tdom

# Provide the default zip codes of none specified
if {$argc == 0} { set argv {98121 98012} }

foreach location $argv {
    set xml [exec curl --silent http://www.google.com/ig/api?weather=$location]

    set doc [dom parse $xml]
    set root [$doc documentElement]

    #
    # Show Forecast Information
    #

    set inf [$doc getElementsByTagName forecast_information]
    set data ""
    append data "[[$inf selectNodes city] getAttribute data] "
    append data "[[$inf selectNodes postal_code] getAttribute data] "
    append data "[[$inf selectNodes current_date_time] getAttribute data] "
    puts "$data"


    #
    # Show Current Condition
    #
    set currentConditions [$doc getElementsByTagName current_conditions]

    set labels {
        condition      "Condition"
        temp_f         "Temperature (F)"
        humidity       "Humidity"
        wind_condition "Wind"
    }

    set longest 0
    foreach {tag labl} $labels {
        set length [string length $labl]
        if {$length > $longest} { set longest $length }
    }

    foreach {tag labl} $labels {
        set node [$currentConditions selectNodes $tag]
        set data [$node getAttribute data]
        regsub {[^:]*: *} $data "" data
        puts [format "  %-*s: %s" $longest $labl $data]
    }

    puts ""

    # Show Conditions for Next Days
    foreach cond [$doc getElementsByTagName forecast_conditions] {
        set data ""
        append data "[[$cond selectNodes day_of_week] getAttribute data] "
        append data "[[$cond selectNodes high] getAttribute data] "
        append data "[[$cond selectNodes low] getAttribute data] "
        append data "[[$cond selectNodes condition] getAttribute data] "
        puts "  $data"
    }
    puts ""
}
