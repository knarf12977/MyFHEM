##############################################
# $Id$
package main;

use strict;
use warnings;
use POSIX;
#use List::Util qw[min max];


# R�ume
my $rooms;
  $rooms->{wohnzimmer}->{alias}="Wohnzimmer";
  $rooms->{wohnzimmer}->{fhem_name}="Wohnzimmer";
  # Definiert nutzbare Sensoren. Reihenfolge gibt Priorit�t an. <= ODER BRAUCHT MAN NUR DIE EINZEL-READING-DEFINITIONEN?
  $rooms->{wohnzimmer}->{sensors}=["wz_raumsensor","wz_wandthermostat","tt_sensor"];
  $rooms->{wohnzimmer}->{sensors_outdoor}=["vr_luftdruck","um_hh_licht","um_vh_licht","um_vh_owts01","hg_sensor"]; # Sensoren 'vor dem Fenster'. Wichtig vor allen bei Licht (wg. Sonnenstand)
  # Definiert nutzbare Messwerte einzeln. Hat vorrang vor der Definition von kompletten Sensoren. Reihenfolge gibt Priorit�t an.
  #ggf. for future use
  #$rooms->{wohnzimmer}->{measurements}->{temperature}=["wz_raumsensor:temperature"];
  #$rooms->{wohnzimmer}->{measurements_outdoor}->{temperature}=["hg_sensor:temperature"];
  #$rooms->{wohnzimmer}->{measurements}->{pressure}=["wz_raumsensor:pressure"];
  #$rooms->{wohnzimmer}->{measurements_outdoor}->{pressure}=["hg_sensor:pressure"];
  
  $rooms->{kueche}->{alias}="K�che";
  $rooms->{kueche}->{fhem_name}="Kueche";
  $rooms->{kueche}->{sensors}=["ku_raumsensor","eg_ku_fk01"];
  $rooms->{kueche}->{sensors_outdoor}=["vr_luftdruck","um_vh_licht","um_vh_owts01","um_hh_licht","hg_sensor"]; 
    
  $rooms->{umwelt}->{alias}="Umwelt";
  $rooms->{umwelt}->{fhem_name}="Umwelt";
  $rooms->{umwelt}->{sensors}=["hg_sensor","um_vh_licht","um_hh_licht","um_vh_owts01","vr_luftdruck"]; # Licht/Bewegung, 1wTemp, TinyTX-Garten (T/H), LichtGarten, LichtVorgarten
  $rooms->{umwelt}->{sensors_outdoor}=[]; # Keine
  
  $rooms->{eg_flur}->{alias}="Flur EG";
  $rooms->{eg_flur}->{fhem_name}="EG_Flur";
  $rooms->{eg_flur}->{sensors}=["eg_fl_raumsensor",""];
  $rooms->{eg_flur}->{sensors_outdoor}=["vr_luftdruck","um_vh_licht","um_hh_licht","um_vh_owts01","hg_sensor"];
  
  $rooms->{og_flur}->{alias}="Flur OG";
  $rooms->{og_flur}->{fhem_name}="OG_Flur";
  $rooms->{og_flur}->{sensors}=["of_sensor",""];
  $rooms->{og_flur}->{sensors_outdoor}=["vr_luftdruck","um_vh_licht","um_hh_licht","um_vh_owts01","hg_sensor"];
  
  $rooms->{garage}->{alias}="Garage";
  $rooms->{garage}->{fhem_name}="Garage";
  $rooms->{garage}->{sensors}=[]; # TODO
  $rooms->{garage}->{sensors_outdoor}=["vr_luftdruck","um_vh_licht","um_hh_licht","um_vh_owts01","hg_sensor"];
  
  $rooms->{schlafzimmer}->{alias}="Schlafzimmer";
  $rooms->{schlafzimmer}->{fhem_name}="Schlafzimmer";
  $rooms->{schlafzimmer}->{sensors}=["sz_raumsensor",""]; # TODO: Fensterkontakt, Thermostat
  $rooms->{schlafzimmer}->{sensors_outdoor}=["vr_luftdruck","um_hh_licht","um_vh_licht","um_vh_owts01","hg_sensor"];
  
  
  # EG Flur, HWR, G�steWC, Garage
  # OG Flur, Bad, Schlafzimmer, Duschbad
  # DG
  # R�ume ohne Sensoren: Speisekammer, Abstellkammer, Kinderzimmer 1 und 2
  
# Aktoren
my $actors;
  $actors->{wz_rollo_r}->{class}="rollo";
  $actors->{wz_rollo_r}->{alias}="WZ Rolladen";
  $actors->{wz_rollo_r}->{fhem_name}="wz_rollo_r";
  $actors->{wz_rollo_r}->{type}="HomeMatic compatible";
  $actors->{wz_rollo_r}->{location}="wohnzimmer";
  $actors->{wz_rollo_r}->{readings}->{level}="level";
  $actors->{wz_rollo_r}->{actions}->{level}->{set}="pct";
  $actors->{wz_rollo_r}->{actions}->{level}->{type}="int"; #?
  $actors->{wz_rollo_r}->{actions}->{level}->{min}="0";    #?
  $actors->{wz_rollo_r}->{actions}->{level}->{max}="100";  #?
  $actors->{wz_rollo_r}->{actions}->{level}->{alias}->{hoch}->{value}="100";
  $actors->{wz_rollo_r}->{actions}->{level}->{alias}->{runter}->{value}="0";
  $actors->{wz_rollo_r}->{actions}->{level}->{alias}->{halb}->{value}="60";
  $actors->{wz_rollo_r}->{actions}->{level}->{alias}->{nacht}->{value}="0";
  $actors->{wz_rollo_r}->{actions}->{level}->{alias}->{schatten}->{valueFn}="TODO";
  
  
