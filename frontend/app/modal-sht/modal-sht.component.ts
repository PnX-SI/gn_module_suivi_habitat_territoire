import {
  Component,
  OnInit,
  Input,
  Output,
  OnDestroy,
  EventEmitter
} from "@angular/core";
import {
  NgbModal,
  NgbModalRef,
  NgbDateParserFormatter
} from "@ng-bootstrap/ng-bootstrap";
import { FormGroup, FormBuilder, FormArray, NgForm } from "@angular/forms";
import { ToastrService } from "ngx-toastr";

import { forkJoin } from "rxjs/observable/forkJoin";
import { Observable } from "rxjs/Observable";

import { DataService } from "../services/data.service";
import { StoreService } from "../services/store.service";
import { FormService } from "../services/form.service";
import { UserService } from "../services/user.service";

@Component({
  selector: "modal-sht",
  templateUrl: "modal-sht.component.html",
  styleUrls: ["./modal-sht.component.scss"]
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
  private visit = {
    id_base_visit: "",
    visit_date_min: "",
    observers: [],
    cor_visit_taxons: [],
    cor_visit_perturbation: [],
    comments: ""
  };
  public modalTitle = "Saisie d'un relevé";
  public disabledForm = false;
  public onUpVisit = false;
  public labelUpVisit = "Editer le relevé";
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

  ngOnInit() {
    this.labelButton = this.labelButton || "";

    this.formVisit = this.formService.initFormSHT();

    if (this.idVisit) {
      this.disabledForm = true;
    }

  }

  getDatas() {
    this._currentSite = this.storeService.getCurrentSite().subscribe(cdhab => {
      this.cd_hab = cdhab.cd_hab;
      this.nom_habitat = cdhab.nom_habitat;
      this.id_base_site = cdhab.id_base_site;
    });

    let datas = [];
    let currentVisit;
    if (this.idVisit) {
      currentVisit = this._api.getOneVisit(this.idVisit);
      this.modalTitle = "Relevé " + this.idVisit;
    } else {
      currentVisit = Observable.of([]);
    }
    datas.push(currentVisit);
    let taxons = this._api.getTaxons(this.cd_hab);
    datas.push(taxons);

    forkJoin(datas).subscribe(results => {
      // results[0] is visit
      // results[1] is species
      this.visit = Object.keys(results[0]).length > 0 ? results[0] : this.visit; // TODO: type visit ?
      this.species = results[1];
      this.pachForm();
      this.checkPermission();
    });
  }

  checkPermission() {
    this.userService.check_user_cruved_visit('U', this.visit).subscribe(ucruved => {
      console.log("ucruved U", ucruved)
      this.isAllowed = ucruved;
    })
  }

  addSpeciesControl() {
    const arr: FormArray = [];
    this.species.forEach(element => {
      element["name"] = element.nom_complet;
      element["id"] = element.cd_nom;
      element["selected"] = false;
      let status = false;
      if (this.visit["cor_visit_taxons"].length > 0) {
        this.visit["cor_visit_taxons"].forEach(specie => {
          if (specie.cd_nom == element.cd_nom) {
            element["selected"] = true;
            status = true;
          }
        });
      }
      arr.push(this._fb.control(status));
    });
    return arr;
  }

  getSpeciesControl() {
    return this.formVisit.get("cor_visit_taxons");
  }

  pachForm() {
    this.formVisit.patchValue({
      cor_visit_taxons: this.addSpeciesControl(),
      id_base_visit: this.visit.id_base_visit,
      visit_date_min: this.dateParser.parse(this.visit.visit_date_min),
      cor_visit_observer: this.visit.observers,
      cor_visit_perturbation: this.visit.cor_visit_perturbation,
      id_base_site: this.id_base_site,
      comments: this.visit.comments
    });
  }

  initData() {
    this.getDatas();
  }

  open(content) {
    this._modalRef = this._modalService.open(content, { size: "lg" });
    this.initData();
  }

  onSave() {
    this.onClose();
    let currentForm = this.formateDataForm();
    if (this.idVisit) {
      this.patchVisit(currentForm);
    } else {
      this.postVisit(currentForm);
    }
  }

  formateDataForm() {
    const currentForm = this.formVisit.value;
    if (!this.idVisit) delete currentForm["id_base_visit"];
    currentForm["id_base_site"] = this.id_base_site;
    currentForm["visit_date_min"] = this.dateParser.format(
      this.formVisit.controls.visit_date_min.value
    );
    //comments
    currentForm["comments"] = this.formVisit.controls.comments.value;
    //cor_visit_taxons
    currentForm["cor_visit_taxons"] = currentForm["cor_visit_taxons"]
      .map((v, i) => {
        return v.value ? { cd_nom: this.species[i].cd_nom } : null;
      })
      .filter(v => {
        return v !== null;
      });
    //cor_visit_perturbations
    if (
      currentForm["cor_visit_perturbation"] !== null &&
      currentForm["cor_visit_perturbation"] !== undefined
    ) {
      currentForm["cor_visit_perturbation"] = currentForm[
        "cor_visit_perturbation"
      ].map(pertu => {
        return { id_nomenclature_perturbation: pertu.id_nomenclature };
      });
    }
    //observers
    currentForm["cor_visit_observer"] = currentForm["cor_visit_observer"].map(
      obs => {
        return obs.id_role;
      }
    );

    return currentForm;
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
    this.onUpVisit = !this.onUpVisit ? true : false;
    this.disabledForm = this.onUpVisit ? false : true;
    this.labelUpVisit = this.onUpVisit ? "Annuler" : "Editer le relevé";
    if (!this.onUpVisit) this._modalRef.close();
  }

  postVisit(currentForm) {
    this._api.postVisit(currentForm).subscribe(
      data => {
        this.visitsUp.emit(data);
        this.toastr.success("Le relevé est enregistré", "", {
          positionClass: "toast-top-right"
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
        this.toastr.success("Le relevé a été modifié", "", {
          positionClass: "toast-top-right"
        });
      },
      error => {
        this.manageError(error);
      }
    );
  }

  manageError(error) {
    if (error.status == 403 && error.error.raisedError == "PostYearError") {
      this.toastr.error(error.error.message, "", {
        positionClass: "toast-top-right"
      });
    } else {
      this.toastr.error(
        "Une erreur est survenue lors de l'enregistrement de votre relevé",
        "",
        {
          positionClass: "toast-top-right"
        }
      );
    }
  }

  ngOnDestroy() {
    if (this._currentSite) this._currentSite.unsubscribe();
  }
}
