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
