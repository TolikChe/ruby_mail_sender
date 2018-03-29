#coding: utf-8

require 'rubygems'
require 'mail'
require 'nokogiri'

$params_file = 'params.xml'


#
# Работает с файлами в кодировке UTF-8 (так проверялось)
# 
# Все параметры хранятся в файле $params_file. Это лобальная переменная. В ней задается имя файла с параметрами.
# Файл с параметрами имеет следующую структуру: 
#	<params>
#		<sender_params>
#			<address>Адрес_почтового_ящика_с_которого_отправляем_письма</address>
#			<login>Логин(обычно_то_что_стоит_перед_@)</login>
#			<password>Пароль_от_почтового_ящика</password>
#			<domain>Почтовый_домен(mail.ru)</domain>
#			<smtp_host>Сервер_SMTP</smtp_host>
#			<smtp_port>Порт сервера SMTP</smtp_port>
#		</sender_params>
#		<receiver_address_list_file>Файл_со_списком_адресов_по_которым_выполняется_рассылка</receiver_address_list_file>
#		<message_params>
#			<topic>Тема_письма</topic>
#			<encoding>Кодировка_письма</encoding>
#			<attachment_list>
#				<attachment>Файл_для_аттачмента</attachment>
#				<attachment>Файл_для_аттачмента</attachment>
#			</attachment_list>
#			<message_file>Файл_с_текстом_письма</message_file>
#		</message_params>
#	</params>
# Класс Params вычитывает параметры в переменную xml
# Класс Reciver содержит параметры отправителя
# Класс Sender содержит параметры получателя (список адресов рассылки)
# Класс Message содержит параметры сообщения
#
# Алгоритм работы: считываем параметры в переменную класса Params
#                  распределяем параметры по переменным классов Reciver, Sender, Message
#                  вызываем процедуру sending_mail которая отправляет письма с заданными параметрами
#
# ----------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------
#
#
# Класс c XML с параметрами
# Описание: Хранит xml с параметрами. Читает его из файла
class Params
	attr_accessor :xml_doc   # xml с параметрами
	#
	# Конструктор
	# Описание: Считывает в xml параметры из файла $params_file
	# Входные параметры: нет
	# Исключения: В случае если файла с параметрами нет, то бросается исключение
	def initialize
		if File.exist?($params_file) then
			# откроем файл
			_f = File.open($params_file,"r")
			@xml_doc = Nokogiri::XML(_f)
			_f.close
		else
			raise 'Файл c параметрами' + $params_file + ' не найден'
		end
	end
end
#
#
# Класс с параметрами получателя
# Описание: Хранит параметры получателя. 
# 			При инициализации из файла $params_file вытаскиваются параметры получателя
class Reciver
	attr_accessor :addresses   # массив адресов получателя
	
	#
	# Конструктор
	# Описание: Заполняет параметры получателя из файла $params_file
	#           Читает из файла $params_file параметр <receiver_address_list_file>. В файле из параметра 
	#           лежит список адресов для рассылки. Одна строка - один адрес
	# Входные параметры: нет
	# Исключения: В случае если файла с параметрами нет, то бросается исключение
	#             В случае если файла с адресами нет, то бросается исключение
	#             В случае если список адресов пуст то бросается исключение
	def initialize
		# Читаем параметры из файла с параметрами
		_params = Params.new
		# вытащим из прочитанных параметров нужные значения
		_address_file = _params.xml_doc.at_xpath('//receiver_address_list_file').text
		# пробуем открыть файл, указанный в параметрах
		if File.exist?(_address_file) then
			# считаем строки в массив
			@addresses = File.readlines(_address_file)
			# выкинем строки которые вряд ли адреса почты
			@addresses.each {|x| if x.match(/\w+@\w+(.)\w+/) == nil then @addresses.delete(x) else x.chomp! end}
		else
			raise 'Файл c адресами ' + _address_file + ' не найден'
		end
		
		# если список пустой то надо бросить исключение
		if @addresses.count == 0 then
			raise 'Файл c адресами ' + _address_file + ' пустой'
		end
	end
	
	#
	# Функция to_s
	# Описание: Выводит содержимое всех полей класса 
	def to_s
		@addresses.each {|x| puts x}
	end
	
end

