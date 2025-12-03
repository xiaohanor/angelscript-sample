struct FDentistBossToolCupMovementDeactivationParams
{
	bool bNaturally = false;
}

class UDentistBossToolCupMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolCup Cup;

	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;

	const float MaxActiveDuration = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cup = Cast<ADentistBossToolCup>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(Cup.bDestroyed)
			return false;

		if(!Cup.bActive)
			return false;

		if(Cup.AttachParentActor != nullptr)
			return false;

		if(!MoveComp.HasImpulse())
			return false;

		if(Cup.bIsFlattened)	
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDentistBossToolCupMovementDeactivationParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(Cup.bDestroyed)
			return true;

		if(!Cup.bActive)
			return true;

		if(Cup.AttachParentActor != nullptr)
			return true;

		if(Cup.bIsFlattened)	
			return true;

		if(ActiveDuration > MaxActiveDuration)
		{
			Params.bNaturally = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Cup.AddActorCollisionBlock(this);
		Cup.RestrainedPlayer.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistBossToolCupMovementDeactivationParams Params)
	{
		if(Params.bNaturally)
			Cup.Deactivate();
		Cup.RemoveActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddPendingImpulses();
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVelocity();

				float Radius = Cup.SphereCollisionComp.SphereRadius;
				float RotationSpeed = (-Cup.AngularVelocity.Size() / Radius);
				FVector RotationAxis = Cup.AngularVelocity.GetSafeNormal();
				FQuat DeltaRotation = FQuat(RotationAxis, RotationSpeed * DeltaTime);

				Cup.MeshComp.AddWorldRotation(DeltaRotation);
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