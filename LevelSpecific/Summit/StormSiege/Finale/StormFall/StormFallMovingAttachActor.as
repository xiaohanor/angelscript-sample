class AStormFallMovingAttachActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent BillboardComp;
	default BillboardComp.SetWorldScale3D(FVector(15.0));
	default BillboardComp.SpriteName = "S_VectorFieldVol";

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditAnywhere)
	FVector StartingOffset;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve MoveCurve;
	default MoveCurve.AddDefaultKey(0.0, 0.0);
	default MoveCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditAnywhere)
	float Duration = 2.5;
	float CurrentTime;

	FVector StartingLoc;
	FVector TargetLoc;

	bool bWasTriggered;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetLoc = ActorLocation;
		StartingLoc = ActorLocation + StartingOffset;
		ActorLocation = StartingLoc; 

		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentTime += DeltaSeconds;
		float Alpha = Math::Clamp(CurrentTime / Duration, 0.0, 1.0);
		ActorLocation = Math::Lerp(StartingLoc, TargetLoc, MoveCurve.GetFloatValue(Alpha));
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		ActivateMovingDebris();
	}

	UFUNCTION()
	void ActivateMovingDebris()
	{
		if (bWasTriggered)
			return;

		bWasTriggered = true;
		SetActorTickEnabled(true);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugBox(ActorLocation + StartingOffset, FVector(800.0, 800.0, 800.0), ActorRotation, FLinearColor::Red, 10.0);
		Debug::DrawDebugLine(ActorLocation, ActorLocation + StartingOffset, FLinearColor::Blue, 10.0);
	}
#endif
};