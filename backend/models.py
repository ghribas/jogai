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

from flask_sqlalchemy import SQLAlchemy
from datetime import datetime, timezone
from werkzeug.security import generate_password_hash, check_password_hash
import random

db = SQLAlchemy()

def generate_random_color():
    return f"#{random.randint(0, 0xFFFFFF):06x}"

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    chats = db.relationship('Chat', backref='user', lazy=True, cascade="all, delete-orphan")

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def __repr__(self):
        return f'<User {self.username}>'

class Chat(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    title = db.Column(db.String(100), nullable=False, default='Novo Chat')
    created_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    last_accessed_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    status = db.Column(db.String(50), nullable=False, default='new') # new, started, ongoing, finished, archived
    observations = db.Column(db.Text, nullable=True)
    color = db.Column(db.String(7), nullable=True, default=generate_random_color) # Armazena cores como #RRGGBB
    
    # Campos de pré-configuração
    universo = db.Column(db.String(100), nullable=True)
    universo_outro = db.Column(db.String(255), nullable=True)
    genero = db.Column(db.String(50), nullable=True)
    genero_outro = db.Column(db.String(255), nullable=True)
    nome_protagonista = db.Column(db.String(100), nullable=True)
    nome_universo_jogo = db.Column(db.String(100), nullable=True) # Renomeado para clareza
    nome_antagonista = db.Column(db.String(100), nullable=True)
    inspiracao = db.Column(db.Text, nullable=True)
    age = db.Column(db.Integer, nullable=True) # Novo campo para idade
    
    messages = db.relationship('Message', backref='chat', lazy=True, cascade="all, delete-orphan", order_by='Message.timestamp')

    def __repr__(self):
        return f'<Chat {self.title}>'

    def to_dict(self, include_messages=False):
        data = {
            'id': self.id,
            'user_id': self.user_id,
            'title': self.title,
            'created_at': self.created_at.isoformat(),
            'last_accessed_at': self.last_accessed_at.isoformat(),
            'status': self.status,
            'observations': self.observations,
            'color': self.color if self.color else generate_random_color(), # Garante que sempre retorne uma cor
            'config': {
                'universo': self.universo,
                'universo_outro': self.universo_outro,
                'genero': self.genero,
                'genero_outro': self.genero_outro,
                'nome_protagonista': self.nome_protagonista,
                'nome_universo_jogo': self.nome_universo_jogo,
                'nome_antagonista': self.nome_antagonista,
                'inspiracao': self.inspiracao,
                'age': self.age, # Adicionar idade à serialização
            }
        }
        if include_messages:
            data['messages'] = [message.to_dict() for message in self.messages]
        return data

class Message(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    chat_id = db.Column(db.Integer, db.ForeignKey('chat.id'), nullable=False)
    sender = db.Column(db.String(50), nullable=False)  # 'user' ou 'gemini'
    content = db.Column(db.Text, nullable=False)
    timestamp = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    def __repr__(self):
        return f'<Message {self.id} from {self.sender}>'

    def to_dict(self):
        return {
            'id': self.id,
            'chat_id': self.chat_id,
            'sender': self.sender,
            'content': self.content,
            'timestamp': self.timestamp.isoformat()
        } 