CREATE or replace FUNCTION file_get_contents(p_file text) RETURNS text AS $f$
   with open(args[0],"r") as content_file:
       content = content_file.read()
   return content
$f$ LANGUAGE PLpythonU;  -- untrusted can read from any folder!

CREATE or replace FUNCTION file_put_contents(p_file text, p_content text) RETURNS text AS $f$
  # see https://stackoverflow.com/a/48485531/287948
  o=open(args[0],"w")
  o.write(args[1]) # no +"\n", no magic EOL
  o.close()
  return "ok"
$f$ LANGUAGE PLpythonU;

CREATE FUNCTION neuro.apres_tipo(p_tipo text) RETURNS text AS $f$
  SELECT ('{"Aprovado para Apresentação Oral":"Oral","Aprovado para Pôster Impresso":"Pôster"}'::jsonb)->>$1
$f$ LANGUAGE SQL IMMUTABLE;

CREATE or replace FUNCTION trim2(p_tipo text) RETURNS text AS $f$
  SELECT trim($1,' ,.;/')
$f$ LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION neuro.split_autores(
  p_autores text, p_aut_responsavel text DEFAULT NULL
) RETURNS jsonb AS $f$
  SELECT jsonb_agg( jsonb_build_object(
     'nome_full',   nome_full,
     'nome_abbrev', nome_abbrev,
     'aff',         aff,
     'aff_id',      aff_id,
     'is_corresp', is_corresp,
     'contrib_id', contrib_id
   ) )
  FROM (
   SELECT  *,
     COALESCE( unaccent(upper(p_aut_responsavel))=unaccent(upper(nome_full)), false ) is_corresp,
     row_number() OVER (PARTITION BY true) contrib_id,
     DENSE_RANK() OVER ( ORDER BY unaccent(upper(aff)) ) aff_id
   FROM (
      SELECT DISTINCT
        trim2(p[1]) nome_full,
        trim2(p[2]) nome_abbrev,
        trim2(p[3]) aff
      FROM (
        SELECT regexp_split_to_array(trim(str_a,'/'),'/') p
        FROM (  SELECT trim(regexp_split_to_table(trim($1,';'), ';')) )  t1(str_a)
      ) t2
   ) t3
  ) t4
$f$ LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION neuro.metadata_bycod(p_codigo int) RETURNS jsonb AS $f$
  select ( (to_jsonb(t1) - 'resumo') - 'autores' )
         || jsonb_build_object(
             'modal',neuro.apres_tipo(modalidade),
             'contribs',neuro.split_autores(autores,aut_responsavel)
         ) j
  from neuro.reltrabalhos t1
  where codigo=$1
$f$ LANGUAGE SQL IMMUTABLE;

CREATE VIEW neuro.vw_relxml1 AS
 SELECT xmlelement(
   name "article-dump",
   xmlattributes(
       1 as version_id, codigo as article_id,
       CASE WHEN num_painel IS NULL THEN 'O'|| DENSE_RANK() OVER (ORDER BY codigo) ELSE 'P'||num_painel END as  pub_id,
       'working' as status, 'simple-jatsfront-level1' as dtd_label
    ),
   xmlelement(name article,
 	xmlattributes('1.0' as "dtd-version", 'congress-abstract' as "article-type", 'interchange' as "specific-use"),
 	xmlelement(name "article-title",titulo),
 	xmlelement(name abstract,resumo)
   ),
   xmlelement( name metadata_json,  jsonb_pretty(neuro.metadata_bycod(codigo)) )
 ) x
 FROM neuro.relTrabalhos
 ORDER BY codigo
;
