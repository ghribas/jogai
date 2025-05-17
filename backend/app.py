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

from flask import Flask, request, jsonify, render_template_string
from flask_migrate import Migrate
from flask_cors import CORS
from datetime import datetime, timezone
from config import Config
from models import db, User, Chat, Message
import google.generativeai as genai
import os

app = Flask(__name__)
app.config.from_object(Config)
CORS(app)

db.init_app(app)
migrate = Migrate(app, db)

# Configuração da API do Gemini
if Config.GEMINI_API_KEY:
    genai.configure(api_key=Config.GEMINI_API_KEY)
    model = genai.GenerativeModel('gemini-1.5-flash-latest')
else:
    model = None
    print("Chave da API do Gemini não configurada. Funcionalidades de chat estarão desabilitadas.")

@app.route('/')
def hello():
    return "Hello, JogAI!"

# --- Autenticação ---
@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({'error': 'Usuário e senha são obrigatórios'}), 400

    if User.query.filter_by(username=username).first():
        return jsonify({'error': 'Usuário já existe'}), 400

    new_user = User(username=username)
    new_user.set_password(password)
    db.session.add(new_user)
    db.session.commit()
    return jsonify({'message': 'Usuário registrado com sucesso!', 'user_id': new_user.id}), 201

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    user = User.query.filter_by(username=username).first()

    if user and user.check_password(password):
        return jsonify({'message': 'Login bem-sucedido!', 'user_id': user.id, 'username': user.username}), 200
    
    return jsonify({'error': 'Credenciais inválidas'}), 401

# --- Chats ---
def format_initial_prompt(chat_config):
    try:
        with open(Config.INITIAL_CHAT_PROMPT_FILE, 'r', encoding='utf-8') as f:
            template_string = f.read()
        # Renderiza o template com os dados do chat_config
        # Garante que apenas chaves existentes em chat_config e no template sejam usadas
        # e que valores None sejam tratados (Jinja2 faz isso bem por padrão)
        return render_template_string(template_string, **chat_config)
    except FileNotFoundError:
        return "Como posso te ajudar hoje?"
    except Exception as e:
        print(f"Erro ao formatar prompt inicial: {e}")
        return "Como posso te ajudar hoje?" # Fallback

