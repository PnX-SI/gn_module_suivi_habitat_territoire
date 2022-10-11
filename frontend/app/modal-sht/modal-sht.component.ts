import { Component, OnInit, Input, Output, EventEmitter, OnDestroy } from '@angular/core';
import { NgbModal, NgbModalRef, NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { FormGroup, FormBuilder, FormArray } from '@angular/forms';
import { ToastrService } from 'ngx-toastr';

import { forkJoin } from 'rxjs/observable/forkJoin';
import { of } from 'rxjs/observable/of';

import { DataService } from '../services/data.service';
import { StoreService } from '../services/store.service';
import { FormService } from '../services/form.service';
import { UserService } from '../services/user.service';

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

  public dataReady = false;
  private formDataSubscription;
  public formVisit: FormGroup;
  private _modalRef: NgbModalRef;
  public species: any[] = [];
  public nonHabitatTaxa: any[] = [];
  public cd_hab;
  public nom_habitat;
  public id_base_site;
  private visit: any = {
    id_base_visit: '',
    visit_date_min: '',
    observers: [],
    cor_visit_taxons: [],
    cor_visit_perturbation: [],
    comments: ''
  };
  public modalTitle = "Saisie d'un relevé";
  public disabledForm = false;
  public onUpVisit = false;
  public labelUpVisit = 'Éditer le relevé';
  public isAllowed = false;

  constructor(
    private _modalService: NgbModal,
    public formService: FormService,
    public storeService: StoreService,
    private _api: DataService,
    private _fb: FormBuilder,
    public dateParser: NgbDateParserFormatter,
    private toastr: ToastrService,
    private userService: UserService
  ) {}

  get taxonsVisit() {
    return this.formVisit.get('taxonsVisit') as FormArray;
  }

  ngOnInit() {
    this.labelButton = this.labelButton || '';

    this.formVisit = this.formService.initializeFormVisit();

    if (this.idVisit) {
      this.modalTitle = 'Relevé ' + this.idVisit;
      this.disabledForm = true;
    }
  }

  ngOnDestroy() {
    if (this.formDataSubscription) {
      this.formDataSubscription.unsubscribe();
    }
  }

  open(content) {
    this._modalRef = this._modalService.open(content, { size: 'lg' });
    this.dataReady = false;
    this.initializeData();
  }

  initializeData() {
    this.formDataSubscription = this.storeService
      .getCurrentSite()
      .flatMap(currentSite => {
        this.cd_hab = currentSite.cd_hab;
        this.nom_habitat = currentSite.nom_habitat;
        this.id_base_site = currentSite.id_base_site;

        return forkJoin({
          currentVisit: this.getCurrentVisit(),
          taxons: this._api.getTaxons(this.cd_hab)
        });
      })
      .flatMap(results => {
        this.visit =
          Object.keys(results.currentVisit).length > 0 ? results.currentVisit : this.visit;
        this.species = this.formatTaxons(results.taxons);
        this.nonHabitatTaxa = this.extractNonHabitatTaxa(
          this.visit['cor_visit_taxons'],
          results.taxons
        );
        return of({ visit: this.visit, species: this.species });
      })
      .subscribe(data => {
        this.patchForm();
        this.clearTaxonsControls();
        this.addTaxonsControls();
        this.checkPermission();
        this.dataReady = true;
      });
  }

  getCurrentVisit() {
    let currentVisit;
    if (this.idVisit) {
      currentVisit = this._api.getOneVisit(this.idVisit);
    } else {
      currentVisit = of([]);
    }
    return currentVisit;
  }

  formatTaxons(taxons) {
    let species = [];
    taxons.forEach((item, idx) => {
      let element = {};
      element['name'] = item.nom_complet;
      element['id'] = item.cd_nom;
      element['selected'] = false;
      if (this.visit['cor_visit_taxons'].length > 0) {
        this.visit['cor_visit_taxons'].forEach(visitTaxon => {
          if (visitTaxon.cd_nom == item.cd_nom) {
            element['selected'] = true;
          }
        });
      }
      species[idx] = element;
    });
    return species;
  }

  private extractNonHabitatTaxa(observedTaxa, habitatTaxa) {
    let nonHabitatTaxaCodes = [];
    if (observedTaxa.length > 0) {
      observedTaxa.forEach(visitTaxon => {
        let nonHabitat = true;
        habitatTaxa.forEach(habitatTaxon => {
          if (visitTaxon.cd_nom == habitatTaxon.cd_nom) {
            nonHabitat = false;
          }
        });
        if (nonHabitat) {
          nonHabitatTaxaCodes.push(visitTaxon.cd_nom);
        }
      });
    }

    let nonHabitatTaxa = [];
    if (nonHabitatTaxaCodes.length > 0) {
      for (let scinameCode of nonHabitatTaxaCodes) {
        this._api.getTaxonsInfos(scinameCode).subscribe(data => {
          nonHabitatTaxa.push(data.nom_complet);
        });
      }
    }
    return nonHabitatTaxa;
  }

  patchForm() {
    this.formVisit.patchValue({
      id_base_visit: this.visit.id_base_visit,
      visit_date_min: this.dateParser.parse(this.visit.visit_date_min),
      cor_visit_observer: this.visit.observers,
      cor_visit_perturbation: this.visit.cor_visit_perturbation,
      id_base_site: this.id_base_site,
      comments: this.visit.comments
    });
  }

  addTaxonsControls() {
    this.species.forEach(element => {
      this.taxonsVisit.push(this._fb.control(element.selected));
    });
  }

  clearTaxonsControls() {
    // WARNING: use removeAt() with a loop to not destroy subscriptions
    while (this.taxonsVisit.length !== 0) {
      this.taxonsVisit.removeAt(0);
    }
  }

  checkPermission() {
    this.userService.check_user_cruved_visit('U', this.visit).subscribe(ucruved => {
      this.isAllowed = ucruved;
    });
  }

  onSave() {
    this.onClose();
    let data = this.formatDataForm();
    if (this.idVisit) {
      this.patchVisit(data);
    } else {
      this.postVisit(data);
    }
  }

  formatDataForm() {
    const currentForm = this.formVisit.value;
    let formatedData = {};

    // id_base_visit
    if (this.idVisit) {
      formatedData['id_base_visit'] = currentForm['id_base_visit'];
    }

    formatedData['id_base_site'] = this.id_base_site;

    formatedData['visit_date_min'] = this.dateParser.format(
      this.formVisit.controls.visit_date_min.value
    );

    // comments
    formatedData['comments'] = this.formVisit.controls.comments.value;

    // taxonsVisits
    formatedData['cor_visit_taxons'] = currentForm['taxonsVisit']
      .map((v, i) => {
        return v ? { cd_nom: this.species[i].id } : null;
      })
      .filter(v => {
        return v !== null;
      });

    // cor_visit_perturbations
    if (
      currentForm['cor_visit_perturbation'] !== null &&
      currentForm['cor_visit_perturbation'] !== undefined
    ) {
      formatedData['cor_visit_perturbation'] = currentForm['cor_visit_perturbation'].map(pertu => {
        return { id_nomenclature_perturbation: pertu.id_nomenclature };
      });
    }

    // observers
    formatedData['cor_visit_observer'] = currentForm['cor_visit_observer'].map(obs => {
      return obs.id_role;
    });

    return formatedData;
  }

  onClose() {
    this._modalRef.close();
    this.onUpVisit = false;
    if (this.idVisit) {
      this.disabledForm = true;
      this.labelUpVisit = 'Éditer le relevé';
    }
  }

  upVisit() {
    this.onUpVisit = !this.onUpVisit ? true : false;
    this.disabledForm = this.onUpVisit ? false : true;
    this.labelUpVisit = this.onUpVisit ? 'Annuler' : 'Éditer le relevé';
    if (!this.onUpVisit) {
      this._modalRef.close();
    }
  }

  postVisit(currentForm) {
    this._api.postVisit(currentForm).subscribe(
      data => {
        this.visitsUp.emit(data);
        this.toastr.success('Le relevé est enregistré', '', {
          positionClass: 'toast-top-right'
        });
      },
      error => {
        this.manageError(error);
      }
    );
  }

  patchVisit(currentForm) {
    this._api.patchVisit(currentForm, this.idVisit).subscribe(
      data => {
        this.visitsUp.emit(data);
        this.toastr.success('Le relevé a été modifié', '', {
          positionClass: 'toast-top-right'
        });
      },
      error => {
        this.manageError(error);
      }
    );
  }

  manageError(error) {
    if (error.status == 403 && error.error.raisedError == 'PostYearError') {
      this.toastr.error(error.error.message, '', {
        positionClass: 'toast-top-right'
      });
    } else {
      this.toastr.error(
        'Une erreur est survenue lors de l\'enregistrement de votre relevé',
        '',
        {
          positionClass: 'toast-top-right'
        }
      );
    }
  }
}
