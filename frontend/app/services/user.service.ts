import { Injectable, Inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs/Observable';

import { AppConfig } from '@geonature_config/app.config';
import { ModuleConfig } from '../module.config';

@Injectable()
export class UserService {
  public currentUser;
  private _cruved = {};

  constructor(private _http: HttpClient) {
    this.currentUser = this.getUser();
  }

  getUser() {
    let currentUser = localStorage.getItem('current_user');
    return JSON.parse(currentUser);
  }

  // Use service geonature ? localstorage ?
  getUserCruved() {
    if (Object.keys(this._cruved).length == 0) {
      return this._http.get<any>(
        `${AppConfig.API_ENDPOINT}/${ModuleConfig.MODULE_URL}/user/cruved`
      );
    } else {
      //return Observable.create( (ucruved: Observer<string>) => ucruved.next(this._cruved));
      return new Observable(ucruved => ucruved.next(this._cruved));
    }
  }

  // id_digitaliser ?
  check_user_cruved_visit(action, visit?): Observable<any> {
    let isAllowed = false;
    return new Observable(observer => {
      this.getUserCruved().subscribe(
        ucruved => {
          this._cruved = ucruved;
          let user_cruved_level = ucruved[action];
          if (visit) {
            if (user_cruved_level == '1') {
              visit.observers.forEach(role => {
                if (role.id_role == this.currentUser.id_role) {
                  isAllowed = true;
                } else if (visit.id_digitiser == this.currentUser.id_role) {
                  isAllowed = true;
                }
              });
            }

            if (user_cruved_level == '2') {
              visit.observers.forEach(role => {
                if (role.id_role == this.currentUser.id_role) {
                  isAllowed = true;
                } else if (visit.id_digitiser == this.currentUser.id_role) {
                  isAllowed = true;
                } else if (visit.id_organisme == this.currentUser.id_organisme) {
                  isAllowed = true;
                }
              });
            }
          }

          if (user_cruved_level == '3' || user_cruved_level == '2') {
            isAllowed = true;
          }

          observer.next(isAllowed);
        },
        error => {
          observer.error('error');
          console.log('Error userCruved: ', error);
        }
      );
    });
  }
}