@app.route('/api/chats', methods=['POST'])
def create_chat():
    data = request.get_json()
    user_id = data.get('user_id')
    # O título do frontend (se houver) pode ser usado como um fallback distante
    frontend_title_placeholder = data.get('title', 'Nova Aventura RPG') 
    age_str = data.get('age')
    age = None

    if age_str is not None:
        try:
            age = int(age_str)
            if not (4 <= age <= 150):
                return jsonify({'error': 'Idade deve ser um número entre 4 e 150.'}), 400
        except ValueError:
            return jsonify({'error': 'Idade inválida. Deve ser um número inteiro.'}), 400
    
    config_data = {
        "universo": data.get('universo'),
        "universo_outro": data.get('universo_outro'),
        "genero": data.get('genero'),
        "genero_outro": data.get('genero_outro'),
        "nome_protagonista": data.get('nome_protagonista'),
        "nome_universo_jogo": data.get('nome_universo_jogo'),
        "nome_antagonista": data.get('nome_antagonista'),
        "inspiracao": data.get('inspiracao'),
        "age": age # Adiciona a idade validada ao config_data
    }

    if not user_id:
        return jsonify({'error': 'user_id é obrigatório'}), 400
    
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'Usuário não encontrado'}), 404

    # Geração do título pelo Gemini
    generated_title_by_gemini = None
    if model: # Tentar gerar título apenas se o modelo Gemini estiver configurado
        try:
            prompt_elements = []
            if config_data.get("universo") and config_data["universo"].lower() != 'outro':
                prompt_elements.append(f"universo de {config_data['universo']}")
            elif config_data.get("universo_outro"):
                 prompt_elements.append(f"universo de {config_data['universo_outro']}")
            
            if config_data.get("genero") and config_data["genero"].lower() != 'outro':
                prompt_elements.append(f"gênero {config_data['genero']}")
            elif config_data.get("genero_outro"):
                prompt_elements.append(f"gênero {config_data['genero_outro']}")

            if config_data.get("nome_protagonista"):
                prompt_elements.append(f"com protagonista {config_data['nome_protagonista']}")
            
            description_for_title = ", ".join(prompt_elements)
            if not description_for_title:
                description_for_title = "uma aventura de RPG"
            
            title_generation_prompt = (
                f"Sugira um título curto e criativo (entre 3 e 7 palavras) para uma aventura de RPG sobre {description_for_title}. "
                f"O título deve ser instigante. Exemplos: 'A Lança do Dragão Ancestral', 'Sombras em Neonville', 'O Enigma da Floresta Sussurrante'. "
                "Responda APENAS com o título sugerido, sem introduções, explicações ou aspas em volta."
            )
            
            title_chat_session = model.start_chat(history=[])
            title_response = title_chat_session.send_message(title_generation_prompt)
            
            if title_response.text and title_response.text.strip():
                generated_title_by_gemini = title_response.text.strip()
                # Limpeza adicional de possíveis prefixos ou sufixos comuns que o modelo pode adicionar
                if generated_title_by_gemini.lower().startswith("título:"):
                    generated_title_by_gemini = generated_title_by_gemini[len("título:"):].strip()
                if generated_title_by_gemini.startswith('"') and generated_title_by_gemini.endswith('"'):
                    generated_title_by_gemini = generated_title_by_gemini[1:-1]
                if generated_title_by_gemini.startswith("'") and generated_title_by_gemini.endswith("'"):
                    generated_title_by_gemini = generated_title_by_gemini[1:-1]

        except Exception as e:
            print(f"Erro ao gerar título com Gemini: {e}")
            # Falha silenciosa, usaremos o fallback

    # Determinar o título final
    final_chat_title = generated_title_by_gemini
    if not final_chat_title:
        # Fallback se o Gemini não gerar título
        if config_data.get("universo") and config_data["universo"].lower() != 'outro':
            final_chat_title = f"Aventura em {config_data['universo']}"
        elif config_data.get("universo_outro"):
            final_chat_title = f"Aventura em {config_data['universo_outro']}"
        else:
            final_chat_title = frontend_title_placeholder # Usa o que o frontend mandou ou o default "Nova Aventura RPG"

    # Criação do chat com todos os dados, incluindo a idade
    new_chat = Chat(
        user_id=user_id, 
        title=final_chat_title, 
        status='new',
        # Removido o desempacotamento de config_data aqui para definir explicitamente
        universo=config_data.get("universo"),
        universo_outro=config_data.get("universo_outro"),
        genero=config_data.get("genero"),
        genero_outro=config_data.get("genero_outro"),
        nome_protagonista=config_data.get("nome_protagonista"),
        nome_universo_jogo=config_data.get("nome_universo_jogo"),
        nome_antagonista=config_data.get("nome_antagonista"),
        inspiracao=config_data.get("inspiracao"),
        age=config_data.get("age") # Passa a idade para o construtor
    )
    db.session.add(new_chat)
    db.session.commit()

    return jsonify(new_chat.to_dict(include_messages=True)), 201

@app.route('/api/chats/<int:user_id>', methods=['GET'])
def get_user_chats(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'Usuário não encontrado'}), 404

    chats = Chat.query.filter_by(user_id=user_id).order_by(Chat.last_accessed_at.desc()).all()
    return jsonify([chat.to_dict() for chat in chats]), 200 # Usar to_dict para cada chat

