function Body()																																												-- основные вычисления
	if (Timer>0) then
		Timer = Timer - 1
		PutErrorToTable(ErrorStr, Problem)																																			-- сообщение об ошибке и подсветка соответствующей строки
		return
	end
	local ServerTime = getInfoParam("SERVERTIME")																														-- получаем время сервера
	if (IsWindowClosed(TableId)) then																																				-- если таблица робота закрыта, открываем ее заново
		PutDataToTableInit()
	end
	if (ServerTime == nil or ServerTime == "") then
		Problem = "Время сервера не получено!"
		Timer = 3
		ErrorStr = 1
		return
	else
		Problem = ""
		ErrorStr = 0
	end
	SetCell(TableId,1,2,ServerTime)																																					-- заполняем таблицу данными
	SetCell(TableId,1,3,Problem)
	local SessionStatus = tonumber(getParamEx(Class, Emit, "STATUS").param_value)																		-- получаем статус торговой сессии из таблицы "текущие торги"
	if (SessionStatus ~= 1) then
		Problem = "Сессия закрыта!"
		Timer = 3
		ErrorStr = 2
		return
	else
		Problem = ""
		ErrorStr = 0
	end
	SetCell(TableId,2,2,"Сессия открыта")																																		-- заполняем таблицу данными
	SetCell(TableId,2,3,Problem)
	if (Class == nil or Class == "") then
		Problem = "Класс не определен!"
		Timer = 3
		ErrorStr = 3
		return
	else
		Problem = ""
		ErrorStr = 0
	end
	SetCell(TableId,3,2,Class)																																								-- заполняем таблицу данными
	SetCell(TableId,3,3,Problem)
	if (Emit == nil or Emit == "") then
		Problem = "Инструмент не определен!"
		Timer = 3
		ErrorStr = 4
		return
	else
		Problem = ""
		ErrorStr = 0
	end
	SetCell(TableId,4,2,Emit)																																								-- заполняем таблицу данными
	SetCell(TableId,4,3,Problem)
	if (MyAccount == nil or MyAccount == "") then
		Problem = "Счет не определен!"
		Timer = 3
		ErrorStr = 5
		return
	else
		Problem = ""
		ErrorStr = 0
	end
	SetCell(TableId,5,2,MyAccount)																																					-- заполняем таблицу данными
	SetCell(TableId,5,3,Problem)
	local TransCount = 0
	local PosNow = PosNowFunc(Emit, MyAccount)																															-- находим текущую позицию по инструменту
	if (PosNow == 0 or (PosNow~=0 and SignFunc(PosNow) ~= SignFunc(PosPrev))) then																-- если произошел переворот позиции или ее закрытие, то нужно убрать профит, чтобы он не сработал (помнить прошлую позицию)
		TransCount = TransCount + DeleteAllProfits(MyAccount, Emit, Class, "Удаление тейк-профита при перевороте или нулевой позиции ")
	end
	local Signal = SignalCheck()																																							-- получаем сигнал с графика и проверяем был переворот или нет
	if (TradeType == "LONG") then
		Signal = math.max(Signal,0)
	elseif (TradeType == "SHORT") then
		Signal = math.min(Signal,0)
	end
	if (math.abs(Signal)==2) then 
		local posNeed = SignFunc(Signal)*Lot
		TransCount = TransCount + CorrectPos(PosNow, posNeed, Emit, MyAccount, Class, "Коррекция по сигналу +-2 ", Slip)
	elseif (math.abs(Signal)==1 and SignFunc(Signal)~=SignFunc(PosNow)) then
		TransCount = TransCount + CorrectPos(PosNow, 0, Emit, MyAccount, Class, "Коррекция по сигналу +-1 ", Slip)
	elseif (TradeType == "LONG" and PosNow < 0) then
		TransCount = TransCount + CorrectPos(PosNow, 0, Emit, MyAccount, Class, "Только ЛОНГ, закрытие ШОРТа ", Slip)
	elseif (TradeType == "SHORT" and PosNow > 0) then
		TransCount = TransCount + CorrectPos(PosNow, 0, Emit, MyAccount, Class, "Только ШОРТ, закрытие ЛОНГа ", Slip)
	end
	if (TransCount ==0) then
		TransCount = TransCount + ProfitControl(PosNow, Emit, MyAccount, Class, "Корректировка позиции профита ")
	end
	
	SetCell(TableId,6,2,tostring(PosNow))																																			-- заполняем таблицу данными
	SetCell(TableId,7,2,tostring(Signal))																																				-- заполняем таблицу данными
	SetCell(TableId,8,2,tostring(Lot))																																					-- заполняем таблицу данными
	SetCell(TableId,9,2,TradeType)																																					-- заполняем таблицу данными
	PosPrev = PosNow
	if (TransCount ~=0) then
		sleep(1000)																																												-- интервал выполнения функции в милисекундах (1 секунда)
	else
		sleep(500)
	end
