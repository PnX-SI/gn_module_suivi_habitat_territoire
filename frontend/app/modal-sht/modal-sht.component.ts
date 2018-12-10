import { Component, OnInit, Input, OnDestroy } from '@angular/core';
import { NgbModal, NgbModalRef } from '@ng-bootstrap/ng-bootstrap';
import { FormControl, FormGroup, FormBuilder, FormArray } from '@angular/forms';

import { forkJoin } from "rxjs/observable/forkJoin";
import { mergeMap } from 'rxjs/operators';
import { Observable } from 'rxjs/Observable';

import { DataService } from '../services/data.service';
import { StoreService } from '../services/store.service';
import { FormService } from '../services/form.service';

@Component({
  selector: 'modal-sht',
  templateUrl: 'modal-sht.component.html'
})

export class ModalSHTComponent implements OnInit, OnDestroy {
  @Input() labelButton: string;
  @Input() classStyle: string;
  @Input() iconStyle: string;
  @Input() idVisit: string;

  public formVisit: FormGroup;
  private _modalRef: NgbModalRef;
  public species = [];
  public cd_hab;
  public nom_habitat;
  public id_base_site;
  private _currentSite;
  private visit = [{"id_visit": "", "visit_date": "", "observers": [], "cor_visit_taxons": [] }];
  public modalTitle = "Saisie d'un relevé";

  constructor(
    private _modalService: NgbModal,
    public formService: FormService,
    public storeService: StoreService,
    private _api: DataService,
    private _fb: FormBuilder
  ) { }

  ngOnInit() {
    this.labelButton = this.labelButton || '';

    this.formVisit = this.formService.initFormSHT();

    if (this.idVisit)
      console.log("idvisit: ", this.idVisit);

  }

  getDatas() {
    this._currentSite = this.storeService.getCurrentSite()
      .subscribe(cdhab => {
        this.cd_hab = cdhab.cd_hab;
        this.nom_habitat = cdhab.nom_habitat;
        this.id_base_site = cdhab.id_base_site;
    });

    let datas = [];
    let currentVisit;
    if ( this.idVisit ) {
      currentVisit= this._api.getOneVisit(this.idVisit)
      this.modalTitle = "Rélevé " + this.idVisit;
    } else {
      currentVisit = Observable.of([]);
    }
    datas.push(currentVisit);
    let taxons = this._api.getTaxons('');
    datas.push(taxons);

    forkJoin(datas).subscribe(results => {
      console.log("results", results);
      // results[0] is visit
      // results[1] is species
      this.visit = (results[0].length > 0) ? results[0] : this.visit; // TODO: type visit ?
      this.species = results[1];
      this.pachForm();
    });
  }

  addSpeciesControl(){
    const arr: FormArray = [];
    this.species.forEach(element => {
      element['name'] = element.nom_complet;
      element['id'] = element.cd_nom;
      element['value'] = false;
      arr.push(this._fb.control(element))
   });
   return arr;
  }

  getSpeciesControl(){
    return this.formVisit.get('cor_visit_species');
  }

  pachForm(){
    this.formVisit.patchValue({
      "cor_visit_species": this.addSpeciesControl(),
      "id_base_visit": this.visit[0].id_visit,
      "visit_date": this.visit[0].visit_date,
      "cor_visit_observer": this.visit[0].observers,
      "id_base_site": this.id_base_site,
      "cor_visit_habitats": this.cd_hab,
      "comments": ""
    })
    console.log("this.formVisit", this.formVisit)

  }

  initData() {
    this.getDatas();
    console.log("this.cd_hab: ", this.cd_hab );
  }

  open(content) {
    if( !this.idVisit ) {
      this._modalRef = this._modalService.open(content, { size: 'lg' });
      this.initData();
    }
  }

  onModif() {
    this._modalRef.close();
    const currentForm = this.formVisit.value;
    console.log(currentForm);
  }

  ngOnDestroy(){
    if( this._currentSite )
      this._currentSite.unsubscribe();
  }
}