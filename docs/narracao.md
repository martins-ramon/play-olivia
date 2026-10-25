# Narração

As falas dos oito jogos são gravações completas em português, incluídas no aplicativo. A reprodução continua disponível sem internet e tem a mesma voz em todos os jogos, independentemente das vozes instaladas no iPad. O Ateliê de Desenho e o Jardim de Colorir também têm suas instruções gravadas.

São 218 gravações: perguntas, dicas, respostas, conclusões, nomes de letras e números. A versão 1.2 acrescentou 14 falas para memória; a 1.3, oito para o Trem das Formas; a 1.4 acrescentou 45 para o Caderno Mágico, incluindo os 36 símbolos de escrita, os três níveis e os retornos da avaliação. As duas instruções das atividades de arte completam o catálogo, com a mesma voz das demais atividades. O Guarda-roupa Mágico acrescenta 22 falas: duas introduções, um retorno de nova tentativa, uma confirmação de visual guardado e perguntas, dicas e celebrações para suas seis situações. O catálogo de produção em `OliviaPlay/Core/NarrationCatalog.swift` é a fonte das falas gravadas. Os textos narrados são independentes dos rótulos visuais: palavras em maiúsculas e algarismos da interface não são enviados à voz.

A produção usa a voz Serene pelo conector Runway, idioma português e velocidade 0,94. As primeiras gravações usam `eleven_v3`; memória, formas, escrita, as duas instruções de arte e o jogo de vestir usam `eleven_multilingual_v2`, com a mesma voz. O modelo de cada gravação está registrado no manifesto. Foram enviados somente os textos das falas. Fotografias e gravações da voz da criança não foram usadas para produzir a narração.

Os MP3 são mono, 44,1 kHz, 128 kbps, com volume normalizado para alvo de −18 LUFS e pico verdadeiro de −2 dB. A preparação retira silêncio apenas das pontas, preservando pausas internas e sem alterar a altura da voz. Originais e referências aos trabalhos de geração ficam em `build/narration`, fora do aplicativo.

`NarrationPlayer` reproduz as frases com `AVAudioPlayer`. Contagens e nomes de letras terminam antes da próxima fala curta; a fila guarda no máximo as duas respostas mais recentes para acompanhar toques rápidos. Instruções e feedbacks substituem a fila anterior com uma transição de 75 ms. Silenciar, sair do jogo e suspender o aplicativo cancelam a reprodução e qualquer transição pendente. Repetir uma instrução que ainda está falando não a reinicia no meio de uma palavra.

Se uma gravação faltar ou estiver ilegível, a voz do sistema é usada como recuperação: português brasileiro, maior qualidade disponível, tom original e velocidade 0,48. A validação de build exige que todas as gravações do catálogo de produção estejam presentes. As instruções das atividades de arte usam `NarrationCatalog.drawingIntro` e `NarrationCatalog.coloringIntro`, incluídas em `allCues` e no manifesto de MP3; o acesso ao jogo e o botão de alto-falante reproduzem essas mesmas gravações. O jogo de vestir usa `dressUpIntro`, `dressUpFreeIntro`, `dressUpPrompt`, `dressUpHint`, `dressUpSuccess`, `dressUpRetry` e `dressUpSaved`; as perguntas e dicas vêm das mesmas situações usadas nas regras do desafio.

## Manutenção e validação

- `scripts/export-narration.swift` exporta o catálogo de produção.
- `scripts/prepare-narration.py` prepara os trabalhos de geração concluídos e cria `narration-manifest.json` com texto e hash SHA-256 de cada gravação.
- `scripts/validate-narration.py` verifica cobertura, correspondência entre texto e gravação, hashes, decodificação, duração, volume e clipping. É executado por `scripts/check.sh` antes do build.
- `scripts/check-narration-player.swift` confirma que o AVAudioPlayer consegue carregar e preparar os MP3.

Ao alterar uma fala, gere novamente o áudio correspondente e atualize o manifesto. A validação rejeita textos modificados que ainda apontem para a gravação anterior.
