class UTundraPlayerSwingComponent : UActorComponent
{
	FVector HorizontalLocation;
	FVector AccOffset;
	float ReturnOffsetDuration;
	AHazePlayerCharacter Player;
	ATundraSwing Swing;

	TOptional<FVector> PendingImpulse;
	bool bFalling = false;
	float LastLaunchTime = 0;
	bool bIsActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	void ApplyLaunch(FVector Impulse)
	{
		PendingImpulse.Set(Impulse);
	}

	void ApplyLaunchOffset(
		FVector LaunchLocation,
		FVector VisualLocation)
	{
		ReturnOffsetDuration = Network::PingOneWaySeconds * 4;
		AccOffset = VisualLocation - LaunchLocation;
		Player.MeshOffsetComponent.SnapToLocation(this, VisualLocation);
	}

	bool HasOffset() const
	{
		return !AccOffset.IsNearlyZero();
	}

	void ResetOffset()
	{
		//Player.MeshOffsetComponent.ResetOffsetWithLerp(this, 0.2);
		Player.MeshOffsetComponent.ClearOffset(this);
	}

	void UpdateLaunchedOffset(float DeltaTime)
	{
		if(HasOffset())
		{
			if(ReturnOffsetDuration > 0)
				AccOffset = Math::VInterpTo(AccOffset, FVector::ZeroVector, DeltaTime, 1.0 / ReturnOffsetDuration);
			else
				AccOffset = FVector::ZeroVector;
			
			Player.MeshOffsetComponent.SnapToRelativeLocation(this, Player.RootComponent, AccOffset);
		}
		else
		{
			Player.MeshOffsetComponent.SnapToRelativeLocation(this, Player.RootComponent, FVector::ZeroVector);
		}
	}
};