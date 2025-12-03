event void FOnBattlefieldLoopSequenceShouldStart(AHazePlayerCharacter LeftPlayer);

class ABattlefieldLoopSequenceManager : AHazeActor
{
	UPROPERTY()
	FOnBattlefieldLoopSequenceShouldStart OnBattlefieldLoopSequenceShouldStart;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15.0));
#endif

	UPROPERTY(EditAnywhere)
	APropLine Spline1;

	UPROPERTY(EditAnywhere)
	APropLine Spline2;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	UBattlefieldHoverboardGrindSplineComponent GrindComp1;
	UBattlefieldHoverboardGrindSplineComponent GrindComp2;

	bool bHaveTriggered;
	bool bCanTrigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrindComp1 = UBattlefieldHoverboardGrindSplineComponent::Get(Spline1);
		GrindComp2 = UBattlefieldHoverboardGrindSplineComponent::Get(Spline2);

		GrindComp1.OnPlayerStoppedGrinding.AddUFunction(this, n"OnPlayerStoppedGrinding");
		GrindComp2.OnPlayerStoppedGrinding.AddUFunction(this, n"OnPlayerStoppedGrinding");

		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		bCanTrigger = true;
	}

	UFUNCTION()
	private void OnPlayerStoppedGrinding(UBattlefieldHoverboardGrindSplineComponent GrindComp,
	                                     AHazePlayerCharacter Player)
	{
		if (!HasControl())
			return;

		if (bHaveTriggered)
			return;

		if (!bCanTrigger)
			return;

		bHaveTriggered = true;

		if (GrindComp == GrindComp1)
		{
			//We are on left one
			CrumbActivateSequence(Player);
		}
		else
		{
			CrumbActivateSequence(Player.OtherPlayer);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivateSequence(AHazePlayerCharacter LeftPlayer)
	{
		// Player.(CapabilityTags::MovementInput, this);
		OnBattlefieldLoopSequenceShouldStart.Broadcast(LeftPlayer);
	}
};