# Sensoren
my $sensors;
  $sensors->{wz_raumsensor}->{alias}     ="WZ Raumsensor";
  $sensors->{wz_raumsensor}->{fhem_name} ="EG_WZ_KS01";
  $sensors->{wz_raumsensor}->{type}      ="HomeMatic compatible";
  $sensors->{wz_raumsensor}->{location}  ="wohnzimmer";
  $sensors->{wz_raumsensor}->{readings}->{temperature} ->{reading}  ="temperature";
  $sensors->{wz_raumsensor}->{readings}->{temperature} ->{unit}     ="�C";
  $sensors->{wz_raumsensor}->{readings}->{temperature} ->{alias}    ="Temperatur";
  $sensors->{wz_raumsensor}->{readings}->{temperature} ->{act_cycle} ="600"; # Zeit in Sekunden ohne R�ckmeldung, dann wird Device als 'dead' erklaert.
  $sensors->{wz_raumsensor}->{readings}->{humidity}    ->{reading}  ="humidity";
  $sensors->{wz_raumsensor}->{readings}->{humidity}    ->{unit}     ="% rH";
  $sensors->{wz_raumsensor}->{readings}->{humidity}    ->{act_cycle} ="600"; 
  $sensors->{wz_raumsensor}->{readings}->{dewpoint}    ->{reading}  ="dewpoint";
  $sensors->{wz_raumsensor}->{readings}->{dewpoint}    ->{unit}     ="�C";
  $sensors->{wz_raumsensor}->{readings}->{dewpoint}    ->{alias}    ="Taupunkt";
  $sensors->{wz_raumsensor}->{readings}->{pressure}    ->{reading}  ="pressure";
  $sensors->{wz_raumsensor}->{readings}->{pressure}    ->{unit}     ="hPa";
  $sensors->{wz_raumsensor}->{readings}->{pressure}    ->{act_cycle} ="600"; 
  $sensors->{wz_raumsensor}->{readings}->{pressure}    ->{alias}    ="Luftdruck";
  $sensors->{wz_raumsensor}->{readings}->{luminosity}  ->{reading}  ="luminosity";
  $sensors->{wz_raumsensor}->{readings}->{luminosity}  ->{alias}    ="Lichtintesit�t";
  $sensors->{wz_raumsensor}->{readings}->{luminosity}  ->{unit}     ="Lx (*)";
  $sensors->{wz_raumsensor}->{readings}->{luminosity}    ->{act_cycle} ="600"; 
  $sensors->{wz_raumsensor}->{readings}->{bat_voltage} ->{reading}  ="batVoltage";
  $sensors->{wz_raumsensor}->{readings}->{bat_voltage} ->{unit}     ="V";
  $sensors->{wz_raumsensor}->{readings}->{bat_status}  ->{reading}  ="battery";
  
  $sensors->{eg_fl_raumsensor}->{alias}     ="EG Flur Raumsensor";
  $sensors->{eg_fl_raumsensor}->{fhem_name} ="EG_FL_KS01";
  $sensors->{eg_fl_raumsensor}->{type}      ="HomeMatic compatible";
  $sensors->{eg_fl_raumsensor}->{location}  ="eg_flur";
  $sensors->{eg_fl_raumsensor}->{readings}->{temperature} ->{reading}  ="temperature";
  $sensors->{eg_fl_raumsensor}->{readings}->{temperature} ->{unit}     ="�C";
  $sensors->{eg_fl_raumsensor}->{readings}->{temperature} ->{alias}    ="Temperatur";
  $sensors->{eg_fl_raumsensor}->{readings}->{temperature} ->{act_cycle} ="600"; # Zeit in Sekunden ohne R�ckmeldung, dann wird Device als 'dead' erklaert.
  $sensors->{eg_fl_raumsensor}->{readings}->{humidity}    ->{reading}  ="humidity";
  $sensors->{eg_fl_raumsensor}->{readings}->{humidity}    ->{unit}     ="% rH";
  $sensors->{eg_fl_raumsensor}->{readings}->{humidity}    ->{act_cycle} ="600"; 
  $sensors->{eg_fl_raumsensor}->{readings}->{dewpoint}    ->{reading}  ="dewpoint";
  $sensors->{eg_fl_raumsensor}->{readings}->{dewpoint}    ->{unit}     ="�C";
  $sensors->{eg_fl_raumsensor}->{readings}->{dewpoint}    ->{alias}    ="Taupunkt";
  $sensors->{eg_fl_raumsensor}->{readings}->{luminosity}  ->{reading}  ="luminosity";
  $sensors->{eg_fl_raumsensor}->{readings}->{luminosity}  ->{alias}    ="Lichtintesit�t";
  $sensors->{eg_fl_raumsensor}->{readings}->{luminosity}  ->{unit}     ="Lx (*)";
  $sensors->{eg_fl_raumsensor}->{readings}->{luminosity}    ->{act_cycle} ="600"; 
  $sensors->{eg_fl_raumsensor}->{readings}->{bat_voltage} ->{reading}  ="batVoltage";
  $sensors->{eg_fl_raumsensor}->{readings}->{bat_voltage} ->{unit}     ="V";
  $sensors->{eg_fl_raumsensor}->{readings}->{bat_status}  ->{reading}  ="battery";
  
  $sensors->{og_fl_raumsensor}->{alias}     ="OG Flur Raumsensor";
  $sensors->{og_fl_raumsensor}->{fhem_name} ="OG_FL_KS01";
  $sensors->{og_fl_raumsensor}->{type}      ="HomeMatic compatible";
  $sensors->{og_fl_raumsensor}->{location}  ="og_flur";
  $sensors->{og_fl_raumsensor}->{readings}->{temperature} ->{reading}  ="temperature";
  $sensors->{og_fl_raumsensor}->{readings}->{temperature} ->{unit}     ="�C";
  $sensors->{og_fl_raumsensor}->{readings}->{temperature} ->{alias}    ="Temperatur";
  $sensors->{og_fl_raumsensor}->{readings}->{temperature} ->{act_cycle} ="600";
  $sensors->{og_fl_raumsensor}->{readings}->{humidity}    ->{reading}  ="humidity";
  $sensors->{og_fl_raumsensor}->{readings}->{humidity}    ->{unit}     ="% rH";
  $sensors->{og_fl_raumsensor}->{readings}->{humidity}    ->{act_cycle} ="600"; 
  $sensors->{og_fl_raumsensor}->{readings}->{dewpoint}    ->{reading}  ="dewpoint";
  $sensors->{og_fl_raumsensor}->{readings}->{dewpoint}    ->{unit}     ="�C";
  $sensors->{og_fl_raumsensor}->{readings}->{dewpoint}    ->{alias}    ="Taupunkt";
  $sensors->{og_fl_raumsensor}->{readings}->{luminosity}  ->{reading}  ="luminosity";
  $sensors->{og_fl_raumsensor}->{readings}->{luminosity}  ->{alias}    ="Lichtintesit�t";
  $sensors->{og_fl_raumsensor}->{readings}->{luminosity}  ->{unit}     ="Lx (*)";
  $sensors->{og_fl_raumsensor}->{readings}->{luminosity}    ->{act_cycle} ="600"; 
  $sensors->{og_fl_raumsensor}->{readings}->{bat_voltage} ->{reading}  ="batVoltage";
  $sensors->{og_fl_raumsensor}->{readings}->{bat_voltage} ->{unit}     ="V";
  $sensors->{og_fl_raumsensor}->{readings}->{bat_status}  ->{reading}  ="battery";

  $sensors->{sz_raumsensor}->{alias}     ="Schlafzimmer Raumsensor";
  $sensors->{sz_raumsensor}->{fhem_name} ="OG_SZ_KS01";
  $sensors->{sz_raumsensor}->{type}      ="HomeMatic compatible";
  $sensors->{sz_raumsensor}->{location}  ="schlafzimmer";
  $sensors->{sz_raumsensor}->{readings}->{temperature} ->{reading}  ="temperature";
  $sensors->{sz_raumsensor}->{readings}->{temperature} ->{unit}     ="�C";
  $sensors->{sz_raumsensor}->{readings}->{temperature} ->{alias}    ="Temperatur";
  $sensors->{sz_raumsensor}->{readings}->{temperature} ->{act_cycle} ="600";
  $sensors->{sz_raumsensor}->{readings}->{humidity}    ->{reading}  ="humidity";
  $sensors->{sz_raumsensor}->{readings}->{humidity}    ->{unit}     ="% rH";
  $sensors->{sz_raumsensor}->{readings}->{humidity}    ->{act_cycle} ="600"; 
  $sensors->{sz_raumsensor}->{readings}->{dewpoint}    ->{reading}  ="dewpoint";
  $sensors->{sz_raumsensor}->{readings}->{dewpoint}    ->{unit}     ="�C";
  $sensors->{sz_raumsensor}->{readings}->{dewpoint}    ->{alias}    ="Taupunkt";
  $sensors->{sz_raumsensor}->{readings}->{luminosity}  ->{reading}  ="luminosity";
  $sensors->{sz_raumsensor}->{readings}->{luminosity}  ->{alias}    ="Lichtintesit�t";
  $sensors->{sz_raumsensor}->{readings}->{luminosity}  ->{unit}     ="Lx (*)";
  $sensors->{sz_raumsensor}->{readings}->{luminosity}  ->{act_cycle} ="600"; 
  $sensors->{sz_raumsensor}->{readings}->{bat_voltage} ->{reading}  ="batVoltage";
  $sensors->{sz_raumsensor}->{readings}->{bat_voltage} ->{unit}     ="V";
  $sensors->{sz_raumsensor}->{readings}->{bat_status}  ->{reading}  ="battery";

  # idee: 
  # $sensors->{vr_luftdruck}->{alias}       ="VirtuellerSensor";
  # $sensors->{vr_luftdruck}->{type}        ="virtual";
  # $sensors->{vr_luftdruck}->{readings}->{X}->{ValueFn}     ="max"; #min, summe, average, eigene... bekommt Record, liefert Wert # wenn ValueFn, dann nur deren Wert, keine weitere Logik
  # $sensors->{vr_luftdruck}->{readings_list} =["X",...]; # f�r ValueFn?
  # $sensors->{vr_luftdruck}->{readings}->{pressure} ="device:reading"; # 'Weiterleitung' ? 
  #
  $sensors->{test}->{alias}       ="TestSensor";
  $sensors->{test}->{type}        ="virtual";
  #$sensors->{test}->{readings}->{test1}->{ValueFn} = '{my $t=1; my $s=2; max($t,$s)}'; # mit Klammern: Direkt evaluieren, ansonsten als Funktion mit Reading-Hash und Device-Hash aufrufen.
  $sensors->{test}->{readings}->{test1}->{ValueFn} = 'senTest';
  $sensors->{test}->{readings}->{test1}->{FnParams} = ["1","2"];
  $sensors->{test}->{readings}->{test1}->{unit} ="?";
  $sensors->{test}->{readings}->{test1}->{alias} ="Funktionstest";
  $sensors->{test}->{readings}->{test2}->{link} ="vr_luftdruck:pressure";
  # 
  $sensors->{virtual_control_sensor}->{alias}       ="Virtuelle Controll-Sammel-Sensor";
  $sensors->{virtual_control_sensor}->{type}        ="virtual";
  $sensors->{virtual_control_sensor}->{comment}     ="Virtueller Sensor mit (berechneten) Readings zur Steuerungszwecken.";
  $sensors->{virtual_control_sensor}->{readings}->{sun}->{ValueFn} = "myCtrlProxies_SunValueFn";
  $sensors->{virtual_control_sensor}->{readings}->{sun}->{FnParams} = [["um_vh_licht:luminosity",10,15], ["um_hh_licht:luminosity",10,15], ["um_vh_bw_licht:brightness",120,130]]; # Liste der Lichtsensoren zur Auswertung mit Grenzwerten (je 2 wg. Histerese)
  $sensors->{virtual_control_sensor}->{readings}->{sun}->{alias} = "Virtuelle Sonne";
  $sensors->{virtual_control_sensor}->{readings}->{sun}->{comment} = "gibt an, ob die 'Sonne' scheint, oder ob es genuegend dunkel ist (z.B. Rolladensteuerung).";
  
  #TODO:
  sub myCtrlProxies_SunValueFn($$) {
  	my ($device, $record) = @_;
  	#my $oRecord=$_[1];
  	my $senList = $record->{FnParams};
  	# keine 'dead' Sensoren verwenden. Wenn verschiedene Ergebnisse => Mehrheit entscheidet. Bei Gleichstand => on, alle 'dead' => on
  	# oldVal (letzter ermittelter Wert) speichern. Je nach oldVal obere oder untere Grenze verwenden
  	my $oldVal = $record->{oldVal};
  	$oldVal='on' unless defined $oldVal;
    my $cnt_on = 0;
    my $cnt_off = 0;
    foreach my $a (@{$senList}) {
    	my $senSpec = $a->[0];
    	my($sensorName,$readingName) = split(/:/, $senSpec);
    	my $senLim1 = $a->[1];
    	my $senLim2 = $a->[2];
    	#Log 3,'>------------>Name: '.$sensorName.', Reading: '.$readingName.', Lim1/2: '.$senLim1.'/'.$senLim2;
    	my $sRec = myCtrlProxies_getSensorValueRecord($sensorName,$readingName);
    	if($sRec->{alive}) {
    		my $sVal = $sRec->{value};
    		#Log 3,'>------------>sVal: '.$sVal;
    		if($oldVal eq 'on') {
    			#Log 3,">------------>XXX: $sVal / $senLim1";
    			if($sVal < $senLim1) {
    				$cnt_off+=1;
    				# Log 3,'>------------>1.1 oldVal: '.$oldVal." => new: off";
    			} else {
    				$cnt_on+=1;
    				# Log 3,'>------------>1.2 oldVal: '.$oldVal." => new: on";
    			}
    		} else {
    			# oldVal war off
    			if($sVal > $senLim2) {
    				$cnt_on+=1;
    				# Log 3,'>------------>2.1 oldVal: '.$oldVal." => new: on";
    			} else {
    				$cnt_off+=1;
    				# Log 3,'>------------>2.2 oldVal: '.$oldVal." => new: off";
    			}
    		}
    	}
    }
    my $newVal = 'on';
    if($cnt_off>$cnt_on) {$newVal = 'off';}
    
    $record->{oldVal}=$newVal;  #TODO: Dauerhaft (Neustartsicher) speichern (Reading?)
    $record->{oldTime}=time();
    #Log 3,'>------------> => newVal '.$newVal;
    return $newVal;
  }
  
  	
  $sensors->{vr_luftdruck}->{alias}     ="Luftdrucksensor";
  $sensors->{vr_luftdruck}->{fhem_name} ="EG_WZ_KS01";
  $sensors->{vr_luftdruck}->{type}      ="HomeMatic compatible";
  $sensors->{vr_luftdruck}->{location}  ="virtual";
  $sensors->{vr_luftdruck}->{readings}->{pressure}    ->{reading}  ="pressure";
  $sensors->{vr_luftdruck}->{readings}->{pressure}    ->{unit}     ="hPa";
  $sensors->{vr_luftdruck}->{readings}->{pressure}    ->{alias}     ="Luftdruck";
  
  $sensors->{wz_wandthermostat}->{alias}     ="WZ Wandthermostat";
  $sensors->{wz_wandthermostat}->{fhem_name} ="EG_WZ_WT01";
  $sensors->{wz_wandthermostat}->{type}      ="HomeMatic";
  $sensors->{wz_wandthermostat}->{location}  ="wohnzimmer";
  $sensors->{wz_wandthermostat}->{composite} =["wz_wandthermostat_climate"]; # Verbindung mit weitere (logischen) Ger�ten, die eine Einheit bilden.
  $sensors->{wz_wandthermostat}->{readings}        ->{bat_voltage} ->{reading}  ="batteryLevel";
  $sensors->{wz_wandthermostat}->{readings}        ->{bat_voltage} ->{unit}     ="V";
  $sensors->{wz_wandthermostat}->{readings}        ->{bat_status}  ->{reading}  ="battery";
  $sensors->{wz_wandthermostat_climate}->{alias}     ="WZ Wandthermostat (Ch)";
  $sensors->{wz_wandthermostat_climate}->{fhem_name} ="EG_WZ_WT01_Climate";
  $sensors->{wz_wandthermostat_climate}->{readings}->{temperature} ->{reading}  ="measured-temp";
  $sensors->{wz_wandthermostat_climate}->{readings}->{temperature} ->{unit}     ="�C";
  $sensors->{wz_wandthermostat_climate}->{readings}->{humidity}    ->{reading}  ="humidity";
  $sensors->{wz_wandthermostat_climate}->{readings}->{humidity}    ->{unit}     ="% rH";
  $sensors->{wz_wandthermostat_climate}->{readings}->{dewpoint}    ->{reading}  ="dewpoint";
  $sensors->{wz_wandthermostat_climate}->{readings}->{dewpoint}    ->{unit}     ="�C";
  $sensors->{wz_wandthermostat_climate}->{readings}->{dewpoint}    ->{alias}    ="Taupunkt";
  
  $sensors->{hg_sensor}->{alias}     ="Garten-Sensor";
  $sensors->{hg_sensor}->{fhem_name} ="GSD_1.4";
  $sensors->{hg_sensor}->{type}      ="GSD";
  $sensors->{hg_sensor}->{location}  ="garten";
  $sensors->{hg_sensor}->{readings}->{temperature} ->{reading}  ="temperature";
  $sensors->{hg_sensor}->{readings}->{temperature} ->{alias}    ="Temperatur";
  $sensors->{hg_sensor}->{readings}->{temperature} ->{unit}     ="�C";
  $sensors->{hg_sensor}->{readings}->{temperature} ->{act_cycle} ="600";
  $sensors->{hg_sensor}->{readings}->{humidity}    ->{reading}  ="humidity";
  $sensors->{hg_sensor}->{readings}->{humidity}    ->{unit}     ="% rH";
  $sensors->{hg_sensor}->{readings}->{humidity}    ->{act_cycle} ="600"; 
  $sensors->{hg_sensor}->{readings}->{bat_voltage} ->{reading}  ="batteryLevel";
  $sensors->{hg_sensor}->{readings}->{bat_voltage} ->{unit}     ="V";
  $sensors->{hg_sensor}->{readings}->{dewpoint}    ->{reading}  ="dewpoint";
  $sensors->{hg_sensor}->{readings}->{dewpoint}    ->{unit}     ="�C";
  $sensors->{hg_sensor}->{readings}->{dewpoint}    ->{alias}    ="Taupunkt";
  
  $sensors->{tt_sensor}->{alias}     ="Test-Sensor";
  $sensors->{tt_sensor}->{fhem_name} ="GSD_1.1";
  $sensors->{tt_sensor}->{type}      ="GSD";
  $sensors->{tt_sensor}->{location}  ="wohnzimmer";
  $sensors->{tt_sensor}->{readings}->{temperature} ->{reading}  ="temperature";
  $sensors->{tt_sensor}->{readings}->{temperature} ->{alias}    ="Temperatur";
  $sensors->{tt_sensor}->{readings}->{temperature} ->{unit}     ="�C";
  $sensors->{tt_sensor}->{readings}->{temperature} ->{act_cycle} ="600"; # Zeit in Sekunden ohne R�ckmeldung, dann wird Device als 'dead' erklaert.
  $sensors->{tt_sensor}->{readings}->{humidity}    ->{reading}  ="humidity";
  $sensors->{tt_sensor}->{readings}->{humidity}    ->{unit}     ="% rH";
  $sensors->{tt_sensor}->{readings}->{humidity}    ->{act_cycle} ="600"; 
  $sensors->{tt_sensor}->{readings}->{bat_voltage}  ->{reading} ="batteryLevel";
  $sensors->{tt_sensor}->{readings}->{bat_voltage}  ->{unit}    ="V";
  $sensors->{tt_sensor}->{readings}->{dewpoint}    ->{reading}  ="dewpoint";
  $sensors->{tt_sensor}->{readings}->{dewpoint}    ->{unit}     ="�C";
  $sensors->{tt_sensor}->{readings}->{dewpoint}    ->{alias}    ="Taupunkt";
  
  $sensors->{of_sensor}->{alias}     ="OG Flur Sensor";
  $sensors->{of_sensor}->{fhem_name} ="GSD_1.3";
  $sensors->{of_sensor}->{type}      ="GSD";
  $sensors->{of_sensor}->{location}  ="og_flur";
  $sensors->{of_sensor}->{readings}->{temperature} ->{reading}  ="temperature";
  $sensors->{of_sensor}->{readings}->{temperature} ->{alias}    ="Temperatur";
  $sensors->{of_sensor}->{readings}->{temperature} ->{unit}     ="�C";
  $sensors->{of_sensor}->{readings}->{temperature} ->{act_cycle} ="600";
  $sensors->{of_sensor}->{readings}->{humidity}    ->{reading}  ="humidity";
  $sensors->{of_sensor}->{readings}->{humidity}    ->{unit}     ="% rH";
  $sensors->{of_sensor}->{readings}->{humidity}    ->{act_cycle} ="600"; 
  $sensors->{of_sensor}->{readings}->{bat_voltage}  ->{reading} ="batteryLevel";
  $sensors->{of_sensor}->{readings}->{bat_voltage}  ->{unit}    ="V";
  $sensors->{of_sensor}->{readings}->{dewpoint}    ->{reading}  ="dewpoint";
  $sensors->{of_sensor}->{readings}->{dewpoint}    ->{unit}     ="�C";
  $sensors->{of_sensor}->{readings}->{dewpoint}    ->{alias}    ="Taupunkt";


  $sensors->{ku_raumsensor}->{alias}     ="KU Raumsensor";
  $sensors->{ku_raumsensor}->{fhem_name} ="EG_KU_KS01";
  $sensors->{ku_raumsensor}->{type}      ="HomeMatic compatible";
  $sensors->{ku_raumsensor}->{location}  ="kueche";
  $sensors->{ku_raumsensor}->{readings}->{temperature} ->{reading}   ="temperature";
  $sensors->{ku_raumsensor}->{readings}->{temperature} ->{alias}     ="Temperatur";
  $sensors->{ku_raumsensor}->{readings}->{temperature} ->{unit}      ="�C";
  $sensors->{ku_raumsensor}->{readings}->{temperature} ->{act_cycle} ="600"; # Zeit in Sekunden ohne R�ckmeldung, dann wird Device als 'dead' erklaert.
  $sensors->{ku_raumsensor}->{readings}->{humidity}    ->{reading}   ="humidity";
  $sensors->{ku_raumsensor}->{readings}->{humidity}    ->{alias}     ="Luftfeuchtigkeit"; 
  $sensors->{ku_raumsensor}->{readings}->{humidity}    ->{unit}      ="% rH";
  $sensors->{ku_raumsensor}->{readings}->{humidity}    ->{act_cycle} ="600"; 
  $sensors->{ku_raumsensor}->{readings}->{luminosity}  ->{reading}   ="luminosity";
  $sensors->{ku_raumsensor}->{readings}->{luminosity}  ->{alias}     ="Lichtintesit�t";
  $sensors->{ku_raumsensor}->{readings}->{luminosity}  ->{unit}      ="Lx (*)";
  $sensors->{ku_raumsensor}->{readings}->{luminosity}  ->{act_cycle} ="600"; 
  $sensors->{ku_raumsensor}->{readings}->{bat_voltage} ->{reading}   ="batVoltage";
  $sensors->{ku_raumsensor}->{readings}->{bat_voltage} ->{alias}     ="Batteriespannung";
  $sensors->{ku_raumsensor}->{readings}->{bat_voltage} ->{unit}      ="V";
  $sensors->{ku_raumsensor}->{readings}->{bat_status}  ->{reading}   ="battery";
  $sensors->{ku_raumsensor}->{readings}->{dewpoint}    ->{reading}   ="dewpoint";
  $sensors->{ku_raumsensor}->{readings}->{dewpoint}    ->{unit}      ="�C";
  $sensors->{ku_raumsensor}->{readings}->{dewpoint}    ->{alias}     ="Taupunkt";
  
  $sensors->{um_vh_licht}->{alias}     ="VH Aussensensor";
  $sensors->{um_vh_licht}->{fhem_name} ="UM_VH_KS01";
  $sensors->{um_vh_licht}->{type}      ="HomeMatic compatible";
  $sensors->{um_vh_licht}->{location}  ="umwelt";
  $sensors->{um_vh_licht}->{readings}->{luminosity}  ->{reading}   ="luminosity";
  $sensors->{um_vh_licht}->{readings}->{luminosity}  ->{alias}     ="Lichtintesit�t";
  $sensors->{um_vh_licht}->{readings}->{luminosity}  ->{unit}      ="Lx (*)";
  $sensors->{um_vh_licht}->{readings}->{luminosity}  ->{act_cycle} ="600"; 
  $sensors->{um_vh_licht}->{readings}->{bat_voltage} ->{reading}   ="batVoltage";
  $sensors->{um_vh_licht}->{readings}->{bat_voltage} ->{alias}     ="Batteriespannung";
  $sensors->{um_vh_licht}->{readings}->{bat_voltage} ->{unit}      ="V";
  $sensors->{um_vh_licht}->{readings}->{bat_status}  ->{reading}   ="battery";
  
  $sensors->{um_hh_licht}->{alias}     ="HH Aussensensor";
  $sensors->{um_hh_licht}->{fhem_name} ="UM_HH_KS01";
  $sensors->{um_hh_licht}->{type}      ="HomeMatic compatible";
  $sensors->{um_hh_licht}->{location}  ="umwelt";
  $sensors->{um_hh_licht}->{readings}->{luminosity}  ->{reading}   ="luminosity";
  $sensors->{um_hh_licht}->{readings}->{luminosity}  ->{alias}     ="Lichtintesit�t";
  $sensors->{um_hh_licht}->{readings}->{luminosity}  ->{unit}      ="Lx (*)";
  $sensors->{um_hh_licht}->{readings}->{luminosity}  ->{act_cycle} ="600"; 
  $sensors->{um_hh_licht}->{readings}->{bat_voltage} ->{reading}   ="batVoltage";
  $sensors->{um_hh_licht}->{readings}->{bat_voltage} ->{alias}     ="Batteriespannung";
  $sensors->{um_hh_licht}->{readings}->{bat_voltage} ->{unit}      ="V";
  $sensors->{um_hh_licht}->{readings}->{bat_status}  ->{reading}   ="battery";
  $sensors->{um_hh_licht}->{readings}->{bat_status}  ->{alias}     ="Batteriezustand";
  $sensors->{um_hh_licht}->{readings}->{temperature} ->{reading}   ="temperature";
  $sensors->{um_hh_licht}->{readings}->{temperature} ->{alias}     ="Temperatur";
  $sensors->{um_hh_licht}->{readings}->{temperature} ->{unit}      ="�C";
  $sensors->{um_hh_licht}->{readings}->{temperature} ->{act_cycle} ="600"; 
  
  $sensors->{um_vh_bw_licht}->{alias}     ="Bewegungsmelder (Vorgarten)";
  $sensors->{um_vh_bw_licht}->{fhem_name} ="UM_VH_HMBL01.Eingang";
  $sensors->{um_vh_bw_licht}->{type}      ="HomeMatic";
  $sensors->{um_vh_bw_licht}->{location}  ="umwelt";
  $sensors->{um_vh_bw_licht}->{readings}->{brightness}  ->{reading}   ="brightness";
  $sensors->{um_vh_bw_licht}->{readings}->{brightness}  ->{alias}     ="Helligkeit";
  $sensors->{um_vh_bw_licht}->{readings}->{brightness}  ->{unit}      ="RANGE: 0-250";
  $sensors->{um_vh_bw_licht}->{readings}->{brightness}  ->{act_cycle} ="600";
  $sensors->{um_vh_bw_licht}->{readings}->{motion}      ->{reading}   ="motion";
  $sensors->{um_vh_bw_licht}->{readings}->{motion}      ->{alias}     ="Bewegungsmelder";
  $sensors->{um_vh_bw_licht}->{readings}->{motion}      ->{unit_type} ="ENUM: on";
  $sensors->{um_vh_bw_licht}->{readings}->{bat_status}  ->{reading}   ="battery";
  $sensors->{um_vh_bw_licht}->{readings}->{bat_status}  ->{alias}     ="Batteriezustand";
  $sensors->{um_vh_bw_licht}->{readings}->{bat_status}  ->{unit_type} ="ENUM: ok,low";
  
  $sensors->{eg_fl_bw_licht}->{alias}     ="Bewegungsmelder (Flur hinten)";
  $sensors->{eg_fl_bw_licht}->{fhem_name} ="EG_FL_MS01";
  $sensors->{eg_fl_bw_licht}->{type}      ="MySensors";
  $sensors->{eg_fl_bw_licht}->{location}  ="eg_flur";
  $sensors->{eg_fl_bw_licht}->{readings}->{brightness}  ->{reading}   ="brightness";
  $sensors->{eg_fl_bw_licht}->{readings}->{brightness}  ->{alias}     ="Helligkeit";
  $sensors->{eg_fl_bw_licht}->{readings}->{brightness}  ->{unit}      ="RANGE: 0-54612";
  $sensors->{eg_fl_bw_licht}->{readings}->{brightness}  ->{act_cycle} ="600";
  $sensors->{eg_fl_bw_licht}->{readings}->{motion}      ->{reading}   ="motion";
  $sensors->{eg_fl_bw_licht}->{readings}->{motion}      ->{alias}     ="Bewegungsmelder";
  $sensors->{eg_fl_bw_licht}->{readings}->{motion}      ->{unit_type} ="ENUM: on";
  
  $sensors->{um_vh_owts01}->{alias}     ="OWX Aussentemperatur";
  $sensors->{um_vh_owts01}->{fhem_name} ="UM_VH_OWTS01.Luft";
  $sensors->{um_vh_owts01}->{type}      ="OneWire";
  $sensors->{um_vh_owts01}->{location}  ="umwelt";
  $sensors->{um_vh_owts01}->{readings}->{temperature}  ->{reading}  ="temperature";
  $sensors->{um_vh_owts01}->{readings}->{temperature}  ->{unit}     ="�C";
  $sensors->{um_vh_owts01}->{readings}->{temperature}  ->{alias}    ="Temperatur";
  
  $sensors->{eg_fl_owts01}->{alias}     ="OWX Flur";
  $sensors->{eg_fl_owts01}->{fhem_name} ="EG_FL_OWTS01.Raum";
  $sensors->{eg_fl_owts01}->{type}      ="OneWire";
  $sensors->{eg_fl_owts01}->{location}  ="eg_flur";
  $sensors->{eg_fl_owts01}->{readings}->{temperature}  ->{reading}  ="temperature";
  $sensors->{eg_fl_owts01}->{readings}->{temperature}  ->{unit}     ="�C";
  $sensors->{eg_fl_owts01}->{readings}->{temperature}  ->{alias}    ="Temperatur";
  
  $sensors->{eg_ku_fk01}->{alias}     ="Fensterkontakt";
  $sensors->{eg_ku_fk01}->{fhem_name} ="EG_KU_FK01.Fenster";
  $sensors->{eg_ku_fk01}->{type}      ="HomeMatic";
  $sensors->{eg_ku_fk01}->{location}  ="kueche";
  $sensors->{eg_ku_fk01}->{readings}->{bat_status}   ->{reading}   ="battery";
  $sensors->{eg_ku_fk01}->{readings}->{bat_status}   ->{alias}     ="Batteriezustand";
  $sensors->{eg_ku_fk01}->{readings}->{bat_status}   ->{unit_type} ="ENUM: ok,low";
  $sensors->{eg_ku_fk01}->{readings}->{cover}        ->{reading}   ="temperature";
  $sensors->{eg_ku_fk01}->{readings}->{cover}        ->{alias}     ="Coverzustand";
  $sensors->{eg_ku_fk01}->{readings}->{cover}        ->{unit_type} ="ENUM: closed,open";
  $sensors->{eg_ku_fk01}->{readings}->{state}        ->{reading}   ="state";
  $sensors->{eg_ku_fk01}->{readings}->{state}        ->{alias}     ="Fensterzustand";
  $sensors->{eg_ku_fk01}->{readings}->{state}        ->{unit_type} ="ENUM: closed,open,tilted";
  #TODO: Mapping f. Zustaende: closed => geschlossen?
  
  $sensors->{eg_wz_fk01}->{alias}     ="Fensterkontakt";
  $sensors->{eg_wz_fk01}->{fhem_name} ="EG_WZ_FK01.Fenster";
  $sensors->{eg_wz_fk01}->{type}      ="HomeMatic";
  $sensors->{eg_wz_fk01}->{location}  ="wohnzimmer";
  $sensors->{eg_wz_fk01}->{readings}->{bat_status}   ->{reading}   ="battery";
  $sensors->{eg_wz_fk01}->{readings}->{bat_status}   ->{alias}     ="Batteriezustand";
  $sensors->{eg_wz_fk01}->{readings}->{bat_status}   ->{unit_type} ="ENUM: ok,low";
  $sensors->{eg_wz_fk01}->{readings}->{cover}        ->{reading}   ="temperature";
  $sensors->{eg_wz_fk01}->{readings}->{cover}        ->{alias}     ="Coverzustand";
  $sensors->{eg_wz_fk01}->{readings}->{cover}        ->{unit_type} ="ENUM: closed,open";
  $sensors->{eg_wz_fk01}->{readings}->{state}        ->{reading}   ="state";
  $sensors->{eg_wz_fk01}->{readings}->{state}        ->{alias}     ="Fensterzustand";
  $sensors->{eg_wz_fk01}->{readings}->{state}        ->{unit_type} ="ENUM: closed,open,tilted";
  
  $sensors->{eg_wz_tk01}->{alias}     ="Terrassent�rkontakt Links";
  $sensors->{eg_wz_tk01}->{fhem_name} ="wz_fenster_l";
  $sensors->{eg_wz_tk01}->{type}      ="HomeMatic";
  $sensors->{eg_wz_tk01}->{location}  ="wohnzimmer";
  $sensors->{eg_wz_tk01}->{readings}->{bat_status}   ->{reading}   ="battery";
  $sensors->{eg_wz_tk01}->{readings}->{bat_status}   ->{alias}     ="Batteriezustand";
  $sensors->{eg_wz_tk01}->{readings}->{bat_status}   ->{unit_type} ="ENUM: ok,low";
  $sensors->{eg_wz_tk01}->{readings}->{cover}        ->{reading}   ="temperature";
  $sensors->{eg_wz_tk01}->{readings}->{cover}        ->{alias}     ="Coverzustand";
  $sensors->{eg_wz_tk01}->{readings}->{cover}        ->{unit_type} ="ENUM: closed,open";
  $sensors->{eg_wz_tk01}->{readings}->{state}        ->{reading}   ="state";
  $sensors->{eg_wz_tk01}->{readings}->{state}        ->{alias}     ="Fensterzustand";
  $sensors->{eg_wz_tk01}->{readings}->{state}        ->{unit_type} ="ENUM: closed,open";

  $sensors->{eg_wz_tk02}->{alias}     ="Terrassent�rkontakt Recht";
  $sensors->{eg_wz_tk02}->{fhem_name} ="wz_fenster_r";
  $sensors->{eg_wz_tk02}->{type}      ="HomeMatic";
  $sensors->{eg_wz_tk02}->{location}  ="wohnzimmer";
  $sensors->{eg_wz_tk02}->{readings}->{bat_status}   ->{reading}   ="battery";
  $sensors->{eg_wz_tk02}->{readings}->{bat_status}   ->{alias}     ="Batteriezustand";
  $sensors->{eg_wz_tk02}->{readings}->{bat_status}   ->{unit_type} ="ENUM: ok,low";
  $sensors->{eg_wz_tk02}->{readings}->{cover}        ->{reading}   ="temperature";
  $sensors->{eg_wz_tk02}->{readings}->{cover}        ->{alias}     ="Coverzustand";
  $sensors->{eg_wz_tk02}->{readings}->{cover}        ->{unit_type} ="ENUM: closed,open";
  $sensors->{eg_wz_tk02}->{readings}->{state}        ->{reading}   ="state";
  $sensors->{eg_wz_tk02}->{readings}->{state}        ->{alias}     ="Fensterzustand";
  $sensors->{eg_wz_tk02}->{readings}->{state}        ->{unit_type} ="ENUM: closed,open";
  
