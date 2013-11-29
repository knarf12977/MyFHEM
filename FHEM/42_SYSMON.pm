
# $Id: $

package main;

use strict;
use warnings;
#use Data::Dumper;

my $VERSION = "0.9";

sub
SYSMON_Initialize($)
{
  my ($hash) = @_;
  
  Log 5, "SYSMON Initialize: ".$hash->{NAME};

  $hash->{DefFn}    = "SYSMON_Define";
  $hash->{UndefFn}  = "SYSMON_Undefine";
  $hash->{GetFn}    = "SYSMON_Get";
  $hash->{SetFn}    = "SYSMON_Set";
  $hash->{AttrFn}   = "SYSMON_Attr";
  $hash->{AttrList} = "filesystems disable:0,1 ".
                       $readingFnAttributes;
}

#####################################


sub
SYSMON_Define($$)
{
  my ($hash, $def) = @_;
  
  logF($hash, "Define", "$def");
  #Log 5, "SYSMON Define: ".$hash->{NAME};

  my @a = split("[ \t][ \t]*", $def);

  return "Usage: define <name> SYSMON [interval]"  if(@a < 2);

  #my $interval = 60;
  #if(int(@a)>=3) { $interval = $a[2]; }
  if(int(@a)>=3) 
  { 
  	SYSMON_setInterval($hash, $a[2]);
  } else {
    SYSMON_setInterval($hash, undef);
  }
  #if( $interval < 60 ) { $interval = 60; }

  #delete( $hash->{INTERVAL_FS} );
  
  $hash->{STATE} = "Initialized";
  #$hash->{INTERVAL} = $interval;

  #$starttime = time() unless defined($starttime);
  $hash->{DEF_TIME} = time() unless defined($hash->{DEF_TIME});

  RemoveInternalTimer($hash);
  InternalTimer(gettimeofday()+$hash->{INTERVAL}, "SYSMON_Update", $hash, 0);

  #$hash->{LOCAL} = 1;
  #SYSMON_Update($hash); #-> so nicht. hat im Startvorgang gelegentlich (oft) den Server 'aufgeh�ngt'
  #delete $hash->{LOCAL};  
  
  return undef;
}

sub
SYSMON_setInterval($$)
{
	my ($hash, $def) = @_;
	
	my $interval = 60;
  if(defined($def)) {$interval = $def;}
  if($interval < 60) {$interval = 60;}

  $hash->{INTERVAL} = $interval;
}

sub
SYSMON_Undefine($$)
{
  my ($hash, $arg) = @_;
  
  logF($hash, "Undefine", "");
  #Log 5, "SYSMON Undefine: ".$hash->{NAME};

  RemoveInternalTimer($hash);
  return undef;
}

sub
SYSMON_Get($@)
{
  my ($hash, @a) = @_;

  my $name = $a[0];
  
  if(@a < 2) 
  {
  	logF($hash, "Get", "@a: get needs at least one parameter");
  	#Log 5, "SYSMON (".$hash->{NAME}.") Get $name : get needs at least one parameter";
    return "$name: get needs at least one parameter";
  }
  
  my $cmd= $a[1];
  
  logF($hash, "Get", "@a");
  #Log 5, "SYSMON (".$hash->{NAME}.") Get $name $cmd";

  if($cmd eq "update")
  {
  	#$hash->{LOCAL} = 1;
  	SYSMON_Update($hash);
  	#delete $hash->{LOCAL};
  	return undef;
  }
  
  if($cmd eq "list") {
    my $map = SYSMON_obtainParameters($hash);
    my $ret = "";
    foreach my $name (keys %{$map}) {
  	  my $value = $map->{$name};
  	  $ret = "$ret\n".sprintf("%-20s %s", $name, $value);
    }
    return $ret;
  }
  
  if($cmd eq "version")
  {
  	return $VERSION;
  }

  if($cmd eq "interval")
  {
  	return $hash->{INTERVAL};
  }
  
  return "Unknown argument $cmd, choose one of list:noArg update:noArg interval:noArg version:noArg";
}

