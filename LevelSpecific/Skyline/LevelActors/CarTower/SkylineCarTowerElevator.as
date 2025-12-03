event void FSkylineCarTowerElevator();

class ASkylineCarTowerElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftDoor;
	UPROPERTY(DefaultComponent, Attach = LeftDoor)
	USceneComponent LeftDoorPivot1;
	UPROPERTY(DefaultComponent, Attach = LeftDoor)
	USceneComponent LeftDoorPivot2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightDoor;
	UPROPERTY(DefaultComponent, Attach = RightDoor)
	USceneComponent RightDoorPivot1;
	UPROPERTY(DefaultComponent, Attach = RightDoor)
	USceneComponent RightDoorPivot2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FrontLeftDoor;
	UPROPERTY(DefaultComponent, Attach = FrontLeftDoor)
	USceneComponent FrontLeftDoorPivot1;
	UPROPERTY(DefaultComponent, Attach = FrontLeftDoor)
	USceneComponent FrontLeftDoorPivot2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FrontRightDoor;
	UPROPERTY(DefaultComponent, Attach = FrontRightDoor)
	USceneComponent FrontRightDoorPivot1;
	UPROPERTY(DefaultComponent, Attach = FrontRightDoor)
	USceneComponent FrontRightDoorPivot2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent ElevatorCamera;

	UPROPERTY(EditAnywhere)
	ABothPlayerTrigger BothPlayerTrigger;

	UPROPERTY(EditAnywhere)
	float DoorOpenDistance1 = 200.0;

	UPROPERTY(EditAnywhere)
	float DoorOpenDistance2 = 50.0;

	UPROPERTY(EditAnywhere)
	float DoorOpenTime = 1.0;

	UPROPERTY(EditAnywhere)
	bool bStartOpen = true;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike DoorAnimation;
	default DoorAnimation.Duration = 1.0;
	default DoorAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default DoorAnimation.Curve.AddDefaultKey(1.0, 1.0);
	default DoorAnimation.bCurveUseNormalizedTime = true;

	UPROPERTY(EditAnywhere)
	float ElevatorHeight = 2000.0;

	UPROPERTY(EditAnywhere)
	float ElevatorTravelTime = 5.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ElevatorAnimation;
	default ElevatorAnimation.Duration = 1.0;
	default ElevatorAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default ElevatorAnimation.Curve.AddDefaultKey(1.0, 1.0);
	default ElevatorAnimation.bCurveUseNormalizedTime = true;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike FrontDoorElevatorAnimation;
	default DoorAnimation.Duration = 1.0;
	default DoorAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default DoorAnimation.Curve.AddDefaultKey(1.0, 1.0);
	default DoorAnimation.bCurveUseNormalizedTime = true;

	FVector InitialRelativeLocation;

	UPROPERTY()
	FSkylineCarTowerElevator OnElevatorActivated;

	UPROPERTY()
	FSkylineCarTowerElevator OnElevatorStop;

	bool bRaised = false;
	bool bEnsureDelayedRaisedCollisionAndNetworkReasons = false;
	bool bDoOnce = true;
	int AliveFrames = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
//		DoorAnimation.NewTime = (bStartOpen ? DoorAnimation.Duration : 0.0);
//		OnDoorUpdate(DoorAnimation.Value);

//		PrintToScreen("DoorAnimation.Value: " + DoorAnimation.Value, 5.0, FLinearColor::Green);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialRelativeLocation = RootComponent.RelativeLocation;

		DoorAnimation.PlayRate = 1.0 / DoorOpenTime;
		ElevatorAnimation.PlayRate = 1.0 / ElevatorTravelTime;

		DoorAnimation.BindUpdate(this, n"OnDoorUpdate");
		DoorAnimation.BindFinished(this, n"OnDoorFinished");

		FrontDoorElevatorAnimation.BindUpdate(this, n"OnFrontDoorUpdate");
		FrontDoorElevatorAnimation.BindFinished(this, n"OnFrontDoorFinished");

		ElevatorAnimation.BindUpdate(this, n"OnElevatorUpdate");
		ElevatorAnimation.BindFinished(this, n"OnElevatorFinished");

		if (BothPlayerTrigger != nullptr)
			BothPlayerTrigger.OnBothPlayersInside.AddUFunction(this, n"ActivateElevator");

