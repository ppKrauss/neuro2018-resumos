
CREATE or replace FUNCTION file_get_contents(p_file text) RETURNS text AS $f$
   with open(args[0],"r") as content_file:
       content = content_file.read()
   return content
$f$ LANGUAGE PLpythonU;  -- untrusted can read from any folder!

CREATE or replace FUNCTION array_distinct_sort (
  ANYARRAY,
  p_no_null boolean DEFAULT true
) RETURNS ANYARRAY AS $f$
  SELECT CASE WHEN array_length(x,1) IS NULL THEN NULL ELSE x END -- same as  x='{}'::anyarray
  FROM (
  	SELECT ARRAY(
        SELECT DISTINCT x
        FROM unnest($1) t(x)
        WHERE CASE
          WHEN p_no_null  THEN  x IS NOT NULL
          ELSE  true
          END
        ORDER BY 1
   )
 ) t(x)
$f$ language SQL strict IMMUTABLE;

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

ALTER TABLE neuro.reltrabalhos ADD COLUMN pub_id text;
UPDATE neuro.reltrabalhos
SET pub_id = t2.pub_prefix||chr(160)|| CASE
      WHEN num_painel IS NULL THEN  lpad(rk::text, 2, '0')
      ELSE  lpad(num_painel::text, 4, '0')
      END
FROM (
  SELECT *, DENSE_RANK() OVER (partition by pub_prefix ORDER BY codigo) rk
  FROM (
    SELECT codigo, CASE WHEN num_painel IS NULL THEN 'TL' ELSE 'PO' END as pub_prefix
    FROM neuro.reltrabalhos
    ORDER BY codigo
  ) t1
) t2
WHERE t2.codigo=reltrabalhos.codigo;

CREATE VIEW neuro.vw_relxml1 AS
 SELECT xmlelement(
   name "article-dump",
   xmlattributes(
       1 as version_id, codigo as article_id,
       pub_id as pub_id,
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

CREATE or replace FUNCTION neuro.sumario( p_tipo text DEFAULT 'Oral') RETURNS xml AS $f$
  SELECT xmlelement(name section,
    xmlelement(name title, p_tipo),
    (
      SELECT xmlagg(line) cpa
      FROM (
       SELECT xmlelement(name p , '- Tema '||DENSE_RANK() OVER (ORDER BY temario) || ' - '||temario||' ... '|| n ||' resumos')
       line
       FROM (
         SELECT temario, count(*) n
         FROM neuro.reltrabalhos rr
         WHERE neuro.apres_tipo(modalidade)=$1
         group by 1 order by 1
       ) t1
      ) t2
    ),
    (SELECT  xmlelement(
      name p,
      '(Total na seção: ' ||count(*) || ' resumos)'
      )
      FROM neuro.reltrabalhos  WHERE neuro.apres_tipo(modalidade)=$1
    )
  )
$f$ LANGUAGE SQL IMMUTABLE;


CREATE or replace FUNCTION name_for_index(p_name text) RETURNS text AS $f$
  SELECT upper(x[array_length(x,1)])||','||chr(160)|| initcap(array_to_string(x[1:array_length(x,1)-1],' '))
  FROM regexp_split_to_array($1, E'\\s+') t(x);
$f$ LANGUAGE SQL IMMUTABLE;

CREATE or replace FUNCTION iniciais(p_name text[], p_sep text DEFAULT '') RETURNS text AS $f$
  SELECT array_to_string(array_agg(upper( substr(xx,1,1)  )),$2)
  FROM unnest($1) t(x), LATERAL trim(x,'. ,;') t2(xx)
  WHERE upper(xx) NOT IN ('DE','DA', 'DOS', 'DAS');
$f$ LANGUAGE SQL IMMUTABLE;

CREATE or replace FUNCTION name_for_resumo(
  p_name text,
  p_name_abrev text default NULL
) RETURNS text AS $f$
  SELECT initcap(  CASE WHEN use_abbrev THEN x[1] ELSE x[array_length(x,1)] END  )||chr(160)||
  CASE
    WHEN use_abbrev THEN regexp_replace(array_to_string(x[2:],''),'[\.,; ]+','','g')
    ELSE CASE WHEN array_length(x,1)>1 THEN iniciais(x[1:array_length(x,1)-1]) ELSE '?' END
    END
  FROM (
    SELECT p_name_abrev IS NOT NULL AND trim(upper(p_name_abrev))!=trim(upper($1))
  ) t2(use_abbrev), LATERAL regexp_split_to_array(CASE WHEN use_abbrev THEN $2 ELSE $1 END, E'[\\s+,;]') t1(x)
$f$ LANGUAGE SQL IMMUTABLE;

CREATE or replace FUNCTION name_for_resumo_BOM(
  p_name text,
  p_name_abrev text default NULL
) RETURNS text AS $f$
  SELECT initcap(  CASE WHEN ck THEN x[1] ELSE x[array_length(x,1)] END  )||chr(160)|| CASE
    WHEN ck THEN regexp_replace(array_to_string(x[2:],''),'[\.,; ]+','','g')
    ELSE iniciais(x[1:array_length(x,1)-1])
    END
  FROM (
    SELECT p_name_abrev IS NOT NULL AND trim(upper(p_name_abrev))!=trim(upper($1))
  ) t2(ck), LATERAL regexp_split_to_array(CASE WHEN ck THEN $2 ELSE $1 END, E'[\\s+,;]') t1(x)
$f$ LANGUAGE SQL IMMUTABLE;

CREATE VIEW neuro.vw_contribs AS
  SELECT codigo, array_agg(nome||'<sup>'||aff_id||'</sup>') name_list,
         array_distinct_sort(array_agg(replace(aff,'&','&amp;'))) aff_list
  FROM (
    SELECT DISTINCT codigo, pub_id, aff_id,
      name_for_resumo(nome_full, nome_abbrev) nome,
      '<sup>'||aff_id||'</sup>'||aff aff
    FROM neuro.relTrabalhos,
         LATERAL jsonb_to_recordset( (neuro.metadata_bycod(codigo))->'contribs' )
         t(nome_full text,nome_abbrev text, aff_id int, aff text)
  ) t
  GROUP BY 1
  ORDER BY 1
;

CREATE or replace VIEW neuro.vw_corpo AS
  SELECT --xmlelement(name div, xmlattributes('bloco' as class)
  xmlconcat(
    xmlelement(name p, xmlattributes('abstractid-p' as class),
      xmlelement(name a, xmlattributes(replace(r.pub_id,chr(160),'') as name),r.pub_id)
    ),
    xmlelement(name p, xmlattributes('abstractid-p' as class), r.titulo),
    xmlelement(name p, xmlattributes('contrib-group' as class), array_to_string(c.name_list,'; ')::xml),
    xmlelement(name p, xmlattributes('aff-list' as class), (' '||array_to_string(c.aff_list,'; '))::xml),
    xmlelement(name p, xmlattributes('email' as class), '* E-mail: '||r.email),
    xmlelement(name p, xmlattributes('abstract' as class), resumo),
    xmlelement(name p, xmlattributes('event' as class),
      'Apresentação: '||array_to_string(array[TO_CHAR(r.data,'dd/mm/yyyy'),r.sala,r.hora],', '))
  ) resumo_full
  FROM neuro.relTrabalhos r INNER JOIN neuro.vw_contribs c ON c.codigo=r.codigo
;
