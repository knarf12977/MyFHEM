##############################################
# $Id$
package main;

use strict;
use warnings;
use POSIX;
use Time::Local;
use Time::HiRes qw(gettimeofday);

use myCtrlHAL;

my $mhash;
my $timerParam;

# Initialisierung
sub
myCtrlBase_Initialize($)
{
  my ($hash) = @_;
  $mhash = $hash;
  
  $hash->{UndefFn} = "myCtrlBase_Undef";

  my $next = int(gettimeofday()) +1; 
  # Parameter fuer die HauptZeitschleife
  $timerParam -> {'next'} = $next;
  # Parameter fuer Heartbeat-Methode
  $timerParam -> {'haertbeat_last'} = $next;
  $timerParam -> {'haertbeat_interval'} = 60;
  InternalTimer($next, 'myCtrlBase_ProcessTimer', $timerParam, 0);
  Log 2, "AutomationControlBase: initialized";
  return $hash;
}

# interne Verarbeitung der periodischen Aufrufen (Steuerung)
sub
myCtrlBase_ProcessTimer(@)
{
  my $param = shift;
  my $now = gettimeofday();
  
  if ($now > $timerParam -> {'haertbeat_last'} + $timerParam -> {'haertbeat_interval'}) {
    $timerParam -> {'haertbeat_last'} = $now;
    # Wichtig ist, dass die Heartbeat-Methode moeglichst schnell ist.
    myCtrlBase_automationHeartbeat();
  }
  
  # Geplante Funktionen pruefen/ausfrufen
  myCtrlBase_handleScheduledTasks();
  
  $param -> {'next'} = int($now) +1;
  InternalTimer($param -> {'next'}, 'myCtrlBase_ProcessTimer', $param, 0);
}

my %scheduledTasks;
my $nexttime;
my $schedcnt=0;

#####################################
# Return the time to the next event (or undef if there is none)
# and call each function which was scheduled for this time
sub
myCtrlBase_handleScheduledTasks() {
  return undef if(!$nexttime);

  my $now = gettimeofday();
  return ($nexttime-$now) if($now < $nexttime);

  $now += 0.01;# need to cover min delay at least
  $nexttime = 0;
  # Check the internal list: unnamed
  foreach my $i (sort { $scheduledTasks{unnamed}{$a}{TRIGGERTIME} <=>
                        $scheduledTasks{unnamed}{$b}{TRIGGERTIME} } keys %{$scheduledTasks{unnamed}}) {
    my $tim = $scheduledTasks{unnamed}{$i}{TRIGGERTIME};
    my $fn = $scheduledTasks{unnamed}{$i}{FN};
    my $arg = $scheduledTasks{unnamed}{$i}{ARG};
    if(!defined($tim) || !defined($fn)) {
      delete($scheduledTasks{unnamed}{$i});
      next;
    } elsif($tim <= $now) {
      no strict "refs";
      if(defined($arg)) {
        eval {
        	&{$fn}($arg);
        };
        #Log (3, "scheduled task ($i) error: $@") if $@;
      } else {
      	eval($fn);
      	#Log (3, "scheduled task ($i) error: $@") if $@;
      }
      Log (3, "scheduled task ($i) error: $@") if $@;
      use strict "refs";
      delete($scheduledTasks{unnamed}{$i});
    } else {
      $nexttime = $tim if(!$nexttime || $nexttime > $tim);
    }
  }
  
  # Check the internal list: named
  foreach my $i (sort { $scheduledTasks{named}{$a}{TRIGGERTIME} <=>
                        $scheduledTasks{named}{$b}{TRIGGERTIME} } keys %{$scheduledTasks{named}}) {
    my $tim = $scheduledTasks{named}{$i}{TRIGGERTIME};
    my $fn = $scheduledTasks{named}{$i}{FN};
    my $arg = $scheduledTasks{named}{$i}{ARG};
    if(!defined($tim) || !defined($fn)) {
      delete($scheduledTasks{named}{$i});
      next;
    } elsif($tim <= $now) {
      no strict "refs";
      if(defined($arg)) {
        eval {
        	&{$fn}($arg);
        };
        #Log (3, "scheduled task ($i) error: $@") if $@;
      } else {
      	eval($fn);
      	#Log (3, "scheduled task ($i) error: $@") if $@;
      }
      Log (3, "scheduled task ($i) error: $@") if $@;
      use strict "refs";
      delete($scheduledTasks{named}{$i});
    } else {
      $nexttime = $tim if(!$nexttime || $nexttime > $tim);
    }
  }

  return undef if(!$nexttime);
  $now = gettimeofday(); # possibly some tasks did timeout in the meantime
                         # we will cover them 
  return ($now+ 0.01 < $nexttime) ? ($nexttime-$now) : 0.01;
}

