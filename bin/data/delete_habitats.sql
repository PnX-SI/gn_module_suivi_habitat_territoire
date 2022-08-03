BEGIN;

\echo '--------------------------------------------------------------------------------'
\echo 'Delete habitats in SHT habitats list'
DELETE FROM ref_habitats.cor_list_habitat
WHERE id_list IN (
    SELECT id_list AS id
    FROM ref_habitats.bib_list_habitat
    WHERE list_name ILIKE :'habitatsListName'
)
AND cd_hab IN (
    SELECT DISTINCT cd_hab
    FROM :moduleSchema.:habitatsTmpTable
);


\echo '--------------------------------------------------------------------------------'
\echo 'Delete link between habitats and taxons'
DELETE FROM :moduleSchema.cor_habitat_taxon
WHERE id_cor_habitat_taxon IN (
    SELECT cht.id_cor_habitat_taxon
    FROM :moduleSchema.cor_habitat_taxon as cht
        JOIN :moduleSchema.:habitatsTmpTable AS h
            ON (cht.id_habitat = h.cd_hab AND cht.cd_nom = h.cd_nom)
);


\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;
