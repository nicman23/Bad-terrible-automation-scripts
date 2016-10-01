#! /usr/bin/bash

user='admin'
pass='1234'
ip='192.168.1.1'
port='80'
status='/status/status_deviceinfo.htm'

data() {
output="$(curl -q http://$user:$pass@$ip:$port$status 2> /dev/null)"
output="$(echo "$output" | sed -e 's/<[^>]*>//g' | sed -e 's/\&nbsp\;//g')"
output="$(echo "$output" | sed -e 's/db/ db/g')"
output="$(echo "$output" | grep -A 1000 'Status:')"
}

info () {
while true; do
  case $@ in
    ''              ) break ;;
    Status*         ) echo -e $1 '\t''\t''\t'$2 ; shift 2 ;;
    HwVer*          ) shift 3 ;;
    IP*             ) echo -e $1 $2 '\t''\t''\t'$3 ; shift 3 ;;
    Mode*           ) echo -e $1 '\t''\t''\t'$2 ; shift 2 ;;
    SNR*            ) echo -e $1 $2 '\t''\t''\t'$3 '\t'$4 '\t'$5 ; snrdown=$3 ; snrup=$4; shift 5 ;;
    Line*           ) echo -e $1 $2 '\t''\t'$3 '\t'$4 '\t'$5 ; shift 5 ;;
    Data*           ) echo -e $1 $2 '\t''\t''\t'$3 '\t'$4 '\t'$5 ; shift 5 ;;
    Status*         ) echo $1 $2 ; shift 2 ;;
    *               ) shift ;;
  esac
done
echo $snrdown $snrup $(date)>> /tmp/stats
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
echo -e Down:'\t'"$(cat /tmp/stats | awk '{print $1}' | awk_from_stack_ex)"
}

snr_statistics_up() {
echo -e Up:'\t'"$(cat /tmp/stats | awk '{print $2}' | awk_from_stack_ex)"
}

stich() {
  date
  echo -e '\n''\n'
  info $output
  echo -e '\n''\t'Data count '\t'Average '\t'Mean median '\t'Minimum datum '\t'Maximum datum
  statistics $old
  snr_statistics_up
  snr_statistics_down
}

rm /tmp/stats &> /dev/null

while true; do
  data
  dialog --no-collapse --infobox "$(stich)" 25 99
  sleep 1s
done
