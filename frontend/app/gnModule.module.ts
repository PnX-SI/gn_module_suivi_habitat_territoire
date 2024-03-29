import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Routes, RouterModule } from '@angular/router';

import { GN2CommonModule } from '@geonature_common/GN2Common.module';

import { DataService } from './services/data.service';
import { StoreService } from './services/store.service';
import { FormService } from './services/form.service';
import { UserService } from './services/user.service';

import { SiteMapListComponent } from './site-map-list/site-map-list.component';
import { ListVisitComponent } from './list-visit/list-visit.component';
import { ModalSHTComponent } from './modal-sht/modal-sht.component';

// Module routing
const routes: Routes = [
  { path: '', component: SiteMapListComponent },
  { path: 'listVisit/:idSite', component: ListVisitComponent }
];

@NgModule({
  declarations: [SiteMapListComponent, ListVisitComponent, ModalSHTComponent],
  imports: [GN2CommonModule, RouterModule.forChild(routes), CommonModule],
  providers: [HttpClient, DataService, StoreService, FormService, UserService],
  bootstrap: []
})
export class GeonatureModule {}
