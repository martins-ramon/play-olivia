# Validação da primeira versão

Data: 11/10/2026. App nativo SwiftUI, iPadOS 16+, direcionado ao iPad de 9ª geração.

## Verificado

- Núcleo Swift compilado e executado: 62 exercícios, alternativas válidas, montagem de todas as palavras, somas até 10, sessões de cinco rodadas e rotação dos desafios.
- Novas tentativas não descontam pontos. Toques repetidos não duplicam estrelas nem avançam etapas pendentes.
- Persistência local, recuperação de armazenamento inválido, mudança de nível e prevenção de registros duplicados.
- Concordância das perguntas em português: quantas maçãs/bananas, quantos morangos/biscoitos.
- Projeto Xcode, esquema, plist, recursos e sintaxe válidos. Fotografias de referência não são empacotadas.
- As 13 unidades Swift compilaram juntas para uma prévia macOS com as próprias telas SwiftUI.
- Teste interativo na prévia: aventura inteira de português (SOL, LUA, BOLA, GATO, SAPO), dica e erro sem penalidade, montagem de palavras, conquista e navegação direta para matemática.
- Teste interativo na prévia: aventura inteira de contagem, toques repetidos no mesmo alimento, dica, conquista, retorno ao catálogo e dez estrelas registradas.
- Área de adultos aberta pela conta proposta; troca de nível aplicada; atividade de soma 2 + 1 respondida com contagem contínua dos dois grupos.
- Layouts das próprias views renderizados e inspecionados em 1080×810 e 810×1080, sem cortes ou sobreposição nas telas iniciais. Veja `output/previews/`.
- Revisadas também montagem de NAVIO com sete alternativas, soma 5 + 5 e recompensa. As alternativas agora cabem em uma linha nas dimensões do iPad, com grade alternativa para larguras menores.
- Xcode 27: 11 testes XCTest passaram sem falhas; builds para iPad Simulator e iPad físico concluídos.
- Aplicativo assinado e instalado no iPad da Olívia (9ª geração, iPadOS 26.6.1). `codesign --verify --deep --strict` passou, e o perfil contém o identificador desse iPad. Expiração do perfil: 18/10/2026 às 14:36, America/Sao_Paulo.
- Após o usuário confiar no perfil de desenvolvimento, `devicectl device process launch` confirmou a abertura de `br.com.oliviaplay.app`. Uma consulta posterior de processos confirmou `OliviaPlay.app/OliviaPlay` em execução no aparelho (PID 590). Registro em `build/ipad-processes.json`.

## Verificações manuais restantes no iPad

A instalação e a abertura no aparelho estão confirmadas. Voz pt-BR, toque, rotação, desempenho e retomada após bloquear o iPad ainda devem ser confirmados por uso no dispositivo; a verificação interativa realizada nesta preparação foi na prévia Mac. A versão para iPad tem identificador separado da prévia Mac; os progressos usados no teste do Mac não são transferidos para a Olívia.

O script `scripts/check.sh` informa explicitamente quando não conseguiu executar um build iOS. A instalação é feita por `scripts/install-ipad.sh` ou pelo Run do Xcode, sem envio à App Store.

## Atualização de narração — versão 1.1

Em 11/10/2026, a narração padrão do sistema foi substituída por 127 gravações incluídas no aplicativo (8,3 MB, cerca de 507 segundos somados), com reprodução offline. Todas as instruções, dicas, respostas, nomes de letras e números dos dois jogos estão cobertos.

- 15 testes XCTest passaram sem falhas, incluindo quatro novos testes que cobrem o catálogo e seus caminhos pelos 62 exercícios.
- Catálogo, manifesto, texto, categoria e hashes SHA-256 conferidos. Todas as gravações passaram na decodificação e nas verificações de duração, volume e clipping.
- As 127 gravações foram carregadas e preparadas pelo AVAudioPlayer no Mac.
- Um teste de integração temporário do player passou em 52 verificações: cancelamento durante transição, ausência de reinício atrasado, descarte de callbacks antigos, deduplicação, fila limitada, término e avanço real de clipes e recuperação de arquivos ausentes/inválidos pela voz do sistema.
- Transcrição local dos 97 áudios de frases por Whisper e revisão do conteúdo; segunda conferência das pronúncias ambíguas com modelo maior. As gravações de “maçãs”, “coco”, “montar a palavra fada” e “três” foram refeitas e reconhecidas corretamente na nova conferência. Os números de zero a dez também foram reconhecidos na sequência completa.
- Builds para iPad Simulator e iPad físico passaram. Registros em `build/narration/`.
- A versão 1.1, build 2, foi instalada e aberta no iPad da Olívia, com o mesmo identificador do aplicativo e sem apagar dados. O pacote assinado contém os 127 MP3 finais, com hashes conferidos contra o manifesto.

