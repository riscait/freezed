import 'package:analyzer/dart/ast/ast.dart';
import 'package:freezed/src/freezed_generator.dart' show FreezedField;
import 'package:freezed/src/models.dart';
import 'package:freezed/src/templates/prototypes.dart';

import '../templates/properties.dart';

sealed class GeneratorBacklog {
  void run(StringBuffer buffer);
}

class UserDefinedClassMixin implements GeneratorBacklog {
  UserDefinedClassMixin({
    required this.typeParameters,
    required this.annotatedClassName,
    required this.mixinName,
    required this.fields,
    required this.unionCases,
    required this.mapConfigs,
    required this.whenConfigs,
  });

  final TypeParameterList? typeParameters;
  final String annotatedClassName;
  final String mixinName;
  final List<FreezedField> fields;
  final List<UnionCaseMeta> unionCases;
  final MapConfig mapConfigs;
  final WhenConfig whenConfigs;

  late final generics = typeParameters?.typeParameters
          .map((e) => e.name.lexeme)
          .toList(growable: false) ??
      const <String>[];

  @override
  void run(StringBuffer buffer) {
    // TODO common properties
    // TODO add when
    // TODO add map
    // TODO add toJson
    // TODO add copyWith

    buffer.write('''
/// The mixin for [$annotatedClassName].
mixin $mixinName${typeParameters ?? ''} {
''');

    _writeProperties(buffer);
    _writePatterns(buffer);

    buffer.writeln('}');
  }

  void _writeProperties(StringBuffer buffer) {
    for (final parameter in fields) {
      buffer.writeln(
        '  ${parameter.typeSource} get ${parameter.name} => throw UnimplementedError();',
      );
    }
  }

  void _writePatterns(StringBuffer buffer) {
    if (whenConfigs.when) {
      whenPrototype(buffer, unionCases);
      buffer.writeln('=> throw $privConstUsedErrorVarName;');
    }
    if (whenConfigs.whenOrNull) {
      whenOrNullPrototype(buffer, unionCases);
      buffer.writeln('=> throw $privConstUsedErrorVarName;');
    }
    if (whenConfigs.maybeWhen) {
      maybeWhenPrototype(buffer, unionCases);
      buffer.writeln('=> throw $privConstUsedErrorVarName;');
    }
    if (mapConfigs.map) {
      mapPrototype(buffer, unionCases, generics);
      buffer.writeln('=> throw $privConstUsedErrorVarName;');
    }
    if (mapConfigs.mapOrNull) {
      mapOrNullPrototype(buffer, unionCases, generics);
      buffer.writeln('=> throw $privConstUsedErrorVarName;');
    }
    if (mapConfigs.maybeMap) {
      maybeMapPrototype(buffer, unionCases, generics);
      buffer.writeln('=> throw $privConstUsedErrorVarName;');
    }
  }
}

class GeneratedFreezedClass implements GeneratorBacklog {
  GeneratedFreezedClass({
    required this.name,
    required this.redirectedName,
    required this.unionCases,
    required this.typeParameters,
    required this.hasConstConstructor,
    required this.mixins,
    required this.implementList,
    required this.extendClause,
    required this.fields,
    required this.mapConfigs,
    required this.whenConfigs,
  });

  final String name;
  final String? redirectedName;
  final List<UnionCaseMeta> unionCases;
  final bool hasConstConstructor;
  final TypeParameterList? typeParameters;
  final List<String> mixins;
  final List<String> implementList;
  final String? extendClause;
  final List<FreezedField> fields;
  final MapConfig mapConfigs;
  final WhenConfig whenConfigs;

  late final generics = typeParameters?.typeParameters
          .map((e) => e.name.lexeme)
          .toList(growable: false) ??
      const <String>[];

