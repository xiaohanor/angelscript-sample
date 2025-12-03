struct FTeenDragonRollLaunchToPointActivationParams
{
	USummitRollLaunchToPointZoneComponent LaunchToPointZoneComp;
}

class UTeenDragonRollLaunchToPointCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 2;

	UPlayerTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;

	UCameraUserComponent CameraUserComp;

	UPlayerMovementComponent MoveComp;
	UTeenDragonRollMovementData Movement;

	const float RotationSpeed = 4.0;
	const float VelocityDirDotThreshold = 0.15;

	const float CollisionDeactivationGracePeriod = 0.5;

	FRotator WallTransitionStartViewRotation;

	bool bHasHadImpact = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);

		CameraUserComp = UCameraUserComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = Cast<UTeenDragonRollMovementData>(MoveComp.SetupMovementData(UTeenDragonRollMovementData));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonRollLaunchToPointActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(RollComp.RollLaunchToPointZonesInside.Num() == 0)
			return false;

		if(!RollComp.IsRolling())
			return false;

		auto TargetLaunchToPointZoneComp = RollComp.RollLaunchToPointZonesInside[0];
		if(TargetLaunchToPointZoneComp.bShouldOnlyTriggerIfGoingTowardsTarget)
		{
			FVector LandingLocation = GetLandingLocation(TargetLaunchToPointZoneComp);
			FVector DirToLanding = (LandingLocation - Player.ActorLocation).GetSafeNormal();
			if(DirToLanding.DotProduct(Player.ActorVelocity.GetSafeNormal()) < VelocityDirDotThreshold)
				return false;
		}

		if(TargetLaunchToPointZoneComp.Mode == ESummitRollLaunchToPointZoneMode::LeavingGround)
		{
			if(MoveComp.IsInAir()
			&& MoveComp.PreviousHadGroundContact())
			{
				Params.LaunchToPointZoneComp = TargetLaunchToPointZoneComp;
				return true;
			}
		}

		if(TargetLaunchToPointZoneComp.Mode == ESummitRollLaunchToPointZoneMode::EnteringZone)
		{
			Params.LaunchToPointZoneComp = TargetLaunchToPointZoneComp;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(bHasHadImpact)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonRollLaunchToPointActivationParams Params)
	{
		FVector TargetLocation = GetLandingLocation(Params.LaunchToPointZoneComp);
		FVector NewVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Player.ActorLocation, TargetLocation, MoveComp.GravityForce, MoveComp.HorizontalVelocity.Size(), MoveComp.WorldUp);
		Player.SetActorVelocity(NewVelocity);

		RollComp.RollingInstigators.AddUnique(this);

		bHasHadImpact = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RollComp.RollingInstigators.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVelocity();

				FRotator TargetRotation = FRotator::MakeFromX(Player.ActorVelocity.GetSafeNormal());
				FRotator NewRotation = Math::RInterpTo(Player.ActorRotation, TargetRotation, DeltaTime, RotationSpeed);
				Movement.SetRotation(NewRotation);

				if(ActiveDuration > CollisionDeactivationGracePeriod)
				{	
					if(MoveComp.HasGroundContact()
					|| MoveComp.HasWallContact()
					|| MoveComp.HasCeilingContact())
						bHasHadImpact = true;
				}
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::RollMovement);
			MoveComp.ApplyMove(Movement);
		}
	}

	FVector GetLandingLocation(USummitRollLaunchToPointZoneComponent LaunchZoneComp) const
	{
		float CapsuleRadius = Player.CapsuleComponent.CapsuleRadius;
		FVector LandLocation = LaunchZoneComp.GetLandingLocation()
			+ LaunchZoneComp.Owner.ActorUpVector * CapsuleRadius
			+ LaunchZoneComp.ForwardVector * CapsuleRadius;

		return LandLocation;
	}
};