#------------------------------------------------------------------------------
my $actTab;
  $actTab->{"schatten"}->{checkFn}="";
  #$actTab->{"schatten"}->{disabled}="0"; #1=disabled, 0, undef,.. => enabled
  #$actTab->{"schatten"}->{deviceList}=[]; # undef=> alle in devTab, ansonsten nur angegebenen
  $actTab->{"nacht"}->{checkFn}="";
  $actTab->{"test"}->{checkFn}=undef;
#------------------------------------------------------------------------------

my $devTab;
# Default.
  $devTab->{DEFAULT}->{SetFn}="";
  $devTab->{DEFAULT}->{SetFn}="";
  $devTab->{DEFAULT}->{valueFns}->{"nacht"}="0";
# Badezimmer (Ost)
#oder so?
# $devTab->{"bz_rollo"}->{actions}->{schatten}->{valueFn}="{if...}";
# $devTab->{"bz_rollo"}->{actions}->{schatten}->{value}="80"; # valueFn hat Vorrang, wenn sie undef liefert (oder nicht existiert), dann das hier
# $devTab->{"bz_rollo"}->{actions}->{schatten}->{enabledFn}="{if...}";
# $devTab->{"bz_rollo"}->{actions}->{schatten}->{enabled}="true"; # s.o. 
# $devTab->{"bz_rollo"}->{actions}->{schatten}->{valueFilterFn}="{...}"; #nachdem Wert errechnet wurde, pr�ft nochmal, ob dieser ggf. korrigiert werden soll (Grenzen etc. z.B. bei ge�ffneter T�r 'schatten' max. auf X% herunterfahren. etc.)
# Idee: Mehrere Action durch zwischengeschaltete Keys (mehrfach, alphabetisch sortiert): Idee: Wenn hier ein HASH, dann einzelene ausf�hren, ansonstel ist hier die Fn direkt
# $devTab->{"bz_rollo"}->{actions}->{schatten}->{enabledFn}->{DoorOpenCheck}="{if(sensorVal($CURRENT_DEVICE, wndOpen)!='closed') {...}}"; # DoorOpenCheck ist ein solcher Key.
#TODO: Statt FHEM-Namen als Keys die Verweise auf actors-Tab verwenden.
  $devTab->{"bz_rollo"}->{valueFns}->{"schatten"}="{if...}";
  $devTab->{"bz_rollo"}->{SetFn}="";