A transcrição automática verifica o conteúdo, mas não substitui a avaliação auditiva de naturalidade no iPad. A redução e restauração do áudio de outros aplicativos usa AVAudioSession e não foi exercitada pela prévia macOS.

## Jogo da memória — versão 1.2

- Terceiro jogo no catálogo: Ateliê da Memória. Começa com 6 peças e acrescenta duas por tabuleiro completo, até 16. Novas partidas embaralham as figuras e posições.
- 23 testes XCTest passaram: 11 do aprendizado anterior, 7 de memória e migração, 5 de narração. Verificados pares exatos, IDs únicos, tamanhos, bloqueio de terceiro toque e carta repetida, conclusão idempotente, estrelas, progressão e preservação de perfis das versões anteriores.
- Teste interativo na prévia nativa Mac: partida completa com 6 peças, conquista de 3 estrelas, avanço explícito para 8 peças, tentativa com desenhos diferentes, bloqueio temporário do tabuleiro e retorno das cartas ao verso. O catálogo manteve as 10 estrelas anteriores e exibiu 13 após a conquista, com 8 peças como próximo nível.
- Após fechar e reabrir a prévia, as 13 estrelas e o nível de 8 peças permaneceram. A área de adultos exibiu o tabuleiro concluído, os níveis anteriores dos outros jogos e a progressão da memória.
- Catálogo com três jogos, tabuleiros de 6 e 16 peças e conquista renderizados e inspecionados nas dimensões do iPad. Tabuleiros cabem em paisagem e retrato; a conquista mantém os botões visíveis.
- As 14 novas falas foram conferidas por transcrição local. Os 141 áudios do aplicativo passaram nas verificações de cobertura, texto, hash, duração, decodificação e volume.
- Build para iPad Simulator concluído. Logs em `build/memory/` e prévias em `output/previews/memory-*.png`.
- Versão 1.2, build 3, compilada, assinada, instalada e aberta no iPad da Olívia, preservando o identificador do aplicativo e seus dados.

Os testes interativos descritos acima foram feitos na prévia Mac. O progresso de teste dessa prévia não é transferido para o iPad da criança. A memória persiste a quantidade de peças alcançada; um tabuleiro inacabado é embaralhado novamente ao reentrar.

## Abertura animada e Trem das Formas — versão 1.3

- Splash com entrada, rotação suave e brilhos da heroína, gatinho e botão para avançar. Uma vez por execução; segue automaticamente após cerca de 2,2 segundos, com espera por ação explícita quando VoiceOver está ativo. Reduzir Movimento elimina a entrada elástica. Um teste de ciclo de vida comprovou callback único, cancelamento em background e conclusão após retomada.
- Quarto jogo: Trem das Formas, com 48 sequências AB, AAB e ABC. Cinco desafios por aventura, três opções por rodada, dicas e novas tentativas sem penalidades. Progressão automática a cada duas aventuras, até a terceira fase.
- 31 testes XCTest passaram: 11 de aprendizado, 7 de memória, 6 de narração e 7 de sequências. Incluem migração dos perfis anteriores, preservação das estrelas, deduplicação das recompensas, limites dos cursores e progressão.
- Prévia Mac: abertura automática e avanço imediato pelo botão confirmados; partida de cinco rodadas completada, incluindo erro, dica, conquista e navegação para letras. As 13 estrelas anteriores viraram 18; após encerrar e reabrir, as 18 estrelas, a memória com 8 peças e a próxima sequência permaneceram. Dica acessível expõe os nomes das formas ao leitor de tela.
- Catálogo 2×2, abertura, fases do trem e conquista renderizados nas dimensões do iPad. Catálogo e telas do jogo inspecionados em retrato e paisagem; todos os controles necessários cabem. Prévias em `output/previews/`.
- Oito novos áudios tiveram seu conteúdo confirmado por transcrição local. Os 149 áudios (627,8 segundos somados) passaram na validação de catálogo, texto, hash, decodificação, duração, volume e picos; todos foram carregados e preparados pelo AVAudioPlayer.
- Build iPad Simulator e prévia nativa concluídos. Ajustes finais de desenho e acessibilidade também compilaram no build para iPad físico.
- Versão 1.3, build 4, assinada, instalada e aberta no iPad da Olívia, mantendo o mesmo identificador e armazenamento. Logs em `build/patterns/`.

