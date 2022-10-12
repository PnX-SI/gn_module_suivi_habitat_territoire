# coding: utf-8
from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Column,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text
)
from sqlalchemy.ext.associationproxy import association_proxy
from sqlalchemy.schema import FetchedValue
from geoalchemy2.types import Geometry
from sqlalchemy.dialects.postgresql.base import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql.expression import func

from pypnusershub.db.models import User
from utils_flask_sqla.serializers import serializable
from utils_flask_sqla.generic import GenericQuery
from utils_flask_sqla_geo.serializers import geoserializable
from geonature.utils.env import DB

from geonature.utils.utilsgeometry import shapeserializable
from geonature.core.gn_monitoring.models import TBaseSites, TBaseVisits, corVisitObserver

@serializable
class CorVisitTaxon(DB.Model):
    __tablename__ = 'cor_visit_taxons'
    __table_args__ = {'schema': 'pr_monitoring_habitat_territory'}

    id_cor_visite_taxons = DB.Column(
        DB.Integer,
        nullable=False,
        server_default=DB.FetchedValue(),
        primary_key=True
    )
    id_base_visit = DB.Column(
        DB.ForeignKey(
            'gn_monitoring.t_base_visits.id_base_visit',
            ondelete='CASCADE',
            onupdate='CASCADE'
        )
    )
    cd_nom = DB.Column(DB.Integer)

@serializable
class CorVisitPerturbation(DB.Model):
    __tablename__ = 'cor_visit_perturbation'
    __table_args__ = {'schema': 'pr_monitoring_habitat_territory'}

    id_base_visit = DB.Column(
        "id_base_visit",
        DB.Integer,
        ForeignKey("gn_monitoring.t_base_visits.id_base_visit"),
        primary_key=True,
    )
    id_nomenclature_perturbation = DB.Column(
        "id_nomenclature_perturbation",
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        primary_key=True,
    )
    create_date = DB.Column(
        DB.DateTime,
        nullable=False,
        default=func.now()
    )

    t_nomenclature = DB.relationship(
        "TNomenclatures",
    )

@serializable
class TVisitSHT(TBaseVisits):
    __tablename__ = 't_base_visits'
    __table_args__ = {
        'schema': 'gn_monitoring',
        'extend_existing': True,
    }

    cor_visit_perturbation = DB.relationship(
        'CorVisitPerturbation',
        lazy="joined",
        backref='t_base_visits'
    )
    cor_visit_taxons = DB.relationship(
        "CorVisitTaxon",
        lazy="joined",
        backref='t_base_visits'
    )

@serializable
class CorHabitatTaxon(DB.Model):
    __tablename__ = 'cor_habitat_taxon'
    __table_args__ = {'schema': 'pr_monitoring_habitat_territory'}

    id_cor_habitat_taxon = DB.Column(
        "id_cor_habitat_taxon",
        DB.Integer,
        primary_key=True,
        server_default=DB.FetchedValue()
    )
    id_habitat = DB.Column(
        "id_habitat",
        DB.Integer,
        ForeignKey("ref_habitats.habref.cd_hab"),
        primary_key=True,
        nullable=False
    )
    cd_nom = DB.Column(
        DB.Integer,
        nullable=False
    )

    habref = DB.relationship(
        'Habref',
    )

@geoserializable
@serializable
class TInfosSite(DB.Model):
    __tablename__ = 't_infos_site'
    __table_args__ = {'schema': 'pr_monitoring_habitat_territory'}

    id_infos_site = DB.Column(
        DB.Integer,
        primary_key=True
    )
    id_base_site = DB.Column(
        DB.ForeignKey('gn_monitoring.t_base_sites.id_base_site'),
        nullable=False
    )
    cd_hab = DB.Column(
        DB.ForeignKey('ref_habitats.habref.cd_hab'),
        nullable=False
    )

    t_base_site = DB.relationship('TBaseSites')
    geom = association_proxy('t_base_site', 'geom')

    def get_geofeature(self):
        return self.as_geofeature('geom', 'id_infos_site')

@serializable
@geoserializable
@shapeserializable
class ExportVisits(DB.Model):
    __tablename__ = 'export_visits'
    __table_args__ = {'schema': 'pr_monitoring_habitat_territory'}

    idbvisit = DB.Column(
        DB.Integer,
        primary_key=True
    )

    idbsite = DB.Column(DB.Integer)
    visitdate = DB.Column(DB.DateTime)
    observers = DB.Column(DB.Unicode)
    organisme = DB.Column(DB.Unicode)
    bsitename = DB.Column(DB.Unicode)
    area_name = DB.Column(DB.Unicode)
    lbhab = DB.Column(DB.Unicode)
    nomvtaxon = DB.Column(DB.Unicode)
    cd_hab = DB.Column(DB.Integer)
    comments = DB.Column(DB.Unicode)
    lbperturb = DB.Column(DB.Unicode)
    geom = DB.Column(Geometry('GEOMETRY', 2154))
    geojson = DB.Column(DB.Unicode)
    covtaxons = DB.Column(DB.Unicode)