# Badezimmer (Ost)
  $devTab->{"bz_rollo"}->{valueFns}->{"nacht"}="0";
  $devTab->{"bz_rollo"}->{valueFns}->{"schatten"}="{if...}";
# Kinderzimmer A (Paula) (West)
  $devTab->{"ka_rollo"}->{SetFn}="";
# Kinderzimmer B (Hanna) (Ost)
  $devTab->{"kb_rollo"}->{SetFn}="";
# Kueche (Ost)
  $devTab->{"ku_rollo"}->{SetFn}="";
# Schlafzimmer (West)
  $devTab->{"sz_rollo"}->{SetFn}="";
# Wohnzimmer (West)
  $devTab->{"wz_rollo_l"}->{SetFn}="";
  $devTab->{"wz_rollo_r"}->{SetFn}=""; 

# TODO


#technisches
sub myCtrlProxies_Initialize($$);


# Rooms
sub myCtrlProxies_getRoom($);
#sub myCtrlProxies_getRooms(;$); # R�ume  nach verschiedenen Kriterien?
#sub myCtrlProxies_getActions(;$); # <DevName>

#sub myCtrlProxies_getRoomSensors($);
#sub myCtrlProxies_getRoomOutdoorSensors($);

sub myCtrlProxies_getRoomSensorNames($);
sub myCtrlProxies_getRoomOutdoorSensorNames($);

