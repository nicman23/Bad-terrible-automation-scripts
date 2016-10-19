#! /usr/bin/bash

user='admin'
pass='admin'
cookie="Authorization=Basic $(echo $user:$pass| base64| sed -e "s/.$/=/g")"
ip='192.168.1.3'
infopage='statsadsl.html'

beep() {
  pacmd play-file /usr/share/sounds/freedesktop/stereo/complete.oga 1
}

data() {
  output="$(curl --cookie "$cookie" --referer http://$ip http://$ip/$infopage 2> /dev/null)"
  output="$(echo "$output" | sed -e 's/<[^>]*>/ /g')"
  output="$(echo "$output" | grep -A 2 'Mode.*')"
}

info () {
  while true; do
    case $@ in
      ''              ) break ;;
      'ATM Status:'*     ) Status=$3 ; shift 3 ;;
      'Mode:'*           ) Mode=$2 ; shift 2 ;;
      'Upstream Rate (Kbps):'*            ) Ratedown=$4 ; Rateup=$5; shift 5 ;;
      'SNR Margin (0.1 dB):'*           ) snrdown=$5 snrup=$6 ; shift 6 ;;
      *               ) shift ;;
    esac
  done

  sleep 1s
  ping=$(ping -w 1 -c 1 8.8.8.8 | grep ttl | awk '{print $7}' | sed -e 's/time=//g')

  if [ -z "$ping" ] ; then
    ping='Timeout' ; beep
  fi

  echo SNRdown: $snrdown SNRUp: $snrup Ping: $ping Date: $(date)>> /tmp/stats
}

awk_from_stack_ex() {
    sort -n | awk '
    BEGIN {
      c = 0;
      sum = 0;
    }
    $1 ~ /^[0-9]*(\.[0-9]*)?$/ {
      a[c++] = $1;
      sum += $1;
    }
    END {
      ave = sum / c;
      if( (c % 2) == 1 ) {
        median = a[ int(c/2) ];
      } else {
        median = ( a[c/2] + a[c/2-1] ) / 2;
      }
      OFS="\t\t";
      print c, ave, median, a[0],  a[c-1];
    }
  '
}

snr_statistics_down() {
echo -e Down:'\t'"$(cat /tmp/stats | awk '{print $2}' | awk_from_stack_ex)"
}

snr_statistics_up() {
echo -e Up:'\t'"$(cat /tmp/stats | awk '{print $4}' | awk_from_stack_ex)"
}

stich() {
  date
  info $output
  echo -e '\n'
  echo Status: $Status
  echo Mode: $Mode
  echo -e '\n''\t''\t''\t''\t'Down'\t'Up
  echo -e 'Data Rate (Kbps):''\t''\t'$Ratedown'\t'$Rateup
  echo -e 'SNR Margin (0.1db):''\t''\t'$snrdown'\t'$snrup
  echo -e '\n''\t'Data count '\t'Average '\t'Mean median '\t'Minimum datum '\t'Maximum datum
  statistics $old
  snr_statistics_up
  snr_statistics_down
}

rm /tmp/stats &> /dev/null

while true; do
  data
  dialog --no-collapse --infobox "$(stich)" 25 99
done
