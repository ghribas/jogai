import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatConfigForm extends StatefulWidget {
  final Function(Map<String, String?>) onSubmit;
  final int? initialAge;

  const ChatConfigForm({
    Key? key, 
    required this.onSubmit, 
    this.initialAge
  }) : super(key: key);

  @override
  State<ChatConfigForm> createState() => _ChatConfigFormState();
}

class _ChatConfigFormState extends State<ChatConfigForm> {
  final _formKey = GlobalKey<FormState>();

  // Universo
  String? _selectedUniverso;
  final TextEditingController _universoOutroController = TextEditingController();
  final List<String> _universoOptions = ['Ficção científica', 'Fantasia', 'Medieval', 'Tempos atuais', 'Cyberpunk', 'Outro'];

  // Gênero
  String? _selectedGenero;
  final TextEditingController _generoOutroController = TextEditingController();
  final List<String> _generoOptions = ['Aventura', 'Crime e investigação', 'Suspense', 'Terror', 'Comédia', 'Drama', 'Romance', 'Outro'];

  final TextEditingController _nomeProtagonistaController = TextEditingController();
  final TextEditingController _nomeUniversoJogoController = TextEditingController();
  final TextEditingController _nomeAntagonistaController = TextEditingController();
  final TextEditingController _inspiracaoController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  bool _showUniversoOutro = false;
  bool _showGeneroOutro = false;
  bool _showAdditionalDetails = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAge != null) {
      _ageController.text = widget.initialAge.toString();
    }
    _universoOutroController.addListener(() {
      setState(() {});
    });
    _generoOutroController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _universoOutroController.dispose();
    _generoOutroController.dispose();
    _nomeProtagonistaController.dispose();
    _nomeUniversoJogoController.dispose();
    _nomeAntagonistaController.dispose();
    _inspiracaoController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      Map<String, String?> configData = {
        'universo': _selectedUniverso == 'Outro' ? _universoOutroController.text : _selectedUniverso,
        'universo_outro': _selectedUniverso == 'Outro' ? _universoOutroController.text : null,
        'genero': _selectedGenero == 'Outro' ? _generoOutroController.text : _selectedGenero,
        'genero_outro': _selectedGenero == 'Outro' ? _generoOutroController.text : null,
        'nome_protagonista': _nomeProtagonistaController.text.isNotEmpty ? _nomeProtagonistaController.text : null,
        'nome_universo_jogo': _nomeUniversoJogoController.text.isNotEmpty ? _nomeUniversoJogoController.text : null,
        'nome_antagonista': _nomeAntagonistaController.text.isNotEmpty ? _nomeAntagonistaController.text : null,
        'inspiracao': _inspiracaoController.text.isNotEmpty ? _inspiracaoController.text : null,
        'age': _ageController.text.isNotEmpty ? _ageController.text : null,
      };
      
      if (_selectedUniverso != 'Outro') {
          configData['universo_outro'] = null;
      } else {
          configData['universo'] = _universoOutroController.text;
      }

      if (_selectedGenero != 'Outro') {
          configData['genero_outro'] = null;
      } else {
          configData['genero'] = _generoOutroController.text;
      }

      widget.onSubmit(configData);
    }
  }
  
  Widget _buildAdditionalDetailsSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool useTwoColumns = screenWidth > 600;

    Widget protagonistaField = TextFormField(
      controller: _nomeProtagonistaController,
      decoration: const InputDecoration(labelText: 'Nome do Protagonista'),
    );
    Widget universoJogoField = TextFormField(
      controller: _nomeUniversoJogoController,
      decoration: const InputDecoration(labelText: 'Nome do Universo/Jogo'),
    );
    Widget antagonistaField = TextFormField(
      controller: _nomeAntagonistaController,
      decoration: const InputDecoration(labelText: 'Nome do Antagonista'),
    );
    Widget inspiracaoField = TextFormField(
      controller: _inspiracaoController,
      decoration: const InputDecoration(labelText: 'Inspiração (livros, etc.)'),
      maxLines: 2,
    );

    if (useTwoColumns) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: protagonistaField),
              const SizedBox(width: 16),
              Expanded(child: universoJogoField),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: antagonistaField),
              const SizedBox(width: 16),
              Expanded(child: inspiracaoField),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          protagonistaField,
          const SizedBox(height: 8),
          universoJogoField,
          const SizedBox(height: 8),
          antagonistaField,
          const SizedBox(height: 8),
          inspiracaoField,
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Universo
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Universo Principal *'),
                value: _selectedUniverso,
                items: _universoOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedUniverso = newValue;
                    _showUniversoOutro = newValue == 'Outro';
                    if (!_showUniversoOutro) {
                      _universoOutroController.clear();
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione um universo.';
                  }
                  if (value == 'Outro' && _universoOutroController.text.trim().isEmpty) {
                    return 'Por favor, especifique o universo.';
                  }
                  return null;
                },
              ),
              if (_showUniversoOutro)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                  child: TextFormField(
                    controller: _universoOutroController,
                    decoration: const InputDecoration(labelText: 'Especifique o Universo *'),
                    validator: (value) {
                      if (_showUniversoOutro && (value == null || value.trim().isEmpty)) {
                        return 'Por favor, especifique o universo.';
                      }
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 16),

              // Gênero
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Gênero Principal *'),
                value: _selectedGenero,
                items: _generoOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGenero = newValue;
                    _showGeneroOutro = newValue == 'Outro';
                    if (!_showGeneroOutro) {
                      _generoOutroController.clear();
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione um gênero.';
                  }
                  if (value == 'Outro' && _generoOutroController.text.trim().isEmpty) {
                    return 'Por favor, especifique o gênero.';
                  }
                  return null;
                },
              ),
              if (_showGeneroOutro)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                  child: TextFormField(
                    controller: _generoOutroController,
                    decoration: const InputDecoration(labelText: 'Especifique o Gênero *'),
                    validator: (value) {
                      if (_showGeneroOutro && (value == null || value.trim().isEmpty)) {
                        return 'Por favor, especifique o gênero.';
                      }
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 16),

              // Idade do Jogador
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Idade do Jogador *'),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe a idade do jogador.';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 4 || age > 150) {
                    return 'A idade deve ser um número entre 4 e 150.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Seção de Detalhes Adicionais Recolhível
              InkWell(
                onTap: () {
                  setState(() {
                    _showAdditionalDetails = !_showAdditionalDetails;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Text(
                        'Detalhes Adicionais ',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.secondary),
                      ),
                      Icon(
                        _showAdditionalDetails ? Icons.remove_circle_outline : Icons.add_circle_outline,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SizeTransition(sizeFactor: animation, child: child);
                },
                child: _showAdditionalDetails
                    ? Container(
                        key: const ValueKey('additional_details_expanded'),
                        margin: const EdgeInsets.only(top: 8.0, bottom:16.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: _buildAdditionalDetailsSection(context),
                      )
                    : const SizedBox.shrink(key: ValueKey('additional_details_collapsed')),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Criar Chat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 