sub
SYSMON_Set($@)
{
  my ($hash, @a) = @_;

  my $name = $a[0];
  
  if(@a < 2) 
  {
  	logF($hash, "Set", "@a: set needs at least one parameter");
  	#Log 5, "SYSMON (".$hash->{NAME}.") Set $name : set needs at least one parameter";
    return "$name: set needs at least one parameter";
  }
  
  my $cmd= $a[1];
  
  logF($hash, "Set", "@a");
  #Log 5, "SYSMON (".$hash->{NAME}.") Set $name $cmd";

  if($cmd eq "interval")
  {
  	if(@a < 3) {
  		logF($hash, "Set", "$name: not enought parameters");
      return "$name: not enought parameters";
  	} 
  	#my $val= $a[2];
  	SYSMON_setInterval($hash, $a[2]);
  	#$hash->{INTERVAL} = $val;
  	return $cmd ." set to ".($hash->{INTERVAL});
  }

  return "Unknown argument $cmd, choose one of interval";
}

sub
SYSMON_Attr($$$)
{
  my ($cmd, $name, $attrName, $attrVal) = @_;
  
  Log 5, "SYSMON Attr: $cmd $name $attrName $attrVal";

  $attrVal= "" unless defined($attrVal);
  #my $orig = $attrVal;
  my $orig = AttrVal($name, $attrName, "");

  if( $cmd eq "set" ) {# set, del
    if( $orig ne $attrVal ) {
    	
    	if($attrName eq "disable")
      {
        my $hash = $main::defs{$name};
        RemoveInternalTimer($hash);
      	if($attrVal ne "0")
      	{
      		InternalTimer(gettimeofday()+$hash->{INTERVAL}, "SYSMON_Update", $hash, 0);
      	}
       	#$hash->{LOCAL} = 1;
  	    SYSMON_Update($hash);
  	    #delete $hash->{LOCAL};
      }
    	
      $attr{$name}{$attrName} = $attrVal;
      #return $attrName ." set to ". $attrVal;
      return undef;
    }
  }
  return;
}

sub
SYSMON_Update($)
{
  my ($hash) = @_;
  
  logF($hash, "Update", "");
  #Log 5, "SYSMON Update: ".$hash->{NAME};
  
  my $name = $hash->{NAME};

  if(!$hash->{LOCAL}) {
    RemoveInternalTimer($hash);
    InternalTimer(gettimeofday()+$hash->{INTERVAL}, "SYSMON_Update", $hash, 1);
  }

  readingsBeginUpdate($hash);

  if( AttrVal($name, "disable", "") eq "1" ) 
  {
  	logF($hash, "Update", "disabled");
  	$hash->{STATE} = "Inactive";
  } else {
  
    my $map = SYSMON_obtainParameters($hash);
 
    #foreach my $aName (keys %{$defs{$name}{READINGS}}) {
    #	if(index($aName, "fs[") == 0) {
    #		delete $defs{$name}{READINGS}{$aName};
		#  }
    #}
 
    # Kopie der Readings
    #my %copy = %{$defs{$name}{READINGS}}; #$defs{$name}{READINGS};
    
    my @cKeys=keys (%{$defs{$name}{READINGS}});
 
 
    $hash->{STATE} = "Active";
    #my $state = $map->{"loadavg"};
    #readingsBulkUpdate($hash,"state",$state);
  
    foreach my $aName (keys %{$map}) {
  	  my $value = $map->{$aName};
  	  #Log 3, "SYSMON DEBUG: ---> ".$aName."=".$value;
  	  readingsBulkUpdate($hash,$aName,$value);
  	  
  	  # Vorhandene Keys l�schen
  	  #delete %copy->{$aName};
  	  my $i=0;
  	  foreach my $bName (@cKeys) {
  	  	if($bName eq $aName) {
  	  		#Log 3, "SYSMON DEBUG: copy keys ---> ".$bName." / ".$aName;
  	      delete $cKeys[$i];
  	      last;
  	    }
  	    $i=$i+1;
  	  }
    }
    
    # Ueberfluessige Readings l�schen
    #foreach my $aName (keys %copy) {
    foreach my $aName (@cKeys) {
      delete $defs{$name}{READINGS}{$aName};
      #Log 3, "SYSMON DEBUG: delete obsolete READING---> ".$aName;
    }
  }

  readingsEndUpdate($hash,defined($hash->{LOCAL} ? 0 : 1));
}


