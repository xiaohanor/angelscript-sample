event void FSummitDarkCaveChainedBallGoalSignature();

class ASummitDarkCaveChainedBallGoal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent BallTargetLocation;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float BallRadius = 300.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DownOffset = 500.0;

	UPROPERTY()
	FSummitDarkCaveChainedBallGoalSignature OnCompleted;

	bool bSinkingOn;

	FVector EndLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EndLoc = ActorLocation - FVector(0,0,DownOffset);
	}

	UFUNCTION(CallInEditor)
	void PlaceBallTargetAboveRoot()
	{
		BallTargetLocation.WorldLocation = ActorLocation + (FVector::UpVector * BallRadius);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(BallTargetLocation.WorldLocation, BallRadius, 12, FLinearColor::Red, 10, 0.0, false);
	}
#endif

	UFUNCTION(BlueprintEvent)
	void BP_ActivateGoal()
	{
		OnCompleted.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivateGoal()
	{
	}

	void StartSinking()
	{
		bSinkingOn = true;
	}
};