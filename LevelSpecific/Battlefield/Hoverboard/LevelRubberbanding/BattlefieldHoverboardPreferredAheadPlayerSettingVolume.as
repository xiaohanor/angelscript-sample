class ABattlefieldPreferredAheadPlayerSettingVolume : APlayerTrigger
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	EHazePlayer NewPreferredAheadPlayer = EHazePlayer::Mio;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"PlayerEntered");
	}

	UFUNCTION(NotBlueprintCallable)
	private void PlayerEntered(AHazePlayerCharacter Player)
	{
		auto PlayerSettings = UBattlefieldHoverboardLevelRubberbandingSettings::GetSettings(Player);
		auto OtherPlayerSettings = UBattlefieldHoverboardLevelRubberbandingSettings::GetSettings(Player.OtherPlayer);

		PlayerSettings.bOverride_PreferredAheadPlayer = true;
		OtherPlayerSettings.bOverride_PreferredAheadPlayer = true;

		PlayerSettings.PreferredAheadPlayer = NewPreferredAheadPlayer;
		OtherPlayerSettings.PreferredAheadPlayer = NewPreferredAheadPlayer;
	}
};