sub
SYSMON_obtainParameters($)
{
	my ($hash) = @_;
	my $name = $hash->{NAME};
	
	my $map;
  
  $map = SYSMON_getUptime($hash, $map);
  $map = SYSMON_getFHEMUptime($hash, $map);
  $map = SYSMON_getLoadAvg($hash, $map);
  $map = SYSMON_getRamAndSwap($hash, $map);
  $map = SYSMON_getCPUTemp($hash, $map);
  $map = SYSMON_getCPUFreq($hash, $map);
  
  my $filesystems = AttrVal($name, "filesystems", undef);
  if(defined $filesystems) 
  {
    my @filesystem_list = split(/,\s*/, trim($filesystems));
    foreach (@filesystem_list)
    {
    	$map = SYSMON_getFileSystemInfo($hash, $map, "$_");
    }
  } else {
    $map = SYSMON_getFileSystemInfo($hash, $map, "/dev/root");
  }
  
  $map = SYSMON_getNetworkInfo($hash, $map, "eth0");
  $map = SYSMON_getNetworkInfo($hash, $map, "wlan0");
  
  return $map;
}

sub
SYSMON_getUptime($$)
{
	my ($hash, $map) = @_;
	
	my $uptime_str = qx(cat /proc/uptime );
  my ($uptime, $idle) = split(/\s+/, trim($uptime_str));
  my $idle_percent = $idle/$uptime*100;  
	
	$map->{"uptime"}=sprintf("%d",$uptime);
	#$map->{"uptime_text"} = sprintf("%d days, %02d hours, %02d minutes, %02d seconds",SYSMON_decode_time_diff($uptime));
	$map->{"uptime_text"} = sprintf("%d days, %02d hours, %02d minutes",SYSMON_decode_time_diff($uptime));
	
  #$map->{"idletime"}=sprintf("%d",$idle);
  $map->{"idletime"}=sprintf("%d %.2f %",$idle, $idle_percent);
	#$map->{"idletime_text"} = sprintf("%d days, %02d hours, %02d minutes, %02d seconds",SYSMON_decode_time_diff($idle));
	$map->{"idletime_text"} = sprintf("%d days, %02d hours, %02d minutes",SYSMON_decode_time_diff($idle)).sprintf(" (%.2f %)",$idle_percent);

	#$map->{"idletime_percent"} = sprintf ("%.2f %",$idle_percent);
	
	return $map; 
}

sub
SYSMON_getFHEMUptime($$)
{
	my ($hash, $map) = @_;
	
	if(defined ($hash->{DEF_TIME})) {
	  my $fhemuptime = time()-$hash->{DEF_TIME};
	  $map->{"fhemuptime"} = sprintf("%d",$fhemuptime);
	  $map->{"fhemuptime_text"} = sprintf("%d days, %02d hours, %02d minutes",SYSMON_decode_time_diff($fhemuptime));
  }

	return $map;
}

sub
SYSMON_getLoadAvg($$)
{
	my ($hash, $map) = @_;
	
	my $la_str = qx(cat /proc/loadavg );
  my ($la1, $la5, $la15, $prc, $lastpid) = split(/\s+/, trim($la_str));
	
	$map->{"loadavg"}="$la1 $la5 $la15";
  #$map->{"load"}="$la1";
	#$map->{"load5"}="$la5";
	#$map->{"load15"}="$la15";
	
	return $map; 
}

#------------------------------------------------------------------------------
# leifert Raspberry Pi CPU Temperature
#------------------------------------------------------------------------------
sub
SYSMON_getCPUTemp($$)
{
	my ($hash, $map) = @_;
	
	my $val = qx( cat /sys/class/thermal/thermal_zone0/temp );
  my $val_txt = sprintf("%.2f", $val/1000);
  $map->{"cpu_temp"}="$val_txt";
  my $t_avg = sprintf( "%.1f", (3 * ReadingsVal($hash->{NAME},"cpu_temp_avg",$val_txt) + $val_txt ) / 4 );
  $map->{"cpu_temp_avg"}="$t_avg";
	
	return $map; 
}

sub
SYSMON_getCPUFreq($$)
{
	my ($hash, $map) = @_;
	
	my $val = qx( cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq );
  my $val_txt = sprintf("%d", $val/1000);
  $map->{"cpu_freq"}="$val_txt";
	
	return $map; 
}

