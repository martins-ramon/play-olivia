# Mundo da Olívia

Aplicativo nativo SwiftUI para o iPad de 9ª geração, com iPadOS 16 ou posterior. Uma abertura animada apresenta a Olívia com um pequeno salto, brilhos e seu gatinho. O catálogo em uma casinha mágica cor-de-rosa coloca Olívia no centro de sete aventuras:

- **Jardim das Letras:** reconhecer letras iniciais e montar palavras curtas em português.
- **Piquenique dos Números:** contar até 5 no começo, avançar até 10 e juntar grupos com apoio visual.
- **Ateliê da Memória:** encontrar pares em tabuleiros de 6, 8, 10, 12, 14 e 16 peças, com progressão salva.
- **Trem das Formas:** descobrir desenhos que se repetem e completar o próximo vagão, avançando de duas formas alternadas para sequências com repetição e três formas.
- **Caderno Mágico:** escrever letras maiúsculas de A a Z e números de 0 a 9 com o dedo ou Apple Pencil. Três níveis: molde, pontinhos e cópia com modelo separado, com avaliação local da semelhança dos traços. Veja [como funciona a escrita](docs/escrita.md).
- **Ateliê de Desenho:** desenhar livremente com o dedo ou Apple Pencil, escolher cores e texturas e alternar entre três tamanhos de pincel.
- **Jardim de Colorir:** escolher uma ilustração e tocar nas partes para preencher com cores e texturas, sem sair do contorno.

As duas atividades de arte têm 11 cores, cinco texturas, borracha, desfazer/refazer e limpeza com confirmação. As criações ficam salvas automaticamente no aparelho, incluindo o preenchimento de cada desenho para colorir. São espaços de criação livre, sem pontuação ou níveis, e não alteram o potinho de estrelas. Recomeçar o progresso dos jogos preserva as criações; elas podem ser apagadas dentro de cada atividade.

Nos jogos de letras, números e formas, cada visita contém 5 desafios, com instruções faladas e reforço positivo. O trem tem 48 sequências diferentes e avança de fase a cada duas aventuras concluídas, até a terceira fase. Na memória, cada tabuleiro completo libera mais duas peças e dá uma estrela por par; a partir de 16 peças, novas partidas mantêm esse tamanho e embaralham novamente. Não há cronômetro nem perda de estrelas por errar. As atividades são pensadas para uma criança de 5 anos. Não representam material oficial nem certificação do currículo da Maple Bear.

Os sete jogos incluem 196 gravações de narração com a mesma voz feminina, frases naturais em português e volume uniforme. Os áudios ficam no próprio aplicativo; não é necessário baixar vozes no iPad nem manter conexão para ouvi-los. O Ateliê de Desenho e o Jardim de Colorir também têm suas instruções gravadas. Detalhes de produção e manutenção em [docs/narracao.md](docs/narracao.md).

Os 57 testes automatizados da versão 1.5.1 passaram, incluindo migração dos dados anteriores, avaliação dos traços, comparação entre os 36 modelos de escrita, persistência, limites e histórico das atividades de arte e cobertura das duas novas narrações. As estrelas, níveis e posições dos jogos anteriores são preservados ao atualizar o aplicativo. Na memória, um tabuleiro interrompido recomeça embaralhado, mantendo a quantidade de peças já alcançada.

A abertura dura cerca de 2,2 segundos e permite entrar imediatamente pelo botão “Vamos brincar!”. Aparece uma vez por execução, respeita Reduzir Movimento e espera pelo botão quando o VoiceOver está ativo.

A versão 1.5.1, build 7, foi instalada e aberta no iPad da Olívia em 17/10/2026, incluindo as narrações gravadas de desenho e colorir. O perfil de desenvolvimento desse pacote vence em 18/10/2026 às 14:36, horário de São Paulo; após a expiração é necessário renovar a assinatura e reinstalar.

O aplicativo funciona localmente, sem conta, anúncios, compras, analytics ou servidor. Progresso, criações e preferências ficam no dispositivo. As fotos originais em `assets/` são referências privadas: essa pasta não entra no projeto nem no aplicativo.

## Abrir e verificar

Requer macOS com Xcode completo e SDK de iOS. A validação dos áudios usa `ffmpeg` e `ffprobe` no Mac. Para os scripts de instalação, use Xcode 15 ou posterior, compatível com a versão de iPadOS instalada.

```sh
python3 scripts/generate-project.py
open OliviaPlay.xcodeproj
./scripts/check.sh
```

