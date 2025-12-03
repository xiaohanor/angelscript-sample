event void FSkylineDaClubVIPElevatorSignature();

class ASkylineDaClubVIPElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftDoorPivot;

	UPROPERTY(DefaultComponent)
	USceneComponent RightDoorPivot;

	UPROPERTY(EditAnywhere)
	float Angle = 90.0;

	UPROPERTY(EditAnywhere)
	bool bStartClosed = false;

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor DoubleInteraction;

	UPROPERTY()
	FSkylineDaClubVIPElevatorSignature OnClosed;

	UPROPERTY()
	FSkylineDaClubVIPElevatorSignature OnOpened;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike DoorAnimation;
	default DoorAnimation.Duration = 3.0;
	default DoorAnimation.bCurveUseNormalizedTime = true;
	default DoorAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default DoorAnimation.Curve.AddDefaultKey(1.0, 1.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoorAnimation.BindUpdate(this, n"HandleDoorAnimationUpdate");
		DoorAnimation.BindFinished(this, n"HandleDoorAnimationFinished");
	
		if (DoubleInteraction != nullptr)
			DoubleInteraction.DisableDoubleInteraction(this);

		if (bStartClosed)
		{
			DoorAnimation.SetNewTime(DoorAnimation.Duration);
			HandleDoorAnimationUpdate(DoorAnimation.Value);
		}
	}

	UFUNCTION()
	private void HandleDoorAnimationUpdate(float CurrentValue)
	{
		LeftDoorPivot.RelativeRotation = FRotator(0.0, -Angle * CurrentValue, 0.0);
		RightDoorPivot.RelativeRotation = FRotator(0.0, Angle * CurrentValue, 0.0);
	}

	UFUNCTION()
	private void HandleDoorAnimationFinished()
	{
		if (!DoorAnimation.IsReversed())
		{
			if (DoubleInteraction != nullptr)
				DoubleInteraction.DisableDoubleInteraction(this);

			OnClosed.Broadcast();
		}
		else
		{
			if (DoubleInteraction != nullptr)
				DoubleInteraction.EnableDoubleInteraction(this);

			OnOpened.Broadcast();
		}
	}

	UFUNCTION()
	void CloseDoors()
	{
		DoorAnimation.Play();
	}

	UFUNCTION()
	void OpenDoors()
	{
		DoorAnimation.Reverse();
	}
};