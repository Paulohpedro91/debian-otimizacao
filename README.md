# 🛠️ Script de Otimização e Manutenção para Debian

Um script em Bash seguro, robusto e automatizado para manutenção, atualização e otimização de sistemas operacionais **Debian** e derivados (como Ubuntu, Linux Mint, POP!_OS, etc.).

O script foi desenvolvido com foco em **segurança**, **transparência** e **usabilidade**, contando com animações visuais de carregamento, modo de simulação (*dry-run*), gestão de exceções e tratamento silencioso de saídas.

---

## 📌 Funcionalidades

- 🔄 **Atualização Completa do Sistema**: Executa a atualização de repositórios e atualizações de pacotes do sistema (`apt full-upgrade`), tratando dependências de Kernel.
- 🧹 **Limpeza de Caches e Arquivos Desnecessários**:
  - Limpa caches de pacotes .deb obsoletos (`autoclean` e `clean`).
  - Remove pacotes órfãos e as suas configurações residuais (`autoremove --purge`).
  - Reduz e otimiza logs antigos do sistema via `journalctl` (mantém os últimos 7 dias).
  - Limpa ficheiros temporários do sistema via `systemd-tmpfiles`.
- 📦 **Suporte a Gerenciadores de Pacotes Universais**:
  - **Flatpak**: Remove *runtimes* e pacotes não utilizados (`uninstall --unused`).
  - **Snap**: Remove automaticamente revisões antigas e desativadas de pacotes.
- 🔤 **Atualização do Cache de Fontes**: Atualiza o cache do sistema via `fc-cache`.
- 🛡️ **Verificação de Integridade**: Executa o audit do `dpkg` para identificar inconsistências na base de dados de pacotes.
- 🔔 **Notificação Inteligente de Reboot**: Alerta o utilizador apenas se houver atualização pendente que exija reinicialização (ex: Kernel ou Glibc).
- ⏳ **Animação Visual (Spinner)**: Exibe um indicador gráfico de progresso durante a execução das tarefas, mantendo os logs de saída limpos.

---

## 🚀 Como Usar

### 1. Clonar ou Baixar o Script
Faça o download do ficheiro `debian-otimizar.sh` para o seu computador.

### 2. Dar Permissão de Execução
Abra o terminal na pasta onde o ficheiro se encontra e execute:

```bash
chmod +x debian-otimizar.sh
```

### 3. Executar o Script

Para rodar a manutenção completa (requer privilégios de `root`):

```bash
sudo ./debian-otimizar.sh
```

---

## ⚙️ Opções e Parâmetros

O script suporta diversas flags para adaptar a execução ao seu fluxo de trabalho:

| Opção | Atalho | Descrição |
| :--- | :--- | :--- |
| `--dry-run` | `-d` | **Modo Simulação:** exibe quais comandos seriam executados sem alterar nada no sistema. |
| `--yes` | `-y` | **Modo Não-Interativo:** responde 'sim' a todas as confirmações automaticamente (útil para automações via Cron). |
| `--help` | `-h` | Exibe o menu de ajuda com a sintaxe de uso e exemplos. |

### Exemplos de Uso:

- **Simular as ações antes de aplicar (Recomendado na primeira vez):**
  ```bash
  sudo ./debian-otimizar.sh --dry-run
  ```

- **Executar a manutenção sem perguntas de confirmação:**
  ```bash
  sudo ./debian-otimizar.sh -y
  ```

---

## 🛡️ Recursos de Segurança Incluídos

1. **Modo Estrito de Bash (`set -Eeuo pipefail`)**: Evita que o script continue a ser executado se algum comando crítico falhar de forma inesperada.
2. **Tratamento de Sinais (`trap`)**: Se o utilizador pressionar `Ctrl+C` durante a execução, o script encerra as operações com segurança e restaura a exibição do cursor no terminal.
3. **Log de Erros Temporário**: As saídas brutas dos comandos são redirecionadas para ficheiros temporários isolados. Caso ocorra uma falha, o log do erro específico é exibido na tela sem poluir a execução normal.
4. **Validação de Privilégios**: Garante que o script só seja executado com permissões de superutilizador (`root`).
5. **Variável `DEBIAN_FRONTEND=noninteractive`**: Impede que telas azuis de confirmação de pacotes travem a execução do script.

---

## 📋 Pré-requisitos

- **Sistema Operacional**: Debian ou qualquer distribuição baseada no Debian.
- **Dependências Padrão**: `apt-get`, `dpkg`, `systemd` e utilitários POSIX básicos (`awk`, `date`, `df`).

---

## 📄 Licença

Este projeto é disponibilizado sob a licença [MIT](LICENSE). Sinta-se livre para modificar, redistribuir e adaptar às suas necessidades.
