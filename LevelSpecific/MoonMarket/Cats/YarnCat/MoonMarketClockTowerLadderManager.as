class AMoonMarketClockTowerLadderManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditInstanceOnly)
	ALadder Ladder;
	FVector OriginalLocation;

	float OffsetHeight = 800;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Ladder.bHasDecidedMobility = false;
		OriginalLocation = Ladder.ActorRelativeLocation; 
		Ladder.ActorRelativeLocation += FVector(0,0,OffsetHeight);
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Ladder.ActorRelativeLocation = Math::VInterpConstantTo(Ladder.ActorRelativeLocation, OriginalLocation, DeltaSeconds, OffsetHeight / 1.5);
		if (Ladder.ActorRelativeLocation == OriginalLocation)
			SetActorTickEnabled(false);
	}

	UFUNCTION()
	void LowerLadder()
	{
		SetActorTickEnabled(true);
	}
};