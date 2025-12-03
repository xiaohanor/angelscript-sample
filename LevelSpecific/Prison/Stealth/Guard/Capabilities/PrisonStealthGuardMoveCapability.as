class UPrisonStealthGuardMoveCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonStealthTags::StealthGuard);
	//default CapabilityTags.Add(PrisonStealthTags::BlockedWhileStunned);

	APrisonStealthGuard StealthGuard;
	UPrisonStealthGuardPatrolComponent PatrolComp;

	const float FORWARD_BACK_MOTOR_ROTATE_AMOUNT = 0.05;
	const float ROTATE_MOTOR_ROTATE_AMOUNT = 0.15;
	const float MOTOR_ROTATE_CLAMP_ANGLE = 30.0;
	FHazeAcceleratedVector AcceleratedLocation;
	FHazeAcceleratedQuat AcceleratedQuat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StealthGuard = Cast<APrisonStealthGuard>(Owner);
		PatrolComp = UPrisonStealthGuardPatrolComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
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
		AcceleratedLocation.SnapTo(StealthGuard.ActorLocation);
		AcceleratedQuat.SnapTo(StealthGuard.ActorQuat);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);
	}

	void TickControl(float DeltaTime)
	{
		const FVector PreviousLocation = StealthGuard.ActorLocation;

		// Interpolate towards the new transform
		FVector TargetLocation = StealthGuard.TargetLocation;
		TargetLocation += FVector::UpVector * PatrolComp.DistanceFromGround;

		float Sin = Math::Sin((Time::GetGameTimeSeconds() * TWO_PI) / PatrolComp.LocationSineBobFrequency);
		TargetLocation += FVector::UpVector * Sin * PatrolComp.LocationSineBobAmplitude;
		
		const FVector NewLocation = AcceleratedLocation.SpringTo(TargetLocation, PatrolComp.LocationSpringStiffness, PatrolComp.LocationSpringDamping, DeltaTime);
		const FQuat NewRotation = AcceleratedQuat.SpringTo(FRotator(0.0, StealthGuard.TargetYaw, 0.0).Quaternion(), PatrolComp.RotationSpringStiffness, PatrolComp.RotationSpringDamping, DeltaTime);

		StealthGuard.SetActorLocationAndRotation(NewLocation, NewRotation);
		StealthGuard.SetActorVelocity((NewLocation - PreviousLocation) / DeltaTime);
	}

	void TickRemote(float DeltaTime)
	{
		const FVector PreviousLocation = StealthGuard.ActorLocation;

		// Get the synced transform
		const FVector NewLocation = StealthGuard.SyncedActorPosition.Position.WorldLocation;
		
		const FRotator NewRotation = StealthGuard.SyncedActorPosition.Position.WorldRotation;
			
		StealthGuard.SetActorLocationAndRotation(NewLocation, NewRotation);
		StealthGuard.SetActorVelocity((NewLocation - PreviousLocation) / DeltaTime);
	}
};