# coding: utf-8
from sqlalchemy import Boolean, CheckConstraint, Column, Date, DateTime, ForeignKey, Index, Integer, Numeric, String, Text
from sqlalchemy.ext.associationproxy import association_proxy
from sqlalchemy.schema import FetchedValue
from geoalchemy2.types import Geometry
from sqlalchemy.dialects.postgresql.base import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql.expression import func

from pypnusershub.db.models import User

from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import (
    serializable,
    geoserializable,
    GenericQuery,
)
from geonature.utils.utilsgeometry import shapeserializable
#from geonature.core.gn_synthese.models import synthese_export_serialization
from geonature.core.gn_monitoring.models import TBaseSites, TBaseVisits, corVisitObserver
# from geonature.core.taxonomie.models import Taxref
from pypnnomenclature.models import TNomenclatures


 

@serializable
class CorVisitTaxon(DB.Model):
    __tablename__ = 'cor_visit_taxons'
    __table_args__ = {'schema': 'pr_monitoring_habitat_territory'}

    id_cor_visite_taxons = DB.Column(DB.Integer, nullable=False, server_default=DB.FetchedValue(), primary_key=True)
    id_base_visit = DB.Column(DB.ForeignKey('gn_monitoring.t_base_visits.id_base_visit', ondelete='CASCADE', onupdate='CASCADE'))
    cd_nom = DB.Column(DB.Integer)


@serializable
class TNomenclature(DB.Model):
    __tablename__ = 't_nomenclatures'
    __table_args__ = {'schema': 'ref_nomenclatures', 'extend_existing': True}

    id_nomenclature = DB.Column(DB.Integer, primary_key=True, server_default=DB.FetchedValue())
    mnemonique = DB.Column(DB.String(255))
    label_default = DB.Column(DB.String(255), nullable=False)

@serializable
class CorVisitPerturbation(DB.Model):
    __tablename__ = 'cor_visit_perturbation'
    __table_args__ = {'schema': 'pr_monitoring_habitat_territory'}

    id_base_visit = DB.Column(DB.ForeignKey('gn_monitoring.t_base_visits.id_base_visit', onupdate='CASCADE'), primary_key=True, nullable=False)
    id_nomenclature_perturbation = DB.Column(DB.ForeignKey('ref_nomenclatures.t_nomenclatures.id_nomenclature', onupdate='CASCADE'), primary_key=True, nullable=False)
    create_date = DB.Column(DB.DateTime, nullable=False, default=func.now())

    #t_base_visit = DB.relationship('TVisitSHT', primaryjoin='CorVisitPerturbation.id_base_visit == TVisitSHT.id_base_visit', backref='cor_visit_perturbations')
    t_nomenclature = DB.relationship('TNomenclature', primaryjoin='CorVisitPerturbation.id_nomenclature_perturbation == TNomenclature.id_nomenclature', backref='cor_visit_perturbations')

@serializable
class Taxonomie(DB.Model):
    __tablename__ = 'taxref'
    __table_args__ = {
        'schema': 'taxonomie',
        'extend_existing': True
    }

    cd_nom = DB.Column(
        DB.Integer,
        primary_key=True
    )
    nom_complet = DB.Column(DB.Unicode)

@serializable
class TVisitSHT(TBaseVisits):
    __tablename__ = 't_base_visits'
    __table_args__ = {'schema': 'gn_monitoring', 'extend_existing': True}

    cor_visit_perturbation = DB.relationship('CorVisitPerturbation', backref='t_base_visits')
    cor_visit_taxons = DB.relationship("CorVisitTaxon", backref='t_base_visits')

    observers = DB.relationship(
        'User',
        secondary=corVisitObserver,
        primaryjoin=(
            corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit
        ),
        secondaryjoin=(corVisitObserver.c.id_role == User.id_role),
        foreign_keys=[
            corVisitObserver.c.id_base_visit,
            corVisitObserver.c.id_role
        ]
    )