# Plant eine gegebene Funktion zur Ausfuehrung ein.
# Params: 
#   tim: Zeit in Sekunden, nach der Ablauf soll die Funktion aufgerufen werden
#   fn:  Funktion
# Opt. Params:
#   arg: Parameter (array), die an die angegebene Funktion beim Aufruf uebergeben werden
#        Werden Parameter definiert, wird Funktionsaufruf verwendet, ansonsten eval()!
#        Damit k�nnen nicht nur Funktionsnamen, sondern auch Anwesungen verwendet werden.
#   ID_Name: Wenn angegeben, wird die ggf. bereits vorhandene Planung mit dem 
#            gleichen Namen entweder dadurch ersetzt oder die erneute Definition 
#            wird ignoriert.
#   mode: 0 (default): die zweite Definition wird verwofen, solange eine 
#            gleichnamige bereits existiert
#         1: die zweite Definition ersetzt die erste. Dadurch wird die Planzeit ggf. ver�ndert.
#            Aber auch ggf. die Funktion und Argumente.
#         2: die laengste Zeit der beiden Definitionen wird genommen. 
#            Auch die Fn und die Parameter werden von dem "Gewinner" genommen.
sub
scheduleTask($$;$$$)
{
	my ($tim, $fn, $arg, $nameID, $nMode) = @_;
	
	if(!defined($tim) || !defined($fn)) {
		return;
	}
	
	if(defined($nameID) && !defined($nMode)) {
		$nMode=0; # default
	}
	
	if(!defined($schedcnt)) {
		$schedcnt = 0;
	}
	
	my $now = gettimeofday();
  $tim+=$now;
  
  if(defined($nameID)) {
  	#Log 3, "schedule: named mode";
  	if(defined($scheduledTasks{named}{$nameID})) {
  		if($nMode == 0) {
  			# ignore second definition
  		  $tim = $scheduledTasks{named}{$nameID}{TRIGGERTIME}; # Wichtig fuer die Berechnung der naechsten Ausfuehrungszeit
  			#Log 3, "schedule: definition allready exists, ignore new (mode 0)";
  		} elsif ($nMode == 1) {
  			#Log 3, "schedule: definition allready exists, update (mode 1)";
  			# update first definition
  			$scheduledTasks{named}{$nameID}{TRIGGERTIME} = $tim;
        $scheduledTasks{named}{$nameID}{FN} = $fn;
        $scheduledTasks{named}{$nameID}{ARG} = $arg;
  		} else {
  			# update first definition else ignore
  			#Log 3, "schedule: definition allready exists, check time (mode 2)";
        if($scheduledTasks{named}{$nameID}{TRIGGERTIME} < $tim) {
        	#Log 3, "schedule: new time later then old, update (mode 2) => $scheduledTasks{named}{$nameID}{TRIGGERTIME} vs. $tim";
  			  $scheduledTasks{named}{$nameID}{TRIGGERTIME} = $tim;
          $scheduledTasks{named}{$nameID}{FN} = $fn;
          $scheduledTasks{named}{$nameID}{ARG} = $arg;
  			} else {
  				#Log 3, "schedule: new time earlier then old, ignore (mode 2) => $scheduledTasks{named}{$nameID}{TRIGGERTIME} vs. $tim";
  				$tim = $scheduledTasks{named}{$nameID}{TRIGGERTIME}; # Wichtig fuer die Berechnung der naechsten Ausfuehrungszeit
  			}
  		}
  	} else {
  		#Log 3, "schedule: new definition";
      $scheduledTasks{named}{$nameID}{TRIGGERTIME} = $tim;
      $scheduledTasks{named}{$nameID}{FN} = $fn;
      $scheduledTasks{named}{$nameID}{ARG} = $arg;
    }
  } else {
  	#Log 3, "schedule: unnamed mode";
    $scheduledTasks{unnamed}{$schedcnt}{TRIGGERTIME} = $tim;
    $scheduledTasks{unnamed}{$schedcnt}{FN} = $fn;
    $scheduledTasks{unnamed}{$schedcnt}{ARG} = $arg;
    $schedcnt++;
  }
  $nexttime = $tim if(!$nexttime || $nexttime > $tim);
  
  return $tim;
}

