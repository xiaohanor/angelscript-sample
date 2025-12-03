delegate void FOnToggleBoolChanged(bool bNewState);

enum EDevToggleEmpty
{
	Empty,
}

struct FHazeDevToggleBool
{
#if !RELEASE
	FName TogglePath;
	FString ToggleTooltip;
#endif

	FHazeDevToggleBool()
	{
#if !RELEASE
		InitFromGlobalVariable("");
#endif	
	}

#if !RELEASE
	void InitFromGlobalVariable(const FString& Suffix)
	{
		FString Namespace = Script::GetNamespaceOfGlobalVariableBeingInitialized();

		TArray<FString> NamespaceParts;
		Namespace.ParseIntoArray(NamespaceParts, "::");

		FString Category;
		FString NamespacePath;

		for (FString& Part : NamespaceParts)
		{
			Part.RemoveFromStart("DevToggles");
			Part.RemoveFromEnd("DevToggles");
			Part = Part.ToDisplayName();

			if (Part.IsEmpty())
				continue;

			if (Category.IsEmpty())
				Category = Part;

			if (!NamespacePath.IsEmpty())
				NamespacePath += "/";
			NamespacePath += Part;
		}

		FString Variable = Script::GetNameOfGlobalVariableBeingInitialized();
		Variable.RemoveFromStart("DevToggle_");
		Variable = Variable.ToDisplayName();
		Variable += Suffix;
		if (Variable.IsEmpty())
			return;

		if (NamespacePath.IsEmpty())
		{
			NamespacePath = "Level Specific";
			Category = "Level Specific";
		}

		TogglePath = FName(NamespacePath + "/" + Variable);
		// Log(f"{TogglePath=}");
		// Log(f"{Category=}");
		DevMenu::AddTogglesCategoryAssociation(FName(Category), TogglePath);
	}
#endif	


	FHazeDevToggleBool(FHazeDevToggleCategory Category, FName Name, FString Tooltip = "")
	{
#if !RELEASE
		TogglePath = FName(Category.CategoryName + "/" + Name);
		ToggleTooltip = Tooltip;
		DevMenu::AddTogglesCategoryAssociation(Category.CategoryName, TogglePath);
		if (!Tooltip.IsEmpty())
			DevMenu::AddDevToggleTooltip(TogglePath, Tooltip);
#endif	
	}

	FHazeDevToggleBool(FHazeDevToggleCategory Category, FName SubCategory, FName Name, FString Tooltip = "")
	{
#if !RELEASE
		TogglePath = FName(Category.CategoryName + "/" + SubCategory + "/" + Name);
		ToggleTooltip = Tooltip;
		DevMenu::AddTogglesCategoryAssociation(Category.CategoryName, TogglePath);
		if (!Tooltip.IsEmpty())
			DevMenu::AddDevToggleTooltip(TogglePath, Tooltip);
#endif	
	}

	void BindOnChanged(UObject Object, FName FunctionName) const
	{
#if !RELEASE
		FHazeInternalDevToggleBool& Internal = UHazeDevToggleSubsystem::Get().GetInternalBool(TogglePath, false);
		Internal.OnChanged.AddUFunction(Object, FunctionName);
#endif	
	}

	void MakeVisible() const
	{
#if !RELEASE
		FHazeInternalDevToggleBool& bNoWarningPlz = UHazeDevToggleSubsystem::Get().GetInternalBool(TogglePath, true);
#endif	
	}

	bool IsEnabled() const
	{
#if !RELEASE
		bool bNoWarningPlz = true;
		if (bNoWarningPlz)
			return UHazeDevToggleSubsystem::Get().GetInternalBool(TogglePath, false).bState;
#endif
		return false;
	}

	FHazeDevToggleBool(EDevToggleEmpty Empty)
	{
	}
}

struct FHazeDevToggleBoolPerPlayer
{
	access KindaPrivate = private, FHazeDevTogglePreset;

	private FHazeDevToggleBool MioBool(EDevToggleEmpty::Empty);
	private FHazeDevToggleBool ZoeBool(EDevToggleEmpty::Empty);
	private FName MioName;
	private FName ZoeName;
	access:KindaPrivate FName MioPath;
	access:KindaPrivate FName ZoePath;

	FHazeDevToggleBoolPerPlayer()
	{
#if !RELEASE
		MioBool.InitFromGlobalVariable(" Mio");
		MioPath = MioBool.TogglePath;

		ZoeBool.InitFromGlobalVariable(" Zoe");
		ZoePath = ZoeBool.TogglePath;
#endif	
	}

	FHazeDevToggleBoolPerPlayer(FHazeDevToggleCategory Category, FName Name, FString Tooltip = "")
	{
#if !RELEASE
		MioName = FName(Name.ToString() + " Mio");
		MioBool = FHazeDevToggleBool(Category, MioName, Tooltip);
		ZoeName = FName(Name.ToString() + " Zoe");
		ZoeBool = FHazeDevToggleBool(Category, ZoeName, Tooltip);
		MioPath = FName(Category.CategoryName + "/" + MioName);
		ZoePath = FName(Category.CategoryName + "/" + ZoeName);
#endif	
	}

	FHazeDevToggleBoolPerPlayer(FHazeDevToggleCategory Category, FName SubCategory, FName Name, FString Tooltip = "")
	{
#if !RELEASE
		MioName = FName(Name.ToString() + " Mio");
		MioBool = FHazeDevToggleBool(Category, SubCategory, MioName, Tooltip);
		ZoeName = FName(Name.ToString() + " Zoe");
		ZoeBool = FHazeDevToggleBool(Category, SubCategory, ZoeName, Tooltip);
		MioPath = FName(Category.CategoryName + "/" + SubCategory + "/" + MioName);
		ZoePath = FName(Category.CategoryName + "/" + SubCategory + "/" + ZoeName);
#endif	
	}

	void MakeVisible() const
	{
#if !RELEASE
		FHazeInternalDevToggleBool bNoWarningPlz = UHazeDevToggleSubsystem::Get().GetInternalBool(MioPath, true);
		bNoWarningPlz = UHazeDevToggleSubsystem::Get().GetInternalBool(ZoePath, true);
#endif	
	}

	bool IsEnabled(const AHazePlayerCharacter Player) const
	{
#if !RELEASE
		if (Player == nullptr)
			return false;
		if (Player.IsMio())
			return UHazeDevToggleSubsystem::Get().GetInternalBool(MioPath, false).bState;
		if (Player.IsZoe())
			return UHazeDevToggleSubsystem::Get().GetInternalBool(ZoePath, false).bState;
#endif
		return false;
	}
}
