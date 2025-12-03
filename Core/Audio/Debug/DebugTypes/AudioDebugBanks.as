class UAudioDebugBanks: UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::Banks; }

	FString GetTitle() override
	{
		return "Banks";
	}

	TArray<int> BanksWithSelectedState;
	EBankLoadState PreviousState = EBankLoadState(-1);
	TMap<FString, int> BanksMediaSizes;
	float TotalMediaSizeShown = 0;

	void Menu(UHazeAudioDevMenu DevMenu, UAudioDebugManager DebugManager, const FHazeImmediateScrollBoxHandle& Section) override
	{
		auto MenuConfig = DevMenu.MenuDebugConfig;

		auto BankStateBox = Section.HorizontalBox();
		BankStateBox.Text("Banks In State:");

		auto BankStateComboBox = BankStateBox
			.ComboBox()
			.Tooltip("Mutes audio posted by either Remote|Control|None side")
			.Items(DevMenu.BankStateSelections)
			.Value(DevMenu.BankStateSelections[MenuConfig.MiscFlags.SelectedBankState]);

		if (BankStateComboBox.GetSelectedIndex() != int(MenuConfig.MiscFlags.SelectedBankState))
		{
			MenuConfig.MiscFlags.SelectedBankState = EBankLoadState(BankStateComboBox.GetSelectedIndex());
			MenuConfig.Save();
		}

		bool bRefresh = BankStateBox
			.Button("Refresh")
			.Tooltip("Update the list of bank states");

		if (bRefresh || PreviousState != MenuConfig.MiscFlags.SelectedBankState)
		{
			PreviousState = MenuConfig.MiscFlags.SelectedBankState;
			BanksWithSelectedState = AudioUtility::GetAllBanksWithState(MenuConfig.MiscFlags.SelectedBankState, bRefresh);
		}

		if (BanksMediaSizes.Num() == 0)
			AudioUtility::GetBanksMediaSizes(BanksMediaSizes);

		Section.Text(f"Total MediaSize Of Shown: {TotalMediaSizeShown}");
	}
	
	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) override
	{
		auto MenuConfig = DebugManager.MenuDebugConfig;

		Section
			.Text("BANKS - " + MenuConfig.MiscFlags.SelectedBankState)
			.Color(FLinearColor::Yellow)
			.Bold()
			.Scale(2.0);

		TotalMediaSizeShown = 0;
		for	(auto BankID: BanksWithSelectedState)
		{
			FString BankName = "Unknown";
			AudioUtility::FindStringFromID(BankID, BankName);
			if (
				DebugManager.IsFiltered(BankName, false, EDebugAudioFilter::Banks) &&
				DebugManager.IsFiltered(f"{uint32(BankID)}", false, EDebugAudioFilter::Banks)
				)
			{
				continue;
			}

			int MediaSizeInBytes = 0;
			BanksMediaSizes.Find(BankName, MediaSizeInBytes);

			float MediaSizeMB = 0;
			if (MediaSizeInBytes != 0)
			{
				MediaSizeMB = float(MediaSizeInBytes)/(1024*1024);
				TotalMediaSizeShown += MediaSizeMB;
			}

			auto VLBox = Section.HorizontalBox();
			VLBox.SlotPadding(50,0,0,0).Text(f"{BankName} - {MediaSizeMB} MB , ID: {uint32(BankID)}");
		}
	}
}