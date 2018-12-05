# coding: utf-8
from sqlalchemy import Boolean, CheckConstraint, Column, Date, DateTime, ForeignKey, Index, Integer, Numeric, String, Text
from sqlalchemy.ext.associationproxy import association_proxy
from sqlalchemy.schema import FetchedValue
from geoalchemy2.types import Geometry
from sqlalchemy.dialects.postgresql.base import UUID
from sqlalchemy.orm import relationship
#from flask_sqlalchemy import SQLAlchemy


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
from geonature.core.users.models import TRoles


@serializable
class BibNomenclaturesType(DB.Model):
    __tablename__ = 'bib_nomenclatures_types'
    __table_args__ = {'schema': 'ref_nomenclatures'}

    id_type = DB.Column(DB.Integer, primary_key=True, server_default=DB.FetchedValue())
    mnemonique = DB.Column(DB.String(255), unique=True)
    label_default = DB.Column(DB.String(255), nullable=False)
    definition_default = DB.Column(DB.Text)
    label_fr = DB.Column(DB.String(255), nullable=False)
    definition_fr = DB.Column(DB.Text)
    label_en = DB.Column(DB.String(255))
    definition_en = DB.Column(DB.Text)
    label_es = DB.Column(DB.String(255))
    definition_es = DB.Column(DB.Text)
    label_de = DB.Column(DB.String(255))
    definition_de = DB.Column(DB.Text)
    label_it = DB.Column(DB.String(255))
    definition_it = DB.Column(DB.Text)
    source = DB.Column(DB.String(50))
    statut = DB.Column(DB.String(20))
    meta_create_date = DB.Column(DB.DateTime, server_default=DB.FetchedValue())
    meta_update_date = DB.Column(DB.DateTime, server_default=DB.FetchedValue())


@serializable
class TNomenclature(DB.Model):
    __tablename__ = 't_nomenclatures'
    __table_args__ = {'schema': 'ref_nomenclatures'}

    id_nomenclature = DB.Column(DB.Integer, primary_key=True, server_default=DB.FetchedValue())
    id_type = DB.Column(DB.ForeignKey('ref_nomenclatures.bib_nomenclatures_types.id_type', onupdate='CASCADE'), nullable=False, index=True)
    cd_nomenclature = DB.Column(DB.String(255), nullable=False)
    mnemonique = DB.Column(DB.String(255))
    label_default = DB.Column(DB.String(255), nullable=False)
    definition_default = DB.Column(DB.Text)
    label_fr = DB.Column(DB.String(255), nullable=False)
    definition_fr = DB.Column(DB.Text)
    label_en = DB.Column(DB.String(255))
    definition_en = DB.Column(DB.Text)
    label_es = DB.Column(DB.String(255))
    definition_es = DB.Column(DB.Text)
    label_de = DB.Column(DB.String(255))
    definition_de = DB.Column(DB.Text)
    label_it = DB.Column(DB.String(255))
    definition_it = DB.Column(DB.Text)
    source = DB.Column(DB.String(50))
    statut = DB.Column(DB.String(20))
    id_broader = DB.Column(DB.ForeignKey('ref_nomenclatures.t_nomenclatures.id_nomenclature'))
    hierarchy = DB.Column(DB.String(255))
    meta_create_date = DB.Column(DB.DateTime, server_default=DB.FetchedValue())
    meta_update_date = DB.Column(DB.DateTime)
    active = DB.Column(DB.Boolean, nullable=False, server_default=DB.FetchedValue())

    parent = DB.relationship('TNomenclature', remote_side=[id_nomenclature], primaryjoin='TNomenclature.id_broader == TNomenclature.id_nomenclature', backref='t_nomenclatures')
    bib_nomenclatures_type = DB.relationship('BibNomenclaturesType', primaryjoin='TNomenclature.id_type == BibNomenclaturesType.id_type', backref='t_nomenclatures')
 