#------------------------------------------------------------------------------
# Liefert Werte fuer RAM und SWAP (Gesamt, Verwendet, Frei).
#------------------------------------------------------------------------------
sub SYSMON_getRamAndSwap($$)
{
  my ($hash, $map) = @_;
  
  my @speicher = qx(free -m);
  
  shift @speicher;
  my ($fs_desc, $total, $used, $free, $shared, $buffers, $cached) = split(/\s+/, trim($speicher[0]));
  shift @speicher;
  my ($fs_desc2, $total2, $used2, $free2, $shared2, $buffers2, $cached2) = split(/\s+/, trim($speicher[0]));
  
  if($fs_desc2 ne "Swap:")
  {
    shift @speicher;
    ($fs_desc2, $total2, $used2, $free2, $shared2, $buffers2, $cached2) = split(/\s+/, trim($speicher[0]));
  }
  
  my $ram;
  my $swap;
  my $percentage_ram;
  my $percentage_swap;
  
  $percentage_ram = sprintf ("%.2f", (($used - $buffers - $cached) / $total * 100), 0);
  $ram = "Total: ".$total." MB, Used: ".($used - $buffers - $cached)." MB, ".$percentage_ram." %, Free: ".($free + $buffers + $cached)." MB";
  
  $map->{"ram"} = $ram;
  
  # if no swap present, total2 is zero -> prevent division by zero
  if($total2 > 0)
  {
    $percentage_swap = sprintf ("%.2f", ($used2 / $total2 * 100));
    $swap = "Total: ".$total2." MB, Used: ".$used2." MB,  ".$percentage_swap." %, Free: ".$free2." MB";
  }
  else
  {
    $swap = "n/a"
  }
  
  $map->{"swap"} = $swap;

  return $map; 
}

#------------------------------------------------------------------------------
# Liefert Fuellstand fuer das angegebene Dateisystem (z.B. '/dev/root', '/dev/sda1' (USB stick)).
# Eingabeparameter: HASH; MAP; FS-Bezeichnung
#------------------------------------------------------------------------------
sub SYSMON_getFileSystemInfo ($$$)
{
	my ($hash, $map, $fs) = @_;
  
  # my @filesystems = qx(df /dev/root);
  my $disk = "df ".$fs." -m 2>&1"; # in case of failure get string from stderr

  my @filesystems = qx($disk);

  # if filesystem is not present, output goes to stderr, i.e. @filesystems is empty
  shift @filesystems;
  #Log 3, "SYSMON DEBUG: ---> filesystems:=".$filesystems[0];
  if (index($filesystems[0], $fs) >= 0) # check if filesystem available -> gives failure on console
  {
    my ($fs_desc, $total, $used, $available, $percentage_used, $mnt_point) = split(/\s+/, $filesystems[0]);
    $percentage_used =~ /^(.+)%$/;
    $percentage_used = $1;
    #my $out_txt = $fs_desc." at ".$mnt_point." => Total: ".$total." MB, Used: ".$used." MB (".$percentage_used."), Available: ".$available." MB";
    my $out_txt = "Total: ".$total." MB, Used: ".$used." MB, ".$percentage_used." %, Available: ".$available." MB";
    #$map->{"fs[$mnt_point]"} = $out_txt; 
    #$map->{"fs:[$mnt_point]"} = $out_txt; 
    $map->{"~ $mnt_point"} = $out_txt; 
    
  } else {
  	#$map->{"fs[$fs]"} = "not available"; 
  	$map->{"~ $fs"} = "not available"; 
  }

  return $map;
}

