BEGIN;

-- Insert or update taxon names (used for autocomplete field in SFT filter form)
WITH try_insert_name AS (
    INSERT INTO taxonomie.bib_noms (cd_nom, cd_ref, nom_francais, comments)
        VALUES (:nameId, :nameRef, :'name', :'comment')
        ON CONFLICT ON CONSTRAINT bib_noms_cd_nom_key
            DO UPDATE SET
                comments = :'comment',
                nom_francais = :'name'
        RETURNING id_nom AS name_id
), new_name AS (
    SELECT name_id FROM try_insert_name
    UNION ALL
    SELECT id_nom AS name_id FROM taxonomie.bib_noms WHERE cd_nom = :nameId
    LIMIT 1
) INSERT INTO taxonomie.cor_nom_liste (id_nom, id_liste)
    VALUES (
        (SELECT name_id FROM new_name),
        (SELECT id_liste FROM taxonomie.bib_listes WHERE nom_liste = :'taxonsListName' ORDER BY id_liste ASC)
    )
    ON CONFLICT ON CONSTRAINT cor_nom_liste_pkey DO NOTHING;

-- Delete duplicates rows in autocomplete table
WITH tax_list AS (
    SELECT id_liste AS id
    FROM taxonomie.bib_listes
    WHERE nom_liste = :'taxonsListName'
    ORDER BY id_liste ASC
    LIMIT 1
)
DELETE FROM taxonomie.vm_taxref_list_forautocomplete AS vtlf1
USING taxonomie.vm_taxref_list_forautocomplete AS vtlf2, tax_list
WHERE vtlf1.ctid < vtlf2.ctid
	AND vtlf1.cd_nom = vtlf2.cd_nom
	AND vtlf1.cd_ref = vtlf2.cd_ref
	AND vtlf1.id_liste = vtlf2.id_liste
	AND vtlf1.id_liste = (SELECT id FROM tax_list);

COMMIT;
