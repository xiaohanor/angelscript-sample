class ASanctuaryWellSlope : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent ArrowComp;

	UPROPERTY()
	FSlideParameters SlideParams;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleImpactStarted");
		ImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"HandleImpactEnded");
		
		SlideParams.SlideWorldDirection = ArrowComp.ForwardVector;
	}

	UFUNCTION()
	private void HandleImpactStarted(AHazePlayerCharacter Player)
	{
		Player.ForcePlayerSlide(this, SlideParams);
	}

	UFUNCTION()
	private void HandleImpactEnded(AHazePlayerCharacter Player)
	{
		Player.ClearForcePlayerSlide(this);
	}
};