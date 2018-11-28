import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';

@Injectable()
export class FormService {
  public disabled = true;

  constructor(private _fb: FormBuilder) {}

  initFormSFT(): FormGroup {
    const formSuivi = this._fb.group({
      id_base_site: null,
      id_base_visit: null,
      visit_date_min: [null, Validators.required],
      visit_date_max: null,
      cor_visit_observer: [null, Validators.required],
      cor_visit_perturbation: new Array(),
      cor_visit_grid: new Array(),
      comments: null
    });
    return formSuivi;
  }
}
