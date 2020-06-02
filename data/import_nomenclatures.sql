BEGIN;

INSERT INTO ref_nomenclatures.t_nomenclatures (
    id_type,
    cd_nomenclature,
    mnemonique,
    label_default,
    definition_default,
    label_fr,
    definition_fr,
    id_broader,
    hierarchy
)
    SELECT
        ref_nomenclatures.get_id_nomenclature_type(:'typeCode'),
        :'code',
        :'mnemonique',
        :'label',
        :'definition',
        :'labelFr',
        :'definitionFr',
        ref_nomenclatures.get_id_nomenclature(:'typeCode', :'broader'),
        CONCAT(ref_nomenclatures.get_id_nomenclature_type(:'typeCode'), :'hierarchy')
WHERE NOT EXISTS (
    SELECT 'X'
    FROM ref_nomenclatures.t_nomenclatures
    WHERE cd_nomenclature = :'code'
        AND mnemonique = :'mnemonique'
);

COMMIT;
