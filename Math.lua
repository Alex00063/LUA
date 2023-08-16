function Body()																																												-- �������� ����������
	if (Timer>0) then
		Timer = Timer - 1
		PutErrorToTable(ErrorStr, Problem)																																			-- ��������� �� ������ � ��������� ��������������� ������
		return
	end
	local ServerTime = getInfoParam("SERVERTIME")																														-- �������� ����� �������
	if (IsWindowClosed(TableId)) then																																				-- ���� ������� ������ �������, ��������� �� ������
		PutDataToTableInit()
	end
	if (ServerTime == nil or ServerTime == "") then
		Problem = "����� ������� �� ��������!"
		Timer = 3
		ErrorStr = 1
		return
	else
		Problem = ""
		ErrorStr = 0
	end
	SetCell(TableId,1,2,ServerTime)																																					-- ��������� ������� �������
	SetCell(TableId,1,3,Problem)
	local SessionStatus = tonumber(getParamEx(Class, Emit, "STATUS").param_value)																		-- �������� ������ �������� ������ �� ������� "������� �����"
	if (SessionStatus ~= 1) then
		Problem = "������ �������!"
		Timer = 3
		ErrorStr = 2
		return
	else
		Problem = ""
		ErrorStr = 0
	end
	SetCell(TableId,2,2,"������ �������")																																		-- ��������� ������� �������
	SetCell(TableId,2,3,Problem)
	if (Class == nil or Class == "") then
		Problem = "����� �� ���������!"
		Timer = 3
		ErrorStr = 3
		return
	else
		Problem = ""
		ErrorStr = 0
	end
	SetCell(TableId,3,2,Class)																																								-- ��������� ������� �������
	SetCell(TableId,3,3,Problem)
	if (Emit == nil or Emit == "") then
		Problem = "���������� �� ���������!"
		Timer = 3
		ErrorStr = 4
		return
	else
		Problem = ""
		ErrorStr = 0
	end
	SetCell(TableId,4,2,Emit)																																								-- ��������� ������� �������
	SetCell(TableId,4,3,Problem)
	if (MyAccount == nil or MyAccount == "") then
		Problem = "���� �� ���������!"
		Timer = 3
		ErrorStr = 5
		return
	else
		Problem = ""
		ErrorStr = 0
	end
	SetCell(TableId,5,2,MyAccount)																																					-- ��������� ������� �������
	SetCell(TableId,5,3,Problem)
	local TransCount = 0
	local PosNow = PosNowFunc(Emit, MyAccount)																															-- ������� ������� ������� �� �����������
	if (PosNow == 0 or (PosNow~=0 and SignFunc(PosNow) ~= SignFunc(PosPrev))) then																-- ���� ��������� ��������� ������� ��� �� ��������, �� ����� ������ ������, ����� �� �� �������� (������� ������� �������)
		TransCount = TransCount + DeleteAllProfits(MyAccount, Emit, Class, "�������� ����-������� ��� ���������� ��� ������� ������� ")
	end
	local Signal = SignalCheck()																																							-- �������� ������ � ������� � ��������� ��� ��������� ��� ���
	if (TradeType == "LONG") then
		Signal = math.max(Signal,0)
	elseif (TradeType == "SHORT") then
		Signal = math.min(Signal,0)
	end
	if (math.abs(Signal)==2) then 
		local posNeed = SignFunc(Signal)*Lot
		TransCount = TransCount + CorrectPos(PosNow, posNeed, Emit, MyAccount, Class, "��������� �� ������� +-2 ", Slip)
	elseif (math.abs(Signal)==1 and SignFunc(Signal)~=SignFunc(PosNow)) then
		TransCount = TransCount + CorrectPos(PosNow, 0, Emit, MyAccount, Class, "��������� �� ������� +-1 ", Slip)
	elseif (TradeType == "LONG" and PosNow < 0) then
		TransCount = TransCount + CorrectPos(PosNow, 0, Emit, MyAccount, Class, "������ ����, �������� ����� ", Slip)
	elseif (TradeType == "SHORT" and PosNow > 0) then
		TransCount = TransCount + CorrectPos(PosNow, 0, Emit, MyAccount, Class, "������ ����, �������� ����� ", Slip)
	end
	if (TransCount ==0) then
		TransCount = TransCount + ProfitControl(PosNow, Emit, MyAccount, Class, "������������� ������� ������� ")
	end
	
	SetCell(TableId,6,2,tostring(PosNow))																																			-- ��������� ������� �������
	SetCell(TableId,7,2,tostring(Signal))																																				-- ��������� ������� �������
	SetCell(TableId,8,2,tostring(Lot))																																					-- ��������� ������� �������
	SetCell(TableId,9,2,TradeType)																																					-- ��������� ������� �������
	PosPrev = PosNow
	if (TransCount ~=0) then
		sleep(1000)																																												-- �������� ���������� ������� � ������������ (1 �������)
	else
		sleep(500)
	end
