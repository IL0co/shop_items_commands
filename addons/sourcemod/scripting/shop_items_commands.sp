#include <sourcemod>
#include <shop>
#include <csgo_colors>

#pragma semicolon 1
#pragma newdecls required

char gBuff[256], gSecBuff[64];
KeyValues kv;

public Plugin myinfo =
{
	name		= "[SHOP] Items Commands",
	author	 	= "iLoco",
	version	 	= "1.0.1",
	url			= "Discord: iLoco#7631"
};

public void OnPluginStart()
{
	kv = new KeyValues("Items Commands");
	BuildPath(Path_SM, gBuff, sizeof(gBuff), "configs/shop/items_commands.cfg");

	if(!kv.ImportFromFile(gBuff))
		SetFailState("File %s does not find!", gBuff);

	kv.GetString("Give Item Command", gBuff, sizeof(gBuff));
	kv.GetString("Give Item Admin Flag", gSecBuff, sizeof(gSecBuff));
	TrimString(gBuff);
	RegAdminCmd(gBuff, Commands_GiveItem, ReadFlagString(gSecBuff), "Give players an item");

	kv.GetString("Take Item Command", gBuff, sizeof(gBuff));
	kv.GetString("Take Item Admin Flag", gSecBuff, sizeof(gSecBuff));
	TrimString(gBuff);
	RegAdminCmd(gBuff, Commands_TakeItem, ReadFlagString(gSecBuff), "Take players an item");

	kv.GetString("Toggle Item Command", gBuff, sizeof(gBuff));
	kv.GetString("Toggle Item Admin Flag", gSecBuff, sizeof(gSecBuff));
	TrimString(gBuff);
	RegAdminCmd(gBuff, Commands_TakeItem, ReadFlagString(gSecBuff), "Change the state of the item");

	kv.GetString("Toggle Category Off Command", gBuff, sizeof(gBuff));
	kv.GetString("Toggle Category Off Admin Flag", gSecBuff, sizeof(gSecBuff));
	TrimString(gBuff);
	RegAdminCmd(gBuff, Commands_ToggleOffCategory, ReadFlagString(gSecBuff), "Toggle off all items in category");

	kv.GetString("Change Duration Command", gBuff, sizeof(gBuff));
	kv.GetString("Change Duration Admin Flag", gSecBuff, sizeof(gSecBuff));
	TrimString(gBuff);
	RegAdminCmd(gBuff, Commands_ChangeDuration, ReadFlagString(gSecBuff), "Change duration of item");

	kv.GetString("Buy Item Command", gBuff, sizeof(gBuff));
	kv.GetString("Buy Item Admin Flag", gSecBuff, sizeof(gSecBuff));
	TrimString(gBuff);
	RegAdminCmd(gBuff, Commands_BuyItem, ReadFlagString(gSecBuff), "Will buy the item for the player at his expense");

	kv.GetString("Sell Item Command", gBuff, sizeof(gBuff));
	kv.GetString("Sell Item Admin Flag", gSecBuff, sizeof(gSecBuff));
	TrimString(gBuff);
	RegAdminCmd(gBuff, Commands_SellItem, ReadFlagString(gSecBuff), "Will sell the item to the player at his expense");

	kv.GetString("Use Item Command", gBuff, sizeof(gBuff));
	kv.GetString("Use Item Admin Flag", gSecBuff, sizeof(gSecBuff));
	TrimString(gBuff);
	RegAdminCmd(gBuff, Commands_UseItem, ReadFlagString(gSecBuff), "Uses player item");

	LoadTranslations("shop_items_commands.phrases");
}

public Action Commands_GiveItem(int client, int args)
{
	if(args < 4)
	{
		GetCmdArg(0, gBuff, sizeof(gBuff));
		ReplyToCommand(client, "%T", "Reply. Usage: Give Command", client, gBuff);
		return Plugin_Handled;
	}

	int[] targets = new int[MaxClients];
	int targets_count = GetCmdTargets(1, client, targets, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

	if(targets_count <= 0)
		return Plugin_Handled;

	GetCmdArg(4, gBuff, sizeof(gBuff));
	int count = StringToInt(gBuff);

	ItemType itemType;
	CategoryId categoryId;
	ItemId itemId;
	char itemName[64], categoryName[64];

	if(!GetCategoryIdFromArgs(client, 2, categoryId, categoryName, sizeof(categoryName)))
		return Plugin_Handled;

	if(!GetItemIdFromArgs(client, 3, categoryId, itemId, itemType, itemName, sizeof(itemName)))
		return Plugin_Handled;

	if(itemType != Item_Togglable && count <= 0)
		count = 1;

	if(itemType == Item_Togglable && count < -1)
		count = -1;

	bool print_server = view_as<bool>(kv.GetNum("Give Item Print Server", 0));
	bool print_admin = view_as<bool>(kv.GetNum("Give Item Print Admin", 1));

	for(int i; i < targets_count; i++)
	{
		if(Shop_GiveClientItem(targets[i], itemId, count) && (!client && print_server) || (client && print_admin))
		{
			if(itemType != Item_Togglable)
				Format(gBuff, sizeof(gBuff), "%T", "Chat. In Count", targets[i], count);

			CGOPrintToChat(targets[i], "%T", "Chat. Give Command Message", targets[i], itemName, categoryName, (itemType != Item_Togglable ? gBuff : ""));
		}
	}
	
	Print_CommandComplete(client);
	return Plugin_Handled;
}

public Action Commands_TakeItem(int client, int args)
{
	if(args < 3)
	{
		GetCmdArg(0, gBuff, sizeof(gBuff));
		ReplyToCommand(client, "%T", "Reply. Usage: Take Command", client, gBuff);
		return Plugin_Handled;
	}

	int[] targets = new int[MaxClients];
	int targets_count = GetCmdTargets(1, client, targets, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

	if(targets_count <= 0)
		return Plugin_Handled;

	GetCmdArg(4, gBuff, sizeof(gBuff));
	int count = StringToInt(gBuff);

	if(count < 0)
		count = 1;

	ItemType itemType;
	CategoryId categoryId;
	ItemId itemId;
	char itemName[64], categoryName[64];

	if(!GetCategoryIdFromArgs(client, 2, categoryId, categoryName, sizeof(categoryName)))
		return Plugin_Handled;

	if(!GetItemIdFromArgs(client, 3, categoryId, itemId, itemType, itemName, sizeof(itemName)))
		return Plugin_Handled;

	if(itemType != Item_Togglable && count <= 0)
		count = 1;

	bool print_server = view_as<bool>(kv.GetNum("Take Item Print Server", 0));
	bool print_admin = view_as<bool>(kv.GetNum("Take Item Print Admin", 1));

	for(int i; i < targets_count; i++)
	{
		if(!Shop_IsClientHasItem(targets[i], itemId))
			continue;

		if(Shop_RemoveClientItem(targets[i], itemId, count) && (!client && print_server) || (client && print_admin))
		{
			if(itemType != Item_Togglable)
				Format(gBuff, sizeof(gBuff), "%T", "Chat. In Count", targets[i], count);

			CGOPrintToChat(targets[i], "%T", "Chat. Take Command Message", targets[i], itemName, categoryName, (itemType != Item_Togglable ? gBuff : ""));
		}
	}
	
	Print_CommandComplete(client);
	return Plugin_Handled;
}

public Action Commands_ToggleItem(int client, int args)
{
	if(args < 3)
	{
		GetCmdArg(0, gBuff, sizeof(gBuff));
		ReplyToCommand(client, "%T", "Reply. Usage: Toggle Command", client, gBuff);

		return Plugin_Handled;
	}

	int[] targets = new int[MaxClients];
	int targets_count = GetCmdTargets(1, client, targets, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

	if(targets_count <= 0)
		return Plugin_Handled;

	GetCmdArg(4, gBuff, sizeof(gBuff));
	int value = StringToInt(gBuff);

	ToggleState state = Toggle;

	if(value == 1)
		state = Toggle_On;
	else if(value == 0)
		state = Toggle_Off;

	ItemType itemType;
	CategoryId categoryId;
	ItemId itemId;
	char itemName[64], categoryName[64];

	if(!GetCategoryIdFromArgs(client, 2, categoryId, categoryName, sizeof(categoryName)))
		return Plugin_Handled;

	if(!GetItemIdFromArgs(client, 3, categoryId, itemId, itemType, itemName, sizeof(itemName)))
		return Plugin_Handled;

	if(Shop_GetItemType(itemId) != Item_Togglable)
	{
		ReplyToCommand(client, "%T", "Reply. Item State Not Supported Togglable", client);
		return Plugin_Handled;
	}

	bool print_server = view_as<bool>(kv.GetNum("Toggle Item Print Server", 0));
	bool print_admin = view_as<bool>(kv.GetNum("Toggle Item Print Admin", 1));

	for(int i; i < targets_count; i++)
	{
		if(!Shop_IsClientHasItem(targets[i], itemId))
			continue;

		if(Shop_ToggleClientItem(targets[i], itemId, state) && (!client && print_server) || (client && print_admin))
		{
			if(state == Toggle_On || state == Toggle && Shop_IsClientItemToggled(targets[i], itemId))
				Format(gBuff, sizeof(gBuff), "%T", "Chat. Toggle On", targets[i]);
			if(state == Toggle_Off || state == Toggle)
				Format(gBuff, sizeof(gBuff), "%T", "Chat. Toggle Off", targets[i]);

			CGOPrintToChat(targets[i], "%T", "Chat. Toggle Command Message", targets[i], itemName, categoryName, (itemType != Item_Togglable ? gBuff : ""));
		}
	}
	
	Print_CommandComplete(client);
	return Plugin_Handled;
}

public Action Commands_ToggleOffCategory(int client, int args)
{
	if(args < 2)
	{
		GetCmdArg(0, gBuff, sizeof(gBuff));
		ReplyToCommand(client, "%T", "Reply. Usage: Toggle Category Off Command", client, gBuff);

		return Plugin_Handled;
	}

	int[] targets = new int[MaxClients];
	int targets_count = GetCmdTargets(1, client, targets, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

	if(targets_count <= 0)
		return Plugin_Handled;

	CategoryId categoryId;
	char categoryName[64];

	if(!GetCategoryIdFromArgs(client, 2, categoryId, categoryName, sizeof(categoryName)))
		return Plugin_Handled;

	bool print_server = view_as<bool>(kv.GetNum("Toggle Category Off Print Server", 0));
	bool print_admin = view_as<bool>(kv.GetNum("Toggle Category Off Print Admin", 1));

	for(int i; i < targets_count; i++)
	{
		Shop_ToggleClientCategoryOff(targets[i], categoryId);

		if((!client && print_server) || (client && print_admin))
			CGOPrintToChat(targets[i], "%T", "Chat. Toggle Category Off Command Message", targets[i], categoryName);
	}
	
	Print_CommandComplete(client);
	return Plugin_Handled;
}

public Action Commands_ChangeDuration(int client, int args)
{
	if(args < 4)
	{
		GetCmdArg(0, gBuff, sizeof(gBuff));
		ReplyToCommand(client, "%T", "Reply. Usage: Change Duration Command", client, gBuff);

		return Plugin_Handled;
	}

	int[] targets = new int[MaxClients];
	int targets_count = GetCmdTargets(1, client, targets, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

	if(targets_count <= 0)
		return Plugin_Handled;

	GetCmdArg(4, gBuff, sizeof(gBuff));
	int duration = StringToInt(gBuff);

	ItemType itemType;
	CategoryId categoryId;
	ItemId itemId;
	char itemName[64], categoryName[64];

	if(!GetCategoryIdFromArgs(client, 2, categoryId, categoryName, sizeof(categoryName)))
		return Plugin_Handled;

	if(!GetItemIdFromArgs(client, 3, categoryId, itemId, itemType, itemName, sizeof(itemName)))
		return Plugin_Handled;

	if(Shop_GetItemType(itemId) != Item_Togglable)
	{
		ReplyToCommand(client, "%T", "Reply. Item State Not Supported Togglable", client);
		return Plugin_Handled;
	}

	bool print_server = view_as<bool>(kv.GetNum("Change duration Print Server", 0));
	bool print_admin = view_as<bool>(kv.GetNum("Change duration Print Admin", 1));

	for(int i, my_duration; i < targets_count; i++)
	{
		if(!Shop_IsClientHasItem(targets[i], itemId))
			continue;

		if(duration < 0)
			my_duration = Shop_GetClientItemTimeleft(targets[i], itemId) - duration;
		else 
			my_duration = Shop_GetClientItemTimeleft(targets[i], itemId) + duration;

		if(my_duration <= 0)
			my_duration = 1;

		if(Shop_SetClientItemTimeleft(targets[i], itemId, (duration == 0 ? duration : my_duration)) && (!client && print_server) || (client && print_admin))
		{
			if(duration == 0)
				Format(gBuff, sizeof(gBuff), "%T", "Chat. Set Infinitely", targets[i]);

			CGOPrintToChat(targets[i], "%T", "Chat. Change Duration Command Message", targets[i], itemName, categoryName, (duration == 0 ? gBuff : ""));
		}
	}
	
	Print_CommandComplete(client);
	return Plugin_Handled;
}

public Action Commands_BuyItem(int client, int args)
{
	if(args < 3)
	{
		GetCmdArg(0, gBuff, sizeof(gBuff));
		ReplyToCommand(client, "%T", "Reply. Usage: Buy Item Command", client, gBuff);

		return Plugin_Handled;
	}

	int[] targets = new int[MaxClients];
	int targets_count = GetCmdTargets(1, client, targets, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

	if(targets_count <= 0)
		return Plugin_Handled;

	GetCmdArg(4, gBuff, sizeof(gBuff));
	int count = gBuff[0] ? StringToInt(gBuff) : 1;

	if(count <= 0)
		count = 1;

	ItemType itemType;
	CategoryId categoryId;
	ItemId itemId;
	char itemName[64], categoryName[64];

	if(!GetCategoryIdFromArgs(client, 2, categoryId, categoryName, sizeof(categoryName)))
		return Plugin_Handled;

	if(!GetItemIdFromArgs(client, 3, categoryId, itemId, itemType, itemName, sizeof(itemName)))
		return Plugin_Handled;

	if(Shop_GetItemHide(itemId))
	{
		ReplyToCommand(client, "%T", "Reply. Item Hidden", client);
		return Plugin_Handled;
	}

	if(itemType == Item_Togglable)
		count = 1;

	bool print_server = view_as<bool>(kv.GetNum("Buy Item Print Server", 0));
	bool print_admin = view_as<bool>(kv.GetNum("Buy Item Print Admin", 1));

	int item_price = Shop_GetItemPrice(itemId);
	if(item_price < 0)
		item_price = 0;

	int need_credits = item_price * count;

	bool iBuyed;
	for(int i; i < targets_count; i++)
	{
		if(Shop_GetClientCredits(targets[i]) < need_credits)
			continue;

		iBuyed = false;
		for(int c; c < count; c++)	if(Shop_BuyClientItem(targets[i], itemId) && !iBuyed)
			iBuyed = true;

		if(iBuyed && (!client && print_server) || (client && print_admin))
		{
			if(count > 1)
				Format(gBuff, sizeof(gBuff), "%T", "Chat. In Count", targets[i], count);

			CGOPrintToChat(targets[i], "%T", "Chat. Buy Item Command Message", targets[i], itemName, categoryName, (count > 1 ? gBuff : ""));
		}
	}

	Print_CommandComplete(client);
	return Plugin_Handled;
}

public Action Commands_SellItem(int client, int args)
{
	if(args < 3)
	{
		GetCmdArg(0, gBuff, sizeof(gBuff));
		ReplyToCommand(client, "%T", "Reply. Usage: Sell Item Command", client, gBuff);

		return Plugin_Handled;
	}

	int[] targets = new int[MaxClients];
	int targets_count = GetCmdTargets(1, client, targets, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

	if(targets_count <= 0)
		return Plugin_Handled;

	GetCmdArg(4, gBuff, sizeof(gBuff));
	int count = gBuff[0] ? StringToInt(gBuff) : 1;

	if(count <= 0)
		count = 1;

	ItemType itemType;
	CategoryId categoryId;
	ItemId itemId;
	char itemName[64], categoryName[64];

	if(!GetCategoryIdFromArgs(client, 2, categoryId, categoryName, sizeof(categoryName)))
		return Plugin_Handled;

	if(!GetItemIdFromArgs(client, 3, categoryId, itemId, itemType, itemName, sizeof(itemName)))
		return Plugin_Handled;

	if(Shop_GetItemSellPrice(itemId) <= 0)
	{
		ReplyToCommand(client, "%T", "Reply. Item Sell Price Is 0", client);
		return Plugin_Handled;
	}

	if(itemType == Item_Togglable)
		count = 1;

	bool print_server = view_as<bool>(kv.GetNum("Sell Item Print Server", 0));
	bool print_admin = view_as<bool>(kv.GetNum("Sell Item Print Admin", 1));

	bool iSelled;
	for(int i; i < targets_count; i++)
	{
		if(!Shop_IsClientHasItem(targets[i], itemId))
			continue;

		iSelled = false;
		for(int c; c < count; c++)	if(Shop_SellClientItem(targets[i], itemId) && !iSelled)
			iSelled = true;

		if(iSelled && (!client && print_server) || (client && print_admin))
		{
			if(count > 1)
				Format(gBuff, sizeof(gBuff), "%T", "Chat. In Count", targets[i], count);

			CGOPrintToChat(targets[i], "%T", "Chat. Sell Item Command Message", targets[i], itemName, categoryName, (count > 1 ? gBuff : ""));
		}
	}

	Print_CommandComplete(client);
	return Plugin_Handled;
}

public Action Commands_UseItem(int client, int args)
{
	if(args < 3)
	{
		GetCmdArg(0, gBuff, sizeof(gBuff));
		ReplyToCommand(client, "%T", "Reply. Usage: Use Item Command", client, gBuff);

		return Plugin_Handled;
	}

	int[] targets = new int[MaxClients];
	int targets_count = GetCmdTargets(1, client, targets, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);

	if(targets_count <= 0)
		return Plugin_Handled;

	GetCmdArg(4, gBuff, sizeof(gBuff));
	int count = gBuff[0] ? StringToInt(gBuff) : 1;

	if(count <= 0)
		count = 1;

	ItemType itemType;
	CategoryId categoryId;
	ItemId itemId;
	char itemName[64], categoryName[64];

	if(!GetCategoryIdFromArgs(client, 2, categoryId, categoryName, sizeof(categoryName)))
		return Plugin_Handled;

	if(!GetItemIdFromArgs(client, 3, categoryId, itemId, itemType, itemName, sizeof(itemName)))
		return Plugin_Handled;

	if(itemType != Item_Finite)
	{
		ReplyToCommand(client, "%T", "Reply. Item State Not Supported Finite", client);
		return Plugin_Handled;
	}

	if(itemType == Item_Togglable)
		count = 1;

	bool print_server = view_as<bool>(kv.GetNum("Use Item Print Server", 0));
	bool print_admin = view_as<bool>(kv.GetNum("Use Item Print Admin", 1));

	bool iUsed;
	for(int i; i < targets_count; i++)
	{
		if(!Shop_IsClientHasItem(targets[i], itemId))
			continue;

		iUsed = false;
		for(int c; c < count; c++)	if(Shop_UseClientItem(targets[i], itemId) && !iUsed)
			iUsed = true;

		if(iUsed && (!client && print_server) || (client && print_admin))
		{
			if(count > 1)
				Format(gBuff, sizeof(gBuff), "%T", "Chat. In Count", targets[i], count);

			CGOPrintToChat(targets[i], "%T", "Chat. Use Item Command Message", targets[i], itemName, categoryName, (count > 1 ? gBuff : ""));
		}
	}

	Print_CommandComplete(client);
	return Plugin_Handled;
}

stock void Print_CommandComplete(int client)
{
	ReplyToCommand(client, "%T", "Reply. Command Complete", client);
}

public int GetCmdTargets(int arg, int client, int[] targets, int flags)
{
	bool tn_is_ml;

	GetCmdArg(arg, gBuff, sizeof(gBuff));
	int targets_count = ProcessTargetString(gBuff, client, targets, MaxClients, flags, gSecBuff, sizeof(gSecBuff), tn_is_ml);

	if(targets_count <= 0)
		ReplyToCommand(client, "%T", "Reply. Players Not Found", client);

	return targets_count;
}

stock bool GetCategoryIdFromArgs(int client, int category_arg, CategoryId &categoryId, char[] name, int len)
{
	GetCmdArg(category_arg, gBuff, sizeof(gBuff));
	categoryId = Shop_GetCategoryId(gBuff);

	if(!Shop_IsValidCategory(categoryId))
	{
		ReplyToCommand(client, "%T", "Reply. Category Not Found", client, gBuff);
		return false;
	}

	Shop_GetCategoryNameById(categoryId, name, len);
	return true;
}

stock bool GetItemIdFromArgs(int client, int item_arg, CategoryId categoryId, ItemId &itemId, ItemType &itemType, char[] name, int len)
{
	GetCmdArg(item_arg, gBuff, sizeof(gBuff));
	itemId = Shop_GetItemId(categoryId, gBuff);

	if(!Shop_IsItemExists(itemId))
	{
		ReplyToCommand(client, "%T", "Reply. Item Not Found", client, gBuff);
		return false;
	}

	Shop_GetItemNameById(itemId, name, len);
	itemType = Shop_GetItemType(itemId);
	
	return true;
}