end

function PutDataToTableInit()																																							-- создание таблицы робота
	TableId = AllocTable()																																									-- инициализация таблицы робота
	AddColumn(TableId,1,"ПАРАМЕТРЫ",true,QTABLE_STRING_TYPE,20)																				-- добавляем колонки к таблице TableId (параметры в справочнике по таблицам)
	AddColumn(TableId,2,"ЗНАЧЕНИЯ",true,QTABLE_STRING_TYPE,20)
	AddColumn(TableId,3,"КОММЕНТАРИИ",true,QTABLE_STRING_TYPE,30)
	CreateWindow(TableId)																																								-- создание окна с таблицей
	SetWindowPos(TableId,100,200,500,300)																																		-- позиция и размеры таблицы
	SetWindowCaption(TableId,"Робот ПАРАБОЛИК")																													-- заголовок таблицы
	for i=1,10 do
		InsertRow(TableId,-1)																																								-- добавляем строки (в конец таблицы с ключем "-1")
	end
	local nRow,nCol = GetTableSize(TableId)
	for i=1,nRow do																																											-- раскрашиваем четные строки в серый цвет
		if (i%2==0) then																																										-- "%"  -  целочисленное деление (в данном случае на два) для выявления четных и нечетных строк
			SetColor(TableId, i, QTABLE_NO_INDEX, RGB(220,220,220), RGB(0,0,0), RGB(0,220,220), RGB(0,0,0))						-- серый цвет
		else
			SetColor(TableId, i, QTABLE_NO_INDEX, RGB(255,255,255), RGB(0,0,0), RGB(0,220,220), RGB(0,0,0))						-- белый цвет
		end
	end
	SetCell(TableId,1,1,"Серверное время")																																		-- именуем строки таблицы																																
	SetCell(TableId,2,1,"Статус сессии")	
	SetCell(TableId,3,1,"Код класса")	
	SetCell(TableId,4,1,"Код инструмента")
	SetCell(TableId,5,1,"Номер счета") 
	SetCell(TableId,6,1,"Текущая позиция")
	SetCell(TableId,7,1,"Сигнал ТС")
	SetCell(TableId,8,1,"Лот")
	SetCell(TableId,9,1,"Тип торговли")
end

function WriteToLogFile(sDataStr)																																					-- запись в лог
	local ServerTime = getInfoParam("SERVERTIME")
	local ServerDate = getInfoParam("TRADEDATE")
	local LogDataString = ServerDate.."; "..ServerTime.."; "..sDataStr.."\n"
	local sFile = getScriptPath().."\\log\\"..ServerDate..".log"
	local f = io.open(sFile,"a")
	if (f ~= nil) then
		f:write(LogDataString)
		f:flush()																																													-- сохраняем файл перед закрытием
		f:close()
	else
		message("Не удалось открыть Лог-файл!")
	end
end

function PutErrorToTable(nEStr, sPrblm)																																			-- сообщение об ошибке и подсветка соответствующей строки
	SetCell(TableId, nEStr, 2, "")	
	SetCell(TableId, nEStr, 3, sPrblm)	
	Highlight(TableId, nEStr, QTABLE_NO_INDEX, RGB(255,0,0), RGB(255,255,255),500)
	sleep(1000)
end

function PosNowFunc(sEmit, sAccount)																																			-- находим текущую позицию по инструменту
	local nSize = getNumberOf("futures_client_holding")																														-- определяем количество строк в таблице "позиции по клиентским счетам" (futures_client_holding)
	if (nSize ~= nil) then
		for i=0, nSize-1 do
			local row = getItem("futures_client_holding", i)																														-- в цикле получаем и проверяем каждую строку из указанной таблицы
			if (row ~= nil and row.sec_code == sEmit and row.trdaccid == sAccount) then
				return tonumber(row.totalnet)
			end
		end
	end
	return 0