end

function PutDataToTableInit()																																							-- �������� ������� ������
	TableId = AllocTable()																																									-- ������������� ������� ������
	AddColumn(TableId,1,"���������",true,QTABLE_STRING_TYPE,20)																				-- ��������� ������� � ������� TableId (��������� � ����������� �� ��������)
	AddColumn(TableId,2,"��������",true,QTABLE_STRING_TYPE,20)
	AddColumn(TableId,3,"�����������",true,QTABLE_STRING_TYPE,30)
	CreateWindow(TableId)																																								-- �������� ���� � ��������
	SetWindowPos(TableId,100,200,500,300)																																		-- ������� � ������� �������
	SetWindowCaption(TableId,"����� ���������")																													-- ��������� �������
	for i=1,10 do
		InsertRow(TableId,-1)																																								-- ��������� ������ (� ����� ������� � ������ "-1")
	end
	local nRow,nCol = GetTableSize(TableId)
	for i=1,nRow do																																											-- ������������ ������ ������ � ����� ����
		if (i%2==0) then																																										-- "%"  -  ������������� ������� (� ������ ������ �� ���) ��� ��������� ������ � �������� �����
			SetColor(TableId, i, QTABLE_NO_INDEX, RGB(220,220,220), RGB(0,0,0), RGB(0,220,220), RGB(0,0,0))						-- ����� ����
		else
			SetColor(TableId, i, QTABLE_NO_INDEX, RGB(255,255,255), RGB(0,0,0), RGB(0,220,220), RGB(0,0,0))						-- ����� ����
		end
	end
	SetCell(TableId,1,1,"��������� �����")																																		-- ������� ������ �������																																
	SetCell(TableId,2,1,"������ ������")	
	SetCell(TableId,3,1,"��� ������")	
	SetCell(TableId,4,1,"��� �����������")
	SetCell(TableId,5,1,"����� �����") 
	SetCell(TableId,6,1,"������� �������")
	SetCell(TableId,7,1,"������ ��")
	SetCell(TableId,8,1,"���")
	SetCell(TableId,9,1,"��� ��������")
end

function WriteToLogFile(sDataStr)																																					-- ������ � ���
	local ServerTime = getInfoParam("SERVERTIME")
	local ServerDate = getInfoParam("TRADEDATE")
	local LogDataString = ServerDate.."; "..ServerTime.."; "..sDataStr.."\n"
	local sFile = getScriptPath().."\\log\\"..ServerDate..".log"
	local f = io.open(sFile,"a")
	if (f ~= nil) then
		f:write(LogDataString)
		f:flush()																																													-- ��������� ���� ����� ���������
		f:close()
	else
		message("�� ������� ������� ���-����!")
	end
end

