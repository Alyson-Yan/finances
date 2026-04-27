# 💰 Finances - Sistema Financeiro Inteligente

Aplicação desenvolvida em Flutter com foco em controle financeiro pessoal baseado em regras reais de negócio, inspirado em planilhas estruturadas.

## 🚀 Objetivo

Criar um sistema que não apenas registra transações, mas que aplica regras financeiras automaticamente, garantindo consistência, previsibilidade e controle total do usuário sobre seus gastos e ganhos.

---

## 🧠 Conceito do Projeto

Diferente de apps comuns de finanças, este projeto segue um modelo baseado em:

* 📌 **Fonte única de verdade**: os dados seguem uma estrutura rígida (inspirada em Excel)
* 🔁 **Regras de negócio automatizadas**
* 📊 **Projeção financeira mensal**
* ⚙️ **Separação entre dados de entrada e cálculos derivados**

---

## 🏗️ Funcionalidades

* ✔️ Cadastro de transações (Ganhos e Gastos)
* ✔️ Sistema de parcelamento automático
* ✔️ Controle de categorias
* ✔️ Histórico financeiro
* ✔️ Cálculo automático de saldo
* ✔️ Estrutura preparada para projeções futuras

---

## 🧩 Arquitetura

O projeto segue uma organização baseada em:

```
lib/
 ├── models/        # Estrutura de dados (transações, parcelamentos)
 ├── providers/     # Gerenciamento de estado (Provider)
 ├── screens/       # Interfaces do usuário
 ├── widgets/       # Componentes reutilizáveis
```

### 🔥 Regras importantes

* O usuário **não altera valores calculados manualmente**
* Transações podem ser:

  * Pontuais
  * Parceladas
  * Futuras (projetadas)
* O sistema gera automaticamente os impactos mensais

---

## 🛠️ Tecnologias

* Flutter
* Dart
* Provider (gerenciamento de estado)

---

## 📦 Como rodar o projeto

```bash
# Clone o repositório
git clone https://github.com/Alyson-Yan/finances.git

# Acesse a pasta
cd finances

# Instale as dependências
flutter pub get

# Rode o projeto
flutter run
```

---

## 📈 Roadmap

* [ ] Gráficos financeiros
* [ ] Filtros avançados
* [ ] Exportação de dados (CSV/JSON)
* [ ] Notificações de despesas recorrentes
* [ ] Integração com APIs bancárias

---

## 🧑‍💻 Autor

Desenvolvido por Alyson Yan Fernandes

---

## ⚠️ Status

🚧 Em desenvolvimento — foco atual em estrutura e regras de negócio