  @override
  void run(StringBuffer buffer) {
    // TODO common properties
    // TODO add when
    // TODO add map
    // TODO add toJson
    // TODO add copyWith

    _writeDocs(buffer);
    _writeClassPrototype(buffer);
    _writeProperties(buffer);
    _writeEqual(buffer);
    _writeHashCode(buffer);
    _writeToString(buffer);
    _writePatterns(buffer);

    buffer.writeln('}');
  }

  void _writeClassPrototype(StringBuffer buffer) {
    buffer.write('class $name ');

    if (typeParameters != null) buffer.write(typeParameters);

    buffer
      ..writeClassPrototype(
        extend: extendClause,
        implements: implementList,
        withs: mixins,
      )
      ..writeln(' {');

    _writeConstructor(buffer);
  }

  void _writeConstructor(StringBuffer buffer) {
    buffer.write('  ');
    if (hasConstConstructor) {
      buffer.writeln('const ');
    }

    buffer
      ..write(name)
      ..writeArguments(
        optionalNamed: fields
            .where((e) => e.isOptional && e.isNamed)
            .map((e) => ('this.${e.name}', defaultValue: e.defaultValueSource)),
        requiredNamed: fields
            .where((e) => e.isRequired && e.isNamed)
            .map((e) => ('this.${e.name}', defaultValue: e.defaultValueSource)),
        optionalPositionals: fields
            .where((e) => e.isOptional && e.isPositional)
            .map((e) => ('this.${e.name}', defaultValue: e.defaultValueSource)),
        requiredPositionals: fields
            .where((e) => e.isRequired && e.isPositional)
            .map((e) => ('this.${e.name}', defaultValue: e.defaultValueSource)),
      );

    if (extendClause != null) {
      buffer.write(' : super._()');
    }

    buffer.writeln(';');
  }

  void _writeProperties(StringBuffer buffer) {
    for (final parameter in fields) {
      buffer.writeln('  final ${parameter.typeSource} ${parameter.name};');
    }
  }

  void _writePatterns(StringBuffer buffer) {
    _when(buffer);
    _whenOrNull(buffer);
    _maybeWhen(buffer);

    _map(buffer);
    _maybeMap(buffer);
    _mapOrNull(buffer);
  }

  void _maybeWhen(StringBuffer buffer) {
    if (!whenConfigs.maybeWhen) return;

    var callbackParameters = fields.map((e) {
      //  TODO refactor logic between all the callbacks
      if (unionCases.any((c) => c.name == e.name)) {
        return 'this.${e.name}';
      }
      return e.name;
    }).join(',');

    buffer.writeln('@override');
    maybeWhenPrototype(buffer, unionCases);
    buffer.write(''' {
  if (${constructorNameToCallbackName(redirectedName)} != null) {
    return ${constructorNameToCallbackName(redirectedName)}($callbackParameters);
  }
  return orElse();
}''');
  }

  void _when(StringBuffer buffer) {
    if (!whenConfigs.when) return;

    var callbackParameters = fields.map((e) {
      if (unionCases.any((c) => c.name == e.name)) {
        return 'this.${e.name}';
      }
      return e.name;
    }).join(',');

    buffer.writeln('@override');
    whenPrototype(buffer, unionCases);
    buffer.write(''' {
  return ${constructorNameToCallbackName(redirectedName)}($callbackParameters);
}''');
  }

  void _whenOrNull(StringBuffer buffer) {
    if (!whenConfigs.whenOrNull) return;

    var callbackParameters = fields.map((e) {
      if (unionCases.any((c) => c.name == e.name)) {
        return 'this.${e.name}';
      }
      return e.name;
    }).join(',');

    buffer.writeln('@override');
    whenOrNullPrototype(buffer, unionCases);
    buffer.write(''' {
  return ${constructorNameToCallbackName(redirectedName)}?.call($callbackParameters);
}''');
  }

