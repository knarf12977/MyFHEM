###############################################################################
#
# FHEM-Modul (see www.fhem.de)
# 36_GSD.pm
# GenericSmartDevice: sensor data receiver
#
# Usage: define  <Name> GSD <Node-Nr>
#   Example: define GSD_1.1 GSD 1.1
#   (or use autocreate)
#
###############################################################################
#
#  Copyright notice
#
#  (c) 2013 Alexander Schulz
#
#  This script is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  The GNU General Public License can be found at
#  http://www.gnu.org/copyleft/gpl.html.
#  A copy is found in the textfile GPL.txt and important notices to the license
#  from the author is found in LICENSE.txt distributed with these scripts.
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  This copyright notice MUST APPEAR in all copies of the script!
#
###############################################################################

# $Id$

package main;
use strict;
use warnings;
use POSIX;
use Data::Dumper;
use vars qw(%defs);
use vars qw(%attr);
use vars qw(%data);
use vars qw(%modules);

my $GSD_MAGIC = 83; # ErkennungsByte

my $VERSION = "0.1.1";

#------------------------------------------------------------------------------
sub GSD_Initialize($)
{
  my ($hash) = @_;

  # Match/Prefix
  my $match = "GSD";
  $hash->{Match}     = "^GSD";
  $hash->{FingerprintFn} = "GSD_Fingerprint";
  $hash->{DefFn}     = "GSD_Define";
  $hash->{UndefFn}   = "GSD_Undefine";
  $hash->{ParseFn}   = "GSD_Parse";
  
  $hash->{GetFn}    = "GSD_Get";
  $hash->{SetFn}    = "GSD_Set";
  $hash->{AttrFn}   = "GSD_Attr";
  
  $hash->{AttrList}  = "disable:0,1".
                       $readingFnAttributes;
  #----------------------------------------------------------------------------
  #
  # Arduino/JeeNodes-Variables:
  # http://arduino.cc/en/Reference/HomePage
  # Integer = 2 Bytes -> form -32,768 to 32,767
  # Long (unsigned) = 4 Bytes -> from 0 to 4,294,967,295
  # Long (signed) = 4 Bytes -> from -2,147,483,648 to 2,147,483,647
  #
  #
  #----------------------------------------------------------------------------
  #
  # Message-Format:
  #   GSD NodeID(1Byte) Magic(1Byte) SubNodeID(1Byte) MsgCounter(2Bytes) [Payload](NBytes)
  # Payload-Format:
  #   TypeID(1Byte) [Data](NBytes)
  #
  #
  #
# 
# Typ-Byte-Aufbau: Einfach eine TypeID (0-255). 
#                  Manche Werte sind reserviert, manche identifizieren Sensoren gleicher Art.
#                  Damit wird es z.B. m�glich, mehrere Temperaturwerte zu �bermitteln.
# 000-015   reserved / unused
#
# 016-127  Default
#   16-23  (8)  Temperatur
#   24-31  (8)  Luftfeuchte
#   32-39  (8)  Lichtintensit�t
#   40-47  (8)  Motion
#   48-49  (2)  Luftdruck
#   50-51  (2)  Regen (Zustand)
#   52-53  (2)  Regenmenge
#   54-61  (8)  Bodenfeuchte
#   62-63  (2)  Windst�rke
#   64-65  (2)  Windrichtung
#   66-73  (8)  reserved / Luft (CO, CO2,..)
#   74-81  (8)  Distance
#   82-85  (4)  Neigung
#   86-93  (8)  ADC Spannungsmessung
#   094-101(8)  ADC Strommessung
#   102-103(2)  Energiez�hler
#   104-105(2)  Wasserz�hler
#   106-109(4)  Counter32
#   110-113(4)  Counter24
#   114-117(4)  Counter16
#   118-125(8)  State (Kontakte/Melder: Reed, Fenster (auch 3state) etc.)
#   126-127(2)  Prozentwerte (xx,xx: F�llstand etc.)
# 
# 128-143 reserved
#
# 144-201 Undefined (User defined)
#
# 202-255 reserved / internal
#   202     power supply : main
#   203     _reserved / power supply
#   204     _reserved / power supply
#   205     _reserved / power supply
#   206     _reserved
#   207     _reserved
#   208     _reserved
#   209     _reserved
#   210     low bat warning : main
#   211     _reserved
#   212     _reserved
#   213     _reserved
#   214     _reserved
#   215     _reserved
#   216     _reserved
#   217     _reserved
#   218     time millis : current
#   219     _reserved
#   220     _reserved
#   221     _reserved
#   222     _reserved
#   223     _reserved
#   224     _reserved
#   225     _reserved
#   226     system temperature : main
#   227     _reserved
#   228     _reserved
#   229     _reserved
#   230     _reserved
#   231     _reserved
#   232     _reserved
#   233     _reserved
#   234     Bereich INTERNAL:    Textnachricht in Form key:value
#   235     Bereich READINGS:    Textnachricht in Form key:value
#   236     Bereich ATTRINBUTES: Textnachricht in Form key:value
#   237     _reserved / Textnachricht
#   238     _reserved
#   239     _reserved
#   240     _reserved
#   241     _reserved
#   242-255 _reserved
#
# 
#
  #
  # Config: Sensor-Format
  #
  # --- 16-23 (8) --- Temperatur -------------------------
  $data{GSCONF}{16}{ReadingName} = "temperature";
  $data{GSCONF}{16}{DataLength} = 2;
  $data{GSCONF}{16}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{17}{ReadingName} = "temperature1";
  $data{GSCONF}{17}{DataLength} = 2;
  $data{GSCONF}{17}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{18}{ReadingName} = "temperature2";
  $data{GSCONF}{18}{DataLength} = 2;
  $data{GSCONF}{18}{CorrFactor} = 0.01;
  # ---  
  $data{GSCONF}{19}{ReadingName} = "temperature3";
  $data{GSCONF}{19}{DataLength} = 2;
  $data{GSCONF}{19}{CorrFactor} = 0.01;
  # ---  
  $data{GSCONF}{20}{ReadingName} = "temperature4";
  $data{GSCONF}{20}{DataLength} = 2;
  $data{GSCONF}{20}{CorrFactor} = 0.01;
  # ---  
  $data{GSCONF}{21}{ReadingName} = "temperature5";
  $data{GSCONF}{21}{DataLength} = 2;
  $data{GSCONF}{21}{CorrFactor} = 0.01;
  # ---  
  $data{GSCONF}{22}{ReadingName} = "temperature6";
  $data{GSCONF}{22}{DataLength} = 2;
  $data{GSCONF}{22}{CorrFactor} = 0.01;
  # ---  
  $data{GSCONF}{23}{ReadingName} = "temperature7";
  $data{GSCONF}{23}{DataLength} = 2;
  $data{GSCONF}{23}{CorrFactor} = 0.01;
  # --- 24-31 (8) --- Luftfeuchte ------------------------
  $data{GSCONF}{24}{ReadingName} = "humidity";
  $data{GSCONF}{24}{DataLength} = 2;
  $data{GSCONF}{24}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{25}{ReadingName} = "humidity1";
  $data{GSCONF}{25}{DataLength} = 2;
  $data{GSCONF}{25}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{26}{ReadingName} = "humidity2";
  $data{GSCONF}{26}{DataLength} = 2;
  $data{GSCONF}{26}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{27}{ReadingName} = "humidity3";
  $data{GSCONF}{27}{DataLength} = 2;
  $data{GSCONF}{27}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{28}{ReadingName} = "humidity4";
  $data{GSCONF}{28}{DataLength} = 2;
  $data{GSCONF}{28}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{29}{ReadingName} = "humidity5";
  $data{GSCONF}{29}{DataLength} = 2;
  $data{GSCONF}{29}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{30}{ReadingName} = "humidity6";
  $data{GSCONF}{30}{DataLength} = 2;
  $data{GSCONF}{30}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{31}{ReadingName} = "humidity7";
  $data{GSCONF}{31}{DataLength} = 2;
  $data{GSCONF}{31}{CorrFactor} = 0.01;
  # --- 32-39 (8) --- Lichtintensit�t --------------------
  $data{GSCONF}{32}{ReadingName} = "brightness";
  $data{GSCONF}{32}{DataLength} = 4;
  $data{GSCONF}{32}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{33}{ReadingName} = "brightness1";
  $data{GSCONF}{33}{DataLength} = 4;
  $data{GSCONF}{33}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{34}{ReadingName} = "brightness2";
  $data{GSCONF}{34}{DataLength} = 4;
  $data{GSCONF}{34}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{35}{ReadingName} = "brightness3";
  $data{GSCONF}{35}{DataLength} = 4;
  $data{GSCONF}{35}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{36}{ReadingName} = "brightness4";
  $data{GSCONF}{36}{DataLength} = 4;
  $data{GSCONF}{36}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{37}{ReadingName} = "brightness5";
  $data{GSCONF}{37}{DataLength} = 4;
  $data{GSCONF}{37}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{38}{ReadingName} = "brightness6";
  $data{GSCONF}{38}{DataLength} = 4;
  $data{GSCONF}{38}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{39}{ReadingName} = "brightness7";
  $data{GSCONF}{39}{DataLength} = 4;
  $data{GSCONF}{39}{CorrFactor} = 0.01;
  # --- 40-47 (8) --- Motion -----------------------------
  $data{GSCONF}{40}{ReadingName} = "motion";
  $data{GSCONF}{40}{DataLength} = 1;
  # ---
  $data{GSCONF}{41}{ReadingName} = "motion1";
  $data{GSCONF}{41}{DataLength} = 1;
  # ---
  $data{GSCONF}{42}{ReadingName} = "motion2";
  $data{GSCONF}{42}{DataLength} = 1;
  # ---
  $data{GSCONF}{43}{ReadingName} = "motion3";
  $data{GSCONF}{43}{DataLength} = 1;
  # ---
  $data{GSCONF}{44}{ReadingName} = "motion4";
  $data{GSCONF}{44}{DataLength} = 1;
  # ---
  $data{GSCONF}{45}{ReadingName} = "motion5";
  $data{GSCONF}{45}{DataLength} = 1;
  # ---
  $data{GSCONF}{46}{ReadingName} = "motion6";
  $data{GSCONF}{46}{DataLength} = 1;
  # ---
  $data{GSCONF}{47}{ReadingName} = "motion7";
  $data{GSCONF}{47}{DataLength} = 1;
  # --- 48-49 (2) --- Luftdruck --------------------------
  $data{GSCONF}{48}{ReadingName} = "pressure";
  $data{GSCONF}{48}{DataLength} = 4;
  $data{GSCONF}{48}{CorrFactor} = 0.01;
  # ---
  $data{GSCONF}{49}{ReadingName} = "pressure0";
  $data{GSCONF}{49}{DataLength} = 4;
  $data{GSCONF}{49}{CorrFactor} = 0.01;
  # --- 50-51 (2) --- Regen (Zustand) --------------------
  # TODO
  # --- 52-53 (2) --- Regenmenge -------------------------
  # TODO
  # --- 54-61 (8) --- Bodenfeuchte -----------------------
  # TODO
  # --- 62-63 (2) --- Windst�rke -------------------------
  # TODO
  # --- 64-65 (2) --- Windrichtung -----------------------
  # TODO
  # --- 66-73 (8) --- reserved / Luft (CO, CO2,..) -------
  # TODO
  # --- 74-81 (8) --- Distance ---------------------------
  # TODO
  # --- 82-85 (4) --- Neigung ----------------------------
  # TODO
  # --- 86-93 (8) --- ADC Spannungsmessung ---------------
  # TODO
  # --- 094-101(8) -- ADC Strommessung -------------------
  # TODO
  # --- 102-103(2) -- Energiez�hler ----------------------
  # TODO
  # --- 104-105(2) -- Wasserz�hler -----------------------
  # TODO
  # --- 106-109(4) -- Counter32 --------------------------
  # TODO
  # --- 110-113(4) -- Counter24 --------------------------
  # TODO
  # --- 114-117(4) -- Counter16 --------------------------
  # TODO
  # --- 118-125(8) -- State (Kontakte/Melder: Reed, Fenster (auch 3state) etc.)
  # TODO
  # --- 126-127(2) -- Prozentwerte (xx,xx: F�llstand etc.)
  # TODO
  #
  #
  # 128-143 reserved
  #
  # 144-201 Undefined (User defined)
  #
  # 202-255 reserved / internal
  #
  # --- 202 --- power supply : main ----------------------
  $data{GSCONF}{202}{ReadingName} = "power_main";
  $data{GSCONF}{202}{DataLength} = 2;
  $data{GSCONF}{202}{CorrFactor} = 0.001;
  # --- 203-205 reserved / power supply
  # --- 206-209 reserved
  # --- 210 --- low bat warning : main -------------------
  $data{GSCONF}{210}{ReadingName} = "battery";
  $data{GSCONF}{210}{DataLength} = 1;
  # --- 211-217 reserved
  # --- 218 --- time millis : current --------------------
  $data{GSCONF}{218}{ReadingName} = "timemillis";
  $data{GSCONF}{218}{DataLength} = 4;
  # --- 219-225 reserved
  # --- 226 --- system temperature : main ----------------
  # --- 227-233 reserved
  # --- 234 --- Bereich INTERNAL:    Textnachricht in Form key:value
  # TODO
  # --- 235 --- Bereich READINGS:    Textnachricht in Form key:value
  # TODO
  # --- 236 --- Bereich ATTRINBUTES: Textnachricht in Form key:value
  # TODO
  # --- 237 --- reserved / Textnachricht
  # --- 238-241 reserved
  #
  # 242-255 reserved
  #
  
  # 
  # $data{JEECONF}{<SensorType>}{ReadingName} => Reading-Name
  # $data{JEECONF}{<SensorType>}{DataBytes=>DataLength}   => Laenge des Datenbereiches
  # $data{JEECONF}{<SensorType>}{Prefix}      => Wozu?
  # $data{JEECONF}{<SensorType>}{CorrFactor}  => Multiplikator (vlue wird damit multipliziert)
  # $data{JEECONF}{<SensorType>}{CorrOffset}  => wird zum value hinzuaddiert
  # $data{JEECONF}{<SensorType>}{ConvertFn}   => Funktion zum Interpretieren von Sensor-Data-Array (ansonsten wird die Standardparsefunktion verwendet)
  # $data{JEECONF}{<SensorType>}{Function=>ParseFn}    => Parsefunktion, falls sich die Standard-Funktion gar nicht eignet
  # $data{JEECONF}{<SensorType>}{FormatStr}   => Formatstring f�r sprintf
  # $data{JEECONF}{<SensorType>}{FormatFn}    => Format-Funktion    
  
  # <SensorType>: 0-9 -> Reserved/not Used
  # <SensorType>: 10-99 -> Default
  # <SensorType>: 100-199 -> Userdifined
  # <SensorType>: 200-255 -> Internal/Test
  # Default-2-Bytes-------------------------------------------------------------
  $data{JEECONF}{12}{ReadingName} = "SensorData";
  $data{JEECONF}{12}{DataBytes} = 2;
  $data{JEECONF}{12}{Prefix} = $match;
  # Temperature ----------------------------------------------------------------
  $data{JEECONF}{11}{ReadingName} = "temperature";
  $data{JEECONF}{11}{DataBytes} = 2;
  $data{JEECONF}{11}{Prefix} = $match;
  $data{JEECONF}{11}{CorrFactor} = 0.01;
  # Brightness- ----------------------------------------------------------------
  $data{JEECONF}{12}{ReadingName} = "brightness";
  $data{JEECONF}{12}{DataBytes} = 4;
  $data{JEECONF}{12}{Prefix} = $match;
  # Triple-Axis-X-Y-Z----------------------------------------------------------
  $data{JEECONF}{13}{ReadingName} = "rtiple_axis";
  $data{JEECONF}{13}{Function} = "GSD_parse_12";
  $data{JEECONF}{13}{DataBytes} = 12;
  $data{JEECONF}{13}{Prefix} = $match;
  #-----------------------------------------------------------------------------
  # 14 Used by 18_JME
  # Counter --------------------------------------------------------------------
  # $data{JEECONF}{14}{ReadingName} = "counter";
  # $data{JEECONF}{14}{DataBytes} = 4;
  # $data{JEECONF}{14}{Prefix} = $match;
  # Pressure -------------------------------------------------------------------
  $data{JEECONF}{15}{ReadingName} = "pressure";
  $data{JEECONF}{15}{DataBytes} = 4;
  $data{JEECONF}{15}{CorrFactor} = 0.01;
  $data{JEECONF}{15}{Prefix} = $match;
  # Humidity -------------------------------------------------------------------
  $data{JEECONF}{16}{ReadingName} = "humidity";
  $data{JEECONF}{16}{DataBytes} = 2;
  $data{JEECONF}{16}{CorrFactor} = 0.01;
  $data{JEECONF}{16}{Prefix} = $match;
  # Light LDR ------------------------------------------------------------------
  $data{JEECONF}{17}{ReadingName} = "light_ldr";
  $data{JEECONF}{17}{DataBytes} = 1;
  $data{JEECONF}{17}{Prefix} = $match;
  # Motion ---------------------------------------------------------------------
  $data{JEECONF}{18}{ReadingName} = "motion";
  $data{JEECONF}{18}{DataBytes} = 1;
  $data{JEECONF}{18}{Prefix} = $match;
  # JeeNode InternalTemperatur -------------------------------------------------
  $data{JEECONF}{251}{ReadingName} = "AtmelTemp";
  $data{JEECONF}{251}{DataBytes} = 2;
  $data{JEECONF}{251}{Prefix} = $match;
  # JeeNode InternalRefVolatge -------------------------------------------------
  $data{JEECONF}{252}{ReadingName} = "PowerSupply";
  $data{JEECONF}{252}{DataBytes} = 2;
  $data{JEECONF}{252}{CorrFactor} = 0.001;
  $data{JEECONF}{252}{Prefix} = $match;
  # JeeNode RF12 LowBat --------------------------------------------------------
  $data{JEECONF}{253}{ReadingName} = "RF12LowBat";
  $data{JEECONF}{253}{DataBytes} = 1;
  $data{JEECONF}{253}{Prefix} = $match;
  # JeeNode Milliseconds -------------------------------------------------------
  $data{JEECONF}{254}{ReadingName} = "Millis";
  $data{JEECONF}{254}{DataBytes} = 4;
  $data{JEECONF}{254}{Prefix} = $match;

}

