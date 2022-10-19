import { Injectable } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';

@Injectable()
export class FormService {
  public disabled = true;

  constructor(private fb: FormBuilder) {}

  initializeFormVisit(): FormGroup {
    const visitForm = this.fb.group({
      id_base_site: null,
      id_base_visit: null,
      visit_date_min: [null, Validators.required],
      cor_visit_observer: [new Array(), Validators.required],
      cor_visit_perturbation: new Array(),
      taxonsVisit: this.fb.array([]),
      comments: null
    });
    return visitForm;
  }
}
