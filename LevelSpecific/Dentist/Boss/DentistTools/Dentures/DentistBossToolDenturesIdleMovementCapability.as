class UDentistBossToolDenturesIdleMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolDentures Dentures;

	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentures = Cast<ADentistBossToolDentures>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(Dentures.bDestroyed)
			return false;

		if(!Dentures.bActive)
			return false;

		if(Dentures.bIsAttachedToJaw)
			return false;
		
		if(Dentures.ControllingPlayer.IsSet())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(Dentures.bDestroyed)
			return true;

		if(!Dentures.bActive)
			return true;

		if(Dentures.bIsAttachedToJaw)
			return true;

		if(Dentures.ControllingPlayer.IsSet())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddGravityAcceleration();

				FVector Velocity = MoveComp.Velocity;
				if(MoveComp.HasGroundContact())
					Velocity = FVector::ZeroVector;

				Movement.AddPendingImpulses();
				Movement.AddVelocity(Velocity);

				FRotator DenturesRotation = Dentures.ActorRotation;
				FVector TargetForward = Dentures.ActorForwardVector.ConstrainToPlane(FVector::UpVector);
				FRotator TargetRotation = FRotator::MakeFromXZ(TargetForward, FVector::UpVector);
				DenturesRotation = Math::RInterpTo(Dentures.ActorRotation, TargetRotation, DeltaTime, 4);
				Movement.SetRotation(DenturesRotation);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
		}
	}
};