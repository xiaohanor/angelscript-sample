class UMoonMarketPlayerSwimmingSettingsComponent : UActorComponent
{
	UPROPERTY()
	UPlayerSwimmingSettings SwimmingSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		Player.ApplySettings(SwimmingSettings, this, EHazeSettingsPriority::Override);
	}
};