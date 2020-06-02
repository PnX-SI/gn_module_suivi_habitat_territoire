BEGIN;

DELETE FROM taxonomie.cor_nom_liste
WHERE
    id_liste IN (SELECT id_liste FROM taxonomie.bib_listes WHERE nom_liste = :'taxonsListName')
    AND id_nom = (SELECT id_nom FROM taxonomie.bib_noms WHERE cd_nom = :nameId);

COMMIT;
