# Como Rodar o Sistema Jog.AI

Este arquivo fornece um guia rápido para iniciar o backend e o frontend do sistema Jog.AI.
Para instruções de configuração completas, incluindo instalação de pré-requisitos e configuração inicial, consulte o arquivo `SETUP.md`.

## 1. Rodar o Backend (Python/Flask)

1.  **Abra um terminal.**
2.  **Navegue até a pasta do backend do projeto:**
    ```bash
    cd backend
    ```
3.  **O ambiente virtual Python:**
    * Usando o PowerShell, faça: 
    ```bash
    python -m venv .venv
    ```

    **Ative o ambiente virtual Python:**
    *   No macOS e Linux:
        ```bash
        source .venv/bin/activate
        ```
    *   No Windows:
        ```bash
        .venv\Scripts\activate
        ```
    *(Se você utilizou um nome diferente para o ambiente virtual ou outro gerenciador como conda, ajuste o comando de ativação.)*


4.  **Verifique o arquivo `.env`:**
    *   Certifique-se de que o arquivo `backend/.env` existe.
    *   Este arquivo deve conter sua chave da API do Gemini, no formato: `GEMINI_API_KEY=SUA_CHAVE_AQUI`.

5.  **Inicie o servidor Flask:**
    ```bash
    python app.py
    ```
    O servidor backend deverá iniciar e ficar acessível em `http://127.0.0.1:5000/` (ou a porta configurada).
    **Deixe este terminal rodando.**

## 2. Rodar o Frontend (Flutter)

1.  **Abra um NOVO terminal.** (Mantenha o terminal do backend rodando.)
2.  **Navegue até a pasta do aplicativo Flutter:**
    ```bash
    cd frontend/jog_ai_app
    ```
3.  **(Opcional) Se você fez alterações nas dependências do Flutter ou está rodando pela primeira vez em um ambiente novo, obtenha as dependências:**
    ```bash
    flutter pub get
    ```
4.  **Inicie o aplicativo Flutter:**
    *   Para rodar na **web** (ex: no navegador Chrome):
        ```bash
        flutter run -d chrome
        ```
    *   Para **listar os dispositivos e emuladores** disponíveis:
        ```bash
        flutter devices
        ```
    *   Para rodar em um **dispositivo ou emulador específico** (substitua `<id_do_dispositivo>` pelo ID real):
        ```bash
        flutter run -d <id_do_dispositivo>
        ```

O Flutter irá compilar o aplicativo e iniciá-lo no dispositivo ou navegador selecionado. A interface do Jog.AI deverá carregar e se conectar ao backend.

## Solução de Problemas Comuns

*   **Backend não inicia:**
    *   Verifique se o ambiente virtual está ativado.
    *   Confirme se todas as dependências em `backend/requirements.txt` estão instaladas (`pip install -r requirements.txt` dentro do ambiente virtual).
    *   Verifique se o arquivo `backend/.env` existe e a `GEMINI_API_KEY` está correta.
*   **Frontend não conecta ao backend (erros de rede, 404 no console do navegador):**
    *   Confirme se o servidor backend está rodando e acessível no endereço esperado (normalmente `http://127.0.0.1:5000/`).
    *   Verifique o arquivo `frontend/jog_ai_app/lib/services/api_service.dart` para garantir que a variável `_baseUrl` aponta para o endereço correto do backend (deve ser `http://127.0.0.1:5000/api`).
*   **Outros erros:** Verifique as mensagens de erro detalhadas nos terminais do backend e do frontend para pistas sobre o problema.

Lembre-se que o arquivo `SETUP.md` contém informações mais detalhadas sobre a configuração inicial do projeto. 