/*
        Gestor XXI - Especialista
        Versão...................: 21.2.0
		Rotinas..................: TABELAS VIRTUALIZADAS DA PRODUÇÃO PARA REPOSITÓRIO DE INTEGRAÇÃO SUPREMA AUTOMAÇÕES
		Tickets..................: 382705 - 383045		
        Liberada para Homologação: 10/11/2021
        Liberada para implantação: 
                
        Histórico de alterações: 
        Data        Hora    Técnico             Descrição
        ==========  =====   ==============      ===============================================================
        22/10/2021			Jorge				Solicitação e levantamento de requisitos
		26/10/2021			Jorge				Análise de Requisitos para Proposta Comercial
		29/10/2021			Osmar				Aprovação comercial
		09/11/2021			Rodrigo				Finalização de Desenvolvimento
		10/11/2021			Jorge				Liberação
*/

/*
		View: sa_ordem_producao
		Conteúdo: Dados Principais da Ordem de Produção
*/
--DROP VIEW sa_ordem_producao;
CREATE OR REPLACE VIEW sa_ordem_producao AS 
	SELECT  pr006.opsempcod AS Empresa,
		pr006.opscod AS Codigo,
		pr006.opsdatemi AS Data_Emissao,
		pr006.opsdatent AS Data_Entrega,
		pr006.opsclicod AS Cliente,
		(select ve001a.CliRazSoc from ve001a where pr006.opsclicod = ve001a.clicod),
		pr006.opsprocod AS Produto,
		(select es001.pronom from es001 where pr006.opsprocod = es001.procod),
		pr006.opsqtd AS Quantidade,
		Case
			When pr006.opssit = 'A' Then 'ABERTA'::character(10)
			When pr006.opssit = 'B' Then 'FINALIZADA'::character(10)
			When pr006.opssit = 'C' Then 'CANCELADA'::character(10)
			Else 'INDEFINIDO'::CHARACTER(10)
		End as situacao,
		Case
			When pr006.opsstacod = 1 Then 'EXPLODIDA'::character(12)
			When pr006.opsstacod = 2 Then 'LIBERADA'::character(12)
			When pr006.opsstacod = 3 Then 'ANDAMENTO'::character(12)
			When pr006.opsstacod = 4 Then 'SUSPENSA'::character(12)
			When pr006.opsstacod = 5 Then 'REABILITADA'::character(12)
			When pr006.opsstacod = 6 Then 'CANCELADA'::character(12)
			When pr006.opsstacod = 7 Then 'FINALIZADA'::character(12)
			Else 'INDEFINIDO'::CHARACTER(10)
		End as Status
	FROM pr006
	WHERE pr006.opscod <> 0::numeric
	ORDER BY pr006.opsempcod, pr006.opscod;

COMMENT ON VIEW sa_ordem_producao
  IS 'Ordens de Produção Cadastradas';
--Select * from sa_ordem_producao
------------------------------------------------------------------------------------------------

/*
		View: sa_produtos
		Conteúdo: Produtos e Quantidades Programadas em OPs
*/
-- DROP VIEW sa_produtos;

CREATE OR REPLACE VIEW sa_produtos AS 
	SELECT  es001.procod AS Produto,
		es001.pronom AS Descricao,
		es001.prouni AS UN,
		es001.proclassi AS Classificacao,
		es001.propesbru AS Peso_Bruto,
		es001.propesliq AS Peso_Liquido,
		(select Sum(pr006.OpsQtd) as Qtd_OPs_Abertas
		 from pr006 
		 where pr006.opsprocod = es001.procod AND pr006.opssit = 'A'),
		 (select Sum(pr006.OpsQtd) as Qtd_OPS_Finalizadas
		 from pr006 
		 where pr006.opsprocod = es001.procod AND pr006.opssit = 'B')
	FROM es001
	WHERE es001.procod <> ''::character
	ORDER BY es001.procod;
COMMENT ON VIEW sa_produtos
  IS 'Produtos e Quantidades Programadas em OPs';
--SELECT * FROM sa_produtos
------------------------------------------------------------------------------------------------

/*
		View: sa_materiais_ft
		Conteúdo: Materiais e Componentes da Ficha Técnica'
*/
-- DROP VIEW sa_materiais_ft;

CREATE OR REPLACE VIEW sa_materiais_ft AS 
	SELECT  A.fchprocod AS Produto,
		C.pronom AS Descricao,
		A.fchver AS Versao,		
		--Dados dos itens
		A.fctprocod AS Item,
		D.pronom AS Descricao_Item,
		Case
			When D.ProClassi = 'P' Then 'PRODUTO'::character(10)
			When D.ProClassi = 'M' Then 'MATERIAL'::character(10)
			When D.ProClassi = 'C' Then 'COMPONENTE'::character(10)
		End AS Classe,
		Case
			When A.fcttipcon = 0 Then 'PROPORCIONAL'::character(12)
			When A.fcttipcon = 1 Then 'FIXO'::character(12)
			When A.fcttipcon = 2 Then 'FREQUENCIAL'::character(12)
			Else 'INDEFINIDO'::CHARACTER(12)
		End AS Tipo_Consumo,
		A.fctperqtd AS Percentual_Qtd,
		A.fchqte AS Quantidade,
		A.fctqtdref AS Qtd_Referencia,
		A.fctperref AS Percentual_Perda
	
	FROM CU001B A
		LEFT JOIN CU005 B ON B.fchprocod = A.fchprocod And B.fchver = A.fchver
		LEFT JOIN ES001 C ON C.procod = A.fchprocod
		LEFT JOIN ES001 D ON D.procod = A.fctprocod

	WHERE B.fchversit = 1; --Somente a versão ativa

COMMENT ON VIEW sa_materiais_ft
  IS 'Materiais e Componentes da Ficha Técnica';

--select * from sa_materiais_ft
------------------------------------------------------------------------------------------------
/*
		View: sa_sequencia_fabricacao
		Conteúdo: Sequencia de Fabricação da Ficha Técnica
*/
-- DROP VIEW sa_sequencia_fabricacao;

CREATE OR REPLACE VIEW sa_sequencia_fabricacao AS 
	SELECT  A.seqprocod AS Produto,
		D.pronom AS Descricao,
		A.seqfchver AS Versao,
		Case
			When D.ProClassi = 'P' Then 'PRODUTO'::character(10)
			When D.ProClassi = 'C' Then 'COMPONENTE'::character(10)
		End AS Classe,
		
		--Processos
		B.seqOrd AS Processo,
		E.PrcDes AS Descricao_Processo,
		B.SeqQtd AS Quantidade,
		Case
			When B.SeqReqIns = 0 Then 'NÃO'::character(3)
			When B.SeqReqIns = 1 Then 'SIM'::character(3)
		End AS Requer_Inspecao
	
	FROM PR005 A
		LEFT JOIN PR0051 B ON B.SeqProCod = A.SeqProCod And B.SeqFchVer = A.SeqFchVer
		LEFT JOIN CU005 C ON C.fchprocod = A.seqprocod And C.fchver = A.seqfchver
		LEFT JOIN ES001 D ON D.procod = A.seqprocod
		LEFT JOIN PR001 E ON E.PrcCod = B.SeqPrcCod
		
		--LEFT JOIN ES001 D ON D.procod = A.fctprocod

	WHERE C.fchversit = 1; --Somente a versão ativa

COMMENT ON VIEW sa_sequencia_fabricacao
  IS 'Sequencia de Fabricação da Ficha Técnica';

--select * from sa_sequencia_fabricacao
------------------------------------------------------------------------------------------------

/*
		View: sa_sequencia_fabricacao
		Conteúdo: Sequencia de Fabricação da Ficha Técnica
*/
-- DROP VIEW sa_sequencia_fabricacao;

CREATE OR REPLACE VIEW sa_sequencia_fabricacao AS 
	SELECT  A.seqprocod AS Produto,
		D.pronom AS Descricao,
		A.seqfchver AS Versao,
		Case
			When D.ProClassi = 'P' Then 'PRODUTO'::character(10)
			When D.ProClassi = 'C' Then 'COMPONENTE'::character(10)
		End AS Classe,
		
		--Processos
		B.seqOrd AS Processo,
		E.PrcDes AS Descricao_Processo,
		B.SeqQtd AS Quantidade,
		Case
			When B.SeqReqIns = 0 Then 'NÃO'::character(3)
			When B.SeqReqIns = 1 Then 'SIM'::character(3)
		End AS Requer_Inspecao
	
	FROM PR005 A
		LEFT JOIN PR0051 B ON B.SeqProCod = A.SeqProCod And B.SeqFchVer = A.SeqFchVer
		LEFT JOIN CU005 C ON C.fchprocod = A.seqprocod And C.fchver = A.seqfchver
		LEFT JOIN ES001 D ON D.procod = A.seqprocod
		LEFT JOIN PR001 E ON E.PrcCod = B.SeqPrcCod
		
		--LEFT JOIN ES001 D ON D.procod = A.fctprocod

	WHERE C.fchversit = 1; --Somente a versão ativa

COMMENT ON VIEW sa_sequencia_fabricacao
  IS 'Sequencia de Fabricação da Ficha Técnica';

--select * from sa_sequencia_fabricacao
------------------------------------------------------------------------------------------------

/*
	View: sa_materiais_processo
	Conteúdo: Materiais por Processo de Fabricação da Ficha Técnica
*/
-- DROP VIEW sa_materiais_processo;

CREATE OR REPLACE VIEW sa_materiais_processo AS 
	SELECT  A.fchprocod AS Produto,
		C.pronom AS Descricao,
		A.fchver AS Versao,
		A.fctprocod,
		D.pronom AS Descricao_Item,
		Case
			When D.ProClassi = 'M' Then 'MATERIAL'::character(10)
			When D.ProClassi = 'C' Then 'COMPONENTE'::character(10)
		End AS Classe,
		
		A.fcdprcord AS Ordem,
		A.fcdprccod AS Processo,
		E.PrcDes AS Descricao_Processo,
		A.fcdiprseq AS Seq_Instrucao,
		A.fcdiprcod AS Cod_Instrucao,
		B.iprdes AS Descricao_Instrucao,
		A.FcdQtd AS Quantidade,
		A.fcdperqtd AS Percentual_Qtd
	
	FROM CU001C A
		LEFT JOIN PR016 B ON B.IprCod = A.fcdiprCod
		LEFT JOIN ES001 C ON C.procod = A.fchprocod
		LEFT JOIN ES001 D ON D.procod = A.fctprocod
		LEFT JOIN PR001 E ON E.PrcCod = A.fcdprccod
		LEFT JOIN CU005 F ON F.fchprocod = A.fchprocod And F.fchver = A.fchver

	WHERE F.fchversit = 1; --Somente a versão ativa
ALTER TABLE sa_materiais_processo
  OWNER TO postgres;
COMMENT ON VIEW sa_materiais_processo
  IS 'Materiais por Processo de Fabricação da Ficha Técnica';

-- SELECT * FROM sa_materiais_processo

------------------------------------------------------------------------------------------------

CREATE ROLE SupremaAutomacao;
GRANT SELECT ON sa_ordem_producao, sa_produtos, sa_materiais_ft, sa_sequencia_fabricacao, sa_materiais_processo TO SupremaAutomacao WITH GRANT OPTION;
CREATE ROLE usuariosa LOGIN PASSWORD 'sa193782' IN ROLE SupremaAutomacao;
