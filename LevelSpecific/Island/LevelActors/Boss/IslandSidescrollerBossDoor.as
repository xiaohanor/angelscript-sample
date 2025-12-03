class AIslandSidescrollerBossDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditInstanceOnly)
	AIslandSidescrollerBossDoorResistEffect ResistEffect;

	UPROPERTY(EditInstanceOnly)
	float ClosingDistance;

	UPROPERTY(EditInstanceOnly)
	bool bRight;

	FHazeAcceleratedVector AccLocation;
	FVector OpenLocation;
	FVector ClosedLocation;
	bool bClose;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenLocation = ActorLocation;
		ClosedLocation = ActorLocation + ActorRightVector * ClosingDistance;
		AccLocation.SnapTo(OpenLocation);
	}

	void StartClosing()
	{
		bClose = true;
	}

	void StopClosing()
	{
		bClose = false;
	}

	void InstantClose()
	{
		ActorLocation = ClosedLocation;
	}

	float GetDistanceFromClosed() property
	{
		return ActorLocation.Distance(ClosedLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bClose)
			return;
		AccLocation.AccelerateTo(ClosedLocation, 10, DeltaSeconds);
		ActorLocation = AccLocation.Value;
	}
}