###############################################################################
# Listet die geplanten Task auf.
# Params:
#   mode: 0: Alle; 1: unnamed tasks only; 2: named tasks only
###############################################################################
sub listScheduledTasks(;$) {
	my($mode) = @_;
	
	$mode = 0 unless defined($mode);
	
	my $ret="";
	
	#unnamed
	if($mode==0 || $mode==1) {
		foreach my $i (sort { $scheduledTasks{unnamed}{$a}{TRIGGERTIME} <=>
                        $scheduledTasks{unnamed}{$b}{TRIGGERTIME} } keys %{$scheduledTasks{unnamed}}) {
      my $tim = $scheduledTasks{unnamed}{$i}{TRIGGERTIME};
      my $fn = $scheduledTasks{unnamed}{$i}{FN};
      my $arg = $scheduledTasks{unnamed}{$i}{ARG};      
      $ret.= sprintf("%10d: %s [%-40s] (%s)\n",
                     $i, strftime("%d.%m.%Y %H:%M:%S", localtime($tim)),
                     $fn,defined($arg)?join(', ', @$arg):"");
    }
	}
	
	#named
	if($mode==0 || $mode==2) {
		foreach my $i (sort { $scheduledTasks{named}{$a}{TRIGGERTIME} <=>
                        $scheduledTasks{named}{$b}{TRIGGERTIME} } keys %{$scheduledTasks{named}}) {
      my $tim = $scheduledTasks{named}{$i}{TRIGGERTIME};
      my $fn = $scheduledTasks{named}{$i}{FN};
      my $arg = $scheduledTasks{named}{$i}{ARG};      
      $ret.= sprintf("%10s: %s [%-40s] (%s)\n",
                     $i, strftime("%d.%m.%Y %H:%M:%S", localtime($tim)),
                     $fn,defined($arg)?join(', ', @$arg):"");
    }
	}
	
	return $ret;
}

# Clean up
sub
myCtrlBase_Undef($$)
{
  RemoveInternalTimer($timerParam -> {'next'});
  Log 2, "AutomationControlBase: clean-up";
  return undef;
}


# --- Automatik und Steuerung -------------------------------------------------
# wird beim Start von FHEM aufgerufen (notify global:INITIALIZED)
sub notifierFn_FHEM_Start() {
	sendMeJabberMessage('Service Message: FHEM gestartet');
	setAllAutomatikControlsDefaults();
	# ggf. Weiteres...
}

# wird beim Shutdown aufgrufen (notify global:SHUTDOWN)
sub notifierFn_FHEM_Shutdown() {
	sendMeJabberMessage('Service Message: FHEM faehrt herunter');
	# ggf. Weiteres...
}

# speichert (Restart-sicher) ein Key/Value-Paar (fuer Steuerungszwecke)
sub putCtrlData($$) {
	my($key, $val) = @_;
  # Ein Dummy als Container verwenden (ein nicht in Frontent sichtbares Reading speichern)
	# es ist egal, an welchen Element man diese Angabe 'anhaengt'... nur ein Container
	setReading(DEVICE_NAME_CTRL_ROLLADEN_DAY_NIGHT, $key, $val);
}

# liefert ein zum einem Key gespeichertes Wert (fuer Steuerungszwecke)
sub getCtrlData($) {
	my($key) = @_;
	# es ist egal, an welchen Element man diese Angabe 'anhaengt'... nur ein Container
	my $val = ReadingsVal(DEVICE_NAME_CTRL_ROLLADEN_DAY_NIGHT, $key, undef);
	return $val;
}

