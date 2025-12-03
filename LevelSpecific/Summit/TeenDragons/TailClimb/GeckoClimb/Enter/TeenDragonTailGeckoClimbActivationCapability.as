class UTeenDragonTailGeckoClimbActivationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonTailClimb);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerTailTeenDragonComponent TailDragonComp;
	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;

	UTeenDragonTailGeckoClimbSettings ClimbSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		TailDragonComp = UPlayerTailTeenDragonComponent::Get(Player);

		GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);

		ClimbSettings = UTeenDragonTailGeckoClimbSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonTailClimbParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(TailDragonComp.IsClimbing())
			return false;

		if(Time::GetGameTimeSince(GeckoClimbComp.TimeLastWalkedOffWall) < 1.0)
			return false;
		
		UTeenDragonTailClimbableComponent ClimbableComp;
		FHitResult Impact;
		if(MoveComp.HasWallContact())
			Impact = MoveComp.GetWallContact().ConvertToHitResult();
		else if(MoveComp.HasGroundContact())
			Impact = MoveComp.GetGroundContact().ConvertToHitResult();
		
		if (!Impact.bBlockingHit || DeactiveDuration < ClimbSettings.WallClimbActivationCooldown)
			return false;
		if (Impact.Actor == nullptr)
			return false;
		
		ClimbableComp = UTeenDragonTailClimbableComponent::Get(Impact.Actor);

		if(ClimbableComp == nullptr)
			return false;
		
		if (ClimbableComp.bIsPrimitiveParentExclusive)
		{
			if (!ClimbableComp.ImpactOnParentValid(Impact.Component))
				return false;
		}
		
		if(!ClimbableComp.ClimbDirectionIsAllowed(Impact.ImpactNormal))
			return false;
		
		Params.Location = Impact.ImpactPoint + Impact.ImpactNormal;
		Params.ClimbUpVector = Impact.ImpactNormal;
		Params.WallNormal = Impact.ImpactNormal;
		Params.ClimbComp = UTeenDragonTailClimbableComponent::Get(Impact.Actor);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Deactivate when Landed
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonTailClimbParams Params)
	{
		TailDragonComp.ClimbingInstigators.Add(this);

		GeckoClimbComp.UpdateClimbParams(Params);
		GeckoClimbComp.SetCameraTransitionAlphaTarget(1.0, ClimbSettings.CameraTransitionJumpOnWallSpeed);
		Player.ApplyBlendToCurrentView(0.5, UTeenDragonTailGeckoClimbBlend());

		FHazeCameraImpulse CamImpulse;
		CamImpulse.WorldSpaceImpulse = MoveComp.PreviousVelocity * 0.5;
		CamImpulse.Dampening = 1.0;
		CamImpulse.ExpirationForce = 10.0;
		Player.ApplyCameraImpulse(CamImpulse, this);
		GeckoClimbComp.bHasReachedWall = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TailDragonComp.ClimbingInstigators.RemoveSingleSwap(this);

		GeckoClimbComp.bHasLandedOnWall = true;
		GeckoClimbComp.StartClimbing();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement, GeckoClimbComp.GetClimbUpVector()))
		{
			if (HasControl())
			{
				Movement.AddOwnerHorizontalVelocity();
				Movement.AddDeltaFromMoveToPositionWithCustomHorizontalAndVerticalVelocity(GeckoClimbComp.GetClimbLocation(), FVector::ZeroVector, FVector::ZeroVector);
				if(!GeckoClimbComp.bIsGeckoJumping)
				{
					FRotator Rotation = FRotator::MakeFromXZ(FVector::UpVector, GeckoClimbComp.GetClimbUpVector());
					Movement.SetRotation(Rotation);
				}
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}
			// Debug::DrawDebugDirectionArrow(TeenDragon.ActorLocation, ClimbParams.ClimbUpVector, 500, 50, FLinearColor::Red, 50, 2);

			MoveComp.ApplyMove(Movement);
			TailDragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::TailTeenClimb);
		}
	}
};