O projeto é gerado sem dependências externas. Execute o gerador depois de acrescentar arquivos ao diretório `OliviaPlay`; ele preserva a Team e o identificador do app configurados no Xcode. `check.sh` valida o projeto, recursos e sintaxe Swift; executa os testes do pacote, quando presente; e compila para o simulador quando o Xcode completo está disponível. O código de saída 2 indica que a validação iOS não pôde ser executada por falta de Xcode. A compilação e o uso no iPad continuam necessários para validar a interface, áudio, desempenho e assinatura.

## Instalar diretamente no iPad

1. Abra o Xcode, conclua a instalação dos componentes e adicione sua Apple Account em **Xcode › Settings › Accounts / Apple Accounts**.
2. Conecte e desbloqueie o iPad. Confirme **Confiar** no iPad e, se solicitado, no Finder do Mac. A Apple descreve esse pareamento em [Confiar neste computador](https://support.apple.com/109054).
3. Inicie o pareamento no Xcode. No iPad, ative **Ajustes › Privacidade e Segurança › Modo de Desenvolvedor** e siga a reinicialização e confirmação. Consulte [Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).
4. No projeto, selecione o target **OliviaPlay**, abra **Signing & Capabilities**, mantenha assinatura automática e selecione sua **Team**. Se o identificador já estiver em uso, personalize `br.com.oliviaplay.app`.
5. Selecione o iPad como destino e clique em **Run ▶**. Não é preciso enviar à App Store.
6. Na primeira abertura, se o iPad informar que o desenvolvedor não é confiável, vá a **Ajustes › Geral › VPN e Gerenciamento de Dispositivo**, selecione o perfil da sua conta Apple e confirme **Confiar**. Depois abra **Mundo da Olívia**.

Também é possível usar o script, depois de configurar a conta no Xcode:

```sh
./scripts/install-ipad.sh --list
./scripts/install-ipad.sh --device 'IDENTIFICADOR_DO_IPAD' --team 'TEAM_ID'
```

As variáveis `IPAD_DEVICE_ID` e `DEVELOPMENT_TEAM` substituem os argumentos correspondentes. `--bundle-id br.com.suafamilia.olivia` personaliza o identificador. O script compila, assina, instala e abre o app somente no dispositivo indicado; a etapa de assinatura pode se conectar aos serviços da Apple. Os scripts escolhem um Xcode já instalado apenas para o próprio processo, sem alterar `xcode-select` no Mac.

Com uma conta gratuita **Personal Team**, a Apple informa que o perfil de provisionamento expira **7 dias após a emissão**. É necessário recompilar e reinstalar depois da expiração; não é uma instalação permanente. Veja os [limites oficiais da conta](https://developer.apple.com/help/account/basics/about-your-developer-account). Uma conta paga tem regras de provisionamento próprias; este projeto não exige publicação na loja.

## Estrutura

- `OliviaPlay/App` e `OliviaPlay/Views`: aplicativo, catálogo e telas.
- `OliviaPlay/Core`: conteúdo e regras dos jogos, sem dependências de interface.
- `OliviaPlay/Resources`: ilustrações e recursos empacotados.
- `scripts`: projeto reproduzível, validação e instalação no iPad.

Para uma prévia de desenvolvimento em Mac com Apple silicon, execute `./scripts/preview-mac.sh` e abra `build/preview/Mundo da Olivia.app`. Essa prévia compila as telas SwiftUI para macOS; não produz um aplicativo de iPad nem valida a experiência de toque. `--run` solicita sua abertura após a compilação.

`./scripts/render-previews.sh` gera imagens das próprias views em `output/previews`, em 1080×810 e 810×1080 pontos. Renderiza uma hierarquia privada de `NSHostingView`, sem capturar a tela do computador. São prévias de layout renderizadas no Mac; a validação final continua sendo feita no iPad.

Quando o Command Line Tools não consegue executar SwiftPM/XCTest, `check.sh` tenta as verificações equivalentes do núcleo em `Tests/CoreChecks.swift` e guarda o diagnóstico em `build/swift-test.log`. Um conflito específico de módulos SwiftBridging no CLT é contornado com um overlay local em `build/toolchain-overlay`, sem modificar o SDK ou outros arquivos do sistema.

## Estado da primeira preparação

Em 11/10/2026, os 11 testes XCTest passaram e os builds para iPad Simulator e iPad físico terminaram com sucesso no Xcode 27. O aplicativo foi assinado, instalado e aberto no **iPad da Olívia**, de 9ª geração, com iPadOS 26.6.1. Após a confirmação de confiança pelo usuário, o Xcode confirmou a abertura e a consulta de processos confirmou que o aplicativo permanecia em execução. A assinatura foi verificada; o perfil inclui esse aparelho e expira em **18/10/2026 às 14:36, horário de Porto Alegre**. Detalhes em [docs/validacao.md](docs/validacao.md).
