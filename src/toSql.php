<?php
/**
 * Alinha material fornecido e gera XML a partir do PostgreSQL.
 * Permite uso de SQL intermediário para debug. Modo de usar:
 *   cp data/*.csv /tmp
 *   php src/toSql.php | psql "postgresql://postgres:postgres@localhost:5432/trydatasets"
 *   # resultado em /tmp/neuro2018.xml
 */

// LIXO, $csvFields from datapackage fora de uso, ver array originais
// $j =json_decode(file_get_contents('datapackage.json'), JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
// $csvFields = $j['resources'][0]['schema']['fields'];
// print 'DEBUG:'.json_encode($csvFields, JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);

$SCH = 'neuro';

$original = [
  'apresOral' => 'codigo int,titulo,resumo,temario,modalidade,aut_responsavel,autores',
  'apresPoster' => 'codigo int,titulo,resumo,temario,modalidade,aut_responsavel,autores',
  'relTrabalhos' => 'codigo int,titulo,resumo,temario,modalidade,num_painel,data date,hora,sala,apresentador,aut_responsavel,email,telefones,cidade,estado,pais,autores',
  'IDcont' => 'num_painel,contagem int',
];

$sql1 = $sql2 = '';
foreach ($original as $k=>$fields) {
	$f = "data/original-$k.csv";
	$linha0 = fgets(fopen($f, 'r'));
	// print "\n\n-- $f = $fields\n\t= $linha0";
	$fields0 = [];
	$field0_names = [];
	foreach( explode(',',$linha0) as $r) {
		$field0_names[] = "\"$r\"";
		$fields0[] = "\"$r\" text";
	}
	$join_fields0 = join(", ",$fields0);

	$sql1 .= <<<EOT
DROP FOREIGN TABLE IF EXISTS tmpcsv_$k CASCADE;
CREATE FOREIGN TABLE tmpcsv_$k (
	$join_fields0
) SERVER files OPTIONS (
	filename '/tmp/original-$k.csv',
	format 'csv',
	header 'true'
);
EOT;
	$sql1 .= "\n";
	$types = [];
	$fields1 = [];
	foreach( explode(',',$fields) as $r) {
		$p = strrpos($r,' ');
		if ($p===false) {
			$types[] = 'text';
			$fields1[] = "$r text";
		} else {
			$fields1[] = $r;
			$types[] = substr($r,$p+1);
		}
	}
	$fields1 = join(", ",$fields1);
	$sql2 .=  "\nCREATE TABLE $SCH.$k (\n\t$fields1);";
	$map = [];
	for ($i=0; $i<count($field0_names); $i++)
		$map[] = " trim($field0_names[$i])::$types[$i]";
	$sql2 .=  "\nINSERT INTO $SCH.$k SELECT ".join(',',$map)." FROM tmpcsv_$k;\n\n";
}

?>

-- cp data/*.csv /tmp

CREATE EXTENSION file_fdw;
CREATE SERVER files FOREIGN DATA WRAPPER file_fdw;

<?php print $sql1 ?>

<?php print "DROP SCHEMA IF EXISTS $SCH CASCADE; CREATE SCHEMA $SCH;\n$sql2" ?>

<?php include 'src/lib.sql' ?>

SELECT file_put_contents(
      '/tmp/neuro2018.xml',
      replace(
         xmlelement( name dumps,  xmlagg(x) )::text,
         '<article-dump',
         E'\n\n<article-dump'
      )
    )
FROM neuro.vw_relxml1;

-- Indice da Capa:
SELECT file_put_contents(
  '/tmp/neuro2018_capa.htm',
  xmlconcat(
    neuro.sumario('Oral'),
    neuro.sumario('Pôster'),
    (select xmlelement(name p, 'Total geral '|| (SELECT count(*) FROM neuro.reltrabalhos) || ' resumos' ))
    )::text
  );

-- Indice dos autores:
SELECT file_put_contents(
  '/tmp/neuro2018_idx.htm',
  replace(xmlagg( xmlelement(name p, autor ||'...'|| array_to_string(itens,', ')) )::text, '<p', E'\n<p')
  )
FROM (
  SELECT
    name_for_index(nome_full) autor, array_agg(r.pub_id) itens
  FROM neuro.relTrabalhos r, LATERAL jsonb_to_recordset( (neuro.metadata_bycod(r.codigo))->'contribs' ) t(nome_full text)
  GROUP BY 1
  ORDER BY 1
) t;
