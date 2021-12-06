Перем _Лог;
Перем _ФайлДжсон;
Перем _ИспользоватьОтносительныеПути;
Перем _ТекущийРабочийКаталог;

Процедура ПриСозданииОбъекта(Знач пФайлДжсон, Знач пЛог, Знач пИспользоватьОтносительныеПути = Ложь)
	
	_ФайлДжсон = пФайлДжсон;
	_Лог       = пЛог;
	_ИспользоватьОтносительныеПути = пИспользоватьОтносительныеПути;
	_ТекущийРабочийКаталог = "";

	Если _ИспользоватьОтносительныеПути Тогда

		файл = Новый Файл(".");
		_ТекущийРабочийКаталог = файл.ПолноеИмя;

	КонецЕсли;

КонецПроцедуры

Процедура Записать(Знач пТаблицаРезультатовПроверки) Экспорт
	
	источникПроверки = ИсточникПроверки();
	
	ошибки              = Новый Массив;
	правила             = Новый Массив;
	существующиеПравила = Новый Соответствие;
	
	Для каждого цСтрока Из пТаблицаРезультатовПроверки Цикл
		
		структОшибка = Новый Структура;
		
		ruleId = ИдентификаторПравил(цСтрока);
		
		Если Не ЗначениеЗаполнено(ruleId) Тогда

			_Лог.Предупреждение("Пустой ruleId для %1", СообщениеОбОшибке(цСтрока));

		КонецЕсли;

		структОшибка.Вставить("engineId", источникПроверки);
		структОшибка.Вставить("ruleId", ruleId);
		структОшибка.Вставить("primaryLocation", МестонахождениеОшибки(цСтрока));
		структОшибка.Вставить("type", ТипОшибки(цСтрока));
		структОшибка.Вставить("severity", ВажностьОшибки(цСтрока));
		структОшибка.Вставить("effortMinutes", ЗатратыНаИсправление(цСтрока));
		структОшибка.Вставить("secondaryLocations", ВторостепенноеМестонахождение(цСтрока));
		
		ошибки.Добавить(структОшибка);
		
		Если существующиеПравила[ruleId] = Истина Тогда
			
			Продолжить;
			
		КонецЕсли;
		
		структПравила = Новый Структура;
		
		структПравила.Вставить("engineId", источникПроверки);
		структПравила.Вставить("ruleId", ruleId);
		структПравила.Вставить("name", ruleId);
		структПравила.Вставить("type", структОшибка.type);
		структПравила.Вставить("severity", структОшибка.severity);
		структПравила.Вставить("description", структОшибка.primaryLocation.message);
		
		правила.Добавить(структПравила);
		
		существующиеПравила.Вставить(ruleId, Истина);
		
	КонецЦикла;
	
	структ = Новый Структура("issues,rules", ошибки, правила);
	
	_Лог.Информация("Подготовлено к записи в джсон ошибок: %1, правил: %2", структ.issues.Количество(), структ.rules.Количество());
	
	ЗаписатьФайлJSON(структ);
	
КонецПроцедуры

Функция ИсточникПроверки()
	
	Возврат "edt";
	
КонецФункции

