
# Requisitos
Conforme documento modelo de 2016.

## Ordem e distribuição

Conforme documento modelo de 2016. O documento precisa ser organizado nos seguintes grupos e nesta ordem:

Capítulos:
* Oral
* Pôster

Dentro de cada capítulo as respectivas seções por tema:

* **Oral**: Cefaleia, Distúrbio Vestibulares e do Equilíbrio, Doença Cerebrovascular, Neurologia Intervencionista e Terapia Intensiva em Neurologia, Doenças do Neurônio Motor - Esclerose Lateral Amiotrófica, Doenças Neuromusculares, Epilepsia, Líquido cefalorraquiano, Neurofisiologia Clínica, Neurogenética, Neuroimunologia, Neuroinfecção, Neurologia Cognitiva E Do Envelhecimento, Neurologia Infantil, Neuropatias Periféricas, Neurorreabilitação, Neurossonologia, Sono, Transtornos do Movimento.

* **Pôster**: Cefaleia, Distúrbio Vestibulares e do Equilíbrio, Doença Cerebrovascular, Neurologia Intervencionista e Terapia Intensiva em Neurologia, Doenças do Neurônio Motor - Esclerose Lateral Amiotrófica, Doenças Neuromusculares, Dor, Epilepsia, História da neurologia, Líquido cefalorraquiano, Neuroepidemiologia, Neurofisiologia Clínica, Neurogenética, Neuroimunologia, Neuroinfecção, Neurologia Cognitiva E Do Envelhecimento, Neurologia Infantil, Neurooncologia, Neuropatias Periféricas, Neurorreabilitação, Neurossonologia, Sono, Transtornos do Movimento, Traumatismo cranioencefálico.

Dentro de cada tema os resumos na sequência correta:

* Oral/Cefaleia: TL 46
* Oral/Distúrbio Vestibulares e do Equilíbrio: TL 22,TL 34
* ...
* Oral/Transtornos do Movimento: TL 05,TL 06,TL 14,TL 28,TL 29,TL 30,TL 32
* Pôster/Cefaleia: PO 0410,PO 0394,PO 0392,PO 0393,PO 0395,PO 0407,PO 0781,PO 1189, ...
* Pôster/Distúrbio Vestibulares e do Equilíbrio: PO 0012, PO 0006, PO 0008, PO 0004, ...
* ...
* Pôster/Traumatismo cranioencefálico: PO 0370, PO 0373, PO 0368, PO 0374, PO 0383, PO 0380, PO 0376, PO 0389,...

-----

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

## Avaliação dos testes
O XML acabou não sendo usado exceto para converir UTF8 na primeira prova. Com o `teste.htm` já ficaram evidentes alguns problemas e decisões:

* Problemas com UTF8 no resumo não serão corrigidos, vieram dos originais. Pode-se tentar filtrar simbolos estranhos substituindo por espaço.

* Autores duplicados sendo aceitos, mas duplicados para multiplas afiliações não.

* Alguns nomes de autores foram trocados pelas afiliações, ver tabela abaixo

codigo | aff_id |nome_suspeito       
--------|--------|---------------
73087 |      7 | Department of Medical Sciences, Institute of Biomedicine-iBiMED, University of Aveiro, Aveiro, Portugal                                   |
73156 |      4 | Neurodiagnostic Brasil\u0096Diagnósticos em Neuropatologia                                                                                |
73244 |      3 | Hospital de Clínicas da Universidade Federal do Paraná                                                                                    |
73463 |      5 | Internal Medicine Department, Postgraduate Program in Medicine: Medical Sciences                                                          |
74264 |      3 | Hospital de Clínicas da Universidade Federal do Paraná                                                                                    |
74387 |      6 | Molecular Medicine Branch, Eunice Kennedy Shriver National Institute of Child Health and Human Development, National Institutes of Health |
74537 |      6 | Center of Neurology and Neurosurgery Associates (NeuroCENNA). BP u0096 A Beneficência Portuguesa                                         |
75213 |      4 | The Brazilian Institute of Neuroscience and Neurotechnology u0096 BRAINN, Campinas, SP, Brazil |

O arquivo *teste_dump* foi gerado por `grep -P "<h|abstractid" /tmp/neuro2018_body.htm > teste_dump.txt` para comprovação da ordem dos tópicos e dos resumos.

### Solicitação extra

Tentou-se resgatar a intenção do autor na estruturação do resumo, permitindo ao layout final, através de escolha de estilos apropriados, dar algum destaque nos tópicos de resumos estruturados. A real demanda, assim como as palavras-tópico, foram determinadas estatisticamente:

Precisa bold?         |  n  | Precisa bold?  | n
--------------------------|-----|------------|------
Introduction:            | 378 |ABSTRACT                 |   4
CASE                     | 156|ABSTRACT:                |   4
presentation:            | 124|BACKGROUND               |   4
INTRODUCTION:            | 117|groups:                  |   4
report:                  |  87|Methods:                 |   4
Presentation:            |  73|history:                 |   3
Report:                  |  73|VI                       |   3
Background:              |  53|Abstract:                |   2
case:                    |  22|caso:                    |   2
Case:                    |  20|Discussion:              |   2
BACKGROUND:              |  19|III                      |   2
Objective:               |  16|INTRODU                  |   2
INTRODUCTION             |  14|INTRODUÇÃO:              |   2
Introdução:              |   7|Introduction/Background: |   2
PRESENTATION:            |   7|Introduction/Objectives: |   2
1:                       |   5|OBJECTIVE:               |   2
SMA                      |   5|...|...

Consulta SQL:
```sql
select unnest(regexp_matches(resumo,'([^\s:,;\.]+:|[A-Z][A-Z]+)')) x, count(*) n 
from neuro.reltrabalhos group by 1 order by 2 desc, 1;
```
Como medida paleativa uma expressão regular baseada nas palavras mais frequentes e pontuação foi gerada, e `<span class="destaque">`  incluso para o operador do layout dar o devido tratamento.

## Entrega final e demais versões

As versões encontram-se em [releases](https://github.com/ppKrauss/neuro2018-resumos/releases), a partir da 1.0.0 temos a versão entregue de produção. O essencial da entrega são os arquivos
`neuro2018_*.htm` da pasta  [entregas](entregas), reunidos em `neuro2018_pacoteHtml.zip`.

O software SQL não foi revisado ou otimizado, fica como legado e curiosidade para as discussões abertas sobre editoração XML e gestão de workflow com SQL.


