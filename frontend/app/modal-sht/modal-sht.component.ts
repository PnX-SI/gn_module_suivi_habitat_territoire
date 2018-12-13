import { Component, OnInit, Input, Output, OnDestroy, EventEmitter } from '@angular/core';
import { NgbModal, NgbModalRef, NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { FormGroup, FormBuilder, FormArray } from '@angular/forms';
import { ToastrService } from 'ngx-toastr';

import { forkJoin } from "rxjs/observable/forkJoin";
import { Observable } from 'rxjs/Observable';

import { DataService } from '../services/data.service';
import { StoreService } from '../services/store.service';
import { FormService } from '../services/form.service';

@Component({
  selector: 'modal-sht',
  templateUrl: 'modal-sht.component.html',
  styleUrls: ['./modal-sht.component.scss']
})

export class ModalSHTComponent implements OnInit, OnDestroy {
  @Input() labelButton: string;
  @Input() classStyle: string;
  @Input() iconStyle: string;
  @Input() idVisit: string;
  @Output() visitsUp = new EventEmitter();

  public formVisit: FormGroup;
  private _modalRef: NgbModalRef;
  public species = [];
  public cd_hab;
  public nom_habitat;
  public id_base_site;
  private _currentSite;
  private visit = [{ "id_visit": "", "visit_date": "", "observers": [], "cor_visit_taxons": [], "cor_visit_perturbation": [], "comments": "" }];
  public modalTitle = "Saisie d'un relevé";
  public disabledForm = false;
  public onUpVisit = false;
  public labelUpVisit = "Editer le relevé"

  constructor(
    private _modalService: NgbModal,
    public formService: FormService,
    public storeService: StoreService,
    private _api: DataService,
    private _fb: FormBuilder,
    public dateParser: NgbDateParserFormatter,
    private toastr: ToastrService,
  ) { }

  ngOnInit() {
    this.labelButton = this.labelButton || '';

    this.formVisit = this.formService.initFormSHT();

    if (this.idVisit) {
      this.disabledForm = true;
      console.log("idvisit: ", this.idVisit);
    }
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
    if (this.idVisit) {
      currentVisit = this._api.getOneVisit(this.idVisit)
      this.modalTitle = "Relevé " + this.idVisit;
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

  addSpeciesControl() {
    const arr: FormArray = [];
    this.species.forEach(element => {
      element['name'] = element.nom_complet;
      element['id'] = element.cd_nom;
      element['selected'] = false;
      if (this.visit[0]['cor_visit_taxons'].length > 0) {
        this.visit[0]['cor_visit_taxons'].forEach(specie => {
          if (specie.cd_nom == element.cd_nom) {
            element['selected'] = true;
          }
        })
      }
      arr.push(this._fb.control(element))
    });
    return arr;
  }

  getSpeciesControl() {
    return this.formVisit.get('cor_visit_species');
  }

  pachForm() {
    this.formVisit.patchValue({
      "cor_visit_species": this.addSpeciesControl(),
      "id_base_visit": this.visit[0].id_visit,
      "visit_date": this.dateParser.parse(this.visit[0].visit_date),
      "cor_visit_observer": this.visit[0].observers,
      "cor_visit_perturbation": this.visit[0].cor_visit_perturbation,
      "id_base_site": this.id_base_site,
      "cor_visit_habitats": this.cd_hab,
      "comments": this.visit[0].comments
    })
  }

  initData() {
    this.getDatas();
  }

  open(content) {
    this._modalRef = this._modalService.open(content, { size: 'lg' });
    this.initData();
  }

  onSave() {
    this.onClose();
    const currentForm = this.formVisit.value;
    console.log(currentForm);
    if (this.idVisit)
      this.patchVisit();
    else
      this.postVisit();
  }

  onClose() {
    this._modalRef.close();
    this.onUpVisit = false;
    if (this.idVisit) {
      this.disabledForm = true;
      this.labelUpVisit = "Editer le relevé";
    }
  }

  upVisit() {
    this.onUpVisit = (!this.onUpVisit) ? true : false;
    this.disabledForm = (this.onUpVisit) ? false : true;
    this.labelUpVisit = (this.onUpVisit) ? "Annulé" : "Editer le relevé";
  }

  postVisit() {
    this._api.postVisit().subscribe(data => {
      this.visitsUp.emit(data);
      this.toastr.success('Le relevé est enregistré', '', {
        positionClass: 'toast-top-right'
      });
    }, error => {
      this.toastr.error('Une erreur est survenue lors de l\'enregistrement de votre relevé', '', {
        positionClass: 'toast-top-right'
      });
    })
  }

  patchVisit() {
    this._api.patchVisit(this.idVisit).subscribe(data => {
      this.visitsUp.emit(data);
      this.toastr.success('Le relevé a été modifié', '', {
        positionClass: 'toast-top-right'
      });
    }, error => {
      this.toastr.error('Une erreur est survenue lors de la modification de votre relevé', '', {
        positionClass: 'toast-top-right'
      });
    })
  }

  ngOnDestroy() {
    if (this._currentSite)
      this._currentSite.unsubscribe();
  }
}