@serializable
class TBaseSite(DB.Model):
    __tablename__ = 't_base_sites'
    __table_args__ = (
        DB.CheckConstraint("ef_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_type_site, 'TYPE_SITE'::character varying"),
        DB.CheckConstraint('public.st_ndims(geom) = 2'),
        DB.CheckConstraint('public.st_srid(geom) = 4326'),
        {'schema': 'gn_monitoring', 'extend_existing': True}
    )

    id_base_site = DB.Column(DB.Integer, primary_key=True, server_default=DB.FetchedValue())
    id_inventor = DB.Column(DB.ForeignKey('utilisateurs.t_roles.id_role', onupdate='CASCADE'), index=True)
    id_digitiser = DB.Column(DB.ForeignKey('utilisateurs.t_roles.id_role', onupdate='CASCADE'))
    id_nomenclature_type_site = DB.Column(DB.ForeignKey('ref_nomenclatures.t_nomenclatures.id_nomenclature', onupdate='CASCADE'), nullable=False, index=True)
    base_site_name = DB.Column(DB.String(255), nullable=False)
    base_site_description = DB.Column(DB.Text)
    base_site_code = DB.Column(DB.String(25), server_default=DB.FetchedValue())
    first_use_date = DB.Column(DB.Date)
    geom = DB.Column(Geometry, nullable=False, index=True)
    uuid_base_site = DB.Column(UUID, server_default=DB.FetchedValue())

    t_role = DB.relationship('TRoles', primaryjoin='TBaseSite.id_digitiser == TRoles.id_role', backref='trole_t_base_sites')
    t_role1 = DB.relationship('TRoles', primaryjoin='TBaseSite.id_inventor == TRoles.id_role', backref='trole_t_base_sites_0')
    t_nomenclature = DB.relationship('TNomenclature', primaryjoin='TBaseSite.id_nomenclature_type_site == TNomenclature.id_nomenclature', backref='t_base_sites')

@serializable
class TBaseVisit(DB.Model):
    __tablename__ = 't_base_visits'
    __table_args__ = {'schema': 'gn_monitoring', 'extend_existing': True}

    id_base_visit = DB.Column(DB.Integer, primary_key=True, server_default=DB.FetchedValue())
    id_base_site = DB.Column(DB.ForeignKey('gn_monitoring.t_base_sites.id_base_site', ondelete='CASCADE'), index=True)
    id_digitiser = DB.Column(DB.ForeignKey('utilisateurs.t_roles.id_role', onupdate='CASCADE'))
    visit_date_min = DB.Column(DB.Date, nullable=False)
    visit_date_max = DB.Column(DB.Date)
    comments = DB.Column(DB.Text)
    uuid_base_visit = DB.Column(UUID, server_default=DB.FetchedValue())

    t_base_site = DB.relationship('TBaseSite', primaryjoin='TBaseVisit.id_base_site == TBaseSite.id_base_site', backref='t_base_visits')
    t_role = DB.relationship('TRoles', primaryjoin='TBaseVisit.id_digitiser == TRoles.id_role', backref='t_base_visits')

@serializable
class CorVisitTaxon(TBaseVisit):
    __tablename__ = 'cor_visit_taxons'
    __table_args__ = {'schema': 'pr_monitoring_habitat_territory'}

    id_cor_visite_taxons = DB.Column(DB.Integer, nullable=False, server_default=DB.FetchedValue())
    id_base_visit = DB.Column(DB.ForeignKey('gn_monitoring.t_base_visits.id_base_visit', ondelete='CASCADE', onupdate='CASCADE'), primary_key=True)
    cd_nom = DB.Column(DB.Integer)

"""     taxref = DB.relationship('Taxref', primaryjoin='CorVisitTaxon.cd_nom == Taxref.cd_nom', backref='cor_visit_taxons')
 """