# wird regelmaessig (minuetlich) aufgerufen (AT)
sub myCtrlBase_automationHeartbeat() {
	# nach Bedarf (nachts) Automatik wieder aktivieren:
	#  - Wenn nicht 'Verrreist', dann Zirkulation, Beschattung, 
	#    Tag/Nachtsteuerung (Rolladen), Presence wieder auf Automatik setzen.
	#  - ...
	
	#Log 3, "AutomationControlBase: Heartbeat";
	
	my $hms = CurrentTime();
	my $cDate = CurrentDate(); 
	# es ist egal, an welchen Element man diese Angabe 'anhaengt'... nur ein Container
	my $lDate = getCtrlData("ctrl_last_automatic_heartbeat_reset");
	# einmal am Tag zw. 2 und 5 Uhr
	if($cDate ne $lDate &&  $hms gt "02:00" and $hms lt "05:00") {
		if(Value(DEVICE_NAME_CTRL_ANWESENHEIT) ne FAR_AWAY) {
		  resetAutomatikControls();
    } else {
      # Verreist:
      #  - ZPumpe in Minimal-Modus
      setValue(DEVICE_NAME_CTRL_ZIRK_PUMPE, ABSENT);
    }
    putCtrlData("ctrl_last_automatic_heartbeat_reset", $cDate);
  }
  
  # TODO: Wenn sich der Wert der Anwesenheit auf Auto geaendert hat (nur bei einer Aenderung!), 
  #       dann auch ZPumpe anpassen. Auch fuer Aenderung auf Anwesend/Abwesend
  #
  	# Wenn PRESENCE Automatic, dann auch 
	  #if(Value(DEVICE_NAME_CTRL_ANWESENHEIT) ne FAR_AWAY) {
		  #setValue(DEVICE_NAME_CTRL_ZIRK_PUMPE, ABSENT);
	  #}

	
	# Wenn in WZ Licht laenger als 3 Minuten an ist 
	#   && Licht-Au�en < 170? && Rolladen offen > 90 
	#  => dann WZ Rolladen auf 30 %. Bei Terrassentueren nur wenn sie beide zu sind 
	# TODO: HAL
	my $lName="EG_WZ_DA01_Licht_Rechts_Sw";
	my $llevel=ReadingsVal($lName,"level","0");
	my $lthr=170;
	my $ctrlBlockName="ctrl_last_RL_WZ_Light";
	# TODO
	
	#{
	#	my $lName="EG_WZ_DA01_Licht_Rechts_Sw";; my $llevel=ReadingsVal($lName,"level","0");; 
	#	my $lthr=$llevel>20?170:130;; my $self="NN_RL_CTRL_SZ_Dn";; 
	#	my $li = ReadingsVal("UM_VH_HMBL01.Eingang", "brightness", "180");; 
	#	if ($li < $lthr &&  $hms gt "17:00" and $hms lt "23:30") {notGreaterThen("sz_rollo", "30");;}
	# {notGreaterThen("wz_rollo_l", 0);;notGreaterThen("wz_rollo_r", 0, ('wz_fenster_l', 'wz_fenster_r'));;fhem("attr ".$self." my_control ".$dt);;}}
	#	} 
	
	
	# TODO
	
	
}

# Diese Methode setzt bei Bedarf die SteuerungsControlls (Dummies) auf 
# Defaultwerte (AUTOMATIC). Sie soll beim FHEM-Start aufgerufen werden (global:INITIALIZED).
sub setAllAutomatikControlsDefaults() {
	# TODO: future: Pruefen, ob z.B. Status "Verreist" bereucksichtigt werden soll
	if(Value(DEVICE_NAME_CTRL_BESCHATTUNG) eq "???" ||  ReadingsVal(DEVICE_NAME_CTRL_BESCHATTUNG,"STATE","???") eq "???") {
	  setValue(DEVICE_NAME_CTRL_BESCHATTUNG, AUTOMATIC);
	}
	
	if(Value(DEVICE_NAME_CTRL_ANWESENHEIT) eq "???" ||  ReadingsVal(DEVICE_NAME_CTRL_ANWESENHEIT,"STATE","???") eq "???") {
    setValue(DEVICE_NAME_CTRL_ANWESENHEIT, AUTOMATIC);
  }
	#setHomePresence_Present();
	
	if(Value(DEVICE_NAME_CTRL_ROLLADEN_DAY_NIGHT) eq "???" ||  ReadingsVal(DEVICE_NAME_CTRL_ROLLADEN_DAY_NIGHT,"STATE","???") eq "???") {
    setValue(DEVICE_NAME_CTRL_ROLLADEN_DAY_NIGHT, AUTOMATIC);
  }
	
	if(Value(DEVICE_NAME_CTRL_ZIRK_PUMPE) eq "???" ||  ReadingsVal(DEVICE_NAME_CTRL_ZIRK_PUMPE,"STATE","???") eq "???") {
    setValue(DEVICE_NAME_CTRL_ZIRK_PUMPE, AUTOMATIC);
  }
}

