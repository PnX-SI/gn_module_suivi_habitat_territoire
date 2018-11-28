import { NgModule } from "@angular/core";
import { CommonModule } from '@angular/common';
import { Routes, RouterModule } from "@angular/router";
import { HttpClient } from '@angular/common/http';

import { GN2CommonModule } from "@geonature_common/GN2Common.module";

import { DataService } from './services/data.service';
import { StoreService } from './services/store.service';

import { SiteMapListComponent } from "./site-map-list/site-map-list.component";


// my module routing
const routes: Routes = [{ path: "", component: SiteMapListComponent }];

@NgModule({
  declarations: [SiteMapListComponent],
  imports: [GN2CommonModule, RouterModule.forChild(routes), CommonModule],
  providers: [HttpClient, DataService, StoreService],
  bootstrap: []
})
export class GeonatureModule {}
