"""create shema

Revision ID: ad6a22b06caf
Revises: 4a1972c1dcec
Create Date: 2022-08-02 09:06:46.349489

"""
import importlib

from alembic import op
from sqlalchemy.sql import text

# revision identifiers, used by Alembic.
revision = "ad6a22b06caf"
down_revision = "4a1972c1dcec"
branch_labels = None
depends_on = None


def upgrade():
    operations = text(
        importlib.resources.read_text(
            "gn_module_monitoring_habitat_territory.migrations.data", "schema.sql"
        )
    )
    op.get_bind().execute(operations)


def downgrade():
    op.execute("DROP SCHEMA pr_monitoring_habitat_territory CASCADE")
