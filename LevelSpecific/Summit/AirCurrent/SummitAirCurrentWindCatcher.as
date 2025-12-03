class ASummitAirCurrentWindCatcher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Meshroot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PullRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PulleyRoot;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent Rotator;

	UPROPERTY()
	FVector Startloc;
	FVector Targetloc;

	UPROPERTY(EditAnywhere)
	float ActiveDuration;

	UPROPERTY(EditAnywhere)
	ASummitAirCurrent PairedCurrent;

	UPROPERTY(EditAnywhere)
	APulleyInteraction Pulley;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	//	Startloc = FVector(0,0,0);
	//	Targetloc = FVector(-2000,0,0);
		Pulley.OnSummitPulleyReleased.AddUFunction(this, n"PulleyReleased");
	}
/*
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PulleyRoot.RelativeLocation = Math::Lerp(Startloc, Targetloc, Pulley.PullAlpha);
	}
	*/
	UFUNCTION()
	private void PulleyReleased()
	{
		if(Pulley.PullAlpha > 0.9)
			BP_PulleyReleased();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_PulleyReleased()
	{
	}
}