sub myCtrlProxies_getRoomMeasurementRecord($$);
sub myCtrlProxies_getRoomMeasurementValue($$);


# Sensoren
sub myCtrlProxies_getSensor($);

sub myCtrlProxies_getSensorValueRecord($$);
sub myCtrlProxies_getSensorReadingValue($$);
sub myCtrlProxies_getSensorReadingUnit($$);

#TODO sub myCtrlProxies_getSensors(;$$$$); # <SenName/undef> [<type>][<DevName>][<location>]

# 
#sub myCtrlProxies_getDevices(;$$$);# <DevName/undef>(undef => alles) [<Type>][<room>]


#

require "$attr{global}{modpath}/FHEM/myCtrlHAL.pm";

# Action
sub myCtrlProxies_doAllActions();
sub myCtrlProxies_doAction($$);
sub myCtrlProxies_DeviceSetFn($@);

#------------------------------------------------------------------------------

sub
myCtrlProxies_Initialize($$)
{
  my ($hash) = @_;
}

# Liefert Record zu der Reading f�r die angeforderte Messwerte
# Param Room-Name, Measurement-Name
# return ReadingsRecord
sub myCtrlProxies_getRoomMeasurementRecord($$) {
	my ($roomName, $measurementName) = @_;
	return myCtrlProxies_getRoomMeasurementRecord_($roomName, $measurementName, "");
}

