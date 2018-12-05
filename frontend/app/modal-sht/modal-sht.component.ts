import { Component, OnInit, Input } from '@angular/core';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';

import { StoreService } from '../services/store.service';
import { FormService } from '../services/form.service';

@Component({
  selector: 'modal-sht',
  templateUrl: 'modal-sht.component.html'
})

export class ModalSHTComponent implements OnInit {
  @Input() labelButton: string;
  public modifGrid;
 

  constructor(
    private _modalService: NgbModal,
    public formService: FormService,
    public storeService: StoreService
  ) { }

  ngOnInit() {
    this.labelButton = this.labelButton || 'Télécharger';
    this.modifGrid = this.formService.initFormSHT();
  }

  open(content) {
    this._modalService.open(content, { size: 'lg' });
  }

  addObs() {
    
  }
}