
UCLASS(Config = EditorUserSettings)
class UAudioOverviewConfigWidget : UHazeAudioOverviewConfigWidget
{
	UPROPERTY(Meta = (BindWidget))
	UHazeImmediateWidget Content;

	UPROPERTY()
	bool bAskAutoConnectToWaapi = true;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
	}
	
	void TickWidget(FGeometry MyGeometry, float InDeltaTime)
	{
		if (Content == nullptr)
			return;

		if (!Content.Drawer.IsVisible())
			return;

		auto UserSettings = Cast<UAkSettingsPerUser>(UAkSettingsPerUser.GetDefaultObject());
		CheckUsersWaapiConnection(UserSettings);

		auto ContentSection = Content.Drawer.Begin("Config");

		ContentSection.Text("Configs/Settings related to audio here!");

		bool bConnectionEnabled = ContentSection
			.CheckBox()
			.Checked(UserSettings.bAutoConnectToWAAPI)
			.Label("Auto connect to Wwise")
			.Tooltip("If Unreal should auto create a connection with Wwise through Waapi");

		if (bConnectionEnabled != UserSettings.bAutoConnectToWAAPI)
		{
			UserSettings.Modify();
			UserSettings.bAutoConnectToWAAPI = bConnectionEnabled;
			UHazeAudioEditorUtils::OnWaapiAutoConnectChanged();
		}

		Content.Drawer.End();
	}

	void CheckUsersWaapiConnection(UAkSettingsPerUser UserSettings)
	{
		if (!bAskAutoConnectToWaapi)
			return;
		
		if (UserSettings.bAutoConnectToWAAPI)
			return;

		// Get the absolute path to the wwise project
		auto Root = FPaths::RootDir();
		auto WwisePath = f"{Root}../Source/Audio/Wwise/Split/Split.wproj";
		auto AbsoluteWwisePath = FPaths::ConvertRelativePathToFull(WwisePath);
		if (FPaths::FileExists(AbsoluteWwisePath))
		{
			if (EditorDialog::ShowMessage(
				FText::FromString("Connect to Wwise?"),
				FText::FromString(f"You have Wwise installed, want to auto connect when opened? \n {AbsoluteWwisePath}"),
				EAppMsgType::YesNo,
				EAppReturnType::Yes
				) == EAppReturnType::Yes)
			{
				UserSettings.Modify();
				UserSettings.bAutoConnectToWAAPI = true;
			}

			bAskAutoConnectToWaapi = false;
		}
	}
}