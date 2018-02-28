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

	this.dataStr = data;
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

    doUnique(arr) {
	var res = [];
	if (arr.length < 1) {
	    return arr;
	}
	res[0] = arr[0];
	for (var i=1; i<arr.length; i++) {
	    if (arr[i] != arr[i-1]) {
		res.push(arr[i]);
	    }
	}
	return res;
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
	    this.internalProblemiCorrenti = this.doUnique(this.internalProblemiCorrenti.concat(usep[j]['p']).sort());
	    this.internalAzioniCorrenti = this.doUnique(this.internalAzioniCorrenti.concat(usep[j]['a']).sort());
	}
    }

}