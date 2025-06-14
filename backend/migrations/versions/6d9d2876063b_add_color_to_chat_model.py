"""Add color to Chat model

Revision ID: 6d9d2876063b
Revises: 10977623d348
Create Date: 2025-05-16 05:26:04.056385

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '6d9d2876063b'
down_revision = '10977623d348'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('chat', schema=None) as batch_op:
        batch_op.add_column(sa.Column('color', sa.String(length=7), nullable=True))
        batch_op.alter_column('created_at',
               existing_type=sa.DATETIME(),
               nullable=False)
        batch_op.alter_column('last_accessed_at',
               existing_type=sa.DATETIME(),
               nullable=False)
        batch_op.alter_column('status',
               existing_type=sa.VARCHAR(length=20),
               type_=sa.String(length=50),
               existing_nullable=False)
        batch_op.alter_column('universo',
               existing_type=sa.VARCHAR(length=50),
               type_=sa.String(length=100),
               existing_nullable=True)
        batch_op.alter_column('inspiracao',
               existing_type=sa.VARCHAR(length=255),
               type_=sa.Text(),
               existing_nullable=True)

    with op.batch_alter_table('message', schema=None) as batch_op:
        batch_op.alter_column('sender',
               existing_type=sa.VARCHAR(length=10),
               type_=sa.String(length=50),
               existing_nullable=False)
        batch_op.alter_column('timestamp',
               existing_type=sa.DATETIME(),
               nullable=False)

    with op.batch_alter_table('user', schema=None) as batch_op:
        batch_op.alter_column('password_hash',
               existing_type=sa.VARCHAR(length=128),
               type_=sa.String(length=256),
               nullable=False)

    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('user', schema=None) as batch_op:
        batch_op.alter_column('password_hash',
               existing_type=sa.String(length=256),
               type_=sa.VARCHAR(length=128),
               nullable=True)

    with op.batch_alter_table('message', schema=None) as batch_op:
        batch_op.alter_column('timestamp',
               existing_type=sa.DATETIME(),
               nullable=True)
        batch_op.alter_column('sender',
               existing_type=sa.String(length=50),
               type_=sa.VARCHAR(length=10),
               existing_nullable=False)

    with op.batch_alter_table('chat', schema=None) as batch_op:
        batch_op.alter_column('inspiracao',
               existing_type=sa.Text(),
               type_=sa.VARCHAR(length=255),
               existing_nullable=True)
        batch_op.alter_column('universo',
               existing_type=sa.String(length=100),
               type_=sa.VARCHAR(length=50),
               existing_nullable=True)
        batch_op.alter_column('status',
               existing_type=sa.String(length=50),
               type_=sa.VARCHAR(length=20),
               existing_nullable=False)
        batch_op.alter_column('last_accessed_at',
               existing_type=sa.DATETIME(),
               nullable=True)
        batch_op.alter_column('created_at',
               existing_type=sa.DATETIME(),
               nullable=True)
        batch_op.drop_column('color')

    # ### end Alembic commands ###
