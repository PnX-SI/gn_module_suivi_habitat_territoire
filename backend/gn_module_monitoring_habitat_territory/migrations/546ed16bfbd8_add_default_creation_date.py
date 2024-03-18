"""add default creation date

Revision ID: 546ed16bfbd8
Revises: f2507963a8bd
Create Date: 2024-03-13 16:57:38.439853

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '546ed16bfbd8'
down_revision = 'f2507963a8bd'
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        alter table pr_monitoring_habitat_territory.cor_visit_perturbation 
        alter column create_date set default now();
        """
    )


def downgrade():
    op.execute(
        """
        alter table pr_monitoring_habitat_territory.cor_visit_perturbation 
        alter column create_date drop default;
        """
    )
