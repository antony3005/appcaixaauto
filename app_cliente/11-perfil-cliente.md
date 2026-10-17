---
status: PARCIAL
ultima_revisao: 2026-09-14
---
# Perfil do cliente

Voltar para [[index-00-app-cliente]], [[10-autenticacao]], [[12-condominio-vinculado]] e [[50-preferencias]].

`ProfilePage` consome `GET /user/{userId}` e mostra nome, CPF mascarado, e-mail e telefone. O token/CPF não são logados. Edição e foto não foram expostas porque as rotas atuais aceitam IDs/campos que exigem revisão de autorização. O Condomínio não faz parte de `UserResponseDTO`.