//		DoorAnimation.NewTime = (bStartOpen ? DoorAnimation.Duration : 0.0);
//		OnDoorUpdate(DoorAnimation.Value);

		if (bStartOpen)
			OpenDoors();

//		PrintToScreen("DoorAnimation.Value: " + DoorAnimation.Value, 5.0, FLinearColor::Green);
	}

	UFUNCTION()
	private void OnFrontDoorUpdate(float CurrentValue)
	{
		FrontLeftDoorPivot1.RelativeLocation = FVector::RightVector * DoorOpenDistance1 * CurrentValue; 
		FrontRightDoorPivot1.RelativeLocation = -FVector::RightVector * DoorOpenDistance1 * CurrentValue; 

		FrontLeftDoorPivot2.RelativeLocation = FVector::RightVector * DoorOpenDistance2 * CurrentValue; 
		FrontRightDoorPivot2.RelativeLocation = -FVector::RightVector * DoorOpenDistance2 * CurrentValue;
	}

	UFUNCTION()
	private void OnFrontDoorFinished()
	{
	}

	UFUNCTION()
	private void ActivateElevator()
	{
		OnElevatorActivated.Broadcast();
		CloseDoors();
	}

	UFUNCTION()
	void OpenDoors()
	{
		DoorAnimation.Play();
	}

	UFUNCTION()
	void OpenFrontDoors()
	{
		FrontDoorElevatorAnimation.Play();
	}

	UFUNCTION()
	void CloseDoors()
	{
		if(bDoOnce)
		{
			DoorAnimation.Reverse();
			bDoOnce=false;
		}
		
	}

	UFUNCTION()
	void RaiseElevator()
	{
		if (bRaised)
			return;

		bRaised = true;
		ElevatorAnimation.Play();
	}

	UFUNCTION()
	void LowerElevator()
	{
		ElevatorAnimation.Reverse();
	}

	UFUNCTION()
	void OnDoorUpdate(float Value)
	{
		LeftDoorPivot1.RelativeLocation = FVector::RightVector * DoorOpenDistance1 * Value; 
		RightDoorPivot1.RelativeLocation = -FVector::RightVector * DoorOpenDistance1 * Value; 

		LeftDoorPivot2.RelativeLocation = FVector::RightVector * DoorOpenDistance2 * Value; 
		RightDoorPivot2.RelativeLocation = -FVector::RightVector * DoorOpenDistance2 * Value; 
	}

	UFUNCTION()
	void OnDoorFinished()
	{
		if (DoorAnimation.IsReversed())
			RaiseElevator();
	}

	UFUNCTION()
	void OnElevatorUpdate(float Value)
	{
		RootComponent.RelativeLocation = InitialRelativeLocation + FVector::UpVector * ElevatorHeight * Value;
	}

	UFUNCTION()
	void OnElevatorFinished()
	{
		OnElevatorStop.Broadcast();	
		OpenDoors();	
	}

	UFUNCTION()
	void StartRaised()
	{
		bRaised = true;
		bEnsureDelayedRaisedCollisionAndNetworkReasons = true;
		RootComponent.SetRelativeLocation(FVector());
		RootComponent.SetRelativeLocation(InitialRelativeLocation + FVector::UpVector * ElevatorHeight);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AliveFrames++;
		if (AliveFrames > 5 && bEnsureDelayedRaisedCollisionAndNetworkReasons)
		{
			bEnsureDelayedRaisedCollisionAndNetworkReasons = false;
			RootComponent.SetRelativeLocation(FVector());
			RootComponent.SetRelativeLocation(InitialRelativeLocation + FVector::UpVector * ElevatorHeight);
		}
	}

}