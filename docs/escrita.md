# Caderno Mágico

O quinto jogo ensina a desenhar letras maiúsculas de A a Z e números de 0 a 9. Cada aventura tem cinco desenhos, começa com formas simples e alterna letras e algarismos. A criança desenha com o dedo ou Apple Pencil, pode desfazer o último traço ou limpar a área e escolhe quando tocar em **Conferir**.

## Três níveis de ajuda

1. **Com molde:** caminho rosa largo, linha central pontilhada e bolinhas numeradas indicando onde começar cada traço.
2. **Com pontinhos:** o caminho largo desaparece; a criança completa o desenho usando a referência pontilhada.
3. **Eu consigo!:** o modelo permanece ao lado, ou acima no iPad em pé; a área de escrita fica sem o molde, com linhas de apoio.

A primeira entrada usa o molde. Os níveis podem ser escolhidos no jogo ou na área dos adultos, e cada nível guarda sua posição na sequência de exercícios. Trocar de nível inicia uma nova aventura naquele nível. Cinco desenhos aceitos e a confirmação da conquista dão cinco estrelas; erros não descontam estrelas. Os traços de uma aventura interrompida não são salvos.

## Como a comparação funciona

O exemplo visual, o molde e a avaliação usam as mesmas linhas vetoriais, desenhadas especificamente para a escrita. A avaliação acontece no aparelho, sem enviar o desenho a um serviço. O algoritmo compara quanto do modelo foi percorrido e quanto do desenho está próximo do modelo; também verifica partes ausentes e traços excessivos. A distribuição de pontos usa distância percorrida, para que desenhar lentamente uma única parte não simule um desenho completo.

Nos dois primeiros níveis, o desenho é comparado na posição do molde. Ao copiar, a comparação alinha o centro e ajusta o tamanho de maneira uniforme, preservando as proporções. Não gira, espelha nem estica a letra em apenas uma direção. Ordem dos traços, sentido e quantidade de vezes que a criança levanta o dedo não precisam reproduzir os do modelo.

O resultado serve como incentivo para praticar esse modelo de letra, não como nota escolar ou reconhecimento universal de caligrafia. Há tolerância para pequenas irregularidades; estilos de escrita diferentes do exemplo podem receber uma nova tentativa. Formas naturalmente parecidas, como O e zero, têm limites de distinção. A interface oferece mensagens curtas sobre aumentar, completar ou tentar de novo, sem exibir porcentagens ou descontar pontos.

Os modelos, a comparação e as regras estão em `OliviaPlay/Core/WritingGame.swift`; a captura de traços e a interface ficam em `OliviaPlay/Views/Games/WritingCanvas.swift` e `WritingGameView.swift`. A área de desenho usa coordenadas proporcionais para manter os traços ao girar o iPad; um traço ainda em andamento é descartado ao interromper o app ou mudar o tamanho da tela.

Todas as instruções, os nomes dos 36 símbolos e os retornos da avaliação têm gravações incluídas no aplicativo. Não é necessária conexão à internet para escrever, avaliar ou ouvir a narração.