# Liefert Record zu der Reading f�r die angeforderte Messwerte
# Param Room-Name, Measurement-Name
# return ReadingsRecord
sub myCtrlProxies_getRoomOutdoorMeasurementRecord($$) {
	my ($roomName, $measurementName) = @_;
	return myCtrlProxies_getRoomMeasurementRecord_($roomName, $measurementName, "_outdoor");
}

# Liefert Record zu der Reading f�r die angeforderte Messwerte und Sensorliste (Internal)
# Param Room-Name, Measurement-Name, Name der Liste (sensors, sensors_outdoor)
# return ReadingsRecord
sub myCtrlProxies_getRoomMeasurementRecord_($$$) {
	my ($roomName, $measurementName, $listNameSuffix) = @_;
	my $listName.="sensors".$listNameSuffix;
	
	#TODO: EinzelReadings
	
	my $sensorList = myCtrlProxies_getRoomSensorNames_($roomName, $listName);	#myCtrlProxies_getRoomSensorNames($roomName);
	return undef unless $sensorList;
	
	foreach my $sName (@$sensorList) {
		if(!defined($sName)) {next;} 
		my $rec = myCtrlProxies_getSensorValueRecord($sName, $measurementName);
		if(defined $rec) {
			my $roomRec=myCtrlProxies_getRoom($roomName);
			$rec->{room_alias}=$roomRec->{alias};
			$rec->{room_fhem_name}=$roomRec->{fhem_name};
			# XXX: ggf. weitere Room Eigenschaften
			return $rec;
		}
	}
	
	return undef;
}


# Liefert angeforderte Messwerte
# Param Room-Name, Measurement-Name
# return ReadingsWert
sub myCtrlProxies_getRoomMeasurementValue($$) {
	my ($roomName, $measurementName) = @_;
	 
	my $sensorList = myCtrlProxies_getRoomSensorNames($roomName);
	return undef unless $sensorList;
	
	foreach my $sName (@$sensorList) {
		if(!defined($sName)) {next;} 
		my $val = myCtrlProxies_getSensorReadingValue($sName, $measurementName);
		if(defined $val) {return $val;}
	}
	
	return undef;
}