#------------------------------------------------------------------------------
# Liefert Netztwerkinformationen
# Parameter: HASH; MAP; DEVICE (eth0 or wlan0)
#------------------------------------------------------------------------------
sub SYSMON_getNetworkInfo ($$$)
{
	my ($hash, $map, $device) = @_;
  
  # in case of network not present get failure from stderr (2>&1)  
  my $cmd="ifconfig ".$device." 2>&1";

  my @dataThroughput = qx($cmd);
  
  #Log 3, "SYSMON DEBUG: ---> network: cmd:".$cmd." : ".@dataThroughput[0]." :- ".grep(/error/, @dataThroughput[0]);
  
  # check if network available
  if (not grep(/Fehler/, @dataThroughput[0]) && not grep(/error/, @dataThroughput[0]))
  {
    # perform grep from above
    @dataThroughput = grep(/RX bytes/, @dataThroughput); # reduce more than one line to only one line

    # change array into scalar variable
    my $dataThroughput = $dataThroughput[0];

    # remove RX bytes or TX bytes from string
    $dataThroughput =~ s/RX bytes://;
    $dataThroughput =~ s/TX bytes://;
    $dataThroughput = trim($dataThroughput);

    @dataThroughput = split(/ /, $dataThroughput); # return of split is array

    my $rxRaw = $dataThroughput[0] / 1024 / 1024;
    my $txRaw = $dataThroughput[4] / 1024 / 1024;
    my $rx = sprintf ("%.2f", $rxRaw);
    my $tx = sprintf ("%.2f", $txRaw);
    my $totalRxTx = $rx + $tx;

    my $out_txt = "RX: ".$rx." MB, TX: ".$tx." MB, Total: ".$totalRxTx." MB";
    $map->{$device} = $out_txt; 
    
    my $lastVal = ReadingsVal($hash->{NAME},$device,"RX: 0 MB, TX: 0 MB, Total: 0 MB");
    my ($d0, $o_rx, $d1, $d2, $o_tx, $d3, $d4, $o_tt, $d5) = split(/\s+/, trim($lastVal));
    
    my $d_rx = $rx-$o_rx;
    if($d_rx<0) {$d_rx=0;}
    my $d_tx = $tx-$o_tx;
    if($d_tx<0) {$d_tx=0;}
    my $d_tt = $totalRxTx-$o_tt;
    if($d_tt<0) {$d_tt=0;}
    my $out_txt_diff = "RX: ".sprintf ("%.2f", $d_rx)." MB, TX: ".sprintf ("%.2f", $d_tx)." MB, Total: ".sprintf ("%.2f", $d_tt)." MB";
    
    #my $out_txt_diff = "---";
    #$out_txt_diff = "RX: ".sprintf ("%.2f", ($rx-$o_rx))." MB, TX: ".sprintf ("%.2f", ($tx-$o_tx))." MB, Total: ".sprintf ("%.2f", ($totalRxTx-$o_tt))." MB";
    $map->{$device."_diff"} = $out_txt_diff; 
  } else {
  	$map->{$device} = "not available"; 
  	$map->{$device."_diff"} = "not available"; 
  }

  return $map;
}

#------------------------------------------------------------------------------
# Systemparameter als HTML-Tabelle ausgeben
# Parameter: Name des SYSMON-Ger�tes (muss existieren), dessen Daten zur Anzeige gebracht werden sollen.
#------------------------------------------------------------------------------
sub SYSMON_ShowValuesHTML ($)
{
	my ($name) = @_;
	my $hash = $main::defs{$name};
	
	# Array mit anzuzeigenden Parametern (Prefix, Name (in Map), Postfix)
	my @dataDescription =
  (
    ["Date", undef, ""],
    ["CPU temperature", "cpu_temp", " &deg;C"],
    ["CPU frequency", "cpu_freq", " MHz"],
    ["System up time", "uptime_text", ""],
    ["FHEM up time", "fhemuptime_text", ""],
    ["Load average", "loadavg", ""], 
    ["RAM", "ram", ""], 
    ["Swap", "swap", ""],
    #["File system", ?, ""],
    #["USB stick", ?, ""],
    ["Ethernet", "eth0", ""],
    ["WLAN", "wlan0", ""],
  );

  my $map = SYSMON_obtainParameters($hash);

  my $div_class="";

  my $htmlcode = "<div  class='".$div_class."'><table>";

  # Datum anzeigen
  $htmlcode .= "<tr><td valign='top'>Date:&nbsp;</td><td>".strftime("%d.%m.%Y %H:%M:%S", localtime())."</td></tr>";

  # oben definierte Werte anzeigen
  my $ref_zeile;
  foreach $ref_zeile (@dataDescription) {
    #foreach my $spalte (@$ref_zeile) { 
    #	print "$spalte " 
    #}
    my $tName = @$ref_zeile[1];
    if(defined $tName) {
      $htmlcode .= "<tr><td valign='top'>".@$ref_zeile[0].":&nbsp;</td><td>".$map->{$tName}.@$ref_zeile[2]."</td></tr>";
    }
  }
  
  # File systems
  foreach my $aName (sort keys %{$map}) {
  	#if(index($aName, "fs[") == 0) {
  	if(index($aName, "~ ") == 0) {
      #$aName =~ /fs\[(.+)\]/;
      $aName =~ /^~ (.+)/;
      #my $dName=$1;
  	  $htmlcode .= "<tr><td valign='top'>File System: ".$1."&nbsp;</td><td>".$map->{$aName}."</td></tr>";
    }
  }

  $htmlcode .= "</table></div><br>";

  return $htmlcode;
}

