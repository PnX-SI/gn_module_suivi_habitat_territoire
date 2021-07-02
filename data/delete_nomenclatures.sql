BEGIN;

\echo '--------------------------------------------------------------------------------'
\echo 'Delete nomenclatures of perturbations type'
DELETE FROM ref_nomenclatures.t_nomenclatures
WHERE id_type = ref_nomenclatures.get_id_nomenclature_type(:'typeCode')
    AND cd_nomenclature = :'code' ;

\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;
