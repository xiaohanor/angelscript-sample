class UMagicGhostBoatCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMagicGhostBoatCamera Camera;
	AActor FocusActor;
	UHazeSplineComponent SplineComp; 
	float CurrentBackOffset;
	FHazeAcceleratedVector AccelVector;

	FVector StartFocusLocation;
	FVector EndFocusLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Camera = Cast<AMagicGhostBoatCamera>(Owner);
		FocusActor = Camera.FocusActor;
		CurrentBackOffset = Camera.BackOffset / 2 ;

		StartFocusLocation = FocusActor.ActorLocation;
		EndFocusLocation = FocusActor.ActorLocation + FVector::UpVector * Camera.TargetRiseAmount;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Camera.bRunCameraBackOffsetBlend)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccelVector.SnapTo(GetCameraPosition());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CurrentBackOffset = Math::FInterpTo(CurrentBackOffset, Camera.BackOffset, DeltaTime, 0.2);
		AccelVector.AccelerateTo(GetCameraPosition(), 0.6, DeltaTime);
		Camera.ActorLocation = AccelVector.Value;
		FocusActor.ActorLocation = Math::Lerp(StartFocusLocation, EndFocusLocation, Camera.GetSplineAlongAlpha());
		// Debug::DrawDebugSphere(FocusActor.ActorLocation, 5000.0, 25, FLinearColor::Green, 30.0);
		Camera.ActorRotation = (FocusActor.ActorLocation - AccelVector.Value).Rotation();
	}

	FVector GetCameraPosition()
	{
		FVector AveragePosition = (Game::Zoe.ActorLocation + Game::Mio.ActorLocation) / 2;
		FVector DirectionToFocus = (FocusActor.ActorLocation - AveragePosition).GetSafeNormal();
		FVector TruePosition = AveragePosition + DirectionToFocus * -CurrentBackOffset;
		TruePosition += FVector::UpVector * Camera.UpOffset;
		return TruePosition;
	}
};