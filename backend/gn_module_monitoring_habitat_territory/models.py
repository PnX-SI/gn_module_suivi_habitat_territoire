# coding: utf-8
from flask import g
from sqlalchemy import ForeignKey, and_
from sqlalchemy.ext.associationproxy import association_proxy

from geoalchemy2.types import Geometry
from sqlalchemy.dialects.postgresql.base import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql.expression import select, func

from pypnusershub.db.models import User
from utils_flask_sqla.serializers import serializable
from utils_flask_sqla.generic import GenericQuery
from utils_flask_sqla_geo.serializers import geoserializable, shapeserializable
from geonature.utils.env import DB

from geonature.core.gn_monitoring.models import TBaseSites, TBaseVisits, corVisitObserver

from pypnnomenclature.models import TNomenclatures


@serializable
class CorVisitTaxon(DB.Model):
    __tablename__ = "cor_visit_taxons"
    __table_args__ = {"schema": "pr_monitoring_habitat_territory"}

    id_cor_visite_taxons = DB.Column(
        DB.Integer, nullable=False, server_default=DB.FetchedValue(), primary_key=True
    )
    id_base_visit = DB.Column(
        DB.ForeignKey(
            "gn_monitoring.t_base_visits.id_base_visit", ondelete="CASCADE", onupdate="CASCADE"
        )
    )
    cd_nom = DB.Column(DB.Integer)

cor_visit_perturbation = DB.Table(
    "cor_visit_perturbation",
    DB.Column(
        "id_base_visit",
        DB.Integer,
        ForeignKey("gn_monitoring.t_base_visits.id_base_visit"),
        primary_key=True,
    ),
    DB.Column(
        "id_nomenclature_perturbation",
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        primary_key=True,
    ),

    schema="pr_monitoring_habitat_territory"
)

class VisitAuthMixin(object):
    def user_is_observer_or_digitiser(self, user):
        if user.id_role == self.id_digitiser:
            return True
        for obs in self.observers:
            if obs.id_role == user.id_role:
                return True
        return False

    def user_is_in_organism_of_visit(self, user):
        for obs in self.observers:
            if obs.id_organisme == user.id_organism:
                return True
        return False
    
    def has_instance_permission(self, scope)-> bool:
        """
        Fonction permettant de dire si un utilisateur
        peu ou non agir sur une donnée
        """
        if scope == 0 or scope not in (1, 2, 3):
            return False

        if scope == 3:
            return True

        # Si l'utilisateur est propriétaire de la données
        if self.user_is_observer_or_digitiser(g.current_user):
            return True

        if scope == 2 and self.user_is_in_organism_of_visit(g.current_user) :
            return True
        return False

@serializable
class TVisitSHT(TBaseVisits, VisitAuthMixin):
    __tablename__ = "t_base_visits"
    __table_args__ = {
        "schema": "gn_monitoring",
        "extend_existing": True,
    }

    perturbations = DB.relationship(
        TNomenclatures, secondary=cor_visit_perturbation,
        lazy="joined",
    )
    cor_visit_taxons = DB.relationship("CorVisitTaxon", lazy="joined", backref="t_base_visits")



        
    


@serializable
class CorHabitatTaxon(DB.Model):
    __tablename__ = "cor_habitat_taxon"
    __table_args__ = {"schema": "pr_monitoring_habitat_territory"}

    id_cor_habitat_taxon = DB.Column(
        "id_cor_habitat_taxon", DB.Integer, primary_key=True, server_default=DB.FetchedValue()
    )
    id_habitat = DB.Column(
        "id_habitat",
        DB.Integer,
        ForeignKey("ref_habitats.habref.cd_hab"),
        primary_key=True,
        nullable=False,
    )
    cd_nom = DB.Column(
        DB.Integer, 
        ForeignKey("taxonomie.taxref.cd_nom"),
        nullable=False,
    )

    habref = DB.relationship(
        "Habref",
    )
    taxref = DB.relationship(
        "Taxref",
        order_by="Taxref.nom_complet"
    )



@geoserializable
@serializable
class TInfosSite(TBaseSites):
    __tablename__ = "t_infos_site"
    __table_args__ = {"schema": "pr_monitoring_habitat_territory"}

    id_infos_site = DB.Column(DB.Integer, primary_key=True)
    id_base_site = DB.Column(
        DB.ForeignKey("gn_monitoring.t_base_sites.id_base_site"), nullable=False
    )
    cd_hab = DB.Column(DB.ForeignKey("ref_habitats.habref.cd_hab"), nullable=False)

    def get_geofeature(self):
        return self.as_geofeature("geom", "id_infos_site")

    @staticmethod
    def has_already_visit_in_year(id_base_site, year)->bool:
        query = select(TInfosSite).join(TBaseVisits).where(
            func.date_part('year', TBaseVisits.visit_date_min) == year,
            TInfosSite.id_base_site == id_base_site
        ).limit(1)
        return bool(DB.session.execute(query).unique().one_or_none())


@serializable
@geoserializable
@shapeserializable
class ExportVisits(DB.Model):
    __tablename__ = "export_visits"
    __table_args__ = {"schema": "pr_monitoring_habitat_territory"}

    id_base_visit = DB.Column(DB.Integer, primary_key=True)
    visit_date = DB.Column(DB.DateTime)
    visit_comment = DB.Column(DB.Unicode)
    id_base_site = DB.Column(DB.Integer)
    base_site_name = DB.Column(DB.Unicode)
    base_site_code = DB.Column(DB.Unicode)
    base_site_uuid = DB.Column(UUID(as_uuid=True))
    geom = DB.Column(Geometry("GEOMETRY", 2154))
    geojson = DB.Column(DB.Unicode)
    municipalities = DB.Column(DB.Unicode)
    habitat_name = DB.Column(DB.Unicode)
    habitat_code = DB.Column(DB.Integer)
    perturbations = DB.Column(DB.Unicode)
    observers = DB.Column(DB.Unicode)
    organisms = DB.Column(DB.Unicode)
    taxons_scinames = DB.Column(DB.Unicode)
    taxons_scinames_codes = DB.Column(DB.Unicode)
