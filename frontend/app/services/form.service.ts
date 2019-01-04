import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder, Validators, FormArray } from '@angular/forms';

@Injectable()
export class FormService {
  public disabled = true;

  constructor(private _fb: FormBuilder) { }

  initFormSHT(): FormGroup {
    const formSuivi = this._fb.group({
      id_base_site: null,
      id_base_visit: null,
      visit_date_min: [null, Validators.required],
      cor_visit_observer: [new Array(), Validators.required],
      cor_visit_perturbation: new Array(),
      cor_visit_species: new Array(),
      cor_visit_habitats: [null, Validators.required],
      comments: null
    });
    return formSuivi;
  }



}
