class UPerchSplineFallOffCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Perch);
	default CapabilityTags.Add(PlayerPerchPointTags::PerchPointSpline);
	default DebugCategory = n"Movement";

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludePerchFallOff);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;
	default TickGroupSubPlacement = 2;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerPerchComponent PerchComp;
	UPlayerAirMotionComponent AirMotionComp;

	FVector FallOffDirection = FVector::ZeroVector;
	const float ImpulseStrength = 125;
	const float MaximumAllowedAngle = 35;
	const float BlockDuration = 0.3;
	bool bHasAppliedImpulse = false;
	bool bHasActivePerchBlock = false;

	const float EnteredPerchCooldown = 0.3;
	float EnteredPerchTimer = 0;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		PerchComp = UPlayerPerchComponent::Get(Player);
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(MoveComp.HasCustomMovementStatus(n"Perching"))
		{
			EnteredPerchTimer += DeltaTime;
			EnteredPerchTimer = Math::Clamp(EnteredPerchTimer, 0, EnteredPerchTimer);
		}
		else
		{
			EnteredPerchTimer = 0;
		}

		if(IsActive() || !bHasActivePerchBlock)
			return;

		if(DeactiveDuration >= BlockDuration)
		{
			Player.UnblockCapabilities(PlayerMovementTags::Perch, this);
			bHasActivePerchBlock = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPerchSplineFallOffActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (bHasActivePerchBlock)
			return false;

		if (PerchComp.Data.ActiveSpline == nullptr /*|| !PerchComp.Data.ActiveSpline.bSoftPerchLock*/)
			return false;

		if (PerchComp.GetState() != EPlayerPerchState::PerchingOnSpline)
			return false;

		if (EnteredPerchTimer < EnteredPerchCooldown)
			return false;

		if (MoveComp.GetNonLockedMovementInput().ConstrainToPlane(MoveComp.WorldUp).IsNearlyZero() || !ShouldExitBasedOnInput(Params.PerpendicularFallOffDirection))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		
		if (bHasAppliedImpulse)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPerchSplineFallOffActivationParams Params)
	{
		Player.BlockCapabilitiesExcluding(PlayerMovementTags::Perch, PlayerMovementExclusionTags::ExcludePerchFallOff, this);
		bHasActivePerchBlock = true;
		bHasAppliedImpulse = false;
		Player.AddMovementImpulse((Params.PerpendicularFallOffDirection * ImpulseStrength) + (Player.ActorForwardVector * (Player.ActorForwardVector.DotProduct(MoveComp.HorizontalVelocity) / 2)));
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
				Movement.AddPendingImpulses();
				bHasAppliedImpulse = true;
			}
			else
			{
				// Follow the crumb trail on the remote side
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
		}
	}

	bool ShouldExitBasedOnInput(FVector& Direction) const
	{
		float SplineDistance = PerchComp.Data.ActiveSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation); 
		FVector SplineLocation = PerchComp.Data.ActiveSpline.Spline.GetWorldLocationAtSplineDistance(SplineDistance);

		float Angle = Math::RadiansToDegrees(MoveComp.GetNonLockedMovementInput().ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal().AngularDistanceForNormals(PerchComp.Data.ActiveSpline.Spline.GetWorldTangentAtSplineDistance(PerchComp.Data.ActiveSpline.Spline.GetClosestSplineDistanceToWorldLocation(SplineLocation)).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal()));
		float BackwardsAngle = Math::RadiansToDegrees(MoveComp.GetNonLockedMovementInput().ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal().AngularDistanceForNormals(-PerchComp.Data.ActiveSpline.Spline.GetWorldTangentAtSplineDistance(PerchComp.Data.ActiveSpline.Spline.GetClosestSplineDistanceToWorldLocation(SplineLocation)).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal()));

		if(Angle >= MaximumAllowedAngle && BackwardsAngle >= MaximumAllowedAngle)
		{
			Direction = MoveComp.GetNonLockedMovementInput().DotProduct(Player.ActorRightVector) >= 0 ? Player.ActorRightVector : -Player.ActorRightVector;
			return true;
		}
		else
			return false;
	}
};

struct FPerchSplineFallOffActivationParams
{
	FVector PerpendicularFallOffDirection = FVector::ZeroVector;
}