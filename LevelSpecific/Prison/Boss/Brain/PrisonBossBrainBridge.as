UCLASS(Abstract)
class APrisonBossBrainBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BridgeRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveBridgeTimeLike;

	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveBridgeTimeLike.BindUpdate(this, n"UpdateMove");
		MoveBridgeTimeLike.BindFinished(this, n"FinishMove");

		StartLocation = ActorLocation;
	}

	UFUNCTION()
	void ExtendBridge()
	{
		SetAttachedActorsVisibility(false);
		MoveBridgeTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void RetractBridge()
	{
		MoveBridgeTimeLike.ReverseFromEnd();
	}

	UFUNCTION()
	private void UpdateMove(float CurValue)
	{
		FVector Loc = Math::Lerp(StartLocation, StartLocation + (ActorForwardVector * 2500.0), CurValue);
		SetActorLocation(Loc);
	}

	UFUNCTION()
	private void FinishMove()
	{
		if (MoveBridgeTimeLike.IsReversed())
			SetAttachedActorsVisibility(true);
	}

	void SetAttachedActorsVisibility(bool bHide)
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			Actor.SetActorHiddenInGame(bHide);
		}
	}

	UFUNCTION()
	void SnapExtend()
	{
		SetActorLocation(StartLocation + (ActorForwardVector * 2500.0));
		SetAttachedActorsVisibility(false);
	}
}