# Diese Methode setzt nachts die SteuerungsControlls (Dummies) auf 
# Defaultwerte (AUTOMATIC). Sie soll jede Nacht zu einem Definierten Zeitpunkt
# aufgerufen werden. Damit wird erreicht, dass alle Uebersteuerungen irgendwann 
# in einen normalen Zustand uebergehen.
sub resetAutomatikControls() {
	setBeschattungAutomaticOn();
	setHomePresence_Automatic();
	#setHomePresence_Present();
	setDayNightRolloAutomaticOn();
	setValue(DEVICE_NAME_CTRL_ZIRK_PUMPE, AUTOMATIC);
}

###############################################################################
# Controlblock: Liefert zu dem Group/Key die Daten der letzten Aufrufe
# Parameter: Group: Gruppe, die Keys der glichen Gruppe werden zusammengefast.
#            Key: Neuer Zustand.
#            Zeitangabe in Sekunden: Fuer diese Zeit wird die Anzahl der Aktionen
#                   der gleichen Gruppe/Key berechnet. Default = 60 (1 Min).
# Return: HASH:
#  SINCE_LAST_SEC     => Zeit seit der letzten Aktion der gleichen Gruppe
#  BETWEEN_2_LAST_SEC => Zeit zw. der letzten und der vorletzten Aktion der Gruppe
#  EQ_ACT_CNT         => Anzahl der Ereignisse der gleichen Gruppe UND Key
#  EQ_ACT_PP_CNT      => Anzahl der Ereignisse der gleichen Gruppe UND Key in letzten N Sekunden
#  EQ_ACT_1MIN_CNT    => Anzahl der Ereignisse der gleichen Gruppe UND Key in der letzten Minute
#  EQ_ACT_15MIN_CNT   => -/- 15
#  EQ_ACT_1HOUR_CNT
#  EQ_ACT_SAME_DAY_CNT=> Anzahl der Ereignisse an dem selben Tag (nicht 24 Stunden)
#
# alt: Return:    Array: [Zeit seit der letzten Aktion der gleichen Gruppe,
#                    Zeit zw. der letzten und der vorletzten Aktion der Gruppe,
#                    Anzahl der Ereignisse der gleichen Gruppe UND Key,
#                    Anzahl der Ereignisse der gleichen Gruppe UND Key in letzten N Sekunden]
###############################################################################
sub getGenericCtrlBlock($;$$) {
	my($group, $new_state, $last_time_diff)=@_;
	if(!defined($last_time_diff)) {$last_time_diff=60;}
	if(!defined($new_state)) {$new_state="X";} # Wenn State nicht definiert, irgendwas definiertes nehmen
	my $ctrl_gl_au = getCtrlData($group);
	# Format: [zustand on|off...],[datum/zeit decimal (sec)],[counter],[counter_last_min],[sekunden seit letzter aktion]
	my $ctrl_cnt=0;
	my $ctrl_state=undef;
	my $ctrl_dt = undef;
	my $ctrl_cnt_last_min = 0;
	my $ctrl_cnt_last_pp = 0;
	my $ctrl_sec_since = 0;
	
	my $ctrl_cnt_last_15min = 0;
	my $ctrl_cnt_last_hour = 0;
	my $ctrl_cnt_same_day = 0;
	
	if(defined($ctrl_gl_au)) {
		# Last used state, Date, Count (eq Key), Cnt last min, cnt between 2 last actions, cnt last N
		($ctrl_state, $ctrl_dt, $ctrl_cnt, $ctrl_cnt_last_min, $ctrl_sec_since, $ctrl_cnt_last_pp, $ctrl_cnt_last_15min, $ctrl_cnt_last_hour, $ctrl_cnt_same_day)  = split(/,/,$ctrl_gl_au);
	} else {
		$ctrl_cnt=0;
		$ctrl_cnt_last_min = 0;
		$ctrl_cnt_last_pp = 0;
		$ctrl_cnt_last_hour = 0;
		$ctrl_cnt_last_15min = 0;
		$ctrl_cnt_same_day = 0;
  	$ctrl_state=undef;
  	my ($sec,$min,$hour,$mday,$month,$year,$wday,$yday,$isdst) = localtime;
	  $month+=1, $year+=1900;
	  $ctrl_dt = dateTime2dec($year."-".$month."-".$mday." ".$hour.":".$min.":".$sec);
	}
	
	# Aktuelle Zeitangaben	
	my $c_date = CurrentDate();
	my $c_time = CurrentTime();
	my ($sec,$min,$hour,$mday,$month,$year,$wday,$yday,$isdst) = localtime;
	my ($lsec,$lmin,$lhour,$lmday,$lmonth,$lyear,$lwday,$lyday,$lisdst) = localtime($ctrl_dt);
	$month+=1, $year+=1900;
	my $dt_dec = dateTime2dec($year."-".$month."-".$mday." ".$hour.":".$min.":".$sec);
	
	$ctrl_cnt_last_min=int($ctrl_cnt_last_min);
	$ctrl_cnt_last_pp = int($ctrl_cnt_last_pp);
	$ctrl_cnt_last_hour = int($ctrl_cnt_last_hour);
	$ctrl_cnt_same_day = int($ctrl_cnt_same_day);
	$ctrl_cnt_last_15min = int($ctrl_cnt_last_15min);
	$ctrl_sec_since=int($ctrl_sec_since);
	if($new_state ne $ctrl_state) {
	  $ctrl_cnt = 0;
	  $ctrl_cnt_last_min = 0;
	  $ctrl_cnt_last_pp = 0;
	  $ctrl_cnt_last_hour = 0;
	  $ctrl_cnt_last_15min = 0;
	  $ctrl_cnt_same_day = 0;
  } else {
  	# wenn gleicher Zustand: 
    if($dt_dec-$ctrl_dt <= 60) {
  	  # wenn innerhalb einer minute
	    $ctrl_cnt_last_min+= 1;
	  } else {
	  	$ctrl_cnt_last_min = 1;
	  }
	  if($dt_dec-$ctrl_dt <= $last_time_diff) {
  	  # wenn innerhalb definierter spanne
	    $ctrl_cnt_last_pp+= 1;
	  } else {
	  	$ctrl_cnt_last_pp = 1;
	  }
	  if($dt_dec-$ctrl_dt <= 900) {
  	  # wenn innerhalb von 15 minuten
	    $ctrl_cnt_last_15min+= 1;
	  } else {
	  	$ctrl_cnt_last_15min = 1;
	  }
	  if($dt_dec-$ctrl_dt <= 3600) {
  	  # wenn innerhalb von 60 minuten
	    $ctrl_cnt_last_hour+= 1;
	  } else {
	  	$ctrl_cnt_last_hour = 1;
	  }
	  if($mday==$lmday) {
  	  # wenn innerhalb am gleichen Tag
	    $ctrl_cnt_same_day+= 1;
	  } else {
	  	$ctrl_cnt_same_day = 1;
	  }
	  # Gesamtcounter
	  $ctrl_cnt+=1;	
  }
	
	putCtrlData($group, $new_state.",".$dt_dec.",".$ctrl_cnt.",".$ctrl_cnt_last_min.",".($dt_dec-$ctrl_dt).",".$ctrl_cnt_last_pp.",".$ctrl_cnt_last_15min.",".$ctrl_cnt_last_hour.",".$ctrl_cnt_same_day);
	
	my $ret;
	$ret->{SINCE_LAST_SEC}=$dt_dec-$ctrl_dt;
	$ret->{BETWEEN_2_LAST_SEC}=$ctrl_sec_since;
	$ret->{EQ_ACT_CNT}=$ctrl_cnt;
	$ret->{EQ_ACT_PP_CNT}=$ctrl_cnt_last_pp;
	$ret->{EQ_ACT_1MIN_CNT}=$ctrl_cnt_last_min;
	$ret->{EQ_ACT_15MIN_CNT}=$ctrl_cnt_last_15min;
	$ret->{EQ_ACT_1HOUR_CNT}=$ctrl_cnt_last_hour;
	$ret->{EQ_ACT_SAME_DAY_CNT}=$ctrl_cnt_same_day;
	
	return $ret;
	
	# Rueckgabe: Sekunden seit der Letzten Abfrage, Sekunden zw. Abfragen davor, GesamtAnzahl gleiche Aktion, Anzahl letzte Minute (gleiche Aktion)
	#return (($dt_dec-$ctrl_dt), $ctrl_sec_since, $ctrl_cnt, $ctrl_cnt_last_min);
}

