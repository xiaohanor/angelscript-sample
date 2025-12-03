struct FTeenDragonTailGeckoClimbRollEnterJumpActivationParams
{
	USummitRollEnterWallZoneComponent EnterWallZoneComp;
	FTeenDragonTailClimbParams EnterClimbParams;
}

class UTeenDragonTailGeckoClimbRollEnterJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonTailClimb);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 15;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;
	UTeenDragonTailGeckoClimbComponent ClimbComp;

	UCameraUserComponent CameraUserComp;

	UPlayerMovementComponent MoveComp;
	UTeenDragonRollMovementData Movement;

	const float RotationSpeed = 4.0;
	const float VelocityDirDotThreshold = 0.15;

	FRotator WallTransitionStartViewRotation;

	float TimeToReachTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);
		ClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);

		CameraUserComp = UCameraUserComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = Cast<UTeenDragonRollMovementData>(MoveComp.SetupMovementData(UTeenDragonRollMovementData));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonTailGeckoClimbRollEnterJumpActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(ClimbComp.RollEnterZoneCompsCurrentlyInside.Num() == 0)
			return false;

		if(!RollComp.IsRolling())
			return false;

		auto TargetWallZoneComp = ClimbComp.RollEnterZoneCompsCurrentlyInside[0];
		FVector LandingLocation = GetLandingLocation(TargetWallZoneComp);

		if(!TargetWallZoneComp.bDisregardFacing)
		{
			FVector DirToLanding = (LandingLocation - Player.ActorLocation).GetSafeNormal();
			if(DirToLanding.DotProduct(Player.ActorVelocity.GetSafeNormal()) < VelocityDirDotThreshold)
				return false;
		}

		if(TargetWallZoneComp.Mode == ESummitRollEnterWallZoneMode::LeavingGround)
		{
			if(MoveComp.IsInAir()
			&& MoveComp.PreviousHadGroundContact())
			{
				Params.EnterWallZoneComp = TargetWallZoneComp;

				FTeenDragonTailClimbParams EnterClimbParams;
				EnterClimbParams.ClimbComp = TargetWallZoneComp.ClimbableComp;
				EnterClimbParams.ClimbUpVector = TargetWallZoneComp.ClimbableComp.ForwardVector;
				EnterClimbParams.WallNormal = TargetWallZoneComp.ClimbableComp.ForwardVector;
				EnterClimbParams.Location = LandingLocation;

				Params.EnterClimbParams = EnterClimbParams;
				return true;
			}
		}

		if(TargetWallZoneComp.Mode == ESummitRollEnterWallZoneMode::EnteringZone)
		{
			Params.EnterWallZoneComp = TargetWallZoneComp;

			FTeenDragonTailClimbParams EnterClimbParams;
			EnterClimbParams.ClimbComp = TargetWallZoneComp.ClimbableComp;
			EnterClimbParams.ClimbUpVector = TargetWallZoneComp.ClimbableComp.ForwardVector;
			EnterClimbParams.WallNormal = TargetWallZoneComp.ClimbableComp.ForwardVector;
			EnterClimbParams.Location = LandingLocation;

			Params.EnterClimbParams = EnterClimbParams;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.HasWallContact())
			return true;

		if(MoveComp.HasGroundContact())
			return true;

		if(MoveComp.HasCeilingContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonTailGeckoClimbRollEnterJumpActivationParams Params)
	{
		ClimbComp.WallEnterClimbParams = Params.EnterClimbParams;
		ClimbComp.bHasWallEnterLocation = true;
		ClimbComp.bIsJumpingOntoWall = true;

		float RollSpeed = Math::Max(MoveComp.HorizontalVelocity.Size(), Params.EnterWallZoneComp.MinRollSpeed);
		FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Player.ActorLocation, Params.EnterClimbParams.Location, MoveComp.GravityForce, RollSpeed, MoveComp.WorldUp);
		Player.SetActorVelocity(LaunchVelocity);
		TimeToReachTarget = GetTimeToReachTarget(Params.EnterClimbParams.Location, LaunchVelocity);

		ClimbComp.OverrideCameraTransitionAlpha(1.0);

		RollComp.RollingInstigators.Add(this);

		Player.ApplyBlendToCurrentView(Params.EnterWallZoneComp.CameraBlendTime, UTeenDragonTailGeckoClimbBlend());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ClimbComp.bHasWallEnterLocation = false;
		ClimbComp.bIsJumpingOntoWall = false;

		if(!ClimbComp.IsOnClimbableWall())
		{
			Player.ApplyBlendToCurrentView(1.5, UTeenDragonTailGeckoClimbBlend());
			ClimbComp.OverrideCameraTransitionAlpha(0.0);
		}

		RollComp.RollingInstigators.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				// RollComp.IgnoreRollThroughActors(Movement);

				Movement.AddGravityAcceleration();
				Movement.AddOwnerVelocity();

				FRotator TargetRotation = FRotator::MakeFromX(Player.ActorVelocity.GetSafeNormal());
				FRotator NewRotation = Math::RInterpTo(Player.ActorRotation, TargetRotation, DeltaTime, RotationSpeed);
				Movement.SetRotation(NewRotation);

				// RollComp.HandleRollingOverlaps();
				// RollComp.HandleRollingImpact();
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

	float GetTimeToReachTarget(FVector LandLocation, FVector Velocity) const
	{
		FVector DeltaToTarget = LandLocation - Player.ActorLocation;
		FVector VerticalToTarget = DeltaToTarget.ProjectOnToNormal(FVector::UpVector);
		FVector HorizontalToTarget = DeltaToTarget - VerticalToTarget;
		float HorizontalDistance = HorizontalToTarget.Size();

		FVector VerticalVelocity = Velocity.ProjectOnToNormal(FVector::UpVector);
		FVector HorizontalVelocity = Velocity - VerticalVelocity;
		float HorizontalSpeed = HorizontalVelocity.Size();
		return HorizontalDistance / HorizontalSpeed;
	}

	FVector GetLandingLocation(USummitRollEnterWallZoneComponent WallZoneComp) const
	{
		float CapsuleRadius = Player.CapsuleComponent.CapsuleRadius;
		FVector LandLocation = WallZoneComp.GetLandingLocation()
			+ WallZoneComp.ClimbableComp.Owner.ActorUpVector * CapsuleRadius
			+ WallZoneComp.ClimbableComp.ForwardVector * CapsuleRadius;

		return LandLocation;
	}
};