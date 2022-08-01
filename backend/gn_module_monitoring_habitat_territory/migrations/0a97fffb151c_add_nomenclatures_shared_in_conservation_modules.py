"""Add nomenclatures shared in conservation modules

Revision ID: 0a97fffb151c
Revises: None
Create Date: 2022-06-14 11:30:26.775634

"""
import importlib

from alembic import op
from sqlalchemy.sql import text
from csv import DictReader
from io import TextIOWrapper
import sqlalchemy as sa

from utils_flask_sqla.migrations.utils import logger


# revision identifiers, used by Alembic.
revision = '0a97fffb151c'
down_revision = None
branch_labels = "nomenclatures_shared_in_conservation_modules"
depends_on = (
    "f06cc80cc8ba", # GeoNature 2.7.5
)

"""
Insert CSV file into specified table.
If source columns are specified, CSV file in copied in a temporary table,
then data restricted to specified source columns are copied in final table.
"""


def copy_from_csv(f, schema, table, dest_cols='', source_cols=None,
                   header=True, encoding=None, delimiter=None):
    tmp_table = False
    if dest_cols:
        dest_cols = ' (' + ', '.join(dest_cols) + ')'
    if source_cols:
        final_table = table
        final_table_cols = dest_cols
        table = f'import_{table}'
        dest_cols = ''
        field_names = get_csv_field_names(
            f, encoding=encoding, delimiter=delimiter)
        op.create_table(table, *[sa.Column(c, sa.String)
                        for c in map(str.lower, field_names)], schema=schema)

    options = ["FORMAT CSV"]
    if header:
        options.append("HEADER")
    if encoding:
        options.append(f"ENCODING '{encoding}'")
    if delimiter:
        options.append(f"DELIMITER E'{delimiter}'")
    options = ', '.join(options)
    cursor = op.get_bind().connection.cursor()
    cursor.copy_expert(f"""
        COPY {schema}.{table}{dest_cols}
        FROM STDIN WITH ({options})
    """, f)

    if source_cols:
        source_cols = ', '.join(source_cols)
        op.execute(f"""
        INSERT INTO {schema}.{final_table}{final_table_cols}
          SELECT {source_cols}
            FROM {schema}.{table};
        """)
        op.drop_table(table, schema=schema)


def get_csv_field_names(f, encoding, delimiter):
    if encoding == 'WIN1252':  # postgresql encoding
        encoding = 'cp1252'    # python encoding
    # t = TextIOWrapper(f, encoding=encoding)
    reader = DictReader(f, delimiter=delimiter)
    field_names = reader.fieldnames
    # t.detach()  # avoid f to be closed on t garbage collection
    f.seek(0)
    return field_names


def upgrade():
    cursor = op.get_bind().connection.cursor()
    with importlib.resources.open_text(
        "gn_module_priority_flora.migrations.data", "perturbation_nomenclatures.csv"
    ) as csvfile:
        logger.info("Inserting perturbations nomenclatures…")
        copy_from_csv(
            csvfile,
            'ref_nomenclatures',
            't_nomenclatures', 
            dest_cols=(
                'id_type',
                'cd_nomenclature',
                'mnemonique',
                'label_default',
                'definition_default',
                'label_fr',
                'definition_fr',
                'id_broader',
                'hierarchy',
            ),
            source_cols=(
                'ref_nomenclatures.get_id_nomenclature_type(type_nomenclature_code)',
                'cd_nomenclature', 
                'mnemonique', 
                'label_default', 
                'definition_default', 
                'label_fr', 
                'definition_fr',
                'ref_nomenclatures.get_id_nomenclature(type_nomenclature_code, cd_nomenclature_broader)',
                'hierarchy',
            ),
            header=True, 
            encoding='UTF-8', 
            delimiter=','
        )


def downgrade():
    delete_nomenclatures("TYPE_PERTURBATION")


def delete_nomenclatures(mnemonique):
    operation = text(
        """
        DELETE FROM ref_nomenclatures.t_nomenclatures
        WHERE id_type = (
            SELECT id_type 
            FROM ref_nomenclatures.bib_nomenclatures_types
            WHERE mnemonique = :mnemonique
        );
        DELETE FROM ref_nomenclatures.bib_nomenclatures_types
        WHERE mnemonique = :mnemonique
        """
    )
    op.get_bind().execute(operation, {"mnemonique": mnemonique})