@app.route('/api/chat/<int:chat_id>', methods=['GET'])
def get_chat_details(chat_id):
    chat = Chat.query.get(chat_id)
    if not chat:
        return jsonify({'error': 'Chat não encontrado'}), 404
    
    # Se o chat é novo e não tem mensagens, gerar a primeira mensagem do Gemini
    if chat.status == 'new' and not chat.messages:
        if not model:
            # Não bloquear o carregamento do chat se o Gemini não estiver disponível,
            # mas talvez logar ou retornar uma mensagem indicando isso.
            # Por enquanto, o chat ficará vazio e o usuário precisará enviar a primeira msg.
            pass # O fluxo normal de send_message lidará com a inicialização se Gemini estiver offline
        else:
            try:
                chat_config_for_prompt = {
                    "universo": chat.universo, "universo_outro": chat.universo_outro,
                    "genero": chat.genero, "genero_outro": chat.genero_outro,
                    "nome_protagonista": chat.nome_protagonista,
                    "nome_universo_jogo": chat.nome_universo_jogo,
                    "nome_antagonista": chat.nome_antagonista,
                    "inspiracao": chat.inspiracao,
                    "age": chat.age # Adicionar idade ao prompt inicial
                }
                base_scenario_prompt = format_initial_prompt(chat_config_for_prompt)
                
                # Instrução adicional para o Gemini gerar o resumo e a pergunta
                prompt_for_gemini_intro = (
                    base_scenario_prompt +
                    "\\n\\n---\\n"
                    "Com base no cenário acima, sua primeira resposta ao jogador deve ser:"
                    "\\n1. Um breve e criativo resumo da aventura que você está prestes a mestrar (2-3 frases)."
                    "\\n2. A pergunta clara: 'Deseja iniciar a aventura agora?'"
                    "\\nResponda apenas com esse resumo e a pergunta."
                )

                # Usar uma sessão de chat temporária para esta primeira mensagem
                # Não passamos histórico pois o prompt_for_gemini_intro já é completo.
                intro_chat_session = model.start_chat(history=[])
                intro_response = intro_chat_session.send_message(prompt_for_gemini_intro)
                gemini_intro_message_content = intro_response.text

                first_gemini_message = Message(chat_id=chat.id, sender='gemini', content=gemini_intro_message_content)
                db.session.add(first_gemini_message)
                chat.last_accessed_at = datetime.now(timezone.utc) # Atualiza o acesso
                db.session.commit()
            except Exception as e:
                print(f"Erro ao gerar mensagem inicial do Gemini para chat {chat.id}: {e}")
                # Não falhar o request, apenas o chat não terá a mensagem inicial do Gemini.
                # O usuário poderá iniciar a conversa normalmente.
                db.session.rollback()

    chat.last_accessed_at = datetime.now(timezone.utc)
    db.session.commit()

    messages = Message.query.filter_by(chat_id=chat_id).order_by(Message.timestamp.asc()).all()

    return jsonify(chat.to_dict(include_messages=True)), 200 # Usar to_dict e incluir mensagens

@app.route('/api/chat/<int:chat_id>/title', methods=['PUT'])
def update_chat_title(chat_id):
    chat = Chat.query.get(chat_id)
    if not chat:
        return jsonify({'error': 'Chat não encontrado'}), 404

    data = request.get_json()
    new_title = data.get('title')

    if not new_title or len(new_title.strip()) == 0:
        return jsonify({'error': 'Título não pode ser vazio'}), 400
    
    chat.title = new_title.strip()
    chat.last_accessed_at = datetime.now(timezone.utc)
    db.session.commit()
    return jsonify(chat.to_dict()), 200 # Retornar o chat atualizado com to_dict