#------------------------------------------------------------------------------
# Uebersetzt Sekunden (Dauer) in Tage/Stunden/Minuten/Sekunden
#------------------------------------------------------------------------------
sub SYSMON_decode_time_diff($)
{
  my $s = shift;

  my $d = int($s/86400);
  $s -= $d*86400;
  my $h = int($s/3600);
  $s -= $h*3600;
  my $m = int($s/60);
  $s -= $m*60;

  return ($d,$h,$m,$s);
}
 
#
# Logging: FUnkrionsaufrufe
#   Parameter: HASH, Funktionsname, Message
#
sub logF($$$)
{
	my ($hash, $fname, $msg) = @_;
  #Log 5, "SYSMON $fname (".$hash->{NAME}."): $msg";
  Log 5, "SYSMON $fname $msg";
}


1;

=pod
=begin html



=end html
=begin html_DE

<a name="SYSMON"></a>
<h3>SYSMON</h3>
<ul>
  Dieses Modul liefert diverse Informationen und Statistiken zu dem System, auf dem FHEM-Server ausgef&uuml;hrt wird.
  Es werden ausschliessliche Linux-basierte Systemen unterst&uuml;tzt. Bis jetzt nur auf Raspberry Pi (Debian Wheezy) getestet.
  <br><br>
  <b>Define</b>
  <br><br>
    <code>define <name> SYSMON [&lt;interval&gt;]</code><br>
    <br>
    Diese Anweisung erstellt eine neue SYSMON-Instanz. Der Parameter &lt;interval&gt; legt den Aktualisierungsinterval fest.<br>
  <br>
  
  <b>Readings:</b>
  <br><br>
  <ul>
    <li>cpu_freq<br>
        CPU-Frequenz
    </li>
    <br>
    <li>cpu_temp<br>
        CPU-Temperatur
    </li>
    <br>
    <li>cpu_temp_avg<br>
        Durchschnitt der CPU-Temperatur, gebildet &uuml;ber die letzten 4 Werte.
    </li>
    <br>
    <li>eth0<br>
    		Menge der &Uuml;betragenen Daten &uuml;ber die Schnittstelle eth0.
    </li>
    <br>
    <li>eth0_diff<br>
    	 &Auml;nderung der &uuml;betragenen Datenmenge in Bezug auf den vorherigen Aufrung (f&uuml; eth0).
    </li>
    <br>
    <li>fhemuptime<br>
    		Zeit (in Sekunden) seit dem Start des FHEM-Servers.
    </li>
    <br>
    <li>fhemuptime_text<br>
    		Zeit seit dem Start des FHEM-Servers: Menschenlesbare Ausgabe (texttuelle Darstellung).
    </li>
    <br>
    <li>idletime<br>
    		Zeit (in Sekunden und in Prozent), die das System (nicht der FHEM-Server!) 
    		seit dem Start in dem Idle-Modus verbracht hat. Also die Zeit der Inaktivit&auml;t.
    </li>
    <br>
    <li>idletime_text<br>
    		Zeit der Inaktivit&auml;t des Systems seit dem Systemstart in menschenlesbarer Form.
    </li>
    <br>
    <li>loadavg<br>
        Ausgabe der Werte f&uuml;r die Systemauslastung (load average): 1 Minute-, 5 Minuten- und 15 Minuten-Werte.
    </li>
    <br>
    <li>ram<br>
       Ausgabe der Speicherauslastung.
    </li>
    <br>
    <li>swap<br>
    		Benutzung und Auslastung der SWAP-Datei (bzw. Partition).
    </li>
    <br>
    <li>uptime<br>
    		Zeit (in Sekenden) seit dem Systemstart.
    </li>
    <br>
    <li>uptime_text<br>
    		Zeit seit dem Systemstart in menschenlesbarer Form.
    </li>
    <br>
    <li>wlan0<br>
        Menge der &Uuml;betragenen Daten &uuml;ber die Schnittstelle wlan0.
    </li>
    <br>
    <li>wlan0_diff<br>
    		&Auml;nderung der &uuml;betragenen Datenmenge in Bezug auf den vorherigen Aufrung (f&uuml; wlan0).
    </li>
    <br>
    <li>Dateisysteminformationen (z.B. ~ /)<br>
    		Iformationen zu der Gr&ouml;&szlig;e und der Belegung der gew&uuml;nschten Dateisystemen.
    </li>
    <br>
  <br>
  </ul>
 
  Beispiel-Ausgabe:<br> 
  <ul>
 