As interações e imagens acima foram verificadas na prévia Mac; instalação e abertura foram confirmadas no iPad físico. A sensação da animação, áudio pelos alto-falantes e toque no aparelho ainda dependem do uso no iPad.

## Escrita de letras e números — versão 1.4

- Quinto jogo: Caderno Mágico, com 26 letras maiúsculas e dez algarismos, sessões de cinco exercícios e níveis de molde, pontinhos e cópia com referência separada. O currículo começa com L, 1, I, 0 e O; cada nível guarda seu próprio cursor.
- 48 testes passaram sem falhas. A avaliação geométrica cobre modelos corretos, pequenas irregularidades, deslocamentos de até 3% do quadro, cópia com escala uniforme e translação, curvas simplificadas, linhas capturadas com poucos pontos e divisão livre dos traços. Casos de ponto, desenho pequeno, incompleto, espelhado, distorcido, rabisco, traço extra e excesso de entrada foram rejeitados conforme esperado.
- Uma matriz de 3.780 comparações entre os 36 modelos nos três níveis não aceitou o modelo exato de um símbolo diferente. Trata-se de um teste sobre os modelos do aplicativo, sem amostra de caligrafia real da criança; não é uma taxa de reconhecimento de escrita infantil.
- Persistência: níveis e cursores independentes, prevenção de recompensas duplicadas, rejeição de resumos incompletos, preservação dos dados anteriores e resumos atrasados sem regressão do cursor verificados.
- Prévia Mac: catálogo manteve 18 estrelas e memória de 8 peças; o novo jogo abriu no nível com molde. Toque no caderno criou tinta, Conferir rejeitou o ponto isolado, Desfazer e Limpar removeram a tinta e desabilitaram Conferir. Trocas para pontinhos e cópia alteraram as instruções e a referência corretamente. Um arrasto por coordenadas não produziu tinta verificável na automação; não foi tratado como teste concluído de desenho contínuo.
- Código de captura revisado para impedir Limpar, Desfazer, Conferir e troca de nível enquanto há traço ativo. Cancelamentos, saída do app e mudança de tamanho descartam o traço em andamento; os traços já concluídos usam coordenadas proporcionais.
- Catálogo com cinco cartões, três níveis de escrita em paisagem/retrato, conquista e prancha com os 36 modelos renderizados e inspecionados. Layout sem cortes, modelo legível e área de escrita grande. Arquivos `output/previews/writing-*.png`.
- As 45 novas falas tiveram conteúdo conferido por transcrição local. Os 194 áudios (839 segundos somados) passaram nas verificações de cobertura, texto, hashes, duração, decodificação, volume e picos. AVAudioPlayer preparou todos sem falhas.
- Build para iPad Simulator e prévia Mac passaram. Versão 1.4, build 5, compilada, assinada e instalada no iPad da Olívia. A primeira tentativa de abertura foi recusada exclusivamente porque o iPad estava bloqueado. Após o usuário desbloqueá-lo, o lançamento foi confirmado pelo Xcode; nenhuma nova confirmação de confiança foi solicitada. Assinatura verificada e hashes dos 194 MP3 do pacote conferidos. Logs em `build/writing/`.

A avaliação foi validada com traços de teste e modelos vetoriais. O ajuste fino da tolerância para os traços reais da Olívia e o uso por toque/Pencil precisam ser observados no aparelho. Desenhos e fotos da criança não foram enviados a serviços externos para avaliar a escrita.

## Desenhar e colorir — versão 1.5

Atualização instalada em 17/10/2026.