#------------------------------------------------------------------------------
# returns Sensor-Record by name
# Parameter: name 
# record:
#  X->{name}->{alias}     ="Text zur Anzeige etc.";
#  X->{name}->{fhem_name} ="Name in FHEM";
#  X->{name}->{type}      ="Typ f�r Gruppierung und Suche";
#  X->{name}->{location}  ="Zugeh�rigkeit zu einem Raum ($rooms)";
#  X->{name}->{readings}->{<readings_name>} ->{reading}  ="temperature";
#  X->{name}->{readings}->{<readings_name>} ->{unit}     ="�C";
#  ...
sub 
myCtrlProxies_getSensor($)
{
	my ($name) = @_;
	return undef unless $name;
	my $ret = $sensors->{$name};
	$ret->{name} = $name; # Name hinzufuegen
	return $ret;
}

# returns Room-Record by name
# Parameter: name 
# record:
#  X->{name}->{alias}      ="Text zur Anzeige etc.";
#  X->{name}->{fhem_name} ="Text zur Anzeige etc.";
# Definiert nutzbare Sensoren. Reihenfolge gibt Priorit�t an. <= ODER BRAUCHT MAN NUR DIE EINZEL-READING-DEFINITIONEN?
#  X->{name}->{sensors}   =(<Liste der Namen>);
#  X->{name}->{sensors_outdor} =(<Liste der SensorenNamen 'vor dem Fenster'>);
sub myCtrlProxies_getRoom($) {
	my ($name) = @_;
	my $ret = $rooms->{$name};
	$ret->{name} = $name; # Name hinzufuegen
	return $ret;
}

# liefert Liste (Referenz) der Sensors in einem Raum (Liste der Namen)
# Param: Raumname
#  Beispiel:   {myCtrlProxies_getRoomSensorNames("wohnzimmer")->[0]}
sub myCtrlProxies_getRoomSensorNames($)
{
	my ($roomName) = @_;
  return myCtrlProxies_getRoomSensorNames_($roomName,"sensors");	
}

# liefert Liste (Referenz) der Sensors f�r einen Raum draussen (Liste der Namen)
# Param: Raumname
#  Beispiel:  {myCtrlProxies_getRoomSensorNames("wohnzimmer")->[0]}
sub myCtrlProxies_getRoomOutdoorSensorNames($)
{
	my ($roomName) = @_;
  return myCtrlProxies_getRoomSensorNames_($roomName,"sensors_outdoor");	
}

# liefert Referenz der Liste der Sensors in einem Raum (List der Namen)
# Param: Raumname, SensorListName (z.B. sensors, sensors_outdoor)
sub myCtrlProxies_getRoomSensorNames_($$)
{
	my ($roomName, $listName) = @_;
	my $roomRec=myCtrlProxies_getRoom($roomName);
	return undef unless $roomRec;
	my $sensorList=$roomRec->{$listName};
	return undef unless $sensorList;
	
	return $sensorList;
}


#### TODO: Sind die Methoden, die Hashesliste zur�ckgeben �berhaupt notwendig?
## liefert Liste der Sensors in einem Raum (Array of Hashes)
## Param: Raumname
##  Beispiel:  {(myCtrlProxies_getRoomSensors("wohnzimmer"))[0]->{alias}}
#sub myCtrlProxies_getRoomSensors($)
#{
#	my ($roomName) = @_;
#  return myCtrlProxies_getRoomSensors_($roomName,"sensors");	
#}
#
## liefert Liste der Sensors f�r einen Raum draussen (Array of Hashes)
## Param: Raumname
##  Beispiel:  {(myCtrlProxies_getRoomOutdoorSensors("wohnzimmer"))[0]->{alias}}
#sub myCtrlProxies_getRoomOutdoorSensors($)
#{
#	my ($roomName) = @_;
#  return myCtrlProxies_getRoomSensors_($roomName,"sensors_outdoor");	
#}
#
## liefert Liste der Sensors in einem Raum (Array of Hashes)
## Param: Raumname, SensorListName (z.B. sensors, sensors_outdoor)
#sub myCtrlProxies_getRoomSensors_($$)
#{
#	my ($roomName, $listName) = @_;
#	my $roomRec=myCtrlProxies_getRoom($roomName);
#	return undef unless $roomRec;
#	my $sensorList=$roomRec->{$listName};
#	return undef unless $sensorList;
#	
#	my @ret;
#	foreach my $sName (@{$sensorList}) {
#		my $sRec = myCtrlProxies_getSensor($sName);
#		push(@ret, \%{$sRec}) if $sRec ;
#	}
#	
#	return @ret;
#}
## <---------------



sub myCtrlProxies_getSensorReadingCompositeRecord_intern($$);
# sucht gew�nschtes reading zu dem angegebenen device, folgt den in {composite} definierten (Unter)-Devices.
# liefert Device und Reading Recors als Array 
sub
myCtrlProxies_getSensorReadingCompositeRecord_intern($$)
{
	my ($device_record,$reading) = @_;
	return (undef, undef) unless $device_record;
	return (undef, undef) unless $reading;
	
	my $readings_record = $device_record->{readings};
	my $single_reading_record = $readings_record->{$reading};
	return ($device_record, $single_reading_record) if $single_reading_record;
	
	# composites verarbeiten
	# e.g.  $sensors->{wz_wandthermostat}->{composite} =("wz_wandthermostat_climate"); 
	my $composites = $device_record->{composite};

	foreach my $composite_name (@{$composites}) {
		my $new_device_record = myCtrlProxies_getSensor($composite_name);
		my ($new_device_record2, $new_single_reading_record) = myCtrlProxies_getSensorReadingCompositeRecord_intern($new_device_record,$reading);
		if(defined($new_single_reading_record )) {
			return ($new_device_record2, $new_single_reading_record);
		}
	}
	
	return (undef, undef);
}

# parameters: name, reading name
# liefert Array mit Device und Reading -Hashes
# record:
#  X->{reading} = "<fhem_device_reading_name>";
#  X->{unit} = "";
sub 
myCtrlProxies_getSensorReadingRecord($$)
{
	my ($name, $reading) = @_;
	my $record = myCtrlProxies_getSensor($name);
	
	if(defined($record)) {
    return myCtrlProxies_getSensorReadingCompositeRecord_intern($record,$reading);
  }
	return (undef, undef);
}

# Sucht den Gewuenschten SensorDevice und liest den gesuchten Reading aus
# parameters: name, reading name
# returns Hash mit Werten zu dem gewuenschten Reading
# X->{value}
# X->{time} # Timestamp der letzten Value Aenderung
# X->{unit}
# X->{alias} # if any
# X->{fhem_name}
# X->{reading}
# X->...
sub myCtrlProxies_getSensorValueRecord($$)
{
	my ($name, $reading) = @_;
  # Sensor/Reading-Record suchen
  my ($device, $record) = myCtrlProxies_getSensorReadingRecord($name,$reading);
  
  return myCtrlProxies_getReadingsValueRecord($device, $record);
  
	#if (defined($record)) {
	#  my $fhem_name = $device->{fhem_name};
  #  my $reading_fhem_name = $record->{reading};
  #
  #  my $val = ReadingsVal($fhem_name,$reading_fhem_name,undef); 
  #  my $ret;
  #  $ret->{value}     =$val;
  #  $ret->{unit}      =$record->{unit};
  #  $ret->{alias}     =$record->{alias};
  #  $ret->{fhem_name} =$device->{fhem_name};
  #  $ret->{reading}   =$record->{reading};
  #  #$ret->{sensor_alias} =$
  #  $ret->{device_alias} =$device->{alias};
  #  return $ret;
	#}
	#return undef;
}

# Nur zum Testen! DELETE ME
sub senTest($;$) {
  my($hash,$device) = @_;
  #return $hash->{FnParams}->[0];
  #return $hash->{FnParams};
  my $w = $hash->{FnParams};
  return "Sen. name: '".$device->{name}."', Params: '".join(", ", @$w)."'";
}

# Liefert ValueRecord (ermittelter Wert und andere SensorReadingDaten)
# Param: Device-Hash, Reading-Hash
# Return: Value-Hash
sub myCtrlProxies_getReadingsValueRecord($$) {
	my ($device, $record) = @_;
	
	if (defined($record)) {
		my $val=undef;
		my $time=undef;
		my $ret;
		
		my $link = $record->{link};
		if($link) {
			my($sensorName,$readingName) = split(/:/, $link);
			$sensorName = $device->{name} unless $sensorName; # wenn nichts angegeben (vor dem :) dann den Sensor selbst verwenden (Kopie eigenes Readings)
			return undef unless $readingName;
			return myCtrlProxies_getSensorValueRecord($sensorName,$readingName);
		} 
		
		my $valueFn =  $record->{ValueFn};
		if($valueFn) {
	    if($valueFn=~m/\{.*\}/) {
	    	# Klammern: direkt evaluieren
	      $val= eval $valueFn;	
	    } else {
	    	no strict "refs";
        my $r = &{$valueFn}($device,$record);
        use strict "refs";
        if(ref $r eq ref {}) {
        	# wenn Hash
        	$ret = $r;
        } else {
        	# Scalar-Wert annehmen
        	$val=$r;
        }
	    }
			#TODO
			#$val="not implemented";
			
		}
		else
		{
	    my $fhem_name = $device->{fhem_name};
      my $reading_fhem_name = $record->{reading};

      $val = ReadingsVal($fhem_name,$reading_fhem_name,undef);
      $time = ReadingsTimestamp($fhem_name,$reading_fhem_name,undef);
      #Log 3,"+++++++++++++++++> Name: ".$fhem_name." Reading: ".$reading_fhem_name." =>VAL:".$val;
    }
    
    $ret->{value}     =$val if(defined $val);
    # dead or alive?
    $ret->{status} = 'unknown';
    my $actCycle = $record->{act_cycle};
    $actCycle = 0 unless defined $actCycle;
    my $iactCycle = int($actCycle);
    if(defined $actCycle && $iactCycle == 0) {
      $ret->{status} = 'alive'; # wenn actCycle == 0 immer alive
    }
    if($time) {
      $ret->{time} = $time;
      if($actCycle && $iactCycle > 0) {
        my $ttime = dateTime2dec($time);
        if($ttime && $ttime>0) {
      	  my $delta = time()-$ttime;
      	  if($delta>$iactCycle) {
      	  	$ret->{status} = 'dead';
      	  } else {
      	  	$ret->{status} = 'alive';
      	  }
        }
      }
    }
    # 'bool' zum Auswerten
    $ret->{alive} = $ret->{status} eq 'alive';
    
    # value_alive nur setzen, wenn Sensor 'alive' ist.
    if ($ret->{alive}) {
      $ret->{value_alive} = $ret->{value};
    } else {
    	$ret->{value_alive} = undef;
    }
    
    $ret->{unit}      =$record->{unit};
    $ret->{alias}     =$record->{alias};
    $ret->{fhem_name} =$device->{fhem_name};
    $ret->{reading}   =$record->{reading};
    #$ret->{sensor_alias} =$
    $ret->{device_alias} =$device->{alias};
    return $ret;
	}
	return undef;
}

# Sucht den Gewuenschten SensorDevice und liest den gesuchten Reading aus
# parameters: name, reading name
# returns current readings value
sub myCtrlProxies_getSensorReadingValue($$)
{
	my ($name, $reading) = @_;
	my $h = myCtrlProxies_getSensorValueRecord($name, $reading);
	return undef unless $h;
	return $h->{value};
}

# Sucht den Gewuenschten SensorDevice und liest zu dem gesuchten Reading das Unit-String aus
# parameters: name, reading name
# returns readings unit
sub myCtrlProxies_getSensorReadingUnit($$)
{
	my ($name, $reading) = @_;
	my $h = myCtrlProxies_getSensorValueRecord($name, $reading);
	return undef unless $h;
	return $h->{unit};
	
	# Sensor/Reading-Record suchen
	my ($device, $record) = myCtrlProxies_getSensorReadingRecord($name,$reading);
	if (defined($record)) {
	  return $record->{unit};
	}
	return undef;
}


#------------------------------------------------------------------------------

#- Steuerung fuer manuelle Aufrufe (AT) ---------------------------------------

###############################################################################
# Alle Aktionen aus der Tabelle ausfuehren.
# (f�r alle Devices, solange nicht anders definiert) 
###############################################################################
sub
myCtrlProxies_doAllActions() {
	Main:Log 3, "PROXY_CTRL:--------> do all ";
	foreach my $act (keys %{$actTab}) {
		my $cTab = $actTab->{$act};
		myCtrlProxies_doAction($cTab, $act);
	}
}

###############################################################################
# Eine bestimmte Aktion ausfuehren.
# (f�r alle Devices, solange nicht anders definiert) 
###############################################################################
sub
myCtrlProxies_doAction($$) {
	my ($cTab, $actName) = @_;
	
	Log 3, "PROXY_CTRL:--------> do ".$actName;
	
	my $disabled = $cTab->{disabled}; # undef => enabled
	Log 3, "PROXY_CTRL:--------> act ".$actName." disabled:".$disabled;
	if(defined($disabled) && $disabled eq '1') { return }; # wenn disabled => raus
	
	my $checkFn = $cTab->{checkFn}; # undef => ausf�hren
	Log 3, "PROXY_CTRL:--------> act ".$actName." checkFn:".$checkFn;
	if(defined($checkFn)) {
		my $valueFn = eval $checkFn;
		if(!defined($valueFn)) { return }; # wenn undef => raus
    if( !$valueFn ) { return }; # wenn false => raus
	}
	
	my @devList = $cTab->{deviceList}; # undef => f�r alle ausf�hren
	Log 3, "PROXY_CTRL:--------> act ".$actName." deviceList: ".@devList;
	if(@devList) {
	 	foreach my $dev (@devList) {
	 		Log 3, "PROXY_CTRL:--------> act ".$actName." device:".$dev;
		  myCtrlProxies_DeviceSetFn($dev, $actName);
	  }
	} else {
	  foreach my $dev (keys %{$devTab}) {     
	  	Log 3, "PROXY_CTRL:--------> act ".$actName." device:".$dev;
  	  if($dev ne 'DEFAULT') {
  	  	myCtrlProxies_DeviceSetFn($dev, $actName, "www"); #?
  	  }
    }
	}
}                                              

#- Steuerung aus ReadingProxy -------------------------------------------------

###############################################################################
# Eine bestimmte (Set-)Aktion f�r ein bestimmtes Ger�t ausfuehren.
# (Commando kann gefiltert und ver�ndert werden, 
# d.h. ggf. nicht oder anders ausgef�hrt)
# Beispiel: Befehl 'schatten' f�r Rolladen: es wird gepr�ft (f�r jedes Rollo
# einzeln) ob die Ausf�hrung notwendig ist (richtige Tageszeit?, Temperatur? 
# starke Sonneneinstrahlung?, aus richtiger Richtung?)
# und auch wie stark (wie weit soll Rollo heruntergefahren werden).
###############################################################################
sub
myCtrlProxies_DeviceSetFn($@) {
	my ($DEVICE,@a) = @_;
	my $CMD = $a[0];
  my $ARGS = join(" ", @a[1..$#a]);
  
  #TODO
  Log 3, "PROXY_CTRL:--------> set ".$DEVICE." - ".$CMD." - ".$ARGS;
  my $cmdFn = $devTab->{$DEVICE}->{valueFns}->{$CMD}; #TODO
  if(defined($cmdFn)) {
  	# TODO
  } else {
    return;
  }
}

# Zur Verwendung in ReadingProxy. Pr�ft (transparent) ob und wie ein Befehl ausgef�hrt werden soll.
# TODO
sub
myCtrlProxies_SetProxyFn($@) {
	my ($DEVICE,@a) = @_;
	my $CMD = $a[0];
  my $ARGS = join(" ", @a[1..$#a]);
  
  #TODO
  Log 3, "PROXY_CTRL:--------> set ".$DEVICE." - ".$CMD." - ".$ARGS;
  my $cmdFn = $devTab->{$DEVICE}->{valueFns}->{$CMD};
  if(defined($cmdFn)) {
  	# TODO
  } else {
    return ""; # pass through cmd to device
  }
}

1;
