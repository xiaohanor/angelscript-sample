UCLASS(Abstract)
class AMeltdownPlayerGlitchIndicator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	bool bIndicatorActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorHiddenInGame(true);
	}

	void ActivateIndicator()
	{
		bIndicatorActive = true;
		SetActorHiddenInGame(false);
		BP_ActivateIndicator();
	}

	void DeactivateIndicator()
	{
		bIndicatorActive = false;
		BP_ActivateIndicator();
		SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateIndicator() {}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivateIndicator() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}
};