@app.route('/api/chat/<int:chat_id>/message', methods=['POST'])
def send_message_to_chat(chat_id):
    if not model:
        return jsonify({'error': 'Modelo Gemini não configurado.'}), 503

    chat = Chat.query.get(chat_id)
    if not chat:
        return jsonify({'error': 'Chat não encontrado'}), 404

    data = request.get_json()
    user_message_content = data.get('message')

    if not user_message_content:
        return jsonify({'error': 'Mensagem é obrigatória'}), 400

    # Salvar a mensagem do usuário primeiro
    user_msg = Message(chat_id=chat.id, sender='user', content=user_message_content)
    db.session.add(user_msg)
    db.session.flush() # Para obter o ID da mensagem do usuário, se necessário antes do commit
    
    gemini_history = []
    
    # 1. Adicionar o prompt de cenário silencioso ao histórico do Gemini
    chat_config_for_prompt = {
        "universo": chat.universo, "universo_outro": chat.universo_outro,
        "genero": chat.genero, "genero_outro": chat.genero_outro,
        "nome_protagonista": chat.nome_protagonista,
        "nome_universo_jogo": chat.nome_universo_jogo,
        "nome_antagonista": chat.nome_antagonista,
        "inspiracao": chat.inspiracao,
        "age": chat.age # Adicionar idade ao prompt inicial
    }
    base_scenario_prompt = format_initial_prompt(chat_config_for_prompt)
    
    # Este é o prompt que configura o Gemini sobre o cenário, mas não é uma mensagem visível.
    gemini_history.append({"role": "user", "parts": [base_scenario_prompt]})
    # Adicionar uma resposta placeholder do modelo para o prompt de cenário.
    # Isso ajuda o Gemini a entender que o prompt de cenário foi processado.
    gemini_history.append({"role": "model", "parts": ["Entendido. Estou ciente do cenário e pronto para prosseguir com a aventura."]})

    # 2. Carregar todas as mensagens visíveis do banco (incluindo a primeira do Gemini e a atual do usuário)
    # Precisamos garantir que a mensagem do usuário recém-adicionada seja incluída.
    db_messages = Message.query.filter_by(chat_id=chat_id).order_by(Message.timestamp.asc()).all()

    for msg in db_messages:
        role = "user" if msg.sender == "user" else "model"
        gemini_history.append({"role": role, "parts": [msg.content]})
    
    # A mensagem atual do usuário já foi adicionada a db_messages antes desta query,
    # ou se não, precisa ser explicitamente adicionada ao gemini_history se db_messages for consultada antes do flush/commit.
    # A forma atual (user_msg adicionada ao BD, depois query db_messages) deve incluir a msg do usuário.

    try:
        # Iniciar a sessão de chat com o histórico construído
        # O histórico já contém a última mensagem do usuário.
        chat_session = model.start_chat(history=gemini_history[:-1] if len(gemini_history) > 1 else [])
        response = chat_session.send_message(gemini_history[-1]['parts']) # Envia a última mensagem (que é do usuário)
        
        gemini_response_content = response.text

    except Exception as e:
        db.session.rollback() # Reverter a adição da mensagem do usuário se o Gemini falhar
        return jsonify({'error': f'Erro ao comunicar com o Gemini: {str(e)}'}), 500

    gemini_msg = Message(chat_id=chat.id, sender='gemini', content=gemini_response_content)
    db.session.add(gemini_msg)

    # Lógica de mudança de status:
    # Se o chat estava 'new' e esta é a primeira mensagem *visível* do usuário,
    # (o que significa que ele respondeu à pergunta "Deseja iniciar..."), mude para 'started'.
    # Contamos as mensagens de usuário no BD *antes* da atual ser totalmente commitada,
    # mas como já fizemos add e flush, ela estará lá.
    
    # Para ter certeza, contamos as mensagens de usuário no `db_messages` que já foi carregado e inclui a atual.
    user_visible_messages_count = sum(1 for m in db_messages if m.sender == 'user')

    if chat.status == 'new' and user_visible_messages_count == 1:
        # Presumimos que a primeira mensagem do usuário é a confirmação para iniciar.
        # Poderíamos adicionar uma verificação do conteúdo da mensagem aqui se quiséssemos ser mais estritos.
        chat.status = 'started'
    
    chat.last_accessed_at = datetime.now(timezone.utc)
    db.session.commit()

    # Retornar apenas as novas mensagens e o status atualizado do chat
    return jsonify({
        'user_message': user_msg.to_dict(),
        'gemini_message': gemini_msg.to_dict(),
        'chat_status': chat.status # O status do chat pode ter mudado para 'started'
    }), 200

@app.route('/api/chat/<int:chat_id>/status', methods=['PUT'])
def update_chat_status(chat_id):
    chat = Chat.query.get(chat_id)
    if not chat:
        return jsonify({'error': 'Chat não encontrado'}), 404

    data = request.get_json()
    new_status = data.get('status')
    valid_statuses = ['new', 'started', 'finished', 'cancelled']

    if not new_status or new_status not in valid_statuses:
        return jsonify({'error': f'Status inválido. Válidos: {valid_statuses}'}), 400

    chat.status = new_status
    chat.last_accessed_at = datetime.now(timezone.utc)
    db.session.commit()
    return jsonify(chat.to_dict()), 200 # Retornar o chat atualizado com to_dict

