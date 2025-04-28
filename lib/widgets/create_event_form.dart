import 'package:flutter/material.dart';

class CreateEventForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onCreate;

  const CreateEventForm({Key? key, required this.onCreate}) : super(key: key);

  @override
  _CreateEventFormState createState() => _CreateEventFormState();
}

class _CreateEventFormState extends State<CreateEventForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _eventData = {
    'title': '',
    'type': '',
    'date': '',
    'location': '',
    'participants': '',
  };

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onCreate(_eventData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Nombre del evento'),
            onSaved: (value) => _eventData['title'] = value!,
            validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Tipo de evento'),
            onSaved: (value) => _eventData['type'] = value!,
            validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Fecha (AAAA-MM-DD HH:MM)'),
            onSaved: (value) => _eventData['date'] = value!,
            validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Lugar'),
            onSaved: (value) => _eventData['location'] = value!,
            validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Número de participantes'),
            keyboardType: TextInputType.number,
            onSaved: (value) => _eventData['participants'] = int.tryParse(value!) ?? 0,
            validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submit,
            child: Text('Crear evento'),
          )
        ],
      ),
    );
  }
}