class ASkylinePerchActivatedPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UPerchPointComponent PerchPointComp;
	default PerchPointComp.bAllowGrappleToPoint = false;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent EnterByZoneComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MovingPivot;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FTransform TargetTransform;
	FTransform InitialTransform;

	UPROPERTY(EditAnywhere)
	float ActivationTime = 0.5;

	FHazeAcceleratedFloat AcceleratedFloat;
	float TargetAlpha = 0.0;

	int PerchingPlayers = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"HandlePerchStarted");
		PerchPointComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"HandlePerchStopped");
	
		InitialTransform = MovingPivot.RelativeTransform;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedFloat.AccelerateTo(TargetAlpha, ActivationTime, DeltaSeconds);
	
		FTransform Transform;
		Transform.Location = Math::Lerp(InitialTransform.Location, TargetTransform.Location, AcceleratedFloat.Value);
		Transform.Rotation = FQuat::Slerp(InitialTransform.Rotation, TargetTransform.Rotation, AcceleratedFloat.Value);
		Transform.Scale3D = Math::Lerp(InitialTransform.Scale3D, TargetTransform.Scale3D, AcceleratedFloat.Value);

		MovingPivot.RelativeTransform = Transform;
	}

	UFUNCTION()
	private void HandlePerchStarted(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		PerchingPlayers++;

		if (PerchingPlayers > 0)
			TargetAlpha = 1.0;
	}

	UFUNCTION()
	private void HandlePerchStopped(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		PerchingPlayers--;

		if (PerchingPlayers == 0)
			TargetAlpha = 0.0;		
	}
};