# Controlblock fuer HomeAutomatic-Schalter
# Parameter: Neuer Zustand
sub getHomeAutomaticCtrlBlock($) {
	my($key)=@_;
	#return getGenericCtrlBlock("ctrl_last_global_automatic_change", $key);
	my $ret = getGenericCtrlBlock("ctrl_last_global_automatic_change", $key);
	
	return ($ret->{SINCE_LAST_SEC}, $ret->{BETWEEN_2_LAST_SEC}, $ret->{EQ_ACT_CNT}, $ret->{EQ_ACT_PP_CNT});
}

# Methode f�r Benachrichtigung beim Klingeln an der Haustuer
sub actHaustuerKlingel() {
	#TODO: HAL
	sendMeJabberMessage("Tuerklingel am ".ReadingsTimestamp('KlingelIn','reading',''));
	voiceDoorbell();
}

sub actPIRVorgarten() {
	#Halloween TEMP
	voiceHalloween(3);
}


# Methode f�r den taster
# Schatet globale Haus-Automatik ein 
# (setzt DEVICE_NAME_CTRL_BESCHATTUNG aud AUTOMATIC)
sub actHomeAutomaticOn() {
	# Derzeit keine globale Automatik, daher delegieren
	setBeschattungAutomaticOn();
	# Tag/Nacht-Steuerung moechte ich hier nicht haben...
	
	# Hier (Sprach)Meldungen
	voiceActGenericUserEvent();

}