#
#
# Класс с параметрами отправителя 
# Описание: Хранит параметры отправителя. 
# 			При инициализации из файла $params_file вытаскиваются параметры отправителя  
class Sender
	attr_accessor :address          # почтовый адрес            Вася@mail.ru
	attr_accessor :login            # логин                     Вася 
	attr_accessor :password         # пароль 
	attr_accessor :domain           # домен почтового сервиса   mail.ru 
	attr_accessor :smtp_host        # хост сервера отправления почты smtp.list.ru
	attr_accessor :smtp_port        # Порт сервера отправления почты 587 
	
	#
	# Конструктор
	# Описание: Заполняет параметры отправителя из файла $params_file
	# Входные параметры: нет
	# Исключения: В случае если файла с параметрами нет, то бросается исключение
	def initialize
		# Читаем параметры из файла с параметрами
		_params = Params.new
		# вытащим из прочитанного нужные значения
		@address = _params.xml_doc.at_xpath('//address').text
		@login = _params.xml_doc.at_xpath('//login').text
		@password = _params.xml_doc.at_xpath('//password').text
		@domain = _params.xml_doc.at_xpath('//domain').text
		@smtp_host = _params.xml_doc.at_xpath('//smtp_host').text
		@smtp_port = _params.xml_doc.at_xpath('//smtp_port').text
	end
	#
	# Функция to_s
	# Описание: Выводит содержимое всех полей класса 
	def to_s
		puts @address
		puts @login
		puts @password
		puts @domain
		puts @smtp_host
		puts @smtp_port
	end
end

#
#
# Класс с параметрами сообщения
# Описание: Хранит параметры сообщения. 
#           При инициализации из файла $params_file вытаскиваются параметры сообщения
class Message
	attr_accessor :topic          # тема письма
	attr_accessor :body_file      # файл, содержащий тело письма
	attr_accessor :attach_files   # массив файлов - аттачментов
	attr_accessor :encoding       # кодировка письма
	
	#
	# Конструктор
	# Описание: Заполняет параметры сообщения из файла $params_file
	# Входные параметры: нет
	# Исключения: В случае если файла с параметрами нет, то бросается исключение
	# 			  В случае если файла с текстом сообщения нет, то бросается исключение	
	def initialize
	
		# Читаем параметры из файла с параметрами
		_params = Params.new
		# вытащим из прочитанного нужные значения
		@topic = _params.xml_doc.at_xpath('//topic').text
		@body_file = _params.xml_doc.at_xpath('//message_file').text
		if not File.exist?(@body_file) then raise 'Файла '+ @body_file + ' не найдено' end
		@attach_files = _params.xml_doc.xpath('//attachment/text()')
		@attach_files.each {|x| if not File.exist?(x) then raise 'Файла для аттачмента '+ x + ' не найдено' end}
		@encoding = _params.xml_doc.at_xpath('//encoding').text
	end
	#
	# Функция to_s
	# Описание: Выводит содержимое всех полей класса 
	def to_s
		puts @topic
		puts @body_file
		@attach_files.each {|x| puts x}
		puts @encoding
	end
end

#
# Функция отправляет от лица sender по алресам reciver сообщение message

def sending_mail _sender, _reciver, _message
	# инициализируем структуру с параметрами отправки
	options = { :address              => _sender.smtp_host,
				:port                 => _sender.smtp_port,
				:domain               => _sender.domain,
				:user_name            => _sender.login,
				:password             => _sender.password,
				:authentication       => 'plain',
				:enable_starttls_auto => true  }

	# задаем параметры отправки
	 Mail.defaults do
	  delivery_method :smtp, options
	end

	#
	# для каждого адреса в списке пытаемся отправить письмо
	_reciver.addresses.each {|x| 
	begin
		puts x
		mail = Mail.new
		mail.from = _sender.address
		mail.to = x
		mail.body = File.read(_message.body_file)
		mail.subject = _message.topic
		mail.charset = _message.encoding
		puts mail.to_s
		mail.deliver!
		puts '-------------------'
	rescue => err
		puts err	
	end
	}

end

##
##
## Получаем параметры из файла и отправляем почту
##
begin
	sender = Sender.new
	puts sender.to_s
	puts '-------'
	message = Message.new
	puts message.to_s
	puts '-------'	
	reciver = Reciver.new
	reciver.addresses.each {|x| puts 'yy ' + x}
	#puts reciver.to_s
	puts '-------'	
	puts '-------'		
	puts 'Начинаем рассылку'	
	sending_mail sender, reciver, message
rescue => err
	puts err
end