@serializable
class Typoref(DB.Model):
    __tablename__ = 'typoref'
    __table_args__ = {'schema': 'habitat'}

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
    __table_args__ = {'schema': 'habitat'}

    cd_hab = DB.Column(DB.Integer, primary_key=True, server_default=DB.FetchedValue())
    fg_validite = DB.Column(DB.String(20), nullable=False)
    cd_typo = DB.Column(DB.ForeignKey('habitat.typoref.cd_typo', ondelete='CASCADE', onupdate='CASCADE'), nullable=False)
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
class CorHabitatTaxon(DB.Model):
    __tablename__ = 'cor_habitat_taxon'
    __table_args__ = {'schema': 'pr_monitoring_habitat_territory'}

    id_cor_habitat_taxon = DB.Column(DB.Integer, primary_key=True, server_default=DB.FetchedValue())
    id_habitat = DB.Column(DB.ForeignKey('habitat.habref.cd_hab', onupdate='CASCADE'), nullable=False)
    cd_nom = DB.Column(DB.Integer, nullable=False)

    #taxref = DB.relationship('Taxref', primaryjoin='CorHabitatTaxon.cd_nom == Taxref.cd_nom', backref='cor_habitat_taxons')
    habref = DB.relationship('Habref', primaryjoin='CorHabitatTaxon.id_habitat == Habref.cd_hab', backref='cor_habitat_taxons')


@serializable
class CorVisitPerturbation(DB.Model):
    __tablename__ = 'cor_visit_perturbation'
    __table_args__ = {'schema': 'pr_monitoring_habitat_territory'}

    id_base_visit = DB.Column(DB.ForeignKey('gn_monitoring.t_base_visits.id_base_visit', onupdate='CASCADE'), primary_key=True, nullable=False)
    id_nomenclature_perturbation = DB.Column(DB.ForeignKey('ref_nomenclatures.t_nomenclatures.id_nomenclature', onupdate='CASCADE'), primary_key=True, nullable=False)
    create_date = DB.Column(DB.DateTime, nullable=False)

    t_base_visit = DB.relationship('TBaseVisit', primaryjoin='CorVisitPerturbation.id_base_visit == TBaseVisit.id_base_visit', backref='cor_visit_perturbations')
    t_nomenclature = DB.relationship('TNomenclature', primaryjoin='CorVisitPerturbation.id_nomenclature_perturbation == TNomenclature.id_nomenclature', backref='cor_visit_perturbations')

""" @serializable
class MailleTmp(DB.Model):
    __tablename__ = 'maille_tmp'
    __table_args__ = {'schema': 'pr_monitoring_habitat_territory'}

    gid = DB.Column(DB.Integer, primary_key=True, server_default=DB.FetchedValue())
    fid = DB.Column(DB.Numeric)
    name = DB.Column(DB.String(254))
    descriptio = DB.Column(DB.String(254))
    timestamp = DB.Column(DB.String(24))
    begin = DB.Column(DB.String(24))
    end = DB.Column(DB.String(24))
    altitudemo = DB.Column(DB.String(254))
    tessellate = DB.Column(DB.Numeric)
    extrude = DB.Column(DB.Numeric)
    visibility = DB.Column(DB.Numeric)
    draworder = DB.Column(DB.Numeric)
    icon = DB.Column(DB.String(254))
    geom = DB.Column(Geometry('MULTIPOLYGON', 2154), index=True) """

@geoserializable
@serializable
class TInfosSite(DB.Model):
    __tablename__ = 't_infos_site'
    __table_args__ = {'schema': 'pr_monitoring_habitat_territory'}

    id_infos_site = DB.Column(DB.Integer, primary_key=True)
    id_base_site = DB.Column(DB.ForeignKey('gn_monitoring.t_base_sites.id_base_site'), nullable=False)
    cd_hab = DB.Column(DB.ForeignKey('habitat.habref.cd_hab'), nullable=False)

    # habref = DB.relationship('Habref', primaryjoin='TInfosSite.cd_hab == Habref.cd_hab', backref='t_infos_sites')
    #t_base_site = DB.relationship('TBaseSite', primaryjoin='TInfosSite.id_base_site == TBaseSite.id_base_site', backref='t_infos_sites')
    t_base_site = DB.relationship('TBaseSite')
    geom = association_proxy('t_base_site', 'geom')

    def get_geofeature(self, recursif=True):
        return self.as_geofeature(
            'geom',
            'id_infos_site',
            recursif
        )

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
