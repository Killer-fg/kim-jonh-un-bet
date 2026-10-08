# Ativar os jogos novos e as correções

O site usa Supabase para validar saldo fictício e resultados. Esta atualização não reseta o saldo.

1. Abra o SQL Editor do projeto swssidrrbyjosestcrmx. Em uma consulta nova, cole todo o conteúdo de arcade-update.sql e clique Run. Ela depende de setup.sql e social-update.sql, já aplicados anteriormente.
2. Em Edge Functions → bet-api → Code, substitua o código por TODO o conteúdo de bet-api-dashboard.ts. Mantenha o nome bet-api e publique com Deploy. O arquivo é único e inclui os motores dos jogos. Mantenha a configuração JWT já usada pelo projeto; a função valida a sessão internamente. Não adicione nenhuma chave secreta ao site.
3. Aguarde a publicação do GitHub Pages e recarregue com Ctrl+F5.
4. Entre em Sahur, pesca ou Plinko. Eles exigem a versão 3 da função; se aparecer aviso de atualização, confira o Deploy da bet-api.

## Regras

- Saldo e apostas são fictícios. Não há dinheiro real.
- Mecha: pintura 2D; zoom até 3×; oito personagens; cada acerto sobe o retorno. Dois cliques no vazio perdem a aposta. Tempo de 60 segundos. Pode recolher antes.
- Sahur: slot 5×3; cinco linhas; WILD substitui; 3/4/5 símbolos desde a esquerda pagam 2×/6×/18×. Só a maior linha paga. Auto: cinco giros, interrompível. Turbo acelera a animação, sem alterar o resultado.
- Pesca: aguarde Mordeu! e recolha em até 1,25 segundo. Antecipar ou atrasar perde a aposta. Retornos por espécie: 0,4×; 0,75×; 1,2×; 2,2×; 4×; 7×. A coleção é visual e fica neste navegador.
- Plinko: nove potes. A aposta total é dividida entre 1/2/3 bolas; duas bolas recebem fator 0,90 e três fator 0,80.
- GB te ama: quando o saldo terminar em zero, sem rodada ou duelo ativo, o jogador pode receber R$ 30 fictícios. Pedidos duplicados não duplicam o crédito.
- O resgate regular de R$ 500 a cada 30 minutos permanece. Apostas individuais continuam limitadas apenas ao saldo disponível.
- X1: os dois jogadores podem girar no mesmo período; os contadores e o intervalo de 1,5 segundo são individuais. O resultado transfere uma vez o lucro positivo do perdedor.

## Validação

Banco PostgreSQL local: migrações executadas; dois jogadores girando; liquidação única; dois erros do Mecha; bônus duplicado bloqueado. DOM: reels, controle de pesca, captura e coleção. Simulações de probabilidades e verificações de autenticação. A aplicação destas duas etapas no projeto Supabase é necessária antes de os jogos funcionarem online.

