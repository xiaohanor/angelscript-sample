class ASolarFlareDoubleDoors : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent DoorRight;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent DoorLeft;

	UPROPERTY(EditAnywhere)
	float OpenAmount = 170.0;

	UPROPERTY(EditAnywhere)
	float OpenDuration = 1.75;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Curve;
	default Curve.AddDefaultKey(0.0, 0.0);
	default Curve.AddDefaultKey(1.0, 1.0);

	FVector DoorLeftStart;
	FVector DoorRightStart;

	bool bIsOpen;

	float CurrenTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoorLeftStart = DoorLeft.RelativeLocation;
		DoorRightStart = DoorRight.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsOpen)
			CurrenTime += DeltaSeconds;
		else
			CurrenTime -= DeltaSeconds;

		CurrenTime = Math::Clamp(CurrenTime, 0.0, OpenDuration);
		float Alpha = CurrenTime / OpenDuration;
		
		float RightOffset = -Curve.GetFloatValue(Alpha) * OpenAmount;
		float LeftOffset = Curve.GetFloatValue(Alpha) * OpenAmount;
		DoorRight.RelativeLocation = DoorRightStart + FVector(0, RightOffset, 0);
		DoorLeft.RelativeLocation = DoorLeftStart + FVector(0, LeftOffset, 0);
	}

	UFUNCTION()
	void OpenDoor() 
	{
		bIsOpen = true;
		FSolarFlareDoubleDoorsParams Params;
		Params.Location = ActorLocation;
		USolarFlareDoubleDoorsEffectHandler::Trigger_OnDoorsOpen(this, Params);
	}
	
	UFUNCTION()
	void CloseDoor() 
	{
		bIsOpen = false;
		FSolarFlareDoubleDoorsParams Params;
		Params.Location = ActorLocation;
		USolarFlareDoubleDoorsEffectHandler::Trigger_OnDoorsClose(this, Params);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateDoor(bool bOpening) {}
}