@serializable
class Typoref(DB.Model):
    __tablename__ = 'typoref'
    __table_args__ = {'schema': 'ref_habitat'}

    cd_typo = DB.Column(DB.Integer, primary_key=True, server_default=DB.FetchedValue())
    cd_table = DB.Column(DB.String(255))
    lb_nom_typo = DB.Column(DB.String(100))
    nom_jeu_donnees = DB.Column(DB.String(255))
    date_creation = DB.Column(DB.String(255))
    date_mise_jour_table = DB.Column(DB.String(255))
    date_mise_jour_metadonnees = DB.Column(DB.String(255))
    auteur_typo = DB.Column(DB.String(4000))
    auteur_table = DB.Column(DB.String(4000))
    territoire = DB.Column(DB.String(4000))
    organisme = DB.Column(DB.String(255))
    langue = DB.Column(DB.String(255))
    presentation = DB.Column(DB.String(4000))


@serializable
class Habref(DB.Model):
    __tablename__ = 'habref'
    __table_args__ = {'schema': 'ref_habitat'}

    cd_hab = DB.Column(DB.Integer, primary_key=True, server_default=DB.FetchedValue())
    fg_validite = DB.Column(DB.String(20), nullable=False)
    cd_typo = DB.Column(DB.ForeignKey('ref_habitat.typoref.cd_typo', ondelete='CASCADE', onupdate='CASCADE'), nullable=False)
    lb_code = DB.Column(DB.String(50))
    lb_hab_fr = DB.Column(DB.String(255))
    lb_hab_fr_complet = DB.Column(DB.String(255))
    lb_hab_en = DB.Column(DB.String(255))
    lb_auteur = DB.Column(DB.String(255))
    niveau = DB.Column(DB.Integer)
    lb_niveau = DB.Column(DB.String(100))
    cd_hab_sup = DB.Column(DB.Integer, nullable=False)
    path_cd_hab = DB.Column(DB.String(2000))
    france = DB.Column(DB.String(5))
    lb_description = DB.Column(DB.String(4000))

    typoref = DB.relationship('Typoref', primaryjoin='Habref.cd_typo == Typoref.cd_typo', backref='habrefs')

@serializable
class CorListHabitat(DB.Model):
    __tablename__ = 'cor_list_habitat'
    __table_args__ = {'schema': 'ref_habitat'}

    id_cor_list = DB.Column(DB.Integer, primary_key=True, server_default=DB.FetchedValue())
    id_list = DB.Column(DB.ForeignKey('ref_habitat.habref.bib_list_habitat', onupdate='CASCADE'), nullable=False)
    cd_hab = DB.Column(DB.ForeignKey('ref_habitat.habref.cd_hab', onupdate='CASCADE'), nullable=False)


@serializable
class CorHabitatTaxon(DB.Model):
    __tablename__ = 'cor_habitat_taxon'
    __table_args__ = {'schema': 'pr_monitoring_habitat_territory'}

    id_cor_habitat_taxon = DB.Column(DB.Integer, primary_key=True, server_default=DB.FetchedValue())
    id_habitat = DB.Column(DB.ForeignKey('ref_habitat.habref.cd_hab', onupdate='CASCADE'), nullable=False)
    cd_nom = DB.Column(DB.Integer, nullable=False)

    #taxref = DB.relationship('Taxref', primaryjoin='CorHabitatTaxon.cd_nom == Taxref.cd_nom', backref='cor_habitat_taxons')
    habref = DB.relationship('Habref', primaryjoin='CorHabitatTaxon.id_habitat == Habref.cd_hab', backref='cor_habitat_taxons')


@geoserializable
@serializable
class TInfosSite(DB.Model):
    __tablename__ = 't_infos_site'
    __table_args__ = {'schema': 'pr_monitoring_habitat_territory'}

    id_infos_site = DB.Column(DB.Integer, primary_key=True)
    id_base_site = DB.Column(DB.ForeignKey('gn_monitoring.t_base_sites.id_base_site'), nullable=False)
    cd_hab = DB.Column(DB.ForeignKey('ref_habitat.habref.cd_hab'), nullable=False)

    # habref = DB.relationship('Habref', primaryjoin='TInfosSite.cd_hab == Habref.cd_hab', backref='t_infos_sites')
    #t_base_site = DB.relationship('TBaseSites', primaryjoin='TInfosSite.id_base_site == TBaseSites.id_base_site', backref='t_infos_sites')
    t_base_site = DB.relationship('TBaseSites')
    geom = association_proxy('t_base_site', 'geom')

    def get_geofeature(self, recursif=True):
        return self.as_geofeature(
            'geom',
            'id_infos_site',
            recursif
        )


