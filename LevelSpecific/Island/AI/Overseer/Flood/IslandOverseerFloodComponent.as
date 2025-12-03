class UIslandOverseerFloodComponent : UActorComponent
{
	UPROPERTY()
	bool bStopSettingRespawnPoints;

	TArray<AIslandOverseerFloodShootablePlatform> Platforms;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Platforms = TListedActors<AIslandOverseerFloodShootablePlatform>().GetArray();
	}

	UFUNCTION()
	void OpenAllPlatforms()
	{
		for(AIslandOverseerFloodShootablePlatform Platform : Platforms)
		{
			Platform.CompletelyOpen(true);
		}
	}
}