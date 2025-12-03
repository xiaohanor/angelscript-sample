class AMeltdownBossFlyingPhaseManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	bool bPhaseOneDone;
	UPROPERTY()
	bool FallingDone;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};