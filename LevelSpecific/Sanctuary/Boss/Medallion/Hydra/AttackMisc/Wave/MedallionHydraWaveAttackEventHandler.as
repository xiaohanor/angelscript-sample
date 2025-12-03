struct FMedallionHydraWaveAttackPlatformData
{
	UPROPERTY()
	ABallistaHydraSplinePlatform Platform;
}

class UMedallionHydraWaveAttackEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartWaveAttack() 
	{
	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaveAttackPlatformLaunch(FMedallionHydraWaveAttackPlatformData NewData) 
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaveAttackPlayerLaunch(FMedallionHydraPlayerData NewData) 
	{
	}	
}