  void _maybeMap(StringBuffer buffer) {
    if (!mapConfigs.maybeMap) return;

    buffer.writeln('@override');
    maybeMapPrototype(buffer, unionCases, generics);

    buffer.write(''' {
  if (${constructorNameToCallbackName(redirectedName)} != null) {
    return ${constructorNameToCallbackName(redirectedName)}(this);
  }
  return orElse();
}''');
  }

  void _map(StringBuffer buffer) {
    if (!mapConfigs.map) return;

    buffer.writeln('@override');
    mapPrototype(buffer, unionCases, generics);

    buffer.write(''' {
  return ${constructorNameToCallbackName(redirectedName)}(this);
}''');
  }

  void _mapOrNull(StringBuffer buffer) {
    if (!mapConfigs.mapOrNull) return;

    buffer.writeln('@override');
    mapOrNullPrototype(buffer, unionCases, generics);

    buffer.write(''' {
  return ${constructorNameToCallbackName(redirectedName)}?.call(this);
}''');
  }

  void _writeEqual(StringBuffer buffer) {
    // TODO handle disabling ==

    final generics = StringBuffer()
      ..writeGenericUsage(
        typeParameters?.typeParameters.map((e) => e.name.lexeme) ?? const [],
      );

    final comparisons = [
      'other.runtimeType == runtimeType',
      'other is $name$generics',
      ...fields.map((field) {
        var name = field.name;
        // if (p.isPossiblyDartCollection) {
        //   if (data.makeCollectionsImmutable &&
        //       (p.isDartList || p.isDartMap || p.isDartSet)) {
        //     name = '_$name';
        //   }
        // }
        final target = field.name == 'other' ? 'this.' : '';

        // if (p.isPossiblyDartCollection) {
        // TODO optimize DeepCollectionEquality away when possible
        // no need to check `identical` as `DeepCollectionEquality` already does it
        return 'const DeepCollectionEquality().equals(other.$name, $target$name)';
        // }
        // return '(identical(other.${p.name}, $target$name) || other.$name == $target$name)';
      }),
    ];

    buffer.write('''
@override
bool operator ==(dynamic other) {
  return identical(this, other) || (${comparisons.join('&&')});
}
''');
  }

  void _writeHashCode(StringBuffer buffer) {
    // TODO Add an annotation parameter to enable hashCode without ==
    // TODO handle disabling hashCode

    // TODO add JsonKey(ignore: true)

    final hashedProperties = [
      /// TODO: can we omit "runtimeType" for non-generic sealed classes?
      'runtimeType',
      for (final field in fields)
        // TODO optimize DeepCollectionEquality away when possible
        // if (property.isPossiblyDartCollection)
        // if (data.makeCollectionsImmutable &&
        //     (property.isDartList || property.isDartMap || property.isDartSet))
        //   'const DeepCollectionEquality().hash(_${property.name})'
        // else
        'const DeepCollectionEquality().hash(${field.name})'
      // else
      // property.name,
    ];

    buffer.write(
      switch (hashedProperties.length) {
        1 => '''
@override
int get hashCode => ${hashedProperties.first}.hashCode;
''',
        >= 20 => '''
@override
int get hashCode => Object.hashAll([${hashedProperties.join(',')}]);
''',
        _ => '''
@override
int get hashCode => Object.hash(${hashedProperties.join(',')});
''',
      },
    );
  }

  void _writeToString(StringBuffer buffer) {
    // TODO handle disabling toString
    // TODO support diagnostics

    // final parameters = globalData.hasDiagnostics
    //     ? '{ DiagnosticLevel minLevel = DiagnosticLevel.info }'
    //     : '';

    final properties = [
      for (final field in fields)
        '${field.name.replaceAll(r'$', r'\$')}: ${wrapClassField(field.name)}',
    ];

    buffer.write('''
@override
String toString() {
  const runtimeType = r'$name';
  return '\$runtimeType(${properties.join(', ')})';
}
''');
  }

  void _writeDocs(StringBuffer buffer) {
    // TODO
  }
}