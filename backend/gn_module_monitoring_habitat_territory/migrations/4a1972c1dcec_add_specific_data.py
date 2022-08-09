"""Add specific data

Revision ID: 4a1972c1dcec
Create Date: 2022-08-01 11:58:17.392946

"""
import importlib

from alembic import op
from sqlalchemy.sql import text


# revision identifiers, used by Alembic.
revision = '4a1972c1dcec'
down_revision = None
branch_labels = "sht"
depends_on = (
    "0a97fffb151c",  # Add nomenclatures shared in conservation modules
    "97d30ecf0cb1", # Add_M25m_mesh
    "f3877ed851b9",  # Add_M50m_mesh
    "e9a5e1372bce",  # Add_M100m_mesh
)


def upgrade():
    operations = text(
        importlib.resources.read_text(
            "gn_module_monitoring_habitat_territory.migrations.data", "data.sql"
        )
    )
    op.get_bind().execute(operations)


def downgrade():
    operations = text(
        importlib.resources.read_text(
            "gn_module_monitoring_habitat_territory.migrations.data", "delete_data.sql"
        )
    )
    op.get_bind().execute(operations)
