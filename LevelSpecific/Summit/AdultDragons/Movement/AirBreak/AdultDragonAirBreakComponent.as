class UAdultDragonAirBreakComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UAdultDragonAirBreakSettings Settings;

	bool bIsBreaking = false;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		Player.ApplyDefaultSettings(Settings);
	}
};