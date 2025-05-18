# Guia de Configuração Detalhada do Jog.ai

Este documento fornece um guia passo a passo para configurar e rodar o sistema Jog.ai em seu ambiente de desenvolvimento local. Ele complementa a seção "Começando" no `README.md`.

## Pré-requisitos

Antes de começar, certifique-se de que você tem o seguinte software instalado em sua máquina:

* **Git:** Para clonar o repositório do projeto. Se não tiver, baixe e instale a partir de [https://git-scm.com/](https://git-scm.com/).
* **Python 3.8 ou superior (3.10 recomendada):** Para o backend. Baixe e instale a partir de [https://www.python.org/downloads/](https://www.python.org/downloads/). É altamente recomendável usar um gerenciador de ambientes virtuais (venv, virtualenv, conda).
* **Flutter SDK:** Para o frontend. Siga o guia de instalação oficial do Flutter para o seu sistema operacional: [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install).
* **Uma chave da Google AI API (para o Gemini):** Você precisará desta chave para que o backend possa interagir com a IA. Obtenha sua chave gratuitamente no [Google AI Studio](https://aistudio.google.com/).

## 1. Clonando o Repositório

Abra o terminal ou prompt de comando e clone o repositório do Jog.ai:

```bash
git clone https://github.com/ghribas/jogai/
```
```bash
cd jogai
```

&nbsp;
---
&nbsp;

## 2. Configuração do Backend (Python)

Navegue até o diretório do backend do projeto (assumindo que a estrutura do seu projeto tenha uma pasta `backend/` na raiz):

```bash
cd backend
```
&nbsp;

### 2.1. Criando e Ativando um Ambiente Virtual

É altamente recomendável usar um ambiente virtual para isolar as dependências do seu projeto:

#### Crie o ambiente virtual na pasta .venv
```bash
python -m venv .venv
```

#### Ative o ambiente virtual
##### No macOS e Linux:
```bash
source .venv/bin/activate
```

##### No Windows:
```bash
.venv\Scripts\activate
```
Se você estiver usando `conda`, os comandos seriam diferentes (`conda create -n jogai_env python=3.8` e `conda activate jogai_env`).

&nbsp;

### 2.2. Instalando as Dependências do Backend

Com o ambiente virtual ativado, instale as bibliotecas Python necessárias listadas no arquivo `requirements.txt`:
```bash
pip install -r requirements.txt
```
&nbsp;

### 2.3. Configurando a Chave da Google AI API

Crie um arquivo chamado `.env` na **raiz do diretório do backend** (`./backend/.env`) e adicione a sua chave da API do Gemini nele. **Nunca exponha sua chave diretamente no código ou a envie para o GitHub.**
```bash
GEMINI_API_KEY=SUA_CHAVE_DA_API_DO_GEMINI
```
**Substitua `SUA_CHAVE_DA_API_DO_GEMINI` pela chave que você obteve no Google AI Studio.** Certifique-se de que o arquivo `.env` está incluído no seu arquivo `.gitignore` para evitar que a chave seja enviada para o repositório público.

&nbsp;

### 2.4. Configurando o Banco de Dados (SQLite)

Como o Jog.ai utiliza SQLite, o banco de dados é um arquivo local. Geralmente, a primeira vez que o backend é executado ou um script de inicialização/migração é rodado, o arquivo do banco de dados e as tabelas serão criados automaticamente.

Se você estiver usando uma ORM (como SQLAlchemy com Alembic para migrações), você pode precisar rodar os comandos de migração a partir do diretório do backend:

#### Exemplo se usando Alembic
```bash
alembic upgrade head
```

Consulte a documentação específica da sua implementação de banco de dados no código Python, caso haja um script de setup diferente.

&nbsp;

### 2.5. Rodando o Servidor Backend

Com as dependências instaladas, a API Key configurada e o DB inicializado, você pode iniciar o servidor backend. O comando exato depende do framework Python que você está usando (Flask, FastAPI, etc.).

#### Exemplo se usando Flask:
Certifique-se de que a variável de ambiente FLASK_APP está definida, ou execute com: 
```bash
flask run
```

##### Para macOS/Linux
```bash
export FLASK_APP=app.py
```

##### Para Windows
```bash
set FLASK_APP=app.py
```

#### Carregue o banco de dados inicial:
```bash
flask db upgrade
```

#### Inicie o servicor:
```bash
flask run
```
- OU, como o arquivo app.py tem o app.run() configurado:
```bash
python app.py
```

##### Exemplo se usando FastAPI (com uvicorn):
uvicorn main:app --reload # SUBSTITUA main:app conforme seu arquivo e instância do FastAPI

O backend deve iniciar e estar acessível, tipicamente em http://127.0.0.1:5000 (Flask) ou http://127.0.0.1:8000 (FastAPI). Deixe este terminal rodando.


&nbsp;
---
&nbsp;


## 3. Configuração do Frontend (Flutter)

Abra um **novo terminal** e navegue até o diretório do frontend do projeto, especificamente a pasta do aplicativo Flutter:
```bash
cd frontend/jog_ai_app
```
&nbsp;

### 3.1. Obtendo as Dependências do Flutter

Execute o comando para obter todas as dependências do projeto Flutter:
```bash
flutter pub get
```
&nbsp;

### 3.2. Configurando o Endereço do Backend

O Frontend precisa saber onde encontrar o Backend. O arquivo `lib/services/api_service.dart` no projeto Flutter está configurado para se comunicar com o backend em `http://127.0.0.1:5000/api`.

Certifique-se de que seu servidor backend esteja rodando neste endereço e porta. Se você alterou a porta ou o host do backend, você precisará atualizar a variável `_baseUrl` no arquivo `frontend/jog_ai_app/lib/services/api_service.dart` correspondente.

&nbsp;

### 3.3. Rodando o Aplicativo Frontend

Com as dependências instaladas e o endereço do backend configurado, você pode rodar o aplicativo Flutter. Especifique o dispositivo ou plataforma onde você quer rodar (ex: `chrome` para web, o ID de um emulador/dispositivo físico).

#### Exemplo para rodar no navegador Chrome (comum para desenvolvimento web)
```bash
flutter run -d chrome
```

#### Para listar dispositivos disponíveis:
```bash
flutter devices
```

#### Para rodar em um dispositivo específico:
```bash
flutter run -d <id_do_dispositivo>
```

O Frontend será compilado e iniciado no dispositivo/navegador selecionado, conectando-se ao Backend que está rodando no outro terminal.


&nbsp;
---
&nbsp;


## 4. Primeiro Uso

1. Uma vez que tanto o Backend quanto o Frontend estejam rodando sem erros, acesse a interface do Jog.ai (geralmente a URL aberta pelo comando `flutter run`).
2. Use a tela de registro para criar um novo usuário.
3. Faça login com as credenciais que você acabou de criar.
4. No dashboard, encontre a opção para "Iniciar Novo Jogo".
5. Defina a sua primeira aventura e comece a interagir no chat!

&nbsp;
---
&nbsp;

Se encontrar quaisquer problemas, verifique as mensagens de erro no terminal do Backend e do Frontend. Problemas comuns incluem variáveis de ambiente incorretas, dependências faltando, ou o Backend não estar rodando antes de tentar iniciar o Frontend. Se os servidores (Backend e Frontend) parecem estar rodando, mas a comunicação não funciona, verifique os firewalls ou se as portas estão acessíveis.