@app.route('/api/chat/<int:chat_id>/observations', methods=['PUT'])
def update_chat_observations(chat_id):
    chat = Chat.query.get(chat_id)
    if not chat:
        return jsonify({'error': 'Chat não encontrado'}), 404

    data = request.get_json()
    new_observations = data.get('observations')
    # Observações podem ser string vazia para limpar
    if new_observations is None:
        return jsonify({'error': 'Observações são obrigatórias (mesmo que string vazia)'}), 400

    chat.observations = new_observations
    chat.last_accessed_at = datetime.now(timezone.utc)
    db.session.commit()
    return jsonify(chat.to_dict()), 200 # Retornar o chat atualizado com to_dict

# Rota para atualizar a cor de um chat
@app.route('/api/chat/<int:chat_id>/color', methods=['PUT'])
def update_chat_color(chat_id):
    chat = Chat.query.get(chat_id)
    if not chat:
        return jsonify({'error': 'Chat não encontrado'}), 404

    data = request.get_json()
    new_color = data.get('color') # Espera uma string hexadecimal, ex: "#RRGGBB"

    if not new_color or not isinstance(new_color, str) or not new_color.startswith('#') or len(new_color) != 7:
        try:
            # Tenta validar se o restante são caracteres hexadecimais válidos
            int(new_color[1:], 16)
        except ValueError:
            return jsonify({'error': 'Formato de cor inválido. Use #RRGGBB.'}), 400
        if len(new_color[1:]) != 6:
             return jsonify({'error': 'Formato de cor inválido. Use #RRGGBB.'}), 400

    chat.color = new_color
    chat.last_accessed_at = datetime.now(timezone.utc)
    db.session.commit()
    return jsonify(chat.to_dict()), 200

# Rota para deletar um chat
@app.route('/api/chat/<int:chat_id>', methods=['DELETE'])
def delete_chat(chat_id):
    # TODO: Adicionar verificação de propriedade do chat (o usuário logado é o dono do chat)
    # Por agora, vamos assumir que a verificação de user_id será feita no frontend ou em uma camada de autenticação mais robusta.
    chat = Chat.query.get(chat_id)
    if not chat:
        return jsonify({'error': 'Chat não encontrado'}), 404

    try:
        db.session.delete(chat)
        db.session.commit()
        return jsonify({'message': 'Chat deletado com sucesso'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Erro ao deletar chat: {str(e)}'}), 500

@app.route('/api/user/change-password', methods=['PUT'])
def change_password():
    data = request.get_json()
    user_id = data.get('user_id')
    current_password = data.get('current_password')
    new_password = data.get('new_password')

    if not all([user_id, current_password, new_password]):
        return jsonify({'error': 'Todos os campos são obrigatórios: user_id, current_password, new_password'}), 400

    try:
        user_id = int(user_id) # Garantir que user_id é um inteiro
    except ValueError:
        return jsonify({'error': 'user_id inválido'}), 400

    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'Usuário não encontrado'}), 404

    if not user.check_password(current_password):
        return jsonify({'error': 'Senha atual incorreta'}), 403

    if len(new_password) < 6:
         return jsonify({'error': 'Nova senha deve ter pelo menos 6 caracteres'}), 400
    
    if new_password == current_password:
        return jsonify({'error': 'Nova senha não pode ser igual à senha atual'}), 400

    user.set_password(new_password)
    db.session.commit()

    return jsonify({'message': 'Senha alterada com sucesso!'}), 200

# Nova rota para buscar a última idade usada
@app.route('/api/user/<int:user_id>/last_used_age', methods=['GET'])
def get_last_used_age(user_id):
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'Usuário não encontrado'}), 404

    last_chat_with_age = Chat.query.filter(
        Chat.user_id == user_id,
        Chat.age.isnot(None)
    ).order_by(Chat.created_at.desc()).first()

    if last_chat_with_age:
        return jsonify({'last_used_age': last_chat_with_age.age}), 200
    else:
        return jsonify({'last_used_age': None}), 200

if __name__ == '__main__':
    # Cria o banco de dados se não existir (para desenvolvimento)
    with app.app_context():
        db.create_all()
    app.run(debug=True, host='0.0.0.0') 