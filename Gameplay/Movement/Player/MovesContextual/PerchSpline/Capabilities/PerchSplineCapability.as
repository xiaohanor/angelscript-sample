class UPlayerPerchSplineCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Perch);
	default CapabilityTags.Add(PlayerPerchPointTags::PerchPointSpline);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludePerch);
	
	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;
	default TickGroupSubPlacement = 1;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerPerchComponent PerchComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UPlayerSplineLockComponent SplineLockComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		SplineLockComp = UPlayerSplineLockComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPerchSplineActivationParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (!IsValid(PerchComp.Data.ActivePerchPoint))
			return false;

        if (!PerchComp.Data.ActivePerchPoint.bHasConnectedSpline)
            return false;

		ActivationParams.ActivatedOnData = PerchComp.Data;
		ActivationParams.SplinePosition = PerchComp.Data.ActiveSpline.Spline.GetPlaneConstrainedClosestSplinePositionToWorldLocation(Player.ActorLocation, MoveComp.WorldUp);
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPerchSplineDeactivationParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
		{
			if(PerchComp.GetState() == EPlayerPerchState::JumpTo)
				Params.DeactivationType = EPerchOnSplineDeactivationTypes::JumpTo;
			else if(PerchComp.Data.bJumpingOff)
				Params.DeactivationType = EPerchOnSplineDeactivationTypes::JumpOff;
			else
				Params.DeactivationType = EPerchOnSplineDeactivationTypes::Interrupted;

			return true;
		}

		if (!IsValid(PerchComp.Data.ActiveSpline) || PerchComp.Data.ActivePerchPoint.IsDisabled())
		{
			Params.DeactivationType = EPerchOnSplineDeactivationTypes::Disabled;
			return true;
		}

		if (!PerchComp.Data.bPerching)
		{
			Params.DeactivationType = EPerchOnSplineDeactivationTypes::Cancel;
			return true;
		}

		if (PerchComp.VerifyReachedPerchSplineEnd())
		{
			Params.DeactivationType = EPerchOnSplineDeactivationTypes::EndPointExit;			
			return true;
		}

		if (!SplineLockComp.IsSplineLockActiveWithInstigator(n"PerchSpline"))
		{
			Params.DeactivationType = EPerchOnSplineDeactivationTypes::EndPointExit;			
			return true;
		}

		if(PerchComp.Data.ActiveSpline.bValidatePlayerSplineDistanceAndSplineLength && (PerchComp.Data.CurrentSplineDistance > PerchComp.Data.ActiveSpline.Spline.SplineLength))
		{
			Params.DeactivationType = EPerchOnSplineDeactivationTypes::Cancel;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPerchSplineActivationParams ActivationParams)
	{
		Player.BlockCapabilitiesExcluding(BlockedWhileIn::PerchSpline, n"ExcludeAirJumpAndDash", this);
		Player.BlockCapabilities(PlayerMovementTags::UnwalkableSlide, this);

		PerchComp.Data = ActivationParams.ActivatedOnData;
		PerchComp.SetState(EPlayerPerchState::PerchingOnSpline);

		if (PerchComp.Data.ActivePerchPoint.PerchCameraSetting != nullptr)
		{
			if (PerspectiveModeComp.IsCameraBehaviorEnabled())
				Player.ApplyCameraSettings(PerchComp.Data.ActivePerchPoint.PerchCameraSetting, 2.0, this, SubPriority = 41);
		}
		
		if(PerchComp.Data.ActivePerchPoint.PerchSettings != nullptr)
			Player.ApplySettings(PerchComp.Data.ActivePerchPoint.PerchSettings, this);

		// Broadcast Started perching event
		PerchComp.Data.ActivePerchPoint.OnPlayerStartedPerchingEvent.Broadcast(Player, PerchComp.Data.ActivePerchPoint);

		// Set our landing velocity for ABP to read
		PerchComp.Data.PerchLandingVerticalVelocity = MoveComp.VerticalVelocity;
		PerchComp.Data.PerchLandingHorizontalVelocity = MoveComp.HorizontalVelocity;

		// Snap to a location on the plane of the spline
		if (PerchComp.bIsLandingOnSpline)
		{
			FVector LocationOnSpline = ActivationParams.SplinePosition.WorldLocation; 
			FVector SnapOffset = LocationOnSpline - Player.ActorLocation;

			FVector SnapLocation = Player.ActorLocation + SnapOffset.ConstrainToPlane(MoveComp.WorldUp);

			float HeightDifference = (LocationOnSpline - Player.ActorLocation).DotProduct(MoveComp.WorldUp);
			if (HeightDifference > 0.0)
				SnapLocation += MoveComp.WorldUp * HeightDifference;

			PerchComp.SplineLandStartOffset = Player.ActorLocation - SnapLocation;
			PerchComp.SplineLandStartVelocity = Player.ActorHorizontalVelocity;
			PerchComp.bSplineLandWasAirbone = MoveComp.IsInAir();

			Player.ActorLocation = SnapLocation;
			MoveComp.TransitionCrumbSyncedPosition(this);
		}

		FPlayerMovementSplineLockProperties LockProperties;
		LockProperties.bCanLeaveSplineAtEnd = false;
		LockProperties.bSyncPositionCrumbsRelativeToSpline = true;
		LockProperties.bConstrainInitialVelocityAlongSpline = true;

		Player.LockPlayerMovementToSpline(
			PerchComp.Data.ActivePerchPoint.ConnectedSpline,
			n"PerchSpline",
			LockProperties = LockProperties,
			Priority = EInstigatePriority::High,
		);

		MoveComp.FollowComponentMovement(PerchComp.Data.ActivePerchPoint.ConnectedSpline.Spline, this, Priority = EInstigatePriority::Interaction);

		if(PerchComp.Data.ActiveSpline != nullptr && PerchComp.Data.ActiveSpline.bCrumbRelativeToSpline)
		{
			MoveComp.ApplyCrumbSyncedRelativePosition(this, PerchComp.Data.ActiveSpline.Spline, Priority = EInstigatePriority::Override);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPerchSplineDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::PerchSpline, this);
		Player.UnblockCapabilities(PlayerMovementTags::UnwalkableSlide, this);

		Player.ClearSettingsByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);
		Player.UnlockPlayerMovementFromSpline(n"PerchSpline");

		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearCrumbSyncedRelativePosition(this);

		PerchComp.PerchSplinePosition = FSplinePosition();
		PerchComp.bIsGroundedOnPerchSpline = false;

		switch(Params.DeactivationType)
		{
			case EPerchOnSplineDeactivationTypes::Disabled:
				if (IsValid(PerchComp.Data.ActivePerchPoint))
					PerchComp.Data.ActivePerchPoint.OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchComp.Data.ActivePerchPoint);
				PerchComp.StopPerching();
				break;

			case EPerchOnSplineDeactivationTypes::EndPointExit:
				if (IsValid(PerchComp.Data.ActivePerchPoint))
					PerchComp.Data.ActivePerchPoint.OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchComp.Data.ActivePerchPoint);
				PerchComp.StopPerching();
				break;
			
			case EPerchOnSplineDeactivationTypes::Cancel:
				Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
				if (IsValid(PerchComp.Data.ActivePerchPoint))
					PerchComp.Data.ActivePerchPoint.OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchComp.Data.ActivePerchPoint);
				PerchComp.StopPerching();
				break;

			//[AL] - StoppedPerchingEvent is fired in jumpoff capability as it should already have stopped perching = our Current perchPoint has been cleared.
			case EPerchOnSplineDeactivationTypes::JumpOff:
				PerchComp.StopPerching(false);
				break;

			case EPerchOnSplineDeactivationTypes::Interrupted:
				if (IsValid(PerchComp.Data.ActivePerchPoint))
					PerchComp.Data.ActivePerchPoint.OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchComp.Data.ActivePerchPoint);
				PerchComp.StopPerching(false);
				break;

			case EPerchOnSplineDeactivationTypes::JumpTo:
				PerchComp.StopPerching();
				break;

			default:
				if (IsValid(PerchComp.Data.ActivePerchPoint))
					PerchComp.Data.ActivePerchPoint.OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchComp.Data.ActivePerchPoint);
				PerchComp.StopPerching();
				break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!IsValid(PerchComp.Data.ActivePerchPoint))
			return;

		PerchComp.PerchSplinePosition = PerchComp.Data.ActiveSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation); 
		float VerticalDistanceToSpline = (Player.ActorLocation - PerchComp.PerchSplinePosition.WorldLocation).DotProduct(MoveComp.WorldUp);
		PerchComp.bIsGroundedOnPerchSpline = Math::Abs(VerticalDistanceToSpline) < 10.0 || MoveComp.IsOnAnyGround() || MoveComp.HasCustomMovementStatus(n"Perching");
	}
}

struct FPerchSplineActivationParams
{
	FSplinePosition SplinePosition;
	FPerchData ActivatedOnData;
}

struct FPerchSplineDeactivationParams
{
	bool bShouldDetach = true;
	EPerchOnSplineDeactivationTypes DeactivationType;
}

enum EPerchOnSplineDeactivationTypes
{
	None,
	Disabled,
	Cancel,
	JumpOff,
	JumpTo,
	Interrupted,
	EndPointExit
}