function PutErrorToTable(nEStr, sPrblm)																																			-- ��������� �� ������ � ��������� ��������������� ������
	SetCell(TableId, nEStr, 2, "")	
	SetCell(TableId, nEStr, 3, sPrblm)	
	Highlight(TableId, nEStr, QTABLE_NO_INDEX, RGB(255,0,0), RGB(255,255,255),500)
	sleep(1000)
end

function PosNowFunc(sEmit, sAccount)																																			-- ������� ������� ������� �� �����������
	local nSize = getNumberOf("futures_client_holding")																														-- ���������� ���������� ����� � ������� "������� �� ���������� ������" (futures_client_holding)
	if (nSize ~= nil) then
		for i=0, nSize-1 do
			local row = getItem("futures_client_holding", i)																														-- � ����� �������� � ��������� ������ ������ �� ��������� �������
			if (row ~= nil and row.sec_code == sEmit and row.trdaccid == sAccount) then
				return tonumber(row.totalnet)
			end
		end
	end
	return 0
end

function SignalCheck()																																										-- �������� ������ � ������� � ��������� ��� ��������� ��� ���
	local NumOfCandlesSAR = getNumCandles(IdSAR)
	local NumOfCandlesPrice = getNumCandles(IdPriceSAR)
	if (NumOfCandlesSAR == nil or NumOfCandlesPrice == nil) then
		Problem = "��� ������ � �������!"
		ErrorStr = 7
		Timer = 3
		return 0
	else 
		Problem = ""
		ErrorStr = 0
	end
	local tSAR, nSAR, _ = getCandlesByIndex(IdSAR, 0, NumOfCandlesSAR-2, 2)																			-- �������� ��� ��������� ����� (NumOfCandlesSAR-2, 2)
	local tPrice, nPrice, _ = getCandlesByIndex(IdPriceSAR, 0, NumOfCandlesPrice-2, 2)
	if (nSAR ~= 2 or nPrice ~= 2) then
		Problem = "������ � ���-�� ������!"
		ErrorStr = 7
		Timer = 3
		return 0
	else 
		Problem = ""
		ErrorStr = 0
	end
	if (tSAR[0].close > tPrice[0].close and tSAR[1].close < tPrice[1].close) then																					-- ������� ��� �������� ������� ������� (���������)
		return 2
	elseif (tSAR[0].close < tPrice[0].close and tSAR[1].close > tPrice[1].close) then																			-- ������� ��� �������� �������� ������� (���������)
		return -2
	elseif (tSAR[1].close < tPrice[1].close) then																																	-- ��������� �� ��, ��� �� ������ ���� ���� � �����, ���� � ������� ������� (�������� �� �����)
		return 1
	elseif (tSAR[1].close > tPrice[1].close) then																																	-- ��������� �� ��, ��� �� ������ ���� ���� � �����, ���� � ������� ������� (�������� �� �����)
		return -1
	end
end

function SignFunc(numb)																																									-- ��������� ����� �����
	if (numb > 0) then
		return 1
	elseif (numb < 0) then
		return -1
	elseif (numb == 0) then
		return 0
	end
end

function RoundToStep(numb, nStep)																																				-- ���������� �� ���� ����
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

function tostringEX(x)																																										-- ���������� ������� ��� �������� ����� � ������ (��� ���������� 0 ����� ����� �����)
	return tostring(math.tointeger(x) or x)
end