Функция ИдентификаторПравил(Знач пДанные)
	
	Если ЗначениеЗаполнено(пДанные.Правило) Тогда
		
		Возврат пДанные.Правило;
	
	КонецЕсли;
	
	текстОшибки = пДанные.Описание;
	
	// Контекст ошибки всегда в конце, просто обрежем все, что после [
	
	начало = СтрНайти(текстОшибки, "[");
	
	Если начало > 0 Тогда
		
		текстОшибки = Лев(текстОшибки, начало - 1);
		
	КонецЕсли;
	
	текстОшибки = ЗаменитьТекстВКавычках(текстОшибки, """", "%1");
	текстОшибки = ЗаменитьТекстВКавычках(текстОшибки, "'", "%1");
	
	// Пояснение к ошибке нам не нужно
	
	начало = СтрНайти(текстОшибки, ":", НаправлениеПоиска.СКонца);
	
	Если начало > 0 Тогда
		
		текстОшибки = СокрЛП(Лев(текстОшибки, начало - 1));
		
	КонецЕсли;
	
	// Сонар не любит запятые в тексте правил
	текстОшибки = СтрЗаменить(текстОшибки, ",", "_");
	
	Возврат СокрЛП(текстОшибки);
	
КонецФункции

Функция ЗаменитьТекстВКавычках(Знач пСтрока, Знач пКавычка = """", Знач пТекстЗамены = "")
	
	ПозицияКавычки = СтрНайти(пСтрока, пКавычка);
	
	Пока ПозицияКавычки > 0 Цикл
		
		ПозицияЗакрывающейКавычки = СтрНайти(Сред(пСтрока, ПозицияКавычки + 1), пКавычка) + ПозицияКавычки;
		
		Если ПозицияЗакрывающейКавычки = 0 Тогда
			
			Прервать;
			
		КонецЕсли;
		
		пСтрока        = Лев(пСтрока, ПозицияКавычки - 1) + пТекстЗамены + Сред(пСтрока, ПозицияЗакрывающейКавычки + 1);
		ПозицияКавычки = СтрНайти(пСтрока, пКавычка);
		
	КонецЦикла;
	
	Возврат пСтрока;
	
КонецФункции

Функция МестонахождениеОшибки(Знач пДанные)
	
	структ = Новый Структура;
	
	структ.Вставить("message", СообщениеОбОшибке(пДанные));
	структ.Вставить("filePath", ПутьКФайлу(пДанные));
	структ.Вставить("textRange", КоординатыОшибки(пДанные));
	
	Возврат структ;
	
КонецФункции

Функция СообщениеОбОшибке(Знач пДанные)
	
	Возврат пДанные.Описание;
	
КонецФункции

Функция ПутьКФайлу(Знач пДанные)
	
	путь = пДанные.Путь;

	разделительПути = ПолучитьРазделительПути();

	путь = СтрЗаменить(путь, _ТекущийРабочийКаталог, "." + разделительПути);

	путь = СтрЗаменить(путь, "\", разделительПути);
	путь = СтрЗаменить(путь, "/", разделительПути);

	Возврат путь;
	
КонецФункции

Функция КоординатыОшибки(Знач пДанные)
	
	структ = Новый Структура;
	МинВалиднаяПозиция = 1;
	
	Попытка
		Позиция = Число(пДанные.НомерСтроки);
		структ.Вставить("startLine", ?(Позиция = 0, МинВалиднаяПозиция, Позиция)); // для сонара 0 невалидная строка
	Исключение
		_Лог.Ошибка("Не удалось преобразовать к числу номер строки: " + пДанные.НомерСтроки);
		структ.Вставить("startLine", МинВалиднаяПозиция);
	КонецПопытки;
	
	Возврат структ;
	
КонецФункции

Функция ТипОшибки(Знач пДанные)
	
	// BUG, VULNERABILITY, CODE_SMELL
	
	Если пДанные.Тип = "Ошибка"
		ИЛИ пДанные.Тип = "Ошибка конфигурации" Тогда
		
		Возврат "BUG";
		
	Иначе
		
		Возврат "CODE_SMELL";
		
	КонецЕсли;
	
КонецФункции

Функция ВажностьОшибки(Знач пДанные)
	
	// BLOCKER, CRITICAL, MAJOR, MINOR, INFO
	
	Если пДанные.Тип = "Ошибка"
			ИЛИ пДанные.Тип = "Ошибка конфигурации" Тогда
		
		Возврат "CRITICAL";

	ИначеЕсли пДанные.Серьезность = "Предупреждение" Тогда
		
		Возврат "MINOR";

	Иначе
		
		Возврат "MINOR";
		
	КонецЕсли;
	
КонецФункции

Функция ЗатратыНаИсправление(Знач пДанные)
	
	Возврат 0;
	
КонецФункции

Функция ВторостепенноеМестонахождение(Знач пДанные)
	
	Возврат Новый Массив;
	
КонецФункции

Процедура ЗаписатьФайлJSON(Знач пЗначение)
	
	ОбщегоНазначения.ЗаписатьJSONВФайл(пЗначение, _ФайлДжсон, _Лог);
	
КонецПроцедуры