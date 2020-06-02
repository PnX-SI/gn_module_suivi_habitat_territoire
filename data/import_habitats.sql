BEGIN;

-- ----------------------------------------------------------------------------
\echo 'Insert habitats in SHT habitats list'
WITH habitat_list AS (
    SELECT id_list AS id
    FROM ref_habitats.bib_list_habitat
    WHERE list_name ILIKE :'habitatsListName'
)
INSERT INTO ref_habitats.cor_list_habitat (id_list, cd_hab)
    SELECT DISTINCT ON (h.cd_hab) l.id, h.cd_hab
    FROM habitat_list AS l, :moduleSchema.:habitatsTmpTable AS h
WHERE NOT EXISTS (
    SELECT 'X'
    FROM ref_habitats.cor_list_habitat AS clh
    WHERE clh.id_list = l.id
        AND clh.cd_hab = h.cd_hab
);
\echo ''

-- ----------------------------------------------------------------------------
\echo 'Insert link between habitats and taxons'
INSERT INTO :moduleSchema.cor_habitat_taxon (id_habitat, cd_nom)
    SELECT cd_hab, cd_nom
    FROM :moduleSchema.:habitatsTmpTable AS h
WHERE NOT EXISTS (
    SELECT 'X'
    FROM :moduleSchema.cor_habitat_taxon AS cht
    WHERE cht.id_habitat = h.cd_hab
        AND cht.cd_nom = h.cd_nom
);
\echo ''

-- ----------------------------------------------------------------------------
COMMIT;
