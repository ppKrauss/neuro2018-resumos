# Relatório de contagens e cosistência

## Avaliação individual dos arquivos
Cada arquivo quanto ao total de registros, distribuição por temas e normalização dos campos.

### ApresOral
Total  288 registros, porém 48 únicos, demais repetidos com mesmo código e a maioria com mesmo título.

### ApresPoster
Total  9348 registros, porém 1558 únicos, demais repetidos com mesmo código e a maioria com mesmo título.

### RelTrabalhos

Total  1606 registros, consistente com o total de itens distintos de cada tipo de apresentação:

* Itens não-repetidos de ApresOral: 48
* Itens não-repetidos de ApresPoster: 1548

Distribuição por tema:

Temário                                        |  n   
-----------------------------------------------|------
Cefaleia                                                                              | Oral 1, Poster 64
Distúrbio Vestibulares e do Equilíbrio                                                | Oral 2, Poster 14
Doença Cerebrovascular, Neurologia Intervencionista <br/>e Terapia Intensiva em Neurologia | Oral 7, Poster 242
Doenças do Neurônio Motor <br/> Esclerose Lateral Amiotrófica                        | Oral 3, Poster 33
Doenças Neuromusculares                                                               | Oral 4, Poster 110
Dor                                                                                   | Poster 3
Epilepsia                                                                             | Oral 3, Poster 72
História da neurologia                                                                | Poster 19
Líquido cefalorraquiano                                                               | Oral 1, Poster 19
Neuroepidemiologia                                                                    | Poster 68
Neurofisiologia Clínica                                                               | Oral 1, Poster 26
Neurogenética                                                                         | Oral 4, Poster 70
Neuroimunologia                                                                       | Oral 1, Poster 163
Neuroinfecção                                                                         | Oral 1, Poster 137
Neurologia Cognitiva e do Envelhecimento                                              | Oral 5, Poster 91
Neurologia Infantil                                                                   | Oral 1, Poster 44
Neurooncologia                                                                        | Poster 41
Neuropatias Periféricas                                                               | Oral 3, Poster 69
Neurorreabilitação                                                                    | Oral 2, Poster 74
Neurossonologia                                                                       | Oral 1, Poster 3
Sono                                                                                  | Oral 1, Poster 19
Transtornos do Movimento                                                              | Oral 7, Poster 154
Traumatismo cranioencefálico                                                          | Poster 23
<!--
scripts dos resultados acima:

select  count(*)  n, count(distinct codigo) n_unicos from neuro.ApresOral;
select  count(*)  n, count(distinct codigo) n_unicos from neuro.apresposter;

SELECT count(distinct codigo) from neuro.reltrabalhos where codigo IN (select codigo from neuro.apresoral); 48

SELECT temario, array_to_string(array_agg(tipo||' '||n),', ') n
FROM (
  SELECT rr.temario, CASE
     WHEN rr.codigo IN (select a.codigo from neuro.apresoral a where a.codigo=rr.codigo) THEN 'Oral' ELSE 'Poster' END tipo,
     count(*) n
  FROM neuro.reltrabalhos rr group by 1,2 order by 1
) t group by 1;
-->

## Avaliação da primeira etapa, XML

* Problemas com UTF8 no resumo não serão corrigidos, vieram dos originais. Pode-se tentar filtrar simbolos estranhos substituindo por espaço.
* Autores duplicados sendo aceitos, mas duplicados para multiplas afiliações não.


## Etapa final, layout HTML

....