# Methode f�r den taster
# Schatet globale Haus-Automatik aus 
# (setzt DEVICE_NAME_CTRL_BESCHATTUNG aud DISABLED)
sub actHomeAutomaticOff() {
	# Derzeit keine globale Automatik, daher delegieren
	setBeschattungAutomaticOff(); # ?
	
	# Hier (Sprach)Meldungen
	voiceActLeaveHome();
  
}

# Schatet Beschattung-Automatik ein (setzt DEVICE_NAME_CTRL_BESCHATTUNG aud AUTOMATIC)
sub setBeschattungAutomaticOn() {
	# Erstmal nur Wert ssetzen. ggf sp�ter eine Aktion ausloesen
	setValue(DEVICE_NAME_CTRL_BESCHATTUNG, AUTOMATIC);
}

# Schatet Beschattung-Automatik aus (setzt DEVICE_NAME_CTRL_BESCHATTUNG aud DISABLED)
sub setBeschattungAutomaticOff() {
	# Erstmal nur Wert ssetzen. ggf sp�ter eine Aktion ausloesen
	setValue(DEVICE_NAME_CTRL_BESCHATTUNG, DISABLED);
}

# Setzt PRESENCE-Status auf automatic 
sub setHomePresence_Automatic() {
	# Erstmal nur Wert ssetzen. ggf sp�ter eine Aktion ausloesen
	setValue(DEVICE_NAME_CTRL_ANWESENHEIT, AUTOMATIC);
}

# Setzt PRESENCE-Status auf anwesend (jemand ist zuhause)
sub setHomePresence_Present() {
	# Erstmal nur Wert setzen. ggf sp�ter eine Aktion ausloesen
	setValue(DEVICE_NAME_CTRL_ANWESENHEIT, PRESENT);
	#Halloween TEMP
	voiceHalloween(1);
}

# Setzt PRESENCE-Status auf abwesend (niemand ist zuhause)
sub setHomePresence_Absent() {
	# Erstmal nur Wert setzen. ggf sp�ter eine Aktion ausloesen
  setValue(DEVICE_NAME_CTRL_ANWESENHEIT, ABSENT);
  #Halloween TEMP
	voiceHalloween(2);
}

# Schatet Tag/Nacht-Rolladen-Automatik ein (setzt DEVICE_NAME_CTRL_ROLLADEN_DAY_NIGHT aud AUTOMATIC)
sub setDayNightRolloAutomaticOn() {
	# Erstmal nur Wert ssetzen. ggf sp�ter eine Aktion ausloesen
	setValue(DEVICE_NAME_CTRL_ROLLADEN_DAY_NIGHT, AUTOMATIC);
}

# Schatet Tag/Nacht-Rolladen-Automatic aus (setzt DEVICE_NAME_CTRL_ROLLADEN_DAY_NIGHT aud DISABLED)
sub setDayNightRolloAutomaticOff() {
	# Erstmal nur Wert ssetzen. ggf sp�ter eine Aktion ausloesen
	setValue(DEVICE_NAME_CTRL_ROLLADEN_DAY_NIGHT, DISABLED);
}


1;