end

function SignalCheck()																																										-- получаем сигнал с графика и проверяем был переворот или нет
	local NumOfCandlesSAR = getNumCandles(IdSAR)
	local NumOfCandlesPrice = getNumCandles(IdPriceSAR)
	if (NumOfCandlesSAR == nil or NumOfCandlesPrice == nil) then
		Problem = "Нет вывода с графика!"
		ErrorStr = 7
		Timer = 3
		return 0
	else 
		Problem = ""
		ErrorStr = 0
	end
	local tSAR, nSAR, _ = getCandlesByIndex(IdSAR, 0, NumOfCandlesSAR-2, 2)																			-- получаем две последние свечи (NumOfCandlesSAR-2, 2)
	local tPrice, nPrice, _ = getCandlesByIndex(IdPriceSAR, 0, NumOfCandlesPrice-2, 2)
	if (nSAR ~= 2 or nPrice ~= 2) then
		Problem = "Ошибка в кол-ве свечей!"
		ErrorStr = 7
		Timer = 3
		return 0
	else 
		Problem = ""
		ErrorStr = 0
	end
	if (tSAR[0].close > tPrice[0].close and tSAR[1].close < tPrice[1].close) then																					-- условие для открытия длинной позиции (переворот)
		return 2
	elseif (tSAR[0].close < tPrice[0].close and tSAR[1].close > tPrice[1].close) then																			-- условие для открытия короткой позиции (переворот)
		return -2
	elseif (tSAR[1].close < tPrice[1].close) then																																	-- указывает на то, что мы должны быть либо в лонге, либо в нулевой позиции (остаемся на месте)
		return 1
	elseif (tSAR[1].close > tPrice[1].close) then																																	-- указывает на то, что мы должны быть либо в шорте, либо в нулевой позиции (остаемся на месте)
		return -1
	end
end

function SignFunc(numb)																																									-- получение знака числа
	if (numb > 0) then
		return 1
	elseif (numb < 0) then
		return -1
	elseif (numb == 0) then
		return 0
	end
end

function RoundToStep(numb, nStep)																																				-- округление до шага цены
	if (numb == nil or nStep == nil) then
		return nil
	elseif (nStep == 0) then
		return numb
	end
	local ost = numb % nStep
	if (ost < nStep/2) then
		return (math.floor(numb/nStep)*nStep)
	else
		return (math.ceil(numb/nStep)*nStep)
	end
end

function tostringEX(x)																																										-- правильная функция для перевода числа в строку (без добавления 0 после целой части)
	return tostring(math.tointeger(x) or x)
end

function CorrectPos(posNow, posNeed, emit, acc, class, prevString, slip)																							-- выставление заявки, корректировка позиции
	local vol = posNeed - posNow
	if (vol == 0) then																																											-- транзакции не было
		return 0
	end
	local BySell = ""
	local price = 0
	local last = tonumber(getParamEx(class, emit, "LAST").param_value)																							-- последнее текущее значение цены
	local step = tonumber(getParamEx(class, emit, "SEC_PRICE_STEP").param_value)																		-- шаг цены
	if (vol >0) then
		BySell = "B"																																												-- сигнал к покупке
		price = last + slip*step																																								-- цена покупки
	else
		BySell = "S"																																												-- иначе, сигнал к продаже
		price = last - slip*step																																								-- цена продажи
	end
	transaction = {																																												-- задаем параметры транзакции (массив)
							["ACTION"] = "NEW_ORDER",
							["SECCODE"] = emit,
							["ACCOUNT"] = acc,
							["CLASSCODE"] = class,
							["OPERATION"] = BySell,
							["PRICE"] = tostringEX(price),																																-- !!!ВАЖНО!!! округляем цену в меньшую сторону, иначе выдает ошибку
							["QUANTITY"] = tostring(math.abs(vol)),
							["TYPE"] = "L",
							["TRANS_ID"] = "123456",																																	-- произвольный номер
							["CLIENT_CODE"] = "РОБОТ"																															-- в это поле на срочной секции можно записать комментарий, на фондовой секции оно должно использоваться по назначению
						}
	local result = sendTransaction(transaction)																																		-- отправка транзакции
	local sLogStr = ""
	sLogStr = "Отклик транзакции = "..result..";  Позиция = "..tostring(posNow)..";  "																	-- далее запись в лог
	for key,val in pairs(transaction) do
		sLogStr = sLogStr..key.." = "..val..";  "
	end
	if (prevString ~= nil or prevString ~= "") then
		sLogStr = prevString.."  "..sLogStr
	end
	WriteToLogFile(sLogStr)
	local count = 1																																												-- проверяем исполнение транзакции
	sleep(100)
	for i = 1, 300 do
		local posNew =  PosNowFunc(emit, acc)
		if (posNew == posNeed) then
			Problem = "Сделка прошла за "..tostring(count*100).." мсек"																								-- подумать в какую строку таблицы робота это выводить!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Либо, если это писать просто в лог, тогда использовать другую, локальную строковую переменную
			WriteToLogFile(Problem)
			return 1
		end
		count = count + 1
		sleep(100)
	end
	Problem = "Проблемы с транзакцией!"
	WriteToLogFile(Problem)
	return nil
end

function NewStopProfit(acc, class, emit, BySell, qty, stopPrice, ProfitOtstup, ProfitSpread, prevString)												-- выставление нового стоп-профита
	transaction = {																																												-- задаем параметры транзакции (массив)
							["ACTION"] = "NEW_STOP_ORDER",
							["SECCODE"] = emit,
							["ACCOUNT"] = acc,
							["CLASSCODE"] = class,
							["STOP_ORDER_KIND"] = "TAKE_PROFIT_STOP_ORDER",
							["TRANS_ID"] = "007",																																		-- произвольный номер
							["CLIENT_CODE"] = "РОБОТ",																														-- в это поле на срочной секции можно записать комментарий, на фондовой секции оно должно использоваться по назначению
							["EXPIRY_DATE"] = "TODAY",																														-- "GTC" - это тип "до отмены" (работает только на боевой версии КВИКа, на тесте не работает! Сбербанк также не позволяет выставлять такие заявки)
							["OPERATION"] = BySell,
							["QUANTITY"] = tostring(qty),
							["STOPPRICE"] = tostringEX(stopPrice),																											-- !!!ВАЖНО!!! округляем цену в меньшую сторону, иначе выдает ошибку
							["OFFSET_UNITS"] = "PRICE_UNITS",																											-- в чем указывать отступ профита (указывается в процентах или пунктах)
							["SPREAD_UNITS"] = "PRICE_UNITS",																											-- в чем указывается проскальзывание
							["OFFSET"] = tostring(ProfitOtstup),																													-- отступ профита
							["SPREAD"] = tostringEX(ProfitSpread)																												-- проскальзывание
						}
	local result = sendTransaction(transaction)																																		-- отправка транзакции
	local sLogStr = ""
	sLogStr = "Отклик транзакции = "..result..";  "																															-- далее запись в лог
	for key,val in pairs(transaction) do
		sLogStr = sLogStr..key.." = "..val..";  "
	end
	if (prevString ~= nil or prevString ~= "") then
		sLogStr = prevString.."  "..sLogStr
	end
	WriteToLogFile(sLogStr)
	return 1
end

function DeleteProfitByNumber(emit, class, keyNumber, prevString)																									-- удаление ненужного стоп-профита по номеру заявки
	transaction = {																																												-- задаем параметры транзакции (массив)
							["ACTION"] = "KILL_STOP_ORDER",
							["SECCODE"] = emit,
							["CLASSCODE"] = class,
							["STOP_ORDER_KEY"] = tostring(keyNumber),
							["TRANS_ID"] = "123456",																																	-- произвольный номер
							["CLIENT_CODE"] = "РОБОТ"																															-- в это поле на срочной секции можно записать комментарий, на фондовой секции оно должно использоваться по назначению
						}
	local result = sendTransaction(transaction)																																		-- отправка транзакции
	local sLogStr = ""
	sLogStr = "Отклик транзакции = "..result..";  "																															-- далее запись в лог
	for key,val in pairs(transaction) do
		sLogStr = sLogStr..key.." = "..val..";  "
	end
	if (prevString ~= nil or prevString ~= "") then
		sLogStr = prevString.."  "..sLogStr
	end
	WriteToLogFile(sLogStr)
	return 1
