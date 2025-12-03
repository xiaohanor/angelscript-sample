event void FIslandFlipFlopActorSignature();

class AIslandFlipFlopActor : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Destination;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;

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
	FIslandFlipFlopActorSignature OnActivated;

	UPROPERTY()
	FIslandTimeLikeBaseSignature OnReachedFirstDestination;

	UPROPERTY()
	bool bReachedFirstDestination;
	bool bIsPlaying;
	bool bMovingBack;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableObject.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = Destination.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

	}

	UFUNCTION()
	void Play()
	{
		if(bIsPlaying)
			return;

		if (!bReachedFirstDestination)
		{
			MoveAnimation.SetPlayRate(1.0 * 2.8);
			MoveAnimation.PlayFromStart();
			OnActivated.Broadcast();

		}
			

	}

	UFUNCTION()
	void Reverse()
	{
		if(bIsPlaying)
			return;

		if (bReachedFirstDestination)
		{
			MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
			MoveAnimation.ReverseFromEnd();
		}

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
		
		if (!bReachedFirstDestination)
			bReachedFirstDestination = true;
		else
			bReachedFirstDestination = false;

		OnReachedFirstDestination.Broadcast();
	}

}