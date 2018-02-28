/*
 * SeA - Sintomi e Azioni
 * Copyright (C) 2018 - Gianluca Moro - giangiammy@gmail.com
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

class SeaData {

    constructor (data) {

	this.dataStr = `
{
  "versione": "201802181000",
  "s0": "S0", 
  "s1": "uso muscoli accessori per respirare",
  "s2": "eloquio limitato",
  "s3": "rumori respiratori (borbottio - fischi - sibili)",
  "s4": "frequenza respiratoria <8 o > 30",
  "s5": "cianosi",
  "s6": "ritmo respiratorio alterato",
  "s7": "dolore al torace",
  "s8": "dolore allo sterno",

  "p0": "ictus",
  "p1": "arresto cardiaco",
  "p2": "edema polmonare",
  "p3": "insufficienza respiratoria",

  "a0": "A0",
  "a1": "ABC",
  "a2": "somministrare ossigeno",
  "a3": "non far camminare",
  "a4": "rassicurare",
  "a5": "posizione seduta/semiseduta",
  "sep": [ 
	{ "s": [1, 2, 3, 4, 5, 6 ], "p": [3], "a": [1, 2, 3, 4, 5 ] },
	{ "s": [1, 2, 3, 4, 5, 6, 7, 8 ], "p": [1], "a": [1, 2, 4, 5 ] }
       ]
}`;

	this.data = JSON.parse(this.dataStr);
	this.internalSintomiAll = this.getAll("s");
	this.internalProblemiAll = this.getAll("p");
	this.internalAzioniAll = this.getAll("a");

	this.internalSintomiCkecked = this.internalSintomiAll.map(function (x) { return false; });
	this.internalProblemiCorrenti = [];
	this.internalAzioniCorrenti = [];
    }

    get sintomiAll  () { return this.internalSintomiAll;  }
    get problemiAll () { return this.internalProblemiAll; }
    get azioniAll   () { return this.internalAzioniAll;   }

    get sintomiChecked   () { return this.internalSintomiCkecked;   }
    get problemiCorrenti () { return this.internalProblemiCorrenti; }
    get azioniCorrenti   () { return this.internalAzioniCorrenti;   }

    getProblemaMsg(i) {
	return this.data['p'+i.toString()];
    }

    getAzioneMsg(i) {
	return this.data['a'+i.toString()];
    }

    getAll(typ) {
	var allStr = [];
	for (var i=0;;i++) {
	    var indexStr = typ + i.toString();
	    if (indexStr in this.data) {
		allStr.push(this.data[indexStr]);
	    } else {
		break;
	    }
	}
	return allStr;
    }

    switchSintomo(i) {
	this.internalSintomiCkecked[i] = this.internalSintomiCkecked[i]?false:true;
	this.updateProblemiAzioniCorrenti();
    }

    isSIncluded(desc, i) {
	return (desc.s.indexOf(i) > -1);
    }

    updateProblemiAzioniCorrenti() {
	this.internalProblemiCorrenti = [];
	this.internalAzioniCorrenti = [];
	var usep = [];
	for (var i=0; i<this.internalSintomiCkecked.length; i++) {
	    if (this.internalSintomiCkecked[i]) {
		for (var k=0; k<this.data.sep.length; k++) {
		    if (this.isSIncluded(this.data.sep[k], i)) {
			usep.push(this.data.sep[k]);
		    }
		}

	    }
	}
	for (var j=0; j<usep.length; j++) {
	    this.internalProblemiCorrenti = jQuery.unique(this.internalProblemiCorrenti.concat(usep[j]['p']).sort());
	    this.internalAzioniCorrenti = jQuery.unique(this.internalAzioniCorrenti.concat(usep[j]['a']).sort());
	}
    }

}