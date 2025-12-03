class USkylineGeckoBlobComponent : UActorComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		USkylineGeckoSettings GeckoSettings = USkylineGeckoSettings::GetSettings(Cast<AHazeActor>(Owner));
		BlobCooldown.Set(GeckoSettings.BlobInitialCooldown);
	}

	FBasicBehaviourCooldown BlobCooldown;
	AHazePlayerCharacter CurrentTarget;
}