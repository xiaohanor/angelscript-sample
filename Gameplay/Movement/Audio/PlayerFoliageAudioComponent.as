class UPlayerFoliageAudioComponent : UActorComponent
{
	UPROPERTY()
	bool bBlocked = false;

	UPROPERTY()
	float MakeupGainAlpha = 1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bBlocked = false;
		MakeupGainAlpha = 1;
	}
};