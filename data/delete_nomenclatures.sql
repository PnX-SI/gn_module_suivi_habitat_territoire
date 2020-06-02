BEGIN;

DELETE FROM ref_nomenclatures.t_nomenclatures
WHERE id_type = ref_nomenclatures.get_id_nomenclature_type(:'typeCode')
    AND cd_nomenclature = :'code' ;

COMMIT;
