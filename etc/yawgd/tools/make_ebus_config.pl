#!/usr/bin/perl
#perl /root/make_ebus_config.pl -i /root/ebus2/ebusd/vaillant.csv -o /tmp/test2.csv
# makes config from ebusd cvs-files
#
# Originally developed by M.Hirsch, 2013
# Modified by john30, 2015
# Modified by XueSheng-GIT, 2023

use warnings;
use strict;
use Getopt::Std;

my $help =
"Please specify paths for config files!\n".
" -i select ebusd-configfile (input)\n".
" -o select plugin output-file (output)\n".
"\n".
"The input file can be created by calling ebusd with the --dumpconfig argument, e.g.\n".
"  'ebusd --dumpconfig --logareas='\n".
"\n".
"You can also query a running ebusd for all message configurations like this:\n".
"  'ebusctl find -f'\n".
"or without ebusctl:\n".
"  'echo find -f|nc localhost 8888'\n";

getopts('o:i:h:', \my %opts) or die $help;
if ($opts{h}) {print $help; exit;}
($opts{i} and $opts{o}) or die $help;
my $config = $opts{i};
print "Input: $config\n";
my $final_cfg = $opts{o};
print "Output $final_cfg\n";

### READ CONFIG
my @cmds;
open (GETCFG,"<$config") || die $!;
while (<GETCFG>){
  if ($_ =~ /^\#/) {
    #if ($debug){plugin_log($plugname,"skipped line");}
  } else {
    #if ($debug){plugin_log($plugname,"line $_");}
    chomp $_;
    $_ =~ s/;/#/g;
    
    # split by separator ',' but respect existing quotes
    # ref: https://stackoverflow.com/a/3068793
    my @array;
    my $sep = ',';
    my $re = qr/(?:^|$sep)(?:"([^"]*)"|([^$sep]*))/;
    while($_ =~ /$re/g) {
      my $value = defined $1 ? $1 : $2;
      push @array, (defined $value ? $value : '');
    }

    my $type = $array[0];
    my $class = $array[1];
    my $name = $array[2];
    my $comment = $array[3];
    $comment =~ s/#/,/g;
    my $elements = (@array - 8) / 6;
    $elements = 1 if ($elements == 0);
    my $prefix = $class." ".$name;
    my $cmd;
    my $comm;
    my $pos = 8;
    my $cnt = 0;
    my %cnts;
    my %ccnts;
    for (my $i=0; $i < $elements; $i++, $pos+=6) {
      next if ($array[$pos+2] and substr($array[$pos+2], 0, 3) =~ m/IGN/);
      $cnt++;
      next if (not defined $array[$pos]);
      if ($cnts{$array[$pos]}) {
        $cnts{$array[$pos]}++;
      } else {
        $cnts{$array[$pos]} = 1;
      }
      $ccnts{$array[$pos]} = 0;
    }
    $pos = 8;
    for (my $i=0, my $j=0; $i < $elements and $j < $cnt; $i++, $pos+=6) {
      next if ($array[$pos+2] and substr($array[$pos+2], 0, 3) =~ m/IGN/);
      if ($cnt>1 and $array[$pos]) {
        $cmd = $prefix." ".$array[$pos];
        if ($cnts{$array[$pos]} > 1) {
          $cmd .= ".".$ccnts{$array[$pos]}++;
        }
      } elsif ($cnt>1) {
        next;
      } else {
        $cmd = $prefix;
      }
      if ($array[$pos+5]) {
        $comm = $array[$pos+5];
        $comm =~ s/#/,/g;
        if (length $comment) {
          $comm = $comment.". ".$comm;
        }
      } else {
        $comm = $comment;
      }
      #print $type." ".$cmd." ".$comment."\n";
      push @cmds,{type => $type, cmd => $cmd, comment => $comm};
      $j++;
    }
  }
}
close GETCFG;

open (WRITECFG,'>',$final_cfg) || die "Can not open file $final_cfg: $!";;
print
"\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#
\#\#\# I N F O \#\#\#
\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\n";
print "All commands are disabled through \"\#\" by default\n";

print "\#GA;DPT;RRD_TYPE;RRD_STEP;TYPE;CMD;COMMENT\n";
print WRITECFG "\#GA;DPT;RRD_TYPE;RRD_STEP;TYPE;CMD;COMMENT\n";
foreach my $cmd (@cmds){
  print WRITECFG "\#;;;;$cmd->{type};$cmd->{cmd};$cmd->{comment} \n";
  print "\#;;;;$cmd->{type};$cmd->{cmd};$cmd->{comment} \n";
}
close WRITECFG;
