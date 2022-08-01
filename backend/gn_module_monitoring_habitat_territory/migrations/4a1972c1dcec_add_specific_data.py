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
# Add nomenclatures shared in conservation modules
depends_on = ("0a97fffb151c",)


def upgrade():
    operations = text(
        importlib.resources.read_text(
            "gn_module_monitoring_habitat_territory.migrations.data", "sht_data_ref.sql"
        )
    )
    op.get_bind().execute(operations)


def downgrade():
    operations = text(
        importlib.resources.read_text(
            "gn_module_monitoring_habitat_territory.migrations.data", "sht_delete_data_ref.sql"
        )
    )
    op.get_bind().execute(operations)
