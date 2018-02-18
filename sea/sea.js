

class SeaData {
    constructor (data) {
	this.dataStr = data;
	this.data = JSON.parse(data);
	this.internalSintomiCorrenti = [];
	this.internalProblemiCorrenti = [];
	this.internalAzioniCorrenti = [];
    }

    get dataJson ()        { return this.data; }
    get sintomi ()         { return this.data.sintomi; }
    get sintomiCorrenti()  { return this.internalSintomiCorrenti; }
    get problemiCorrenti() { return this.internalProblemiCorrenti; }
    get azioniCorrenti()   { return this.internalAzioniCorrenti; }

    set sintomiCorrenti(x) { this.internalSintomiCorrenti = x; updateCorrentiFromSintomi(); }
    set problemiCorrenti(x){ this.internalProblemiCorrenti = x;updateCorrentiFromProblemi(); }
    set azioniCorrenti(x)  { this.internalAzioniCorrenti = x;  updateCorrentiFromAzioni();}

    findSintomoByStr(str) {
	return this.data.sintomi.filter(x => x.desc == str);
    }

    addSintomoCorrente(str) {
	var s = this.findSintomoByStr(str);
        this.internalSintomiCorrenti = this.internalSintomiCorrenti.concat(s);
	//console.log(s);
        //console.log(this.internalSintomiCorrenti);
	this.updateCorrentiFromSintomi();
	return this.internalSintomiCorrenti;
    }

    unique(arr) {
	if (arr.length < 1) return arr;
	var ret=[arr[0]];
	var last=arr[0];
	for (var i=1; i<arr.length; i++) {
	    //console.log(arr[i]); console.log(last);
	    if (arr[i] != last) { ret.push(arr[i]); last = arr[i]; }
	}
	return ret;
    }

    updateCorrentiFromSintomi() {
	var aus = [];
        var legamiCorrenti = [];
	//console.log("in updateCorrentiFromSintomi");
	for (var i=0; i<this.internalSintomiCorrenti.length; i++) {
	    var ids = this.internalSintomiCorrenti[i].id;
	    var aus = this.data.legami.filter(x => x.s == ids);
	    legamiCorrenti = legamiCorrenti.concat(aus);
	}
	var probIds = legamiCorrenti.map(x => x.p);
        var azioniIds = legamiCorrenti.map(x => x.a);

	probIds.sort();
	azioniIds.sort();

	probIds = this.unique(probIds);
	azioniIds = this.unique(azioniIds);

	//console.log(legamiCorrenti);
	//console.log(probIds);

        this.internalProblemiCorrenti = probIds.map(x => this.data.problemi[x]);
        this.internalAzioniCorrenti = azioniIds.map(x => this.data.azioni[x]);

	//console.log(this.internalProblemiCorrenti);
    }

}