function CorrectPos(posNow, posNeed, emit, acc, class, prevString, slip)																							-- ����������� ������, ������������� �������
	local vol = posNeed - posNow
	if (vol == 0) then																																											-- ���������� �� ����
		return 0
	end
	local BySell = ""
	local price = 0
	local last = tonumber(getParamEx(class, emit, "LAST").param_value)																							-- ��������� ������� �������� ����
	local step = tonumber(getParamEx(class, emit, "SEC_PRICE_STEP").param_value)																		-- ��� ����
	if (vol >0) then
		BySell = "B"																																												-- ������ � �������
		price = last + slip*step																																								-- ���� �������
	else
		BySell = "S"																																												-- �����, ������ � �������
		price = last - slip*step																																								-- ���� �������
	end
	transaction = {																																												-- ������ ��������� ���������� (������)
							["ACTION"] = "NEW_ORDER",
							["SECCODE"] = emit,
							["ACCOUNT"] = acc,
							["CLASSCODE"] = class,
							["OPERATION"] = BySell,
							["PRICE"] = tostringEX(price),																																-- !!!�����!!! ��������� ���� � ������� �������, ����� ������ ������
							["QUANTITY"] = tostring(math.abs(vol)),
							["TYPE"] = "L",
							["TRANS_ID"] = "123456",																																	-- ������������ �����
							["CLIENT_CODE"] = "�����"																															-- � ��� ���� �� ������� ������ ����� �������� �����������, �� �������� ������ ��� ������ �������������� �� ����������
						}
	local result = sendTransaction(transaction)																																		-- �������� ����������
	local sLogStr = ""
	sLogStr = "������ ���������� = "..result..";  ������� = "..tostring(posNow)..";  "																	-- ����� ������ � ���
	for key,val in pairs(transaction) do
		sLogStr = sLogStr..key.." = "..val..";  "
	end
	if (prevString ~= nil or prevString ~= "") then
		sLogStr = prevString.."  "..sLogStr
	end
	WriteToLogFile(sLogStr)
	local count = 1																																												-- ��������� ���������� ����������
	sleep(100)
	for i = 1, 300 do
		local posNew =  PosNowFunc(emit, acc)
		if (posNew == posNeed) then
			Problem = "������ ������ �� "..tostring(count*100).." ����"																								-- �������� � ����� ������ ������� ������ ��� ��������!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ����, ���� ��� ������ ������ � ���, ����� ������������ ������, ��������� ��������� ����������
			WriteToLogFile(Problem)
			return 1
		end
		count = count + 1
		sleep(100)
	end
	Problem = "�������� � �����������!"
	WriteToLogFile(Problem)
	return nil
end

function NewStopProfit(acc, class, emit, BySell, qty, stopPrice, ProfitOtstup, ProfitSpread, prevString)												-- ����������� ������ ����-�������
	transaction = {																																												-- ������ ��������� ���������� (������)
							["ACTION"] = "NEW_STOP_ORDER",
							["SECCODE"] = emit,
							["ACCOUNT"] = acc,
							["CLASSCODE"] = class,
							["STOP_ORDER_KIND"] = "TAKE_PROFIT_STOP_ORDER",
							["TRANS_ID"] = "007",																																		-- ������������ �����
							["CLIENT_CODE"] = "�����",																														-- � ��� ���� �� ������� ������ ����� �������� �����������, �� �������� ������ ��� ������ �������������� �� ����������
							["EXPIRY_DATE"] = "TODAY",																														-- "GTC" - ��� ��� "�� ������" (�������� ������ �� ������ ������ �����, �� ����� �� ��������! �������� ����� �� ��������� ���������� ����� ������)
							["OPERATION"] = BySell,
							["QUANTITY"] = tostring(qty),
							["STOPPRICE"] = tostringEX(stopPrice),																											-- !!!�����!!! ��������� ���� � ������� �������, ����� ������ ������
							["OFFSET_UNITS"] = "PRICE_UNITS",																											-- � ��� ��������� ������ ������� (����������� � ��������� ��� �������)
							["SPREAD_UNITS"] = "PRICE_UNITS",																											-- � ��� ����������� ���������������
							["OFFSET"] = tostring(ProfitOtstup),																													-- ������ �������
							["SPREAD"] = tostringEX(ProfitSpread)																												-- ���������������
						}
	local result = sendTransaction(transaction)																																		-- �������� ����������
	local sLogStr = ""
	sLogStr = "������ ���������� = "..result..";  "																															-- ����� ������ � ���
	for key,val in pairs(transaction) do
		sLogStr = sLogStr..key.." = "..val..";  "
	end
	if (prevString ~= nil or prevString ~= "") then
		sLogStr = prevString.."  "..sLogStr
	end
	WriteToLogFile(sLogStr)
	return 1
