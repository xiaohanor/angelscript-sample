event void FSummitCoopBranchSignature();

class ASummitCoopBranch : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndingPositionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;

	UPROPERTY(EditAnywhere)
	bool bAutoPlay;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnimation.Curve.AddDefaultKey(1.0, 1.0);

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY()
	FSummitCoopBranchSignature OnActivated;

	UPROPERTY()
	FSummitCoopBranchSignature OnReachedFirstDestination;

	UPROPERTY()
	FSummitCoopBranchSignature OnReachedSecondDestination;

	bool bReachedFirstDestination;
	bool bReachedSceondDestination;
	UPROPERTY()
	bool bIsPlaying;
	bool bMovingBack;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableObject.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = EndingPositionComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		
		if (bAutoPlay)
			MoveAnimation.PlayFromStart();
	}

	UFUNCTION()
	void Start()
	{
		MoveAnimation.Play();
		OnActivated.Broadcast();

	}

	UFUNCTION()
	void Reverse()
	{
		MoveAnimation.Reverse();

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		bIsPlaying = true;

		MovableObject.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		MovableObject.SetWorldRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));

	}

	
	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;

	}

}