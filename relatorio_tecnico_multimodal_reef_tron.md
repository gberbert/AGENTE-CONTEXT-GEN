# Relatório Técnico-Funcional Multimodal — REEF / TRON

> **Base de evidências:** transcrição Whisper integral e oito frames OCR fornecidos pelo solicitante: Frame 01 @ 03:56, Frame 02 @ 07:48, Frame 03 @ 11:39, Frame 04 @ 15:30, Frame 05 @ 19:21, Frame 06 @ 23:13, Frame 07 @ 27:04 e Frame 08 @ 30:55. O relatório utiliza somente informações sustentadas por essas fontes.
>
> **Convenção de evidência:** afirmações visuais trazem `[Evidência Visual: Frame NN @ MM:SS]`. Onde a transcrição apresenta nomes deformados, a variação é preservada e contextualizada sem tratá-la como nomenclatura oficial.
>
> **Filtro visual aplicado:** foram ignorados elementos de videoconferência, webcams, controles de chamada, barras do sistema operacional e menus de Excel. A análise visual concentra-se exclusivamente no conteúdo técnico das células da planilha compartilhada.

---

## 1. Síntese executiva

A sessão foi uma rodada de esclarecimentos funcionais e técnicos sobre a plataforma de seguros referida como **REEF**, **RIF/Rift Core** e **TRON**, com apoio de uma planilha de dúvidas de formação. O objetivo prático foi reduzir incertezas da equipe antes de trilhas posteriores sobre emissão, sinistros, tesouraria e outros domínios.

A mensagem executiva central é que a solução deve ser entendida como um **núcleo corporativo configurável**, e não como uma seguradora pronta para operar imediatamente. Ela oferece módulos, tabelas, modelo de dados, integrações por APIs, mecanismos de extensão Oracle e produtos corporativos-base; cada país precisa configurar a operação, adequar legislação, tarifas, documentos, integrações e regras locais.

Os sistemas e conceitos mais recorrentes foram: core REEF/RIF/TRON, TRONWeb, Neutron, Marketplace, DUP, RTE/RT, ORION G2, CILIA, QAPTER, IQRF, módulo de terceiros, gerador de produtos, Oracle, RE21 e BI. A fonte não define formalmente a relação entre REEF, RIF e TRON; portanto, o relatório não os declara sinônimos absolutos.

A sessão também explicita uma direção de governança: evitar a dispersão de código causada por personalizações diretas no núcleo histórico de TRON. Evoluções reutilizáveis devem passar por avaliação corporativa e versionamento; particularidades locais devem ser configuradas ou implementadas pelos mecanismos previstos, sem presumir liberdade irrestrita para alterar o core.

---

## 2. Contexto e antecedentes

O contexto é o de uma plataforma corporativa de seguros que permanece ativa, atende países com portes e maturidades muito diferentes e concentra capacidades de uma companhia seguradora. O especialista enfatiza que a aplicação é ampla, complexa e evolutiva: cobre contratos/apólices, subscrição, sinistros, terceiros, tesouraria e funções correlatas, mas requer conhecimento progressivo para ser configurada corretamente.

A transcrição descreve um antecedente importante: em versões anteriores de TRON, países fizeram muitas personalizações diretamente no núcleo. Isso dificultou a atualização posterior de pacotes e versões, pois havia risco de perda das customizações. A preocupação dos participantes é que REEF não repita esse padrão.

Há coexistência de cenários tecnológicos. Alguns países são associados a REEF Core/Neutron; outros ainda são citados como usuários de TRONWeb ou versões anteriores. A sessão não fornece uma matriz completa por país, nem um cronograma de migração. A fala somente sustenta que os países estão em estágios distintos e que houve esforço para aproximá-los da versão mais atual do núcleo.

A planilha `formación-Agenda`, predominantemente na aba `Dudas formación`, organiza a formação por temas como `1. REEF-Presentación`, `2. TRON-Introducción-General`, `3. TRON-Introducción-Arquitectura`, `4. TRON-Introducción-siniestros`, `5. TRON-Introducción-tesorería-c...` e `6. Arquitectura`. As colunas observadas são `DUDA`, `TEMA`, `MÓDULO`, `PERSONA`, `Comentarios`, `Respuesta`, `PREGUNTAR A MAPFRE` e `REVISADAS LATAM+ESP.`. [Evidência Visual: Frame 03 @ 11:39]

---

## 3. Problemas e necessidades identificados

### 3.1 Acesso incompleto à governança documental

**Problema.** A equipe não possuía acesso aos procedimentos de versionamento, regularização de dados em produção e catalogação de ativos no Marketplace.

**Impacto.** Sem esses documentos, a equipe não consegue alinhar seu trabalho à metodologia corporativa nem antecipar regras de evolução e operação em produção.

**Prioridade.** A própria equipe afirma querer evitar sair do que já está definido. A resposta indica que os procedimentos são complexos e deveriam ser disponibilizados, embora o respondente precise encaminhar a solicitação à área responsável. [Evidência Visual: Frame 01 @ 03:56]

### 3.2 Fragmentação do núcleo e dificuldade de atualização

**Problema.** Países que mantêm versões antigas de TRON muito personalizadas encontram dificuldade para atualizar seus pacotes.

**Impacto.** A customização direta no core compromete o recebimento de versões posteriores e cria risco de perda de ajustes locais.

**Prioridade.** A discussão posiciona a redução dessa dispersão como orientação estrutural de REEF. A resposta visual registra que a versão a instalar deveria ser a mais atual, mas reconhece o obstáculo das instalações antigas altamente personalizadas. [Evidência Visual: Frame 01 @ 03:56]

### 3.3 Incerteza sobre arquitetura e instâncias

**Problema.** Há dúvida sobre a permanência de duas instâncias REEF e sobre a implantação de Vida no Brasil.

**Impacto.** Sem resposta de arquitetura, não se pode definir topologia, instalação, suporte ou estratégia de infraestrutura.

**Prioridade.** A planilha informa que ainda existem duas instâncias — América Central/Panamá e Vida/Uruguai — e que Brasil teria instância dedicada ainda pendente de validação corporativa. O especialista funcional recusa corretamente confirmar detalhes fora de sua área. [Evidência Visual: Frame 01 @ 03:56]

### 3.4 Ambiguidade de soluções de cálculo e tarificação

**Problema.** DUP e RTE aparecem como capacidades semelhantes para cálculo/pricing, sem que a equipe soubesse quando usar cada uma.

**Impacto.** Pode haver decisão técnica inadequada se se assumir equivalência operacional total ou substituição imediata entre elas.

**Prioridade.** A sessão esclarece que DUP é externo e RTE é interno, criado no movimento de Java para microserviços, mas ainda usado de modo incompleto em alguns países. [Evidência Visual: Frame 02 @ 07:48]

### 3.5 Expectativa de integração automática do Marketplace

**Problema.** Ferramentas do Marketplace poderiam ser entendidas como componentes plug-and-play ou obrigatórios.

**Impacto.** Essa interpretação criaria estimativas erradas de implantação e ocultaria o esforço de análise, APIs e adequação local.

**Prioridade.** A resposta é explícita: a integração depende da necessidade de cada país e exige análise prévia para determinar como fazê-la. [Evidência Visual: Frame 03 @ 11:39]

### 3.6 Documentação e mudança contínua

**Problema.** A equipe precisa de parâmetros detalhados e materiais atualizados para configurar o core e os módulos.

**Impacto.** Documentação defasada em relação a evolutivos pode levar a configuração inadequada e dependência excessiva de especialistas.

**Prioridade.** Existe documentação e uma academia de formação em estruturação/atualização, além de guia inicial de configuração REEF; contudo, a fala reconhece que a aplicação segue evoluindo. [Evidência Visual: Frame 04 @ 15:30]

### 3.7 Ausência de padronização corporativa completa para documentos de saída

**Problema.** Não há confirmação de formatos corporativos únicos para cartas, certificados, condições particulares e demais documentos de negócio.

**Impacto.** Países precisam tratar documentos e ferramentas de envio localmente, com risco de heterogeneidade.

**Prioridade.** A necessidade surge no ciclo de vida de apólices, sinistros e notificações; o especialista reconhece que essa padronização seria desejável, mas não está confirmada na sessão.

---

## 4. Solução apresentada: visão conceitual

A solução apresentada é um ecossistema de core de seguros orientado a configuração e governança. O núcleo oferece capacidades, mas não emite apólices, não tramita sinistros e não cadastra terceiros de forma operacional sem que uma companhia configure suas tabelas, parâmetros, produtos, regras, papéis e integrações.

O modelo mental contém dois princípios complementares:

1. **Núcleo corporativo preservado:** valores e funcionalidades reutilizáveis devem ser avaliados, versionados e distribuídos pelo corporativo quando passarem a integrar o core.
2. **Localização controlada:** cada país pode precisar configurar produtos, tarifas, impostos, documentos, validações, canais e integrações segundo legislação e operação local.

Produtos pré-configurados são tratados como bases ou esqueletos, não como cópias finais utilizáveis em qualquer mercado. Automóveis, Hogar, Salud, Vida Riesgo e Vida Ahorro são citados como produtos corporativos. A mesma base pode ser adaptada, como no exemplo de Automóveis de Panamá utilizado como ponto de partida para Honduras, considerando a realidade legislativa hondurenha.

A plataforma é posicionada como núcleo para múltiplas companhias, grandes e pequenas. Por isso, não se pressupõe que todos os países adotem os mesmos módulos complementares, ferramentas externas ou ritmo tecnológico.

---

## 5. Arquitetura e funcionamento: reconstrução lógica

A reunião não exibe um diagrama de infraestrutura e não detalha nuvem, rede, mensageria, alta disponibilidade, banco em nível físico ou segurança. O diagrama abaixo é uma reconstrução **lógica**, baseada apenas nas afirmações apresentadas.

```text
Usuários e canais locais
(operação interna, portais de cliente/mediador quando configurados)
                         |
                         | APIs / serviços e integrações por país
                         v
+------------------------------------------------------------------+
| Core REEF / RIF / TRON (terminologia varia na fonte)             |
|  - emissão e subscrição                                          |
|  - sinistros                                                      |
|  - terceiros                                                      |
|  - tesouraria                                                      |
|  - módulos comuns: usuários, papéis, tipos, moedas               |
|  - produtos, coberturas, tarifas, impostos, regras               |
+------------------------------------------------------------------+
       |                         |                       |
       |                         |                       +--> BI / relatórios analíticos
       |                         |
       |                         +--> Marketplace / APIs
       |                               ORION G2, CILIA, QAPTER
       |                               e integrações locais
       |
       +--> Oracle
            - modelo de dados
            - tabelas e catálogos de configuração
            - pacotes/procedures e sinônimos
            - pacote padrão do core ou pacote local

Capacidades especializadas
- Cálculo/tarificação: DUP (externo) ou RTE/RT (interno)
- Resseguro: gestão no core ou integração com RE21
- Notificações e documentos operacionais
```

A extensibilidade Oracle é o mecanismo técnico mais concreto citado. A fala diz que inúmeras tabelas permitem chamadas em tempo real a pacotes Oracle. Por meio de sinônimos, a chamada pode apontar para pacote padrão do núcleo ou para um pacote local, modificando o comportamento conforme necessidade de país. A planilha confirma esse uso de pacotes Oracle por sinônimos para adequar o comportamento do REEF Core. [Evidência Visual: Frame 04 @ 15:30]

As APIs são mencionadas como meio de integração com Marketplace e canais. A fonte não especifica REST, SOAP, autenticação, eventos, filas, arquivos batch, sincronismo ou assincronismo. Logo, esses aspectos não podem ser afirmados.

---

## 6. Componentes e conceitos mencionados

### 6.1 Core REEF / RIF / TRON

**Finalidade.** Núcleo para capacidades de seguros, incluindo emissão/subscrição, sinistros, terceiros, tesouraria e parametrização.

**Funcionamento.** Depende de configuração de tabelas, regras, produtos, permissões e extensões. Há guia inicial de configuração e documentação por processos, tabelas e versões.

**Limitações conhecidas.** A fonte alterna REEF, RIF/Rift Core e TRON sem uma taxonomia oficial. Não é seguro declarar que sejam exatamente o mesmo produto, camada ou versão.

### 6.2 TRONWeb e Neutron

**Finalidade/contexto.** São citados como modalidades, versões ou contextos tecnológicos presentes em diferentes países.

**Dependências.** O novo modelo de terceiros é associado mais a REEF Core/Neutron do que a TRONWeb.

**Limitação.** A sessão não detalha arquitetura, relação de versões, critérios de migração ou matriz de países.

### 6.3 Módulos comuns

**Finalidade.** Organizam estruturas compartilhadas, incluindo usuários, papéis, moedas, tipos e partes da estrutura de produtos.

**Funcionamento.** Papéis nativos podem ser complementados por necessidades locais; o especialista alerta que os vídeos introdutórios não mostram todas as tabelas do módulo.

**Limitação.** Não há catálogo integral de tabelas, permissões ou responsabilidades fornecido nesta sessão.

### 6.4 Gerador de produtos

**Finalidade.** Área em que são configurados produtos, coberturas, entidades, tarifas, impostos, bonificações, recargos e descontos técnicos ou comerciais.

**Funcionamento.** A localização fiscal e tarifária é tratada no contexto do produto. Há trabalho em curso para tornar o gerador mais guiado e orientado a negócio.

**Limitação.** Não foram informados cronograma, escopo final ou disponibilidade da evolução. O gerador atual é descrito como pouco usável e semelhante ao existente em TRONWeb.

### 6.5 DUP e RTE/RT

**Finalidade.** Microserviços de cálculo/tarificação, descritos como realizando principalmente a mesma função.

**Funcionamento.** DUP é externo. RTE é interno, baseado no modelo de dados e tarifas do core; foi implementado para migrar do ambiente Java para microserviços. RTE é usado parcialmente em alguns países, sem toda a tarifa nesse microserviço. [Evidência Visual: Frame 02 @ 07:48]

**Limitação.** A tendência futura apontada é continuar com RTE, mas não há compromisso de substituição integral de DUP nem prazo universal.

### 6.6 Marketplace, ORION G2, CILIA e QAPTER

**Finalidade.** Ferramentas e integrações complementares ao core.

**Funcionamento.** O país decide se usa zero, uma ou várias integrações conforme necessidade e estratégia; o core disponibiliza APIs/serviços, e o desenho requer GAP analysis.

**Limitação.** A sessão não confirma integração direta, fluxo de dados ou função detalhada entre ORION G2, CILIA e QAPTER. A hipótese da pergunta — danos via fotos e gestão de sinistros online — não foi tecnicamente validada pelo respondente.

### 6.7 IQRF

**Finalidade.** Gestão de incidências, queixas, reclamações e felicitações, sob orientação da área corporativa de Operações.

**Funcionamento.** Permite captura, registro, acompanhamento e encerramento em contextos como terceiros, emissão, sinistros e tesouraria, conforme perfis autorizados.

**Limitação.** A sigla não é expandida na fonte e não há inventário completo de funcionalidades OOTB. A planilha indica que IQRF pertence à formação de nível 2 ou 3. [Evidência Visual: Frame 01 @ 03:56]

### 6.8 Módulo de terceiros

**Finalidade.** Cadastro transversal de pessoas físicas, jurídicas e outras entidades relacionadas ao negócio.

**Funcionamento.** Cada terceiro possui código de atividade, que influencia processos, blocos de dados e permissões funcionais. Agente, empregado, clínica, resseguradora, cliente e outros são exemplos de papéis citados.

**Limitação.** Validações de incompatibilidade entre papéis não são bloqueios universais do core; precisam ser configuradas conforme companhia/país.

### 6.9 Modelo de dados e catálogos

**Finalidade.** Suportar dados do core, dados locais e novo modelo de terceiros em Oracle.

**Funcionamento.** A planilha registra possibilidade de solicitar ampliação ao time Core para dados reutilizáveis por outros países; dados muito locais devem ser colocados em outras tabelas do país. [Evidência Visual: Frame 02 @ 07:48]

**Limitação.** Não foram exibidos o modelo entidade-relacionamento, os quinze catálogos mencionados, o dicionário de dados ou as regras de precedência entre estruturas globais e locais.

### 6.10 RE21, coaseguro e resseguro

**Finalidade.** O core contempla coaseguro e resseguro. RE21 é descrito como aplicação irmã/satélite, originada em MAPFRE Global Risk, destinada à gestão de resseguro.

**Funcionamento.** O produto pode indicar se possui resseguro e sua tipologia. O core pode tratar a gestão internamente ou chamar serviço/API de RE21, mantendo configurações coerentes entre os sistemas.

**Limitação.** A fonte não detalha contratos de API, custos, licenças, países conectados ou matriz de decisão.

### 6.11 BI, relatórios, notificações e documentos

**Finalidade.** Relatórios operacionais atendem rotinas dos módulos; BI atende análises além do escopo operacional. Notificações e documentos sustentam comunicações de processos.

**Funcionamento.** Podem ser enviados e-mails, comunicações físicas e notificações configuradas, por exemplo, para exigir questionário médico antes de vigência de apólice ou informar regulador após cadastro de agente.

**Limitação.** Não há formato corporativo único confirmado para cartas, certificados, recibos, condições particulares ou documentos de saída.

---

## 7. Especificação funcional das telas e interfaces (OCR & Evidências Visuais)

### 7.1 Artefato visual identificado

A evidência visual consiste na planilha `formación-Agenda`, com a aba `Dudas formación` ativa. Ela é um repositório de dúvidas de formação e respostas consolidadas entre NTTDATA, MAPFRE, LATAM e Espanha. A planilha é relevante como registro de requisitos, pendências e esclarecimentos técnicos; menus do Excel e elementos de videoconferência foram deliberadamente ignorados.

| Coluna observada | Papel identificado |
|---|---|
| `DUDA` | Pergunta funcional, técnica ou de governança submetida pela equipe. |
| `TEMA` | Classificação por conteúdo/sessão de formação, como `1. REEF-Presentación` e `2. TRON-Introducción-General`. |
| `MÓDULO` | Módulo ou domínio associado, por exemplo Marketplace e Módulos de Comunes. |
| `PERSONA` | Pessoa vinculada ao registro da dúvida. |
| `Comentarios` | Referência a vídeo, minuto, slide ou anotação contextual. |
| `Respuesta` | Resposta consolidada, com trechos atribuídos a NTTDATA ou MAPFRE. |
| `PREGUNTAR A MAPFRE` | Campo de encaminhamento para validação pela MAPFRE. |
| `REVISADAS LATAM+ESP` | Campo de revisão entre as regiões. |

O rodapé mostra, em momentos diferentes, `Se encontraron 123 de 135 registros`, `23 de 136 registros` e `124 de 136 registros`. Isso indica navegação/filtro e atualização do conjunto exibido; não permite inferir quantidade de pendências abertas, aprovadas ou resolvidas. [Evidência Visual: Frames 01 @ 03:56, 04 @ 15:30 e 06 @ 23:13]

### 7.2 Linhas e respostas técnicas visíveis

| Linha / conteúdo | Extração fiel e implicação documental | Evidência |
|---|---|---|
| L2–3 | Solicita procedimentos do marco normativo: versionamento, regularização de dados produtivos e catalogação de ativos no Marketplace; comentário remete ao vídeo 38:55, slide 18. | Frame 01 @ 03:56 |
| L5 | Pergunta sobre duas instâncias REEF e Vida/Brasil. Resposta: REEF permanece com duas instâncias; Brasil exigiria instância dedicada ainda a validar com MAPFRE Corporativo. | Frame 01 @ 03:56 |
| L9 / G9 | DUP e RTE são microserviços com função principalmente semelhante. A resposta consolidada visível define DUP como externo e RTE como interno; RTE foi implementado para sair de Java em direção a microserviços e é usado incompletamente em alguns países. | Frames 02 @ 07:48 e 03 @ 11:39 |
| L10 | A integração de ORION G2 com CILIA/QAPTER depende das necessidades e usos de cada país, por APIs disponíveis, e requer análise prévia. | Frame 04 @ 15:30 |
| L11 | Para os módulos de configuração com REEF, a resposta observável é: `Se está trabajando en la ampliación de la estructura de productos.` | Frame 04 @ 15:30 |
| L12 / G12 | A documentação está sendo estruturada para academia; MAPFRE informa atualização e guia inicial REEF para uso do Core em gestão de apólices. O texto adicional afirma suporte a chamadas de pacotes Oracle por sinônimos para modificar comportamento padrão do REEF Core conforme país. | Frame 05 @ 19:21 |
| L13 | Produtos corporativos listados visualmente: Automóviles, Hogar, Salud, Vida Riesgo e Vida Ahorro; Panamá: Automóviles; Honduras: Automóviles em implantação. A continuação da lista não é legível/completa. | Frame 06 @ 23:13 |
| L15 / G15 | IQRF está associado à área corporativa de Operações, que define gestão de reclamações e felicitações. Em cada módulo, há gestão de registro de queixa, reclamação e felicitação conforme papel do usuário. | Frames 06 @ 23:13 e 07 @ 27:04 |
| L16 | O histórico de personalizações no core TRON dificultava atualizações. A resposta MAPFRE aparece truncada no Frame 08; a fala completa a intenção de alinhar versões REEF entre países. | Frames 07 @ 27:04 e 08 @ 30:55 |
| L17 / G17 | Para catálogos de terceiros, NTTDATA orienta solicitar expansão ao Core quando os dados forem reutilizáveis; itens muito locais devem ser registrados em outras tabelas. MAPFRE reforça que tabelas do núcleo não podem ser modificadas e a parte local deve ser levada separadamente. | Frame 08 @ 30:55 |

### 7.3 Estado e limitações do OCR

Não foram fornecidas telas transacionais do core, formulários de emissão, telas de sinistro, diagramas de arquitetura, mensagens de erro de aplicação, máscaras de campos ou interfaces de APIs. Logo, não há base visual para especificar controles de UI do REEF/TRON além da planilha de dúvidas.

O Frame 08 contém resposta de MAPFRE interrompida ao final (`aunque aún está en...`). O texto não deve ser completado por inferência. Da mesma forma, o texto adicional da resposta de IQRF no Frame 06 inicia `En`, mas só fica concluído no Frame 07.

---

## 8. Modelo de integração

A integração é apresentada como decisão de implantação, e não como ativação automática. O core expõe APIs/serviços para conectar Marketplace, ferramentas complementares e possivelmente canais como portais de clientes ou mediadores. Porém, cada país precisa definir o que usa e realizar análise prévia das lacunas.

O **GAP analysis** é citado explicitamente como etapa necessária para confrontar a necessidade do país, a capacidade da ferramenta/core e a forma de integração. A fonte não apresenta artefatos, papéis decisórios, critérios de aceite ou método formal desse processo.

| Integração / capacidade citada | Modelo informado | Limite da evidência |
|---|---|---|
| Marketplace | Uso depende de necessidade local; integração por APIs disponíveis; exige análise prévia. | Não foram fornecidos contratos, autenticação ou protocolos. |
| ORION G2, CILIA, QAPTER | Ferramentas complementares a serem avaliadas por país. | Não há integração direta confirmada entre elas. |
| DUP | Dependência externa para cálculo/tarificação. | Não há contrato técnico ou país de uso detalhado. |
| RTE/RT | Microserviço interno de cálculo/tarificação. | Adoção parcial; sem topologia ou cronograma. |
| RE21 | Chamada a serviço/API para tratamento externo de resseguro quando configurado. | Não há especificação de mensagens ou sincronismo. |
| Integrações locais | Podem existir fora do Marketplace, como validação de pessoa em um país. | Não há catálogo nem processo de publicação detalhado. |

Não há evidência de mensageria, filas, eventos, arquivos batch, ETL, replicação de banco ou chamadas assíncronas. A descrição deve permanecer em APIs/serviços e pacotes Oracle, que são os mecanismos efetivamente citados.

---

## 9. Modelo operacional

### 9.1 Configuração antes da operação

Antes de operar, cada companhia precisa configurar o núcleo. A fonte cita produtos, tabelas, tarifas, impostos, coberturas, intervenções de terceiros, papéis, permissões, documentos, notificações, regras de negócio e integrações. A guia inicial de configuração permite navegar pelo core e pelas estruturas iniciais; ela não substitui a configuração de cada operação.

A preparação também envolve decidir quais ferramentas Marketplace serão utilizadas, realizar GAP analysis e definir se evoluções solicitadas são corporativas ou locais. Para produtos corporativos, a equipe deve aplicar a base disponibilizada e adequá-la a legislação, tarifas e processos do país.

### 9.2 Dados compartilhados em tempo real

A fala afirma que, uma vez cadastrado, um terceiro fica disponibilizado para processos, sub-processos e procedimentos do sistema, como tesouraria e resseguro. Isso é apresentado como integração interna em tempo real, sem JCLs ou jobs no exemplo dado.

Há, contudo, blocos de informação condicionados pela atividade do terceiro. Uma resseguradora, agente, empregado, clínica ou cliente pode exigir conjuntos de dados distintos. O especialista ilustra que dados bancários podem não ser coletados para um tramitador interno, como proteção contra fraude.

A sessão não detalha monitoramento, SLAs, incidentes, hotfixes, suporte ou mecanismos técnicos de replicação entre países. A operação de releases é referida de modo geral como dependente de procedimento de versionamento e de área responsável.

---

## 10. Governança, versionamento e evolução

### 10.1 Procedimentos corporativos mencionados

Foram citados três procedimentos do marco normativo: versionamento, regularização de dados em ambientes produtivos e catalogação de ativos no Marketplace. A equipe solicita acesso, e a resposta visual registra que MAPFRE dará acesso. [Evidência Visual: Frame 01 @ 03:56]

A reunião também aponta que a documentação da plataforma está sendo organizada/atualizada para academia de formação. Não foram fornecidos os documentos nem a versão aplicável na própria sessão.

### 10.2 Evolutivos e mudanças no núcleo

Parâmetros ou listas considerados corporativos não devem ser modificados livremente. Se uma necessidade for reutilizável entre países, ela deve ser submetida ao corporativo, versionada e distribuída. Se for estritamente local, a solução pode ser local, mas a fala não define todos os critérios de decisão nem a autonomia exata de cada país.

A intenção declarada é evitar o cenário histórico de customização direta do núcleo TRON. As particularidades precisam ser construídas sobre mecanismos governados, como configurações, tabelas locais e pacotes Oracle por sinônimos.

### 10.3 Estado de versões

A orientação visual é que a versão de TRON a instalar seja a mais atual. O impedimento apontado são versões antigas muito personalizadas. [Evidência Visual: Frame 01 @ 03:56]

A reunião não apresenta versionamento semântico, política de suporte, janela de release, cadência, compatibilidade, rollback, ambientes ou cronograma de atualização por país.

---

## 11. Organização das equipes e responsabilidades

| Papel/entidade citada | Responsabilidade que a sessão permite identificar |
|---|---|
| José Ramón | Especialista funcional; responde por módulos comuns e terceiros; declara não ser responsável por arquitetura ou infraestrutura. |
| Área de arquitetura | Deve responder por instâncias, infraestrutura e topologia. Não foram identificados nomes ou responsabilidades detalhadas. |
| MAPFRE Corporativo / corporativo | Avalia evoluções reutilizáveis, valida temas de core e Brasil, participa de documentação e governança. |
| Mafretech / área de núcleo | Citada como área que trata ampliações de listas/valores corporativos. A estrutura formal não foi detalhada. |
| José de Abreu / equipe de implantação | Citado para decisões de implantação, especialmente Brasil e trabalho local de produto mínimo viável. |
| Antonio | Citado como organizador/ponte para agenda e formações seguintes. |
| Lourdes | Citada para sessões de emissão/tesouraria, sem detalhamento de cargo. |
| Marta Pérez | Citada para sessão de sinistros, sem detalhamento de cargo. |
| Países/equipes locais | Configuram necessidades locais, produtos, documentos, integrações e regras, sob governança corporativa. |

A transcrição não descreve formalmente Product Managers, Product Owners, Scrum Masters ou organograma de squads. Não se deve atribuir esses papéis sem evidência.

---

## 12. Modelo de produto

### 12.1 Produtos pré-configurados citados

Os produtos mencionados como pré-configurados corporativamente são:

- Automóveis;
- Hogar/Lar;
- Salud/Saúde;
- Vida Riesgo/Vida Risco;
- Vida Ahorro/Vida Poupança.

Panamá é citado com Automóveis já instalado. Honduras é citado com Automóveis em implantação, adaptado da base de Panamá à realidade legislativa hondurenha.

### 12.2 Direção de padronização

A padronização não significa copiar um produto sem alterações. O produto corporativo funciona como esqueleto. O país precisa completar e adaptar configurações conforme legislação, tarifas, operação e permissões concedidas pelo corporativo.

A fala menciona que, em produtos corporativos, a direção é restringir a definição completamente do zero em cada país e ampliar o reaproveitamento de uma base comum. Porém, legislação local prevalece quando necessário. O especialista usa números ilustrativos — um produto com muitas tabelas poderia ter apenas parte configurada na base — e esclarece que tais números não são métricas reais.

---

## 13. Terceiros, atividades e modelo de dados

### 13.1 Papel do módulo de terceiros

O módulo de terceiros mantém cadastro transversal de pessoas físicas, jurídicas e demais entidades relacionadas à seguradora. O mesmo indivíduo ou organização pode ter papéis distintos, como segurado, cliente, beneficiário, empregado, agente, clínica ou resseguradora, conforme configuração e contexto.

### 13.2 Atividades e papéis

O código de atividade é central. Ele classifica o terceiro e permite determinar quais processos, blocos de informação e tratamentos fazem sentido. A atividade de agente, por exemplo, pode participar de processos de comissão; a atividade de empregado não deve ser considerada nesses processos.

As primeiras cem atividades são descritas como reservadas ao núcleo. Um país pode criar atividade adicional a partir de faixa posterior para necessidade local. A atividade não é apresentada como um catálogo limitado a produto ou ramo: o terceiro, uma vez cadastrado, pode ser usado transversalmente onde fizer sentido.

### 13.3 Incompatibilidades e regras de validação

O core permite configurar validações para combinações de papéis que uma companhia considere inadequadas. Não há confirmação de uma matriz corporativa universal de incompatibilidades. O exemplo de empregado simultaneamente agente é discutido como algo que pode ser impedido por validação local, não como bloqueio nativo obrigatório.

### 13.4 Proteção de dados e consentimentos

O novo modelo de dados — e o modelo anterior de modo menos simples — permite tipificar consentimentos expressos ou implícitos de cliente/segurado para a seguradora. A pergunta menciona GDPR e contexto LATAM, mas a resposta não apresenta desenho de conformidade, bases legais, retenção, anonimização, trilha de auditoria ou fluxos de direito de acesso, retificação e cancelamento.

### 13.5 Rating e documentos de identificação

Não existe catálogo único obrigatório de rating: cada país/companhia pode decidir qual classificação usa e como a consome em suas regras. Registrar um rating não cria automaticamente bloqueio de subscrição; esse efeito precisa ser configurado.

Para documentos de identificação, a fala cita exemplos como NIF, DNI, CURP e RTN, com validações locais implementáveis por configuração e pequena peça de código. Esses exemplos ilustram capacidade de localização, não uma lista fechada de documentos suportados.

---

## 14. Produtos, tarifas, impostos e regras locais

### 14.1 Tarifação e impostos

Impostos geograficamente diferenciados, como o exemplo argentino de imposto de selo, devem ser tratados no produto e em suas tabelas tarifárias locais. O sistema permite impostos, bonificações, recargos e descontos técnicos ou comerciais, mas cada caso deve ser analisado conforme produto e país.

Não é possível concluir que exista um motor tributário único, uma hierarquia geográfica específica ou fórmulas prontas para todos os países. A decisão de reaproveitar uma tabela corporativa de Automóveis, por exemplo, depende de sua adequação à necessidade local.

### 14.2 Gerador de produtos

O gerador de produtos é descrito como o local de definição de entidades, coberturas, tarifas, impostos e parâmetros de produto. Há evolução em curso para torná-lo mais guiado, voltado a usuários de negócio e menos dependente de informática.

### 14.3 Rating e motores de cálculo

DUP e RTE/RT são as capacidades de cálculo/tarificação citadas. DUP é externo; RTE é interno e baseado no modelo de dados/tarifa do core, criado para a transição de Java a microserviços. A escolha efetiva depende de país, maturidade, orçamento e estratégia de implantação; a sessão não determina uma arquitetura única.

---

## 15. Sinistros, documentos e notificações

### 15.1 Documentos e faturas

O core possui relatórios operacionais e suporta documentos/números de fatura configuráveis, inclusive numéricos ou alfanuméricos. A configuração de tipos de documento pode influenciar retenções. O exemplo da fronteira norte do México ilustra que dois documentos de fatura podem ter tratamentos diferentes para uma mesma numeração ou contexto fiscal.

A reunião não explica integração contábil detalhada, estrutura de chave com sinistro, validações por fornecedor ou modelo fiscal padronizado.

### 15.2 Notificações

Há módulo/capacidade de notificações para disparar comunicações físicas ou por e-mail de acordo com eventos e regras configuradas. Exemplos mencionados: solicitar informação em sinistro, exigir questionário médico para vigência de apólice de saúde e comunicar regulador ao cadastrar agente.

Os disparos dependem de configuração de tabelas, regras e permissões. O core pode ser acessado por canais via APIs, de modo que portal de cliente ou mediador pode participar da captura conforme configuração.

### 15.3 Limitação de formatos corporativos

A sessão reconhece que não há formato corporativo único confirmado para condições particulares, cartas, certificados ou demais documentos do ciclo de vida de apólice. Cada país mantém seus formatos e pode usar ferramentas próprias ou capacidades do core para envio de documentação.

---

## 16. Cosseguro e resseguro

O especialista confirma que a solução contempla cosseguro e resseguro. Para resseguro, o produto pode ser configurado com tipologia que indique, por exemplo, se há resseguro ou determinadas modalidades. A conversa menciona contratos, coberturas, quota-parte, retenção, excesso e excesso de perdas como elementos que precisam ser configurados em tabelas.

O core permite duas abordagens:

1. gestão dentro do próprio core;
2. integração com RE21, aplicação satélite/irmã de MAPFRE Global Risk para resseguro.

Quando RE21 é utilizado, o core realiza cessão/emissão e chama serviço/API externo; a configuração do resseguro precisa permanecer coerente entre os dois ambientes. A fonte não detalha contratos proporcionais versus não proporcionais de forma sistemática, apenas cita os conceitos no contexto de configuração.

---

## 17. Casos concretos mencionados

### 17.1 Brasil

**Cenário.** Citado como operação grande e como alvo de implantação de Vida.

**Arquitetura/adaptação.** A planilha registra que Brasil teria instância dedicada para essa implementação, ainda dependente de validação com MAPFRE Corporativo. [Evidência Visual: Frame 01 @ 03:56]

**Limite.** Não há confirmação de topologia, data, hospedagem ou decisão de DUP/RTE para Brasil.

### 17.2 Panamá

**Cenário.** Automóveis é citado como produto instalado.

**Arquitetura/adaptação.** Panamá utiliza o novo modelo de terceiros, segundo a fala. A pergunta visual também associa Panamá à instância da América Central.

**Lição.** Uma implantação pode servir como base para outro país, sem se tornar cópia direta.

### 17.3 Honduras

**Cenário.** Citado como companhia menor e implantação em andamento.

**Arquitetura/adaptação.** Automóveis, baseado em Panamá, é adaptado à legislação hondurenha. Honduras também é citado como usuária do novo modelo de terceiros.

**Lição.** O produto corporativo requer localização; o mínimo produto viável e as integrações efetivas devem ser definidos pela implantação.

### 17.4 Uruguai

**Cenário.** A pergunta visual associa Vida/Uruguai a uma das duas instâncias REEF.

**Limite.** A fala não confirma detalhes adicionais de produto, versão ou operação.

### 17.5 Chile

**Cenário.** É citado em exemplos de produto, documentos e modelo de terceiros.

**Arquitetura/adaptação.** A fala sugere que talvez não utilize o novo modelo de terceiros, mas a formulação é insegura. Não deve ser tratada como situação definitiva.

### 17.6 Argentina

**Cenário.** Referência a integração local para validar dados de pessoa e a impostos geograficamente diferenciados, como imposto de selo.

**Lição.** Integrações e regras fiscais podem ser específicas de país e devem ser configuradas/avaliadas no produto.

### 17.7 Peru

**Cenário.** Citado como referência para discutir funcionalidades/coberturas de Vida Ahorro.

**Limite.** Não foram fornecidas condições, coberturas ou arquitetura efetiva da implantação.

### 17.8 México

**Cenário.** Citado em exemplos de documentos de identificação e de tratamentos diferenciados de faturas na fronteira norte.

**Lição.** Validações documentais e fiscais são localizáveis por configuração.

### 17.9 Espanha, Estados Unidos, Portugal, Malta e Turquia

Esses países são citados para ilustrar heterogeneidade de porte, orçamento, legislação e produtos. Não há descrição suficiente para documentar arquitetura ou módulos implantados em cada um.

---

## 18. Roadmap e evolução

Somente as evoluções explicitamente mencionadas podem ser registradas:

| Evolução / marco | Estado afirmado |
|---|---|
| Estrutura de produtos | Está sendo ampliada; a fala associa a necessidade ao uso por “Maudi”, termo cuja grafia oficial não foi confirmada. |
| Gerador de produtos | Existe projeto em curso para torná-lo mais guiado, mais orientado a negócio e menos dependente de informática. |
| RTE/RT | É apresentado como direção futura natural para seguir em microserviços, mas está incompleto/parcial em alguns países. |
| Documentação / academia | Plataforma e documentação estão sendo estruturadas/atualizadas para fazer parte de academia de formação. |
| Produtos corporativos | Há direção de maior fechamento/padronização corporativa, sem cronograma por país. |
| Honduras / Automóveis | Implantação em andamento, sem data final declarada. |
| Brasil / Vida | Instância dedicada ainda em validação corporativa, sem prazo declarado. |

Não foram informadas ondas de implantação, datas de release, prazos de migração de TRONWeb, nem compromisso de término dos projetos em curso.

---

## 19. Números e indicadores citados

| Indicador / Métrica | Valor declarado | Contexto e interpretação |
|---|---:|---|
| Duração disponível para a sessão | 2 horas | Tempo inicialmente previsto para tratar dúvidas. |
| Registros encontrados na planilha | 123 de 135 | Contador visual exibido no Frame 01; não equivale necessariamente a dúvidas abertas. [Evidência Visual: Frame 01 @ 03:56] |
| Instâncias REEF | 2 | América Central/Panamá e Vida/Uruguai, conforme pergunta/resposta visual. [Evidência Visual: Frame 01 @ 03:56] |
| Catálogos do módulo de terceiros | 15 | Quantidade citada na pergunta visual; o catálogo não foi exibido. [Evidência Visual: Frame 02 @ 07:48] |
| Atividades reservadas do núcleo | primeiras 100 | As primeiras cem posições da tabela de atividades são do core, segundo a fala. |
| Produtos corporativos citados | 5 tipos | Automóveis, Hogar, Salud, Vida Riesgo e Vida Ahorro. |
| Tabelas em exemplo ilustrativo | 500 / 20, 50 ou 70 | Números usados pelo especialista apenas como ilustração do quanto uma base corporativa pode não cobrir. Não são métricas reais. |

Todos os valores são declarações da reunião ou evidências visuais; não constituem indicadores operacionais auditados.

---

## 20. Mapa cronológico integrado da sessão (Fala + Telas)

| Timestamp | Frame / tela exibida | Evidência visual chave & OCR | Tópico técnico discutido na fala |
|---|---|---|---|
| 03:56 | Frame 01 — `Dudas formación` | Marco normativo, instâncias REEF, DUP/RTE, ORION G2/CILIA/QAPTER, documentação, produtos e limites de personalização. | Roteiro de dúvidas gerais e encaminhamentos para MAPFRE/arquitetura. |
| 07:48 | Frame 02 — célula G9 | DUP/RTE classificados como microserviços similares; texto curto apresenta DUP interno/RTE externo, mas a resposta mais completa posterior corrige a classificação. | Discussão de cálculo/pricing e transição tecnológica. |
| 11:39 | Frame 03 — resposta completa L9 | DUP externo e RTE interno; RTE implementado para sair de Java rumo a microserviços; adoção parcial. | Esclarecimento consolidado de DUP versus RTE. |
| 15:30 | Frame 04 — células G10/G11 | Integrações do Marketplace por APIs dependem de necessidade do país e análise prévia; estrutura de produtos em ampliação. | Integrações locais e evolução dos módulos/configuração. |
| 19:21 | Frame 05 — célula G12 | Documentação/academia, guia inicial REEF e extensão por pacotes Oracle via sinônimos. | Configuração do core, documentação e comportamento local. |
| 23:13 | Frame 06 — célula G15 | Produtos corporativos e situação de Panamá/Honduras; IQRF ligado à área corporativa de Operações. | Produtos OOTB e gestão de queixas/reclamações/felicitações. |
| 27:04 | Frame 07 — L16 e resposta IQRF | Resposta IQRF completa: registro de ocorrências condicionado ao papel; pergunta sobre personalização do código. | Perfis, IQRF e governança de customizações. |
| 30:55 | Frame 08 — célula G17 | Catálogos reutilizáveis podem ser propostos ao Core; tabelas do núcleo não podem ser modificadas; dados locais ficam fora delas. | Extensibilidade do modelo de terceiros e separação core/local. |
| Sem frame correspondente | — | — | Terceiros, privacidade, impostos, documentos, notificações, BI, resseguro e RE21 são fundamentados pela fala. |

**Nota de consistência OCR.** O Frame 02 traz uma formulação breve que inverte DUP/RTE (`DUP es interno, y RTE es externo`). O Frame 03 apresenta a resposta completa e é coerente com a explicação oral: **DUP externo; RTE interno**. Este relatório adota a resposta completa e registra a divergência sem ocultá-la.

---

## 21. Perguntas e respostas relevantes (Q&A Exaustivo)

### 21.1 Acesso aos procedimentos do marco normativo

**Pergunta.** É possível obter acesso aos procedimentos de versionamento, regularização de dados produtivos e catalogação de ativos do Marketplace?

**Resposta.** O especialista não é responsável pela área, mas afirma que a equipe deveria ter conhecimento completo e que encaminhará a solicitação. Salienta que o procedimento de versionamento é complexo.

**O que essa resposta esclarece.** Existe governança formal, mas o material ainda não foi entregue durante a sessão. [Evidência Visual: Frame 01 @ 03:56]

### 21.2 Instâncias REEF e Vida/Brasil

**Pergunta.** Permanecem duas instâncias REEF e onde Vida/Brasil será instalada?

**Resposta.** O especialista funcional declara que a questão é de arquitetura/infraestrutura. A planilha informa duas instâncias e uma instância dedicada para Brasil ainda a validar com MAPFRE Corporativo.

**O que essa resposta esclarece.** A decisão de Brasil não estava finalizada; nenhuma conclusão de infraestrutura pode ser extraída. [Evidência Visual: Frame 01 @ 03:56]

### 21.3 Versão de TRON por país

**Pergunta.** A cópia de TRON instalada muda conforme volume de negócio?

**Resposta.** A resposta visual orienta usar a versão mais atual, mas reconhece dificuldade de atualização em países com versões antigas muito personalizadas.

**O que essa resposta esclarece.** O fator apontado é personalização/legado, não volume de negócio. [Evidência Visual: Frame 01 @ 03:56]

### 21.4 DUP versus RTE

**Pergunta.** Qual a diferença entre DUP e RTE e quando se usa cada um?

**Resposta.** Ambos realizam principalmente cálculo/tarificação. DUP é externo; RTE é interno, baseado no modelo de dados/tarifas do core e criado para a transição de Java a microserviços. RTE ainda não é completo em todos os países.

**O que essa resposta esclarece.** A direção futura pode favorecer RTE, mas a adoção depende de país, orçamento, estágio tecnológico e implantação. [Evidência Visual: Frame 02 @ 07:48]

### 21.5 ORION G2, CILIA e QAPTER

**Pergunta.** ORION G2 integra-se com CILIA ou QAPTER? Quando cada ferramenta é utilizada?

**Resposta.** Ferramentas complementares são usadas conforme necessidade de cada país. O core dispõe de APIs/serviços, mas há GAP analysis e trabalho de implantação.

**O que essa resposta esclarece.** Não há integração automática nem relação direta confirmada entre as ferramentas. [Evidência Visual: Frame 03 @ 11:39]

### 21.6 Módulos de configuração com REEF

**Pergunta.** A configuração continuará funcionando como em TRON após REEF?

**Resposta.** A plataforma é dinâmica; a estrutura de produtos está sendo ampliada. Mudanças devem ser documentadas e conhecidas no trabalho de manutenção.

**O que essa resposta esclarece.** Vídeos de formação representam uma fotografia, não uma configuração imutável. [Evidência Visual: Frame 04 @ 15:30]

### 21.7 Documentação de configuração

**Pergunta.** Existe documentação detalhada dos parâmetros do core e módulos?

**Resposta.** Sim. Há documentação por processos, tabelas e versões, em atualização para academia de formação, além de guia inicial REEF. Pacotes Oracle e sinônimos podem particularizar comportamento.

**O que essa resposta esclarece.** Existe material, mas pode haver defasagem em relação a evoluções. [Evidência Visual: Frame 04 @ 15:30]

### 21.8 Produtos pré-configurados

**Pergunta.** Quais produtos vêm pré-configurados?

**Resposta.** Automóveis, Hogar, Salud, Vida Riesgo e Vida Ahorro. Panamá tem Automóveis; Honduras está adaptando Automóveis à sua legislação.

**O que essa resposta esclarece.** Produto corporativo é uma base; não é cópia pronta para outro país.

### 21.9 IQRF e OOTB

**Pergunta.** IQRF vem de fábrica? Quais recursos são OOTB?

**Resposta.** IQRF é ligado a incidências, queixas, reclamações e felicitações; permite registrar, acompanhar e encerrar ocorrências conforme papéis. A planilha aponta formação de nível 2 ou 3.

**O que essa resposta esclarece.** Há capacidade funcional, mas configuração de papéis, canais e regras continua necessária. O catálogo integral OOTB não foi fornecido. [Evidência Visual: Frame 01 @ 03:56]

### 21.10 Personalização do código e de parâmetros

**Pergunta.** É possível personalizar todos os módulos e adicionar parâmetros?

**Resposta.** Há valores/constantes que não devem ser modificados localmente. Necessidades reutilizáveis devem ir ao corporativo/Mafretech para avaliação, versionamento e distribuição; necessidades locais podem demandar solução local.

**O que essa resposta esclarece.** Personalização é governada para evitar a fragmentação histórica do core.

### 21.11 Proteção do núcleo contra dispersão

**Pergunta.** REEF busca evitar que países modifiquem o core, como ocorreu em TRON?

**Resposta.** Sim, essa é a intenção. Os países estão em diferentes fases e alguns ainda usam cenários anteriores, mas o objetivo é evitar dispersão de código.

**O que essa resposta esclarece.** A estratégia é centralizar o núcleo e organizar extensões/configurações, sem que a sessão detalhe mecanismo técnico obrigatório de enforcement.

### 21.12 Catálogos e novo modelo de terceiros

**Pergunta.** É possível ampliar/personalizar catálogos do módulo de terceiros e ver o novo modelo de dados?

**Resposta.** Ampliações de core devem ser levadas ao corporativo; se reutilizáveis, podem entrar no núcleo, e se muito locais devem usar outras tabelas. Haverá capacitação adicional para esse tipo de informação.

**O que essa resposta esclarece.** Não há liberdade confirmada para modificar indiscriminadamente catálogos do núcleo. [Evidência Visual: Frame 02 @ 07:48]

### 21.13 Integrações comuns e próprias de país

**Pergunta.** As integrações do Marketplace são comuns a todos os países? Uma integração própria pode existir fora dele?

**Resposta.** O Marketplace oferece ampliações comuns que cada país decide usar. Integrações próprias podem fazer parte da implantação local; é necessário trabalho com equipe de implantação e corporativo.

**O que essa resposta esclarece.** Disponibilidade não significa obrigatoriedade nem publicação automática no Marketplace.

### 21.14 Cosseguro, resseguro e impostos geográficos

**Pergunta.** O sistema contempla cosseguro/resseguro? Onde configurar impostos por geografia?

**Resposta.** Sim, contempla cosseguro e resseguro. Impostos são tratados no produto/gerador de produtos e tabelas locais; há suporte a impostos, bonificações, recargos e descontos.

**O que essa resposta esclarece.** Não foi apresentada estrutura geográfica padrão; a regra é produto-país.

### 21.15 Atividades de terceiros

**Pergunta.** Como códigos de atividade são aplicados e onde se relacionam com produtos, módulos e processos?

**Resposta.** Atividade classifica o terceiro, habilita contextos/processos e direciona blocos de dados. Há atividades do núcleo e atividades locais adicionais. O cadastro é transversal; produto define intervenções/tipos de terceiros quando necessário.

**O que essa resposta esclarece.** Atividade não é catálogo exclusivo de um produto e regras de incompatibilidade são locais.

### 21.16 Hierarquia de dados, privacidade e rating

**Pergunta.** Será possível entender a hierarquia de dados, aplicar proteção de dados e usar ratings distintos?

**Resposta.** Haverá acesso ao modelo Oracle; o modelo permite tipificar consentimentos. O rating é escolha local e seu uso para bloquear/permitir regras de negócio deve ser configurado.

**O que essa resposta esclarece.** Não foram apresentados modelo ER, políticas completas de privacidade ou catálogo universal de ratings.

### 21.17 Faturas e validações

**Pergunta.** Como validar faturas e conectá-las a sinistros/contabilidade, inclusive por região ou fornecedor?

**Resposta.** O número pode ser numérico ou alfanumérico e tipos de documento podem levar regras de retenção. O sistema permite validações configuradas.

**O que essa resposta esclarece.** Regras são locais; a sessão não fornece padrão contábil/fiscal único.

### 21.18 Reporting, BI e documentos

**Pergunta.** Existem relatórios, impressões e documentos para o ciclo de vida da apólice?

**Resposta.** Há relatórios operacionais por módulo; necessidades além disso vão para BI. O core suporta notificações e documentos operacionais, mas formatos de saída são locais.

**O que essa resposta esclarece.** Há separação entre relatórios operacionais, BI e documentos de negócio; não há padrão corporativo único confirmado.

### 21.19 Abrangência dos produtos corporativos

**Pergunta.** Onde ver todas as funcionalidades por ramo, especialmente Vida Ahorro?

**Resposta.** A resposta remete à equipe de implantação e responsáveis de Vida/Não Vida. Produtos são guias/esqueletos e precisam de localização.

**O que essa resposta esclarece.** A sessão introdutória não é um catálogo completo de coberturas/funções por produto e país.

### 21.20 RE21 versus resseguro interno

**Pergunta.** RE21 faz parte do core ou é sistema externo? O que é tratado em cada um?

**Resposta.** RE21 é aplicação satélite/irmã de resseguro. O core pode gerir internamente ou integrar-se a RE21 por serviço/API, conforme configuração e necessidade da companhia.

**O que essa resposta esclarece.** Existem duas opções funcionais; a escolha depende de companhia, custos/licenças e estratégia, sem matriz detalhada.

---

## 22. Limitações reconhecidas

1. O especialista funcional não responde por arquitetura, infraestrutura ou definição de instâncias.
2. Os procedimentos normativos solicitados não foram apresentados na sessão.
3. A documentação existe, mas pode apresentar atraso em relação aos evolutivos.
4. RTE/RT é usado parcialmente em alguns países e pode não conter toda a tarifa.
5. Marketplace e ferramentas complementares não são integrações plug-and-play; exigem análise e trabalho local.
6. Nem todos os países usam o mesmo modelo de terceiros, a mesma versão ou a mesma modalidade tecnológica.
7. O catálogo completo de OOTB e a expansão da sigla IQRF não foram fornecidos.
8. Formatos corporativos únicos para documentos de saída não estão confirmados.
9. Regras de incompatibilidade entre atividades, ratings, faturas e impostos dependem de configuração local.
10. A fonte não apresenta especificação de APIs, mensageria, segurança, desempenho ou operação de produção.

---

## 23. Riscos e desafios

### 23.1 Riscos explicitamente mencionados

- **Perda de customizações em upgrade:** consequência histórica de personalizações diretas no core TRON.
- **Defasagem documental:** mudança contínua pode criar intervalo entre versão e material disponível.
- **Adoção desigual entre países:** países grandes e pequenos têm orçamento, capacidade e ritmo diferentes.
- **Integrações subestimadas:** usar Marketplace sem GAP analysis pode falhar por diferença de necessidade local.
- **Inconsistência de configuração entre core e RE21:** a fala alerta que não pode haver configurações incompatíveis entre os ambientes.
- **Uso indevido de dados bancários de terceiros internos:** o exemplo do tramitador aponta risco de fraude mitigável por modelagem de blocos de dados.

### 23.2 Desafios derivados do contexto

- **Governança versus velocidade local:** a necessidade de aprovação corporativa pode conflitar com demandas urgentes de país; a sessão não informa mecanismo de priorização.
- **Complexidade de manutenção:** múltiplas versões, modelos de dados e produtos-base tornam treinamento e documentação fundamentais.
- **Rastreabilidade de extensões Oracle:** o uso de sinônimos e pacotes locais permite flexibilidade, mas exige disciplina de documentação, testes e versionamento; esta é uma implicação analítica, não um procedimento explicitado.
- **Heterogeneidade de documentos:** formatos locais podem dificultar padronização, auditoria e reuso corporativo.
- **Ambiguidade terminológica:** variações Whisper entre REEF, RIF/Rift Core, TRON e outros nomes podem gerar erro documental se não forem validadas em fonte oficial.

---

## 24. Transformações estruturais identificadas

1. **Tecnológica:** transição ou intenção de transição do ambiente Java para microserviços, representada pelo RTE/RT, sem que isso signifique adoção completa em todos os países.
2. **De extensibilidade:** de customizações diretas e dispersas no núcleo para configurações, extensões Oracle via pacotes/sinônimos e evoluções corporativamente avaliadas.
3. **De produto:** de produtos locais construídos do zero para produtos corporativos-base/esqueletos, ainda sujeitos a legislação e operação local.
4. **De integração:** de uma visão de core isolado para um core conectado por APIs a Marketplace, ferramentas complementares, canais e RE21 quando aplicável.
5. **Organizacional:** necessidade de dividir claramente questões funcionais, de implantação, de arquitetura e de governança, pois uma única função não responde todos os domínios.

Essas transformações são leituras analíticas fundamentadas nas falas, não um plano formal de transformação apresentado pela organização.

---

## 25. O que a reunião NÃO permite concluir

- Infraestrutura de nuvem, regiões, servidores, redes, Kubernetes, banco de dados físico, DR ou alta disponibilidade.
- Arquitetura final e aprovação da instância dedicada de Vida/Brasil.
- Relação oficial entre REEF, RIF/Rift Core, TRON, TRONWeb e Neutron.
- Catálogo de APIs, autenticação, protocolos, SLAs, sincronismo, assincronismo, mensageria ou eventos.
- Integração efetiva entre ORION G2, CILIA e QAPTER.
- Catálogo integral de OOTB, significado expandido de IQRF ou conteúdo de treinamentos de nível 2/3.
- Diagrama entidade-relacionamento, dicionário Oracle, lista dos quinze catálogos ou matriz de permissões.
- Regras fiscais, regulatórias e de privacidade completas por país.
- Cronograma de rollout, migração, releases ou ondas de implantação.
- Coberturas, tarifas e configuração definitiva dos produtos por país.
- Custos, licenças e critérios de decisão entre resseguro interno e RE21.
- Modelo padronizado de documentos e comunicações de toda a corporação.

---

## 26. Glossário terminológico, siglas e entidades

| Termo / Sigla | Significado / Expansão | Descrição e papel no ecossistema |
|---|---|---|
| REEF | Não expandido na fonte | Nome usado para plataforma/iniciativa e, em partes da fonte, para core. Relação oficial com RIF/TRON não foi explicada. |
| RIF / Rift Core | Variação fonética da transcrição | Referência ao core, frequentemente falado como “Riftcore”. Pode estar associado a REEF Core, mas requer validação oficial. |
| TRON | Não expandido na fonte | Plataforma/core configurável com histórico de personalizações locais. |
| TRONWeb | Não expandido na fonte | Modalidade/versão anterior ainda citada em alguns países. |
| Neutron | Não expandido na fonte | Termo associado ao REEF Core e novo modelo de terceiros; sem arquitetura explicada. |
| Marketplace | Não expandido na fonte | Contexto/catálogo de ferramentas e integrações complementares. |
| GAP analysis | Análise de lacunas | Análise prévia para definir adequação e forma de integração. |
| DUP | Não expandido na fonte | Microserviço/mecanismo externo de cálculo/tarificação. |
| RTE / RT | Não expandido na fonte | Microserviço interno de cálculo/tarificação, associado à transição para microserviços. |
| ORION G2 | Não expandido na fonte | Ferramenta Marketplace citada em pergunta; função e integração não confirmadas em detalhe. |
| CILIA / CIJIA | Grafia variável na fonte | Ferramenta citada em pergunta sobre Marketplace; não detalhada. |
| QAPTER | Não expandido na fonte | Ferramenta citada em pergunta sobre Marketplace; não detalhada. |
| IQRF | Não expandido na fonte | Capacidade de gestão de incidências, queixas, reclamações e felicitações. |
| OOTB | Out Of The Box | Funcionalidade disponível de fábrica; catálogo completo não fornecido. |
| Oracle | Nome de tecnologia citado | Suporta modelo de dados, tabelas, pacotes e sinônimos. |
| Sinônimo Oracle | Mecanismo Oracle | Redireciona chamadas para pacote padrão do core ou pacote local. |
| Terceiro | Conceito funcional | Pessoa física, jurídica ou entidade cadastrada para uso transversal. |
| Atividade | Conceito funcional | Código que classifica terceiro e condiciona processos e blocos de dados. |
| Gerador de produtos | Módulo/área funcional | Configura produtos, coberturas, tarifas, impostos e parâmetros. |
| Coaseguro | Conceito de seguros | Capacidade declarada como contemplada, sem detalhamento. |
| Resseguro | Conceito de seguros | Gestão configurável no core ou em integração com RE21. |
| RE21 | Nome de aplicação | Aplicação satélite/irmã de MAPFRE Global Risk para resseguro. |
| BI | Business Intelligence | Camada analítica baseada no modelo/tabelas do núcleo. |
| Mafretech | Entidade/área citada | Área relacionada à governança de evoluções do núcleo; escopo formal não detalhado. |
| Maudi | Termo possivelmente deformado pelo Whisper | Associado à ampliação da estrutura de produtos; grafia e identidade oficial não confirmadas. |

---

## 27. Conclusões principais

A reunião consolida que REEF/RIF/TRON deve ser tratado como uma plataforma corporativa ampla, configurável e em evolução, apta a sustentar operações de seguros heterogêneas. Seu valor está na combinação de núcleo comum, parametrização local, integrações por APIs, extensibilidade Oracle e produtos corporativos-base.

O direcionamento técnico mais importante é preservar a governança do core e evitar o legado de customizações diretas que dificultam atualização. Evoluções reutilizáveis devem seguir processo corporativo de avaliação/versionamento; necessidades locais devem ser implementadas por configuração, tabelas locais ou extensões compatíveis com a arquitetura descrita.

Os próximos passos sustentados pela sessão são: obter os procedimentos normativos solicitados; aprofundar formações por módulo e nível; tratar arquitetura/infraestrutura com a área competente; acessar documentação/modelo de dados; executar GAP analysis para integrações locais; e validar país a país o modelo de dados, produtos, documentos, cálculos e resseguro aplicáveis.

A principal ressalva é epistemológica: a sessão é rica em visão funcional, mas não permite concluir detalhes de infraestrutura, APIs, segurança, cronogramas ou relação oficial entre as nomenclaturas citadas. Essas lacunas precisam ser resolvidas por documentação corporativa e pelas equipes responsáveis antes de qualquer decisão de implantação.