- Dois jogos adicionados ao catálogo: Ateliê de Desenho e Jardim de Colorir. Ambos oferecem 11 cores, cinco texturas, borracha, desfazer/refazer, limpeza com confirmação e salvamento local. Desenho tem três espessuras; colorir tem quatro páginas (jardim, borboleta, casinha e mar), com preenchimento contido nas regiões e histórico independente por página.
- 56 testes passaram sem falhas, incluindo persistência das duas atividades, preservação das configurações dos traços, desfazer/refazer e ramificações do histórico, limites de entrada, rejeição de dados inválidos e exclusão das atividades criativas da pontuação.
- Layouts em retrato e paisagem renderizados e inspecionados no Mac, com amostras de todas as texturas, borracha e quatro páginas preenchidas. Ajustados o espaçamento do desenho e os botões do painel de colorir. Prévias em `output/previews/drawing-*.png` e `output/previews/coloring-*.png`.
- Builds para iPad Simulator e iPad físico concluídos. O pacote 1.5/build 6 inclui os símbolos dos novos jogos e os 194 áudios anteriores, com hashes conferidos contra o manifesto. As orientações das atividades de arte usam a voz pt-BR do sistema.
- Assinatura verificada com `codesign --verify --deep --strict` fora do sandbox. Instalação sobre `br.com.oliviaplay.app`, sem desinstalar o aplicativo anterior. `devicectl` confirmou versão 1.5/build 6 instalada e abertura no iPad da Olívia (iPadOS 26.6.1); consulta posterior confirmou o processo em execução, PID 3663.
- O perfil existente não foi renovado automaticamente: expira em **18/10/2026 às 14:36:31, America/Sao_Paulo**. O iPad da Olívia está incluído nesse perfil.
- Registros: `build/art-ipad-build.log`, `build/art-ipad-install.json`, `build/art-ipad-launch.json`, `build/art-ipad-app.json` e `build/art-ipad-processes.json`.

A instalação e abertura foram confirmadas no iPad físico. As verificações de desenho, texturas e layout foram realizadas com testes do núcleo e prévias renderizadas no Mac; uso contínuo com dedo/Pencil, áudio e rotação devem ser observados no aparelho.

## Narração das atividades de arte — versão 1.5.1

Preparação em 17/10/2026. As instruções de desenho e colorir passaram da síntese do aparelho para MP3 incluídos no aplicativo, usando a mesma voz Serene, idioma português, velocidade 0,94 e modelo `eleven_multilingual_v2` das gravações de memória, formas e escrita.

- `drawing-intro` e `coloring-intro` entraram no catálogo central; as telas usam essas referências tanto ao entrar quanto ao repetir pelo alto-falante. A validação agora exige 196 gravações, incluindo as duas novas.
- Preparação com o mesmo pipeline: silêncio aparado somente nas pontas, mono, 44,1 kHz, 128 kbps, alvo de −18 LUFS e pico verdadeiro de −2 dB. Medições dos MP3 finais: desenho −19,13 LUFS / −2,43 dBTP; colorir −18,28 LUFS / −2,17 dBTP. Valores próximos das referências de escrita (−18,93 LUFS) e formas (−18,25 LUFS).
- Transcrição local das duas gravações corresponde a todas as palavras dos textos esperados, com diferenças apenas de pontuação. Durações: desenho 12,39 s; colorir 11,17 s. Esta conferência automatizada não substitui avaliação auditiva no iPad.
- 57 testes passaram, build para iPad Simulator concluído e AVAudioPlayer carregou/preparou os 196 MP3. As 194 gravações anteriores foram preservadas; os hashes dos dois novos arquivos no pacote para iPad correspondem ao manifesto.
- Relatórios: `build/art-narration-check.log`, `build/art-narration-player.log`, `build/narration/art-transcripts.json` e `build/narration/art-loudness.json`.
- Versão 1.5.1/build 7 compilada, assinada, instalada e aberta no iPad da Olívia em 17/10/2026. `codesign --verify --deep --strict` passou; consulta no aparelho confirmou a versão instalada e o processo em execução (PID 3680). Registros: `build/art-narration-ipad-deploy.log`, `build/art-narration-ipad-app.json` e `build/art-narration-ipad-processes.json`. O perfil mantém a expiração de 18/10/2026 às 14:36:31, America/Sao_Paulo.