<table style="border: 1px solid black;">
<tr><td style="border-bottom: 1px solid black;"><div class="dname">cpu_freq</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>900</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">cpu_temp</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>49.77</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">cpu_temp_avg</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>49.7</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">eth0</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>RX: 2954.22 MB, TX: 3469.21 MB, Total: 6423.43 MB</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">eth0_diff</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>RX: 6.50 MB, TX: 0.23 MB, Total: 6.73 MB</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">fhemuptime</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>11231</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">fhemuptime_text&nbsp;&nbsp;</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>0 days, 03 hours, 07 minutes</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">idletime</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>931024 88.35 %</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">idletime_text</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>10 days, 18 hours, 37 minutes (88.35 %)</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">loadavg</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>0.14 0.18 0.22</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">ram</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>Total: 485 MB, Used: 140 MB, 28.87 %, Free: 345 MB</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">swap</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>n/a</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">uptime</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>1053739</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">uptime_text</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>12 days, 04 hours, 42 minutes</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">wlan0</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>RX: 0.00 MB, TX: 0.00 MB, Total: 0 MB</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">wlan0_diff</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>RX: 0.00 MB, TX: 0.00 MB, Total: 0.00 MB</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">~ /</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>Total: 7404 MB, Used: 3533 MB, 50 %, Available: 3545 MB</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">~ /boot</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>Total: 56 MB, Used: 19 MB, 33 %, Available: 38 MB</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td><div class="dname">~ /media/usb1</div></td>
<td><div>Total: 30942 MB, Used: 6191 MB, 21 %, Available: 24752 MB&nbsp;&nbsp;</div></td>
<td><div>2013-11-27 00:05:36</div></td>
</tr>
</table>
  </ul><br>
  
  <b>Get:</b><br><br>
    <ul>
    <li>interval<br>
    Listet die bei der Definition angegebene Polling-Intervale auf.
    </li>
    <br>
    <li>list<br>
    Gibt alle Readings aus.
    </li>
    <br>
    <li>update<br>
    Aktualisiert alle Readings. Alle Werte werden neu abgefragt.
    </li>
    <br>
    <li>version<br>
    Zeigt die Version des SYSMON-Moduls.
    </li>
    <br>
    </ul><br>
    
  <b>Set:</b><br><br>
    <ul>
    <li>interval<br>
    Definiert Polling-Intervale (wie bei der Definition des Ger&auml;tes).
    </li>
    <br>
    </ul><br>
    
  <b>Attributes:</b><br><br>
    <ul>
    <li>filesystems<br>
    Gibt die zu &uuml;berwachende Dateisysteme an. Es wird eine kommaseparierte Liste erwartet.<br>
    Beispiel: <code>/boot, /, /media/usb1</code>
    </li>
    <br>
    <li>disable<br>
    M&ouml;gliche Werte: <code>0,1</code>. Bei <code>1</code> wird die Aktualisierung gestoppt.
    </li>
    <br>
    </ul><br>
  
  <b>Plots:</b><br><br>
    <ul>
    F&uuml;r dieses Modul sind bereits einige gplot-Dateien vordefiniert:<br>
     <ul>
      <code>
       mySMRAM.gplot<br>
       mySMCPUTemp.gplot<br>
       mySMFS_Root.gplot<br>
       mySMFS_usb1.gplot<br>
       mySMLoad.gplot<br>
       mySMNetworkEth0.gplot<br>
       mySMNetworkEth0t.gplot<br>
      </code>
     </ul>
    </ul><br>
    
  <b>HTML-Ausgabe-Methode (f&uuml;r ein Weblink): SYSMON_ShowValuesHTML</b><br><br>
    <ul>
    Das Modul definiert eine Funrktion, die ausgew&auml;hlte Readings in HTML-Format ausgibt. <br>
    Als Parameter wird der Name des definierten SYSMON-Ger&auml;ten erwartet.<br><br>
    <code>define SysValues weblink htmlCode {SYSMON_ShowValuesHTML('sysmon')}</code>
    </ul><br>
  
  <b>Beispiele:</b><br><br>
    <ul>
    <code>
      # Modul-Definition<br>
      define sysmon SYSMON 60<br>
      attr sysmon event-on-update-reading cpu_temp,cpu_temp_avg,cpu_freq,eth0_diff,loadavg,ram,^~ /.*usb.*,~ /$<br>
      attr sysmon filesystems /boot, /, /media/usb1<br>
      attr sysmon group RPi<br>
      attr sysmon room 9.03_Tech<br>
      <br>
      # Log<br>
      define FileLog_sysmon FileLog ./log/sysmon-%Y-%m.log sysmon<br>
      attr FileLog_sysmon group RPi<br>
      attr FileLog_sysmon logtype mySMCPUTemp:Plot,text<br>
      attr FileLog_sysmon room 9.03_Tech<br>
      <br>
      # Visualisierung: CPU-Temperatur<br>
      define wl_sysmon_temp SVG FileLog_sysmon:mySMCPUTemp:CURRENT<br>
      attr wl_sysmon_temp group RPi<br>
      attr wl_sysmon_temp label "CPU Temperatur: Min $data{min2}, Max $data{max2}, Last $data{currval2}"<br>
      attr wl_sysmon_temp room 9.03_Tech<br>
      <br>
      # Visualisierung: Netzwerk-Daten&uuml;bertragung f&uuml; eth0<br>
      define wl_sysmon_eth0 SVG FileLog_sysmon:mySMNetworkEth0:CURRENT<br>
      attr wl_sysmon_eth0 group RPi<br>
      attr wl_sysmon_eth0 label "Netzwerk-Traffic eth0: $data{min1}, Max: $data{max1}, Aktuell: $data{currval1}"<br>
      attr wl_sysmon_eth0 room 9.03_Tech<br>
      <br>
      # Visualisierung: CPU-Auslastung (load average)<br>
      define wl_sysmon_load SVG FileLog_sysmon:mySMLoad:CURRENT<br>
      attr wl_sysmon_load group RPi<br>
      attr wl_sysmon_load label "Load Min: $data{min1}, Max: $data{max1}, Aktuell: $data{currval1}"<br>
      attr wl_sysmon_load room 9.03_Tech<br>
      <br>
      # Visualisierung: RAM-Nutzung<br>
      define wl_sysmon_ram SVG FileLog_sysmon:mySMRAM:CURRENT<br>
      attr wl_sysmon_ram group RPi<br>
      attr wl_sysmon_ram label "RAM-Nutzung Total: $data{max1}, Min: $data{min2}, Max: $data{max2}, Aktuell: $data{currval2}"<br>
      attr wl_sysmon_ram room 9.03_Tech<br>
      <br>
      # Visualisierung: Dateisystem: Root-Partition<br>
      define wl_sysmon_fs_root SVG FileLog_sysmon:mySMFS_Root:CURRENT<br>
      attr wl_sysmon_fs_root group RPi<br>
      attr wl_sysmon_fs_root label "Root Partition Total: $data{max1}, Min: $data{min2}, Max: $data{max2}, Aktuell: $data{currval2}"<br>
      attr wl_sysmon_fs_root room 9.03_Tech<br>
      <br>
      # Visualisierung: Dateisystem: USB-Stick<br>
      define wl_sysmon_fs_usb1 SVG FileLog_sysmon:mySMFS_usb1:CURRENT<br>
      attr wl_sysmon_fs_usb1 group RPi<br>
      attr wl_sysmon_fs_usb1 label "USB1 Total: $data{max1}, Min: $data{min2}, Max: $data{max2}, Aktuell: $data{currval2}"<br>
      attr wl_sysmon_fs_usb1 room 9.03_Tech<br>
      <br>
      # Anzeige der Readings zum EInbinden in ein 'Raum'.<br>
      define SysValues weblink htmlCode {SYSMON_ShowValuesHTML('sysmon')}<br>
      attr SysValues group RPi<br>
      attr SysValues room 9.03_Tech<br>
    </code>
    </ul>
  
  </ul>
  
=end html_DE
=cut