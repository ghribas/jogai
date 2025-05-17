# -----------------------------------------------------------------------------
# Sistema: JogAI
# Autor: Guilherme Heyse Ribas
# Criado em: 15 e 16 de maio de 2025
# Evento: Imersão IA - 3ª Edição (Alura + Google Gemini)
#
# Este sistema foi inteiramente desenvolvido com auxílio da inteligência artificial
# Google Gemini, utilizando Python e Flutter com integração direta ao modelo Gemini.
#
# Todos os arquivos deste projeto foram gerados durante a Imersão promovida pela Alura
# em parceria com o Google, como uma exploração prática do uso de IA em desenvolvimento
# de software.
# -----------------------------------------------------------------------------

import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'uma-chave-secreta-muito-dificil'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///app.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY')
    INITIAL_CHAT_PROMPT_FILE = 'initial_chat_prompt.txt' 