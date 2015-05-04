﻿RESTOCKSHOP_LOCALIZATION = setmetatable( {}, { __index = function( self, key )
	self[key] = key; -- Use original phrase for undefined keys
	return key;
end } );
--
local L = RESTOCKSHOP_LOCALIZATION;
-- enUS, enGB
if GetLocale() == "enUS" or GetLocale() == "enGB" then
-- deDE
elseif GetLocale() == "deDE" then
-- esES
elseif GetLocale() == "esES" then
-- frFR
elseif GetLocale() == "frFR" then
-- itIT
elseif GetLocale() == "itIT" then
-- koKR
elseif GetLocale() == "koKR" then
-- ptBR
elseif GetLocale() == "ptBR" then
L["Abort"] = "Abortar"
L["Addon %s required"] = "Addon %s necessário"
L["All Characters"] = "Todos os Personagens"
L["Asking server about %d item(s)... %d second(s) please"] = "Perguntando servidor sobre %d itens ... %d segundo por favor"
L["AtrValue (Auctionator - Auction Value)"] = "AtrValue (Auctionator - Leilão Valor)"
L["Attempting to import %d items..."] = "A tentativa de importar %d itens ..."
L["AucAppraiser (Auctioneer - Appraiser)"] = "AucAppraiser (Auctioneer - Avaliador)"
L["AucMarket (Auctioneer - Market Value)"] = "AucMarket (Auctioneer - Valor de Mercado)"
L["AucMinBuyout (Auctioneer - Minimum Buyout)"] = "AucMinBuyout (Auctioneer - Compra Mínima)"
L["Buy All"] = "Comprar Todos"
L["Buy All has been stopped"] = "Comprar Todos foi parado"
L["Confirm before deleting an item from a shopping list"] = "Confirme antes de excluir um item de uma lista de compras"
L["Copy List"] = "Copiar Lista"
L["Copy List: %s"] = "Copiar Lista: %s"
L["Could not query Auction House after several attempts, please try again in a few moments"] = "Não foi possível consultar Auction House depois de várias tentativas, por favor, tente novamente em alguns instantes"
L["Create List"] = "Criar Lista"
L["Current Character"] = "Personagem Atual"
L["Current Shopping List:"] = "Lista de Compras Atual:"
-- L["DBGlobalMarketAvg (AuctionDB - Global Market Value Average (via TSM App))"] = ""
-- L["DBGlobalMarketMedian (AuctionDB - Global Market Value Median (via TSM App))"] = ""
-- L["DBGlobalMinBuyoutAvg (AuctionDB - Global Minimum Buyout Average (via TSM App))"] = ""
-- L["DBGlobalMinBuyoutMedian (AuctionDB - Global Minimum Buyout Median (via TSM App))"] = ""
-- L["DBGlobalSaleAvg (AuctionDB - Global Sale Average (via TSM App))"] = ""
L["DBMarket (AuctionDB Market Value)"] = "DBMarket (AuctionDB Valor de Mercado)"
L["DBMinBuyout (AuctionDB Minimum Buyout)"] = "DBMinBuyout (AuctionDB Compra Mínima)"
L["Delete item? %s from %s"] = "Excluir produto? %s de %s"
L["Delete List"] = "Apagar Lista"
L["Delete list? %s"] = "Apagar lista? %s"
L["%d invalid item(s) not imported:"] = "%d itens inválidos não importados:"
L["Display item settings for the currently selected shopping list in the item's tooltip"] = "Definições do item de exibição para a lista de compras atualmente selecionado na dica do item"
L["Display the Item ID in the tooltip of all items"] = "Mostrar a ID do item na dica de todos os itens"
-- L["%d items remaining"] = ""
L["%d of %d items imported"] = "%d de %d itens importados"
L["%d stacks of %d"] = "%d pilhas de %d"
L["Export Items"] = "Itens de exportação"
L["Export items from list: %s\\n\\n|cffffd200TSM|r\\nComma-delimited Item IDs\\n|cff82c5ff12345,12346|r\\n\\nor\\n\\n|cffffd200RestockShop|r\\nComma-delimited items\\nColon-delimited settings\\n|cff82c5ff12345:5:115:105:0,12346:40:110:100:0|r\\n"] = "Itens de exportação da lista de IDs de item: %s\\n\\n|cffffd200TSM|r\\ndelimitado por vírgula\\n|cff82c5ff12345,12346|r\\n\\nou\\n\\n|cffffd200RestockShop|r\\nitens de configurações delimitado por\\nColon delimitado por vírgula\\n|cff82c5ff12345:5:115:105:0,12346:40:110:100:0|r\\n"
L["Full"] = "Cheio"
L["Full Stock Qty"] = "Cheio Estoque Qtde"
L["Import Items"] = "Itens de importação"
L["Import items to list: %s\\n\\n|cffffd200TSM|r\\nComma-delimited Item IDs\\nNo subgroup structure\\n|cff82c5ff12345,12346|r\\n\\nor\\n\\n|cffffd200RestockShop|r\\nComma-delimited items\\nColon-delimited settings\\n|cff82c5ff12345:5:115:105:0,12346:40:110:100:0|r\\n"] = "Importar itens para a lista de IDs de item: %s\\n\\n|cffffd200TSM|r\\ndelimitado por vírgula\\nNenhuma estrutura subgrupo\\n|cff82c5ff12345,12346|r\\nou\\n\\n|cffffd200RestockShop|r\\nitens de configurações delimitado\\npor Colon delimitado por vírgula \\n|cff82c5ff12345:5:115:105:0,12346:40:110:100:0|r\\n"
L["Include Guild Bank(s)"] = "Incluir Banco(s) da Guilda"
L["Item added"] = "Item adicionado"
L["Item deleted"] = "Item excluído"
L["Item ID"] = "ID do Item"
L["Item not found, check your %sItem ID|r"] = "Item não encontrado, verifique o seu %sID do Item|r"
L["Item Price"] = "Item Preço"
L["Item Tooltip"] = "Item Dica"
L["Item updated"] = "Item atualizado"
L["Item Value"] = "Item Valor"
-- L["Item Value Source (Auctionator, Auctioneer, AuctionDB, WoWuction)"] = ""
L["List"] = "Lista"
L["List created"] = "Lista criado"
L["List deleted"] = "Lista eliminado"
L["List name cannot be empty"] = "Nome da lista não pode ser vazio"
-- L["List not created, that name already exists"] = ""
L["Low"] = "Baixo"
L["Macro %s/rs acceptbuttonclick|r for fast key or mouse bound buying"] = "Macro %s/rs acceptbuttonclick|r para teclado ou mouse rápido obrigado a compra"
L["% Max Price"] = "% Preço Máximo"
L["Max Price"] = "Preço Máx"
L["Max prices, percentage of Item's Value"] = "Preço máximo, percentagem do Item Valor"
L["Miscellaneous"] = "Diverso"
-- L["No additional auctions matched your settings"] = ""
-- L["No auctions were found that matched your settings"] = ""
L["Norm"] = "Norma"
L["On Hand"] = "Na Mão"
L["On Hand Tracking (TSM ItemTracker)"] = "Na Mão Rastreamento (TSM ItemTracker)"
-- L["Press \"Shop\" to scan your list or click an item on the right to scan a single item"] = ""
L["Requires Item Value"] = "Requer Item Valor"
L["Requires %s Data"] = "Requer Dados %s"
L["Restock %"] = "Reabastecer %"
-- L["Restock Shopping List"] = ""
L["%sAt least one of the following addons must be enabled to provide an Item Value Source: %s|r"] = "%sPelo menos um dos seguintes addons deve estar habilitado para fornecer uma Item Valor Fonte: %s|r"
L["Scanning"] = "Escaneo"
L["Scanning %s: Page %d of %d"] = "Escaneo %s: Página %d de %d"
L["Select an auction to buy or click \"Buy All\""] = "Selecione um leilão para comprar ou clique em \"Comprar Todos\""
L["Selection ignored, busy scanning"] = "Seleção ignorado, escaneo ocupado"
L["%sFull Stock Qty|r cannot be empty"] = "%sCheio Estoque Qtde|r não pode estar vazio"
L["Shop"] = "Comprar"
L["Shopping Lists"] = "Listas de Compras"
L["Shopping List Settings"] = "Configurações Listas de Compras"
L["Show Delete Item Confirmation Dialog"] = "Mostrar Excluir diálogo de confirmação do item"
L["%sItem not added, incorrect or missing data|r"] = "%sItem não adicionado, os dados incorretos ou ausentes|r"
L["Skipping %s: %sFull Stock Qty|r reached and no %sFull|r price set"] = "Ignorando %s: %sCheio Estoque Qtde|r atingido e nenhum preço %sCheio|r entrou"
L["Skipping %s: %sRequires %s data|r"] = "Ignorando %s: %sRequer dados %s|r"
L["%sLow|r cannot be empty"] = "%sBaixo|r não pode estar vazio"
L["%sLow|r cannot be smaller than %sNorm|r"] = "%sBaixo|r não pode ser menor do que o %sNorma|r"
L["%sLow Stock %%|r (Percent of Item's Full Stock Qty)"] = "%sBaixo Estoque %%|r (Percentual de do Item Cheio Estoque Qtde)"
L["%sNorm|r cannot be empty"] = "%sNorma|r não pode estar vazio"
L["%sNorm|r cannot be smaller than %sFull|r"] = "%sNorma|r não pode ser menor do que o %sCheio|r"
L["%s%sx%d|r for %s per item not found after rescan"] = "%s%sx%d|r para %s por item não foi encontrado após escaneo novamente"
L["%s%sx%d|r for %s per item not found, rescanning item"] = "%s%sx%d|r para %s por item não encontrado, inciso escaneo novamente"
L["%s%sx%d|r for %s per item was found after rescan"] = "%s%sx%d|r para %s por item foi encontrado após escaneo novamente"
L["Stack Size"] = "Pilha Tamanho"
L["Stop"] = "Pare"
L["Submit"] = "Submeter"
L["That auction belonged to you and couldn't be won"] = "Esse leilão pertencia a você, e não poderia ser vencida"
L["That auction was no longer available"] = "Esse leilão não estava mais disponível"
L["These options allow you to control how %s\"Item Value\"|r and %s\"On Hand\"|r quantities are calculated. %s\"Low Stock %%\"|r determines at what %s\"On Hand\"|r percentage of %s\"Full Stock Qty\"|r an item's max price becomes the %s\"Low\"|r setting."] = "Essas opções permitem que você controle como %s\"Item Valor\"|r e quantidades %s\"Na Mão\"|r são calculados. %s\"Baixa Estoque %%\"|r determina em que %s\"Na Mão\"|r percentagem de %s\"Cheio Estoque Qtde\"|r preço máximo de um item torna-se a definição %s\"Baixo\"|r."
L["These options allow you to create, copy, and delete shopping lists and the items they contain. ITEMS - %s\"Full Stock Qty\"|r is the maximum number of an item you want to keep in stock. %s\"Low\"|r, %s\"Norm\"|r, and %s\"Full\"|r contain an item's max price in terms of it's %s\"Item Value\"|r at the corresponding stock quantity. If you want to stop shopping for an item at %s\"Full Stock Qty\"|r leave %s\"Full\"|r %sempty|r or set to %s0|r."] = "Estas opções permitem-lhe criar, copiar e excluir listas de compras e os itens que eles contêm. ITENS - %s\"Cheio Estoque Qtde\"|r é o número máximo de um item que você deseja manter em estoque. %s\"Baixo\"|r, %s\"Norma\"|r, e %s\"Cheio\"|r conter preço máximo de um item em termos de que é %s\"Item Valor\"|r na quantidade de estoque correspondente. Se você quer parar de comprar um item em %s\"Cheio Estoque Qtde\"|r licença %s\"Cheio\"|r %svazio|r ou definido como %s0|r."
L["Unknown command"] = "Comando Desconhecido"
L["Upgraded version %s to %s"] = "Versão atualizada %s-%s"
L["wowuctionMarket (WoWuction Realm Market Value)"] = "wowuctionMarket (WoWuction Valor Realm Mercado)"
L["wowuctionMedian (WoWuction Realm Median Price)"] = "wowuctionMedian (WoWuction Realm Preço Mediano)"
L["wowuctionRegionMarket (WoWuction Region Market Value)"] = "wowuctionRegionMarket (WoWuction Região Valor de Mercado)"
L["wowuctionRegionMedian (WoWuction Region Median Price)"] = "wowuctionRegionMedian (WoWuction Região Média do Preço)"
L["You can't carry anymore of that item"] = "Você não pode carregar mais desse item"
-- L["You can't delete your only list, you must keep at least one"] = ""
L["You don't have enough money to buy that auction"] = "Você não tem dinheiro suficiente para comprar esse leilão"
L["You reached the %sFull Stock Qty|r of %s%d|r on %s"] = "Você alcançou o %sCheio Estoque Qtde|r de %s%d|r em %s"
-- ruRU
elseif GetLocale() == "ruRU" then
-- zhCN
elseif GetLocale() == "zhCN" then -- Partial credit to zzhfromcn aka 梦中情圣
L["Abort"] = "退出"
L["Addon %s required"] = "所需插件%s"
L["All Characters"] = "所有角色"
L["Asking server about %d item(s)... %d second(s) please"] = "约%d项要求服务器...%d秒请"
L["AtrValue (Auctionator - Auction Value)"] = "AtrValue (Auctionator - 拍卖价值)"
L["Attempting to import %d items..."] = "尝试导入%d项..."
L["AucAppraiser (Auctioneer - Appraiser)"] = "AucAppraiser (Auctioneer - 估价师)"
L["AucMarket (Auctioneer - Market Value)"] = "AucMarket (Auctioneer - 市场价值)"
L["AucMinBuyout (Auctioneer - Minimum Buyout)"] = "AucMinBuyout (Auctioneer - 最小买断)"
L["Buy All"] = "全部购买"
L["Buy All has been stopped"] = "已停止全部购买"
L["Confirm before deleting an item from a shopping list"] = "删除从购物清单中的项目之前确认"
L["Copy List"] = "复制列表"
L["Copy List: %s"] = "复制列表: %s"
L["Could not query Auction House after several attempts, please try again in a few moments"] = "几次访问拍卖行均失败，请稍后重试"
L["Create List"] = "创建列表"
L["Current Character"] = "当前角色"
L["Current Shopping List:"] = "当前采购列表:"
-- L["DBGlobalMarketAvg (AuctionDB - Global Market Value Average (via TSM App))"] = ""
-- L["DBGlobalMarketMedian (AuctionDB - Global Market Value Median (via TSM App))"] = ""
-- L["DBGlobalMinBuyoutAvg (AuctionDB - Global Minimum Buyout Average (via TSM App))"] = ""
-- L["DBGlobalMinBuyoutMedian (AuctionDB - Global Minimum Buyout Median (via TSM App))"] = ""
-- L["DBGlobalSaleAvg (AuctionDB - Global Sale Average (via TSM App))"] = ""
L["DBMarket (AuctionDB Market Value)"] = "DBMarket (AuctionDB 市场价格)"
L["DBMinBuyout (AuctionDB Minimum Buyout)"] = "DBMinBuyout (AuctionDB 最低一口价)"
L["Delete item? %s from %s"] = "删除物品 %s 自 %s"
L["Delete List"] = "删除列表"
L["Delete list? %s"] = "删除列表 %s"
L["%d invalid item(s) not imported:"] = "未导入%d无效的项目:"
L["Display item settings for the currently selected shopping list in the item's tooltip"] = "显示项目设置为当前选择的购物清单中的项目的提示"
L["Display the Item ID in the tooltip of all items"] = "显示项目的ID在所有项目的提示"
-- L["%d items remaining"] = ""
L["%d of %d items imported"] = "%d出%d项进口"
L["%d stacks of %d"] = "%d 堆 %d"
L["Export Items"] = "输出项目"
L["Export items from list: %s\\n\\n|cffffd200TSM|r\\nComma-delimited Item IDs\\n|cff82c5ff12345,12346|r\\n\\nor\\n\\n|cffffd200RestockShop|r\\nComma-delimited items\\nColon-delimited settings\\n|cff82c5ff12345:5:115:105:0,12346:40:110:100:0|r\\n"] = "从列表导出项目：%s\\n\\n|cffffd200TSM|r\\n逗号分隔的项ID\\n|cff82c5ff12345,12346|r\\n\\n或\\n\\n|cffffd200RestockShop|r\\n逗号分隔的项目\\n冒号分隔设置\\n|cff82c5ff12345:5:115:105:0,12346:40:110:100:0|r\\n"
L["Full"] = "全额"
L["Full Stock Qty"] = "全额仓储"
L["Import Items"] = "进口项目"
L["Import items to list: %s\\n\\n|cffffd200TSM|r\\nComma-delimited Item IDs\\nNo subgroup structure\\n|cff82c5ff12345,12346|r\\n\\nor\\n\\n|cffffd200RestockShop|r\\nComma-delimited items\\nColon-delimited settings\\n|cff82c5ff12345:5:115:105:0,12346:40:110:100:0|r\\n"] = "进口物品的清单：%s\\n\\n|cffffd200TSM|r\\n逗号分隔的项ID\\n号子群结构\\n|cff82c5ff12345,12346|r\\n\\n或\\n\\n|cffffd200RestockShop|r\\n逗号分隔的项目\\n冒号分隔设置\\n|cff82c5ff12345:5:115:105:0,12346:40:110:100:0|r\\n"
L["Include Guild Bank(s)"] = "包含公会银行"
L["Item added"] = "物品已添加"
L["Item deleted"] = "物品已删除"
L["Item ID"] = "物品ID"
L["Item not found, check your %sItem ID|r"] = "未发现物品，请检查 %s的 ID|r"
L["Item Price"] = "物品价格"
L["Item Tooltip"] = "物品提示"
L["Item updated"] = "物品更新"
L["Item Value"] = "物品价值"
-- L["Item Value Source (Auctionator, Auctioneer, AuctionDB, WoWuction)"] = ""
L["List"] = "列表"
L["List created"] = "列表已创建"
L["List deleted"] = "列表已删除"
L["List name cannot be empty"] = "列表名称不能为空"
-- L["List not created, that name already exists"] = ""
L["Low"] = "偏低"
L["Macro %s/rs acceptbuttonclick|r for fast key or mouse bound buying"] = "宏 %s/rs acceptbuttonclick|r 以便快速按键或鼠标绑定购买"
L["% Max Price"] = "% 最高价格"
L["Max Price"] = "最高价格"
L["Max prices, percentage of Item's Value"] = "最高价格（按物品价值的百分比计算）"
L["Miscellaneous"] = "杂项"
-- L["No additional auctions matched your settings"] = ""
-- L["No auctions were found that matched your settings"] = ""
L["Norm"] = "正常"
L["On Hand"] = "自有"
L["On Hand Tracking (TSM ItemTracker)"] = "自有追踪 (TSM ItemTracker)"
-- L["Press \"Shop\" to scan your list or click an item on the right to scan a single item"] = ""
L["Requires Item Value"] = "必须有物品价值"
L["Requires %s Data"] = "需要 %s 的数据"
L["Restock %"] = "重新仓储 %"
-- L["Restock Shopping List"] = ""
L["%sAt least one of the following addons must be enabled to provide an Item Value Source: %s|r"] = "%s至少有一个如下的插件必须能够提供该产品的价值来源: %s|r"
L["Scanning"] = "正在扫描"
L["Scanning %s: Page %d of %d"] = "正在扫描 %s: 第 %d 页，共 %d 页"
L["Select an auction to buy or click \"Buy All\""] = "选择一件拍卖品以购买或点击 \"全部购买\""
L["Selection ignored, busy scanning"] = "忽略选定物品，正在进行扫描"
L["%sFull Stock Qty|r cannot be empty"] = "%s全部仓储 Qty|r 不能为空"
L["Shop"] = "采购"
L["Shopping Lists"] = "采购列表"
L["Shopping List Settings"] = "采购列表设置"
L["Show Delete Item Confirmation Dialog"] = "显示删除项目确认对话框"
L["%sItem not added, incorrect or missing data|r"] = "物品 %s 未被添加，无效或遗缺数据|r"
L["Skipping %s: %sFull Stock Qty|r reached and no %sFull|r price set"] = "跳过物品 %s: %s已仓储足够数量|r 并且没有 %s的完整|r 价格设置"
L["Skipping %s: %sRequires %s data|r"] = "跳过物品 %s: %s 需要 %s的数据|r"
L["%sLow|r cannot be empty"] = "%s低|r 不能为空"
L["%sLow|r cannot be smaller than %sNorm|r"] = "%s低|r 不能比 %s正常价格小|r"
L["%sLow Stock %%|r (Percent of Item's Full Stock Qty)"] = "%s低仓储 %%|r (物品全仓储数量的百分比)"
L["%sNorm|r cannot be empty"] = "%s正常|r 不能为空"
L["%sNorm|r cannot be smaller than %sFull|r"] = "%s正常|r 不能小于 %s的完整|r"
L["%s%sx%d|r for %s per item not found after rescan"] = "%s%sx%d|r for %s per item 在再次扫描后未发现"
L["%s%sx%d|r for %s per item not found, rescanning item"] = "%s%sx%d|r for %s per item 未发现，再次进行扫描"
L["%s%sx%d|r for %s per item was found after rescan"] = "%s%sx%d|r for %s per item 再次扫描后发现该物品"
L["Stack Size"] = "堆叠数量"
L["Stop"] = "停止"
L["Submit"] = "提交"
L["That auction belonged to you and couldn't be won"] = "不能购买自己发布的拍卖品"
L["That auction was no longer available"] = "拍卖品不存在"
L["These options allow you to control how %s\"Item Value\"|r and %s\"On Hand\"|r quantities are calculated. %s\"Low Stock %%\"|r determines at what %s\"On Hand\"|r percentage of %s\"Full Stock Qty\"|r an item's max price becomes the %s\"Low\"|r setting."] = "这些选项可以允许您控制 %s\"物品价值\"|r 以及 %s\"自有\"|r 的数量计算。 %s\"低仓储 %%\"|r 决定于 %s\"自有\"|r 占 %s\"全额仓储\"|r 的百分比，物品的最高价格变为 %s\"低\"|r 的设置。"
L["These options allow you to create, copy, and delete shopping lists and the items they contain. ITEMS - %s\"Full Stock Qty\"|r is the maximum number of an item you want to keep in stock. %s\"Low\"|r, %s\"Norm\"|r, and %s\"Full\"|r contain an item's max price in terms of it's %s\"Item Value\"|r at the corresponding stock quantity. If you want to stop shopping for an item at %s\"Full Stock Qty\"|r leave %s\"Full\"|r %sempty|r or set to %s0|r."] = "本选项允许您管理采购列表及其物品。物品%s\"全额仓储\"|r为您想拥有的最大数量。%s\"偏低\"|r,%s\"正常\"|r,以及%s\"全额\"|r设定不同的仓储条件下的%s\"物品价值\"|r最高价格百分比。如想停购物品，在%s\"全额仓储\"|r中设定%s\"全额仓储\"|r%s为空|r或%s0|r。"
L["Unknown command"] = "未知命令"
L["Upgraded version %s to %s"] = "从版本 %s 升级至 %s"
L["wowuctionMarket (WoWuction Realm Market Value)"] = "wowuctionMarket (WoWuction 服务器市场价值)"
L["wowuctionMedian (WoWuction Realm Median Price)"] = "wowuctionMedian (WoWuction 服务器市场价格)"
L["wowuctionRegionMarket (WoWuction Region Market Value)"] = "wowuctionRegionMarket (WoWuction 区域市场价值)"
L["wowuctionRegionMedian (WoWuction Region Median Price)"] = "wowuctionRegionMedian (WoWuction 区域市场价格)"
L["You can't carry anymore of that item"] = "您不能再携带该物品"
-- L["You can't delete your only list, you must keep at least one"] = ""
L["You don't have enough money to buy that auction"] = "您没有足够的金币购买拍卖品"
L["You reached the %sFull Stock Qty|r of %s%d|r on %s"] = "您已经达到了 %s的全额仓储|r of %s%d|r on %s"
-- zhTW
elseif GetLocale() == "zhTW" then
end