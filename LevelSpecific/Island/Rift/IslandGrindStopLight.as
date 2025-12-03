UCLASS(Abstract)
class AIslandGrindStopLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationPivot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndingPositionComp;

	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.4;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY(EditAnywhere)
	bool bStartOpen;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = RotationPivot.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = EndingPositionComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		if (bStartOpen)
		{
			OnUpdate(1);
			BP_OpenBlock();
		}

	}

	UFUNCTION()
	void OpenBlock()
	{
		MoveAnimation.PlayFromStart();
		BP_OpenBlock();
	}

	UFUNCTION()
	void CloseBlock()
	{
		MoveAnimation.ReverseFromEnd();
		BP_CloseBlock();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{

		RotationPivot.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		RotationPivot.SetWorldRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenBlock(){}

	UFUNCTION(BlueprintEvent)
	void BP_CloseBlock(){}

};