end

function DeleteAllProfits(acc, emit, class, prevString)																															-- удаление всех стоп-профитов
	local N = getNumberOf("stop_orders")
	local count = 0
	for i = 0,N-1 do
		local row = getItem("stop_orders", i)
		if (row.account == acc and row.sec_code == emit and row.class_code == class) then
			if (bit.band(row.flags,1)>0) then																																			-- "1" указывается в 10-й системе счисления (означает 00000001) поскольку в сравниваемом числе в нулевом бите должна стоять 1, что означает, что заявка активна
				local keyNumber = row.order_num
				DeleteProfitByNumber(emit, class, keyNumber, prevString)																								-- удаляем активную заявку
				count = count + 1
			end
		end
	end
	return count
end

function EnterPrice(posNow, acc, emit, class)																																	-- находим цену входа в сделку (функция работает только внутри дня, так как КВИК не запоминает позицию за прошлый период.)
	if (posNow ==0) then
		return 0
	end
	local function fn1(param1, param2)
		if (param1 == acc and param2 == emit) then
			return true
		else
			return false
		end
	end
	local index = SearchItems("trades", 0, getNumberOf("trades")-1, fn1, "account, sec_code")
	local PN = posNow
	local Sum = 0
	if (index ~= nil) then
		for i=#index,1,-1 do
			local row = getItem("trades", index[i])
			local direct
			if (bit.band(row.flags,4)>0) then																																			-- 3-й бит "заявка на продажу, иначе на покупку"
				direct = -1																																										-- для продажи
			else
				direct = 1																																											-- иначе, для покупки
			end
			local price = row.price
			local qty = row.qty
			local PNext = PN - direct*qty
			if (SignFunc(PNext)~=SignFunc(PN)) then
				Sum = Sum + direct*SignFunc(posNow)*price*math.min(qty, math.abs(PN))
				return Sum/math.abs(posNow)
			else
				Sum = Sum + direct*SignFunc(posNow)*price*qty
			end
			PN = PNext
		end
	end
	return 0
end

function ProfitControl(posNow, emit, acc, class, prevString)																												-- корректировка позиции профита
	local function fn1(param1, param2, param3)
		if (param1 == acc and param2 == emit and param3 ==class) then
			return true
		else
			return false
		end
	end
	local step = tonumber(getParamEx(class, emit, "SEC_PRICE_STEP").param_value)																		-- шаг цены
	local enterPrice = RoundToStep(EnterPrice(posNow, acc, emit, class), step)
	local profitPrice = enterPrice + SignFunc(posNow)*Profit*step
	local profCorrect = false																																								-- нашли или нет нужный профит
	local count = 0
	local index = SearchItems("stop_orders", 0, getNumberOf("stop_orders")-1, fn1, "account, sec_code, class_code")
	if (index ~= nil) then
		for i=1,#index do
			local row = getItem("stop_orders", index[i])
			if (bit.band(row.flags,1)>0) then
				if (row.stop_order_type ~= 6 or profCorrect == true) then																									-- если нашли правильную заявку
					local keyNumber = row.order_num
					DeleteProfitByNumber(emit, class, keyNumber, "Функция корректировки профита ")
					count = count + 1
				else
					local qtyX = row.qty
					local profitPriceX = row.condition_price
					local buySellX = row.condition
					local signPosX = 0
					if (buySellX == 4) then
						signPosX = -1
					elseif (buySellX == 5) then 
						signPosX = 1
					end
					if (signPosX == SignFunc(posNow) and qtyX == math.abs(posNow) and profitPriceX == profitPrice) then
						profCorrect = true
					else
						local keyNumber = row.order_num
						DeleteProfitByNumber(emit, class, keyNumber, prevString)
						count = count + 1
					end
				end
			end
		end
	end
	if (profCorrect == false and posNow~=0) then
		local ProfitSpread = 30*step
		if (posNow>0) then
			BySell = "S"
		else
			BySell = "B"
		end
		NewStopProfit(acc, class, emit, BySell, math.abs(posNow), profitPrice, 0, ProfitSpread, "Функция корректировки профита ")
		count = count + 1
	end
	return count
end