end

function DeleteProfitByNumber(emit, class, keyNumber, prevString)																									-- �������� ��������� ����-������� �� ������ ������
	transaction = {																																												-- ������ ��������� ���������� (������)
							["ACTION"] = "KILL_STOP_ORDER",
							["SECCODE"] = emit,
							["CLASSCODE"] = class,
							["STOP_ORDER_KEY"] = tostring(keyNumber),
							["TRANS_ID"] = "123456",																																	-- ������������ �����
							["CLIENT_CODE"] = "�����"																															-- � ��� ���� �� ������� ������ ����� �������� �����������, �� �������� ������ ��� ������ �������������� �� ����������
						}
	local result = sendTransaction(transaction)																																		-- �������� ����������
	local sLogStr = ""
	sLogStr = "������ ���������� = "..result..";  "																															-- ����� ������ � ���
	for key,val in pairs(transaction) do
		sLogStr = sLogStr..key.." = "..val..";  "
	end
	if (prevString ~= nil or prevString ~= "") then
		sLogStr = prevString.."  "..sLogStr
	end
	WriteToLogFile(sLogStr)
	return 1
end

function DeleteAllProfits(acc, emit, class, prevString)																															-- �������� ���� ����-��������
	local N = getNumberOf("stop_orders")
	local count = 0
	for i = 0,N-1 do
		local row = getItem("stop_orders", i)
		if (row.account == acc and row.sec_code == emit and row.class_code == class) then
			if (bit.band(row.flags,1)>0) then																																			-- "1" ����������� � 10-� ������� ��������� (�������� 00000001) ��������� � ������������ ����� � ������� ���� ������ ������ 1, ��� ��������, ��� ������ �������
				local keyNumber = row.order_num
				DeleteProfitByNumber(emit, class, keyNumber, prevString)																								-- ������� �������� ������
				count = count + 1
			end
		end
	end
	return count
end

function EnterPrice(posNow, acc, emit, class)																																	-- ������� ���� ����� � ������ (������� �������� ������ ������ ���, ��� ��� ���� �� ���������� ������� �� ������� ������.)
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
			if (bit.band(row.flags,4)>0) then																																			-- 3-� ��� "������ �� �������, ����� �� �������"
				direct = -1																																										-- ��� �������
			else
				direct = 1																																											-- �����, ��� �������
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

function ProfitControl(posNow, emit, acc, class, prevString)																												-- ������������� ������� �������
	local function fn1(param1, param2, param3)
		if (param1 == acc and param2 == emit and param3 ==class) then
			return true
		else
			return false
		end
	end
	local step = tonumber(getParamEx(class, emit, "SEC_PRICE_STEP").param_value)																		-- ��� ����
	local enterPrice = RoundToStep(EnterPrice(posNow, acc, emit, class), step)
	local profitPrice = enterPrice + SignFunc(posNow)*Profit*step
	local profCorrect = false																																								-- ����� ��� ��� ������ ������
	local count = 0
	local index = SearchItems("stop_orders", 0, getNumberOf("stop_orders")-1, fn1, "account, sec_code, class_code")
	if (index ~= nil) then
		for i=1,#index do
			local row = getItem("stop_orders", index[i])
			if (bit.band(row.flags,1)>0) then
				if (row.stop_order_type ~= 6 or profCorrect == true) then																									-- ���� ����� ���������� ������
					local keyNumber = row.order_num
					DeleteProfitByNumber(emit, class, keyNumber, "������� ������������� ������� ")
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
		NewStopProfit(acc, class, emit, BySell, math.abs(posNow), profitPrice, 0, ProfitSpread, "������� ������������� ������� ")
		count = count + 1
	end
	return count
end