sub
GSD_Fingerprint($$)
{
  my ($name, $msg) = @_;
  # => Message ID (Counter) einf�hren. Diese als Duplikate einstufen (z.B. Doppel-Empfang von 2 JeeLinks)
  
  # Keine Messages als Duplikate einstufen.
  # (es k�nnen ja auch wirklich die gleichen Werte sein)
  # ggf. sp�ter die Message ID (gibt es noch nicht), NodeId und sNodeId auswerten.
  # (=> msg manupiulieren, s. 00_CUL.pm)
  return ($name, undef);
}

#-------------------------------------------------------------------------------
sub GSD_Define($){
  # define GSD_1.1 GSD 1.1
  my ($hash, $def) = @_;
  my @a = split(/\s+/, $def);
  return "Usage: define <name> GSD NetID.NodeID"  if(int(@a) != 3);
  my $NodeID = $a[2];
  if(defined($modules{GSD}{defptr}{$NodeID})) {
    return "Node $NodeID allready defined";
  }
  #$hash->{CODE} = $NodeID;
  $hash->{STATE} = "Initialized: " . TimeNow();
  #$hash->{OrderID} = $NodeID;
  $hash->{NODE_ID} = $NodeID;
  $modules{GSD}{defptr}{$NodeID}   = $hash;
  # TODO: ? ERRCOUNT, IODev,.. rssi,.. Bei Attributen: IODev?, model?, Version?, Activity?
  return undef;
}

#-------------------------------------------------------------------------------
sub GSD_Undefine($$){
  my ($hash, $name) = @_;
  Log 4, "GSD Undef: " . Dumper(@_);
  my $NodeID = $hash->{NODE_ID};
  if(defined($modules{GSD}{defptr}{$NodeID})) {
    delete $modules{GSD}{defptr}{$NodeID}
  }
  return undef;
}

#-------------------------------------------------------------------------------
sub GSD_Parse($$) {
  my ($hash, $rawmsg) = @_;
  # rawmsg =  GSD 1 83 1 252 241 15 11 172 8 16 66 19
  Log 3, "GSD: parse RAW message: " . $rawmsg . " IODev: " . $hash->{NAME};
  my @msg_data = split(/\s+/, $rawmsg);
  my $NodeID = $msg_data[1].".".$msg_data[3];
  my $magic = $msg_data[2];
  if($magic eq $GSD_MAGIC) {
    my ($dev_hash,$dev_name);
    if(defined($modules{GSD}{defptr}{$NodeID})) {
      $dev_hash =  $modules{GSD}{defptr}{$NodeID};
      $dev_name = $dev_hash->{NAME};
    } else {
      return "UNDEFINED GSD_$NodeID GSD $NodeID";
    };
  
    my $data_len = int(@msg_data);
    
    my $dMap;
    $dMap->{INDEX} = 4; # erster Byte der eigentlichen Nachricht
    @{$dMap->{DATA}} = @msg_data; # message data
    my $rMap;
    $dMap->{READINGS} = $rMap; # readings
    
    my $index_old = $dMap->{INDEX};
    while ($dMap->{INDEX} < $data_len) {
      #my $msg_data = $dMap->{DATA};
      #my $data_index = $dMap->{INDEX};
      my $msg_type = $msg_data[$dMap->{INDEX}];
      if(defined($data{JEECONF}{$msg_type}{ReadingName})) {
        if(defined($data{JEECONF}{$msg_type}{Function})) {
          my $func = $data{JEECONF}{$msg_type}{Function};
          if(!defined(&$func)) {
            # Function nicht bekannt
            Log 0, "GSD: ERROR: parse function not defined: $msg_type -> $func";
            return undef;
          }
          no strict "refs";
          $dMap = &$func($dMap);
          use strict "refs";
        } else {
          $dMap = GSD_parseDefault($hash, $dMap);
        }
        if (!defined($dMap)) {
          # Function hat Abbruch-Kennzeichen geliefert (es wir alles oder nichts verarbeitet)
          log 0, "GSD: ERROR: parse function failure";
          return undef;
        }
        #$data_index = $dMap->{INDEX};
      } else {
        # Nachricht ungueltig => abbruch
        Log 3, "GSD: ERROR: parse failure. unknown message type: " . $msg_type;
        return undef;
      }
      if($index_old == $dMap->{INDEX}) {
        # Index nicht versetzt, Function falsch / nicht ausgef�hrt
        Log 0, "GSD: ERROR: parse function failure. index not modified. message type: " . $msg_type;
        return undef;
      }
      $index_old = $dMap->{INDEX};  
    }
    
    # Readings erstellen / updaten
    Log 3, "GSD: update readings for $dev_name";
    my @readings_keys=keys($dMap->{READINGS});
    if(scalar(@readings_keys)>0) {
      readingsBeginUpdate($dev_hash);
      foreach my $reading (sort @readings_keys) {
        my $val = $dMap->{READINGS}->{$reading};
        Log 3, "GSD: update $dev_name $reading: " . $val;
        readingsBulkUpdate($dev_hash, $reading, $val);
        #readingsSingleUpdate($dev_hash, $reading, $val, 1);
      }
      readingsEndUpdate($dev_hash, 1);
      
      # Mitteilen, dass sich die Readings der aktuellen Instanz geaendert haben.
      my @list;
      push(@list, $dev_name);
      return @list;
    }
    
  } else {
    # Falsche MagicNumber
    DoTrigger($hash->{NAME}, "UNKNOWNCODE $rawmsg");
    Log3 $hash->{NAME}, 3, "$hash->{NAME}: Unknown code $rawmsg, help me!";
    return undef;
  }
  
  return undef;
}

#------------------------------------------------------------------------------
sub GSD_parseDefault($$) {
  my ($hash, $dMap) = @_;
  
  #Log 3, "GSD: default parse function. data: " . join(" ",@{$dMap->{DATA}});
  
  my @msg_data = @{$dMap->{DATA}};
  my $data_index = $dMap->{INDEX};
  my $msg_type = @msg_data[$data_index];
  
  Log 3, "GSD: default parse function. index: " . $data_index . " msg type: " . $msg_type;
   
  my $msg_len = $data{JEECONF}{$msg_type}{DataBytes};
  if(defined($msg_len)) {
    my $reading_name = $data{JEECONF}{$msg_type}{ReadingName};
    my $data_end = $data_index+1+$msg_len;
    my @sensor_data = @msg_data[$data_index+1..$data_end-1];
    
    @sensor_data = reverse(@sensor_data);
    #my $raw_value = join("",@sensor_data);
    my $value = "";
    map {$value .= sprintf "%02x",$_} @sensor_data;
    $value = hex($value);
    
    Log 3, "GSD: read sensor data: $msg_type : " . join(" " , @sensor_data) . " = " . $value;
    
    if(defined($data{JEECONF}{$msg_type}{CorrFactor})) {
      my $corr = $data{JEECONF}{$msg_type}{CorrFactor};
      $value = $value * $corr;
    }
  if(defined($data{JEECONF}{$msg_type}{Offset})) {
    my $offset = $data{JEECONF}{$msg_type}{Offset};
    $value = $value + $offset;
  }
    $dMap->{READINGS}{$reading_name} = $value;
    
    $dMap->{INDEX} = $data_end; # 1 Byte Type und N Bytes Data
  } else {
    # Definition des Message-Typs ungueltig
    Log 0, "GSD: ERROR: parse failed. no data length defined";
    return undef;
  }
  
  return $dMap; 
}

#------------------------------------------------------------------------------
sub GSD_parseTextMsg($$) {
  my ($hash, $dMap) = @_;
  #TODO
  
  return $dMap;
}

sub
GSD_Get($@)
{
  my ($hash, @a) = @_;

  my $name = $a[0];

  if(@a < 2)
  {
    logF($hash, "Get", "@a: get needs at least one parameter");
    return "$name: get needs at least one parameter";
  }

  my $cmd= $a[1];
  logF($hash, "Get", "@a");

  if($cmd eq "list") {
    my $ret = "";
    foreach my $kname (keys %{$defs{$name}{READINGS}}) {
      my $value = $defs{$name}{READINGS}->{$kname}->{VAL};
      my $time  = $defs{$name}{READINGS}->{$kname}->{TIME};
      $ret = "$ret\n".sprintf("%-20s %-10s (%s)", $kname, $value, $time);
    }
    return $ret;
  }

  if($cmd eq "version")
  {
    return $VERSION;
  }

  return "Unknown argument $cmd, choose one of list:noArg version:noArg";
}

sub
GSD_Set($@)
{
  my ($hash, @a) = @_;

  my $name = $a[0];

  if(@a < 2)
  {
    logF($hash, "Set", "@a: set needs at least one parameter");
    return "$name: set needs at least one parameter";
  }

  my $cmd= $a[1];
  logF($hash, "Set", "@a");

  if($cmd eq "clean") {    
    # alle Readings loeschen
    foreach my $aName (keys %{$defs{$name}{READINGS}}) {
      delete $defs{$name}{READINGS}{$aName};
    }
    return;
  }
  
  if($cmd eq "clear")
  {
    my $subcmd = my $cmd= $a[2];
    if(defined $subcmd) {
      delete $defs{$name}{READINGS}{$subcmd};
      return;
    }
    return "missing parameter. use clear <reading name>";
  }

  return "Unknown argument $cmd, choose one of clean:noArg clear";
}

sub
GSD_Attr($$$)
{
  my ($cmd, $name, $attrName, $attrVal) = @_;

  Log 5, "GSD Attr: $cmd $name $attrName $attrVal";

  $attrVal= "" unless defined($attrVal);
  my $orig = AttrVal($name, $attrName, "");

  if( $cmd eq "set" ) {
    if( $orig ne $attrVal ) {
      my $hash = $main::defs{$name};
      if($attrName eq "disable")
      {
        # TODO
      }

      $attr{$name}{$attrName} = $attrVal;
      return undef;
    }
  }
  return;
}

#------------------------------------------------------------------------------
# Logging: Funkrionsaufrufe
#   Parameter: HASH, Funktionsname, Message
#------------------------------------------------------------------------------
sub logF($$$)
{
	my ($hash, $fname, $msg) = @_;
  #Log 5, "GSD $fname (".$hash->{NAME}."): $msg";
  Log 5, "GSD $fname $msg";
}

1;

=pod
=begin html

<a name="GSD"></a>
<h3>GSD</h3>

TODO: EN

=end html
=begin html_DE
<a name="GSD"></a>
<h3>GSD</h3>

TODO: DE

=end html_DE
=cut