---
status: PARCIAL — ESTADO SEM VÍNCULO TRATADO
ultima_revisao: 2026-09-30
---
# Condomínio vinculado

Voltar para [[index-00-app-cliente]], [[11-perfil-cliente]] e [[21-produtos-condominio]].

`ClientBootstrap` e Home/Perfil usam o `CondominiumSummary` autoritativo retornado por `GET /app-cliente/bootstrap`. Uma conta global pode autenticar antes do vínculo; nesse estado o backend retorna `409 TENANT_LINK_REQUIRED` e o app mostra instrução explícita para utilizar o convite fornecido pelo estabelecimento/administrador.

O app não apresenta seletor livre de Empresa/Condomínio. O vínculo continua sendo feito pelo contrato seguro `POST /app-cliente/tenant-link`, cujo body contém somente o token opaco e cuja resposta renova o JWT com o tenant resolvido pelo backend. A captura/consumo desse convite no Flutter permanece como próximo passo desta tela.
