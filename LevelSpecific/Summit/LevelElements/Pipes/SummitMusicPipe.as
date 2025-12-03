event void FOnSummitPipeActivated(ASummitMusicPipe Pipe);

enum ESummitMusicPipe
{
	Acid,
	Tail
}

class ASummitMusicPipe : AHazeActor
{
	UPROPERTY()
	ESummitMusicPipe PipeType;

	UPROPERTY()
	FOnSummitPipeActivated OnSummitPipeActivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent SymbolMeshComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY()
	TArray<FRotator> SymbolMeshRotations;

	UPROPERTY(EditAnywhere)
	int Type;

	float TimeSinceLastEvent;
	float EventDuration = 1.5;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (Type < SymbolMeshRotations.Num() && Type >= 0)
			SymbolMeshComp.SetRelativeRotation(SymbolMeshRotations[Type]);
	}

	void ActivatePipeEvent()
	{
		if (Time::GameTimeSeconds < TimeSinceLastEvent)
			return;

		TimeSinceLastEvent = Time::GameTimeSeconds + EventDuration;
		OnSummitPipeActivated.Broadcast(this);
	}
};
