# Backlog — homebrew-claude-insights

> Backlog de implementações pendentes.

---

---

## URGENTE — Auditoria de convenções 2026-07-22 (sessão Fable)

### A1. CLAUDE.md criado do zero — validar descrição e convenções
**Prioridade**: URGENTE
**Descrição**: O projecto não tinha CLAUDE.md nenhum (governança zero — nenhuma rule carregava). Foi criado no formato mínimo: descrição de 1 parágrafo (inferida do README) + 2 convenções + bloco canónico Tier1+Tier2. Validar se a descrição e as convenções batem com a realidade do projecto e enriquecer se necessário (ou correr /atualizar-claude-md).

## [URGENTE] Qualidade — SonarQube bloqueante e cobertura honesta

### SONAR-01. O Sonar tem de bloquear o CI e a cobertura tem de medir o que e escrito a mao
**Prioridade**: URGENTE
**Origem**: decisao do utilizador 2026-07-25 — transversal a **todos** os repos InfoWhere.
Nasceu da limpeza do `project-finances`, onde as exclusoes escondiam 142 classes com logica.
**Estado neste repo**: **sem Sonar nenhum** — nao ha `sonar-project.properties` nem job no CI. Montar de raiz.

**Decisao**: o SonarQube e obrigatorio em todos os projectos e o Quality Gate tem de
**bloquear** o CI. Nenhum pipeline pode passar com o gate vermelho. Projectos sem Sonar
ou sem ferramenta de cobertura tem de passar a ter.

**O que fazer**

1. Garantir analise Sonar no CI — job dedicado + `sonar-project.properties`.
2. **Ligar o gate bloqueante**: `-Dsonar.qualitygate.wait=true` no scan, e o job Sonar
   nos required status checks do `main`.
3. `sonar.exclusions` = **so codigo gerado**. Nada mais. O que la esta deixa de ser
   analisado para bugs, vulnerabilidades e smells — nao e sitio para esconder `config`,
   `dto`, `entity` ou `exception`.
4. `sonar.coverage.exclusions` tem de **espelhar exactamente** as exclusoes da ferramenta
   de cobertura (JaCoCo / coverage.py / vitest). Se divergirem, o Sonar ve ficheiro sem
   dados e conta **0% coberto** — excluir so num sitio faz a cobertura *cair*.
5. `sonar.newCode.referenceBranch=main` — sem isto o "novo codigo" acumula divida
   historica e o `new_coverage` nunca melhora, por mais testes que se escrevam.
6. **(Java)** `<excludes>` do JaCoCo = so codigo gerado + a classe `*Application`.
   Mappers, config, entities, dtos e exceptions **contam**. Medido no `project-finances`:
   exclui-los comprava 0,69pp a troco de deixar de medir 2173 linhas — incluindo
   `SecurityConfig`, `ApiKeyAuthFilter` e `GlobalExceptionHandler`. E `dto`/`entity`/
   `exception` sao records: o JaCoCo ja filtra os membros gerados, sao 3% do codigo e
   estavam **acima** da media, portanto exclui-los ate baixava o numero.
7. **(Java)** `report` do JaCoCo na fase `verify`, nao `test` — no `mvn verify` o failsafe
   corre depois do `test`, e com o report no `test` o `jacoco.xml` que vai para o Sonar
   fica **sem os testes de integracao**.
8. **(Java)** `prepare-agent` com `append` no default (true) — o failsafe corre num JVM
   novo e tem de **somar** ao exec do surefire. Para a acumulacao local, apagar so o
   `target/jacoco.exec` na fase `initialize` com o `maven-clean-plugin`
   (`excludeDefaultDirectories=true`).

**Armadilha conhecida**: se o CI usa `SonarSource/sonarqube-scan-action` (scanner CLI), as
propriedades `<sonar.*>` do `pom.xml` **sao ignoradas** — vale o `sonar-project.properties`.
Confirmar em que ficheiro estao as propriedades antes de assumir que estao activas.

**Referencia**: `project-finances` — `1f93dbc` (exclusoes minimas, report em verify,
check a 0.80) e `70eb267` (failsafe deixa de sobrescrever o exec do surefire).

## [URGENTE] Deploy — promover o artefacto, nao repetir o pipeline

### DEPLOY-01. Construir uma vez em develop, promover a imagem, e mergear so se o deploy passar
**Prioridade**: URGENTE
**Origem**: decisao do utilizador 2026-07-25 — transversal a **todos** os repos InfoWhere.
Nasceu do `project-finances`, onde o push para `main` repetia testes, Sonar e build.
**Estado neste repo**: **sem pipeline nenhum** — nao ha workflows no `.github/`. Criar de raiz: testes + build com tag por SHA + workflow de promocao.
**Regra**: `standarts/private/rules/devops.md` > CI/CD > "Promocao para producao"

**O problema**: colocar em producao esta a correr o pipeline outra vez. Alem do tempo
desperdicado, **a imagem que vai para producao nao e a que foi testada** — e uma
reconstrucao do mesmo codigo. Parecido nao e igual.

**O pipeline correcto**

```
push em develop
  |- testes + Sonar                      (a validacao acontece AQUI, uma vez)
  `- build das imagens, tag :<sha>       (o artefacto nasce AQUI)
     push para o Nexus

promocao (/colocar-em-producao)
  |- 1. deploy.yml -f image_sha=<sha>    (compose pull + up + health checks)
  |      falhou? -> rollback automatico + run VERMELHO + SEM merge.  FIM.
  `- 2. so se passou: gh pr merge -> main   (o merge e o RECIBO, nao o gatilho)
```

**O que fazer**

1. Mover o job de build de imagens para correr em `develop`, depois dos testes.
2. Tag da imagem = **SHA do commit**. Nunca so `:latest`.
3. Acrescentar rotulos OCI no build (`org.opencontainers.image.revision`, `.source`,
   `.created`) — a tag e externa e pode ser reescrita; o rotulo viaja dentro da imagem.
4. `docker-compose.prod.yml` passa a usar `${IMAGE_TAG:?}` em vez de `:latest`. **Sem
   default**: um fallback silencioso faria subir uma versao antiga sem ninguem dar por isso.
5. Criar `deploy.yml` com `workflow_dispatch` e input `image_sha`: verifica que o artefacto
   existe no Nexus, guarda a versao a correr (lida do container, nao de um ficheiro),
   `compose pull` + `up -d`, health checks. **Sem testes, sem build.**
6. **Rollback automatico**: se os health checks falharem, repor a versao anterior **e deixar o
   run vermelho**. Producao continua a servir; o deploy falhado continua visivel. Nunca
   reparar em silencio.
7. **Deploy primeiro, merge depois**: o `main` so avanca se a versao entrou mesmo. Assim o
   `main` e sempre o que esta vivo, e nunca uma promessa por cumprir.
8. O push para `main` deixa de disparar testes e build — os obrigatorios correm no PR, que e
   onde a branch protection os exige.
9. O `/colocar-em-producao` chama o `gh` (`gh workflow run`, `gh pr merge`) em vez de fazer
   `git merge` local. O `git merge` esta em deny global — e bem: a promocao nao deve depender
   do estado da maquina de quem promove.

**Ganhos**: promocao de ~10 min para ~1-2 min; a imagem em producao e o binario testado;
rollback = re-deploy de um SHA anterior que ja esta no Nexus; o `main` deixa de poder mentir.

**Validado contra a industria (2026-07-25)**: "build once, deploy many" e principio de
Continuous Delivery; a Docker desaconselha explicitamente o `:latest` em producao e recomenda
rotulos OCI; "merge-as-receipt, not-trigger" e o padrao que o proprio GitHub usa (merge queues);
rollback automatico com notificacao e pratica corrente (AWS ECS, ArgoCD).

**Armadilha**: se o frontend recebe `VITE_*` como `--build-arg`, a imagem fica especifica do
ambiente — construir no develop significa construir "o frontend de producao". Com um so
ambiente funciona; com staging obriga a segunda imagem. A saida e servir a configuracao em
runtime, mas nao e obrigatorio ja.

**Nao fazer sem o piloto**: aguardar a implementacao no `project-finances`, que serve de
referencia, antes de replicar aqui.
