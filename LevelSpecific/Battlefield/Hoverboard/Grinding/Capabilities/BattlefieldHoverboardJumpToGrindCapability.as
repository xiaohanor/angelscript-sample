class UBattlefieldHoverboardJumpToGrindCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::Jump);

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 84;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardJumpComponent JumpComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;

	UCameraUserComponent CameraUserComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UBattlefieldHoverboardJumpSettings JumpSettings;
	UBattlefieldHoverboardGrindingSettings GrindSettings;

	bool bIsFirstFrame = false;

	UBattlefieldHoverboardGrindSplineComponent GrindSplineCompJumpingTo;

	const float StartGrindBufferLength = 500.0;
	const float DebugDrawDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		JumpComp = UBattlefieldHoverboardJumpComponent::Get(Player);
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);

		CameraUserComp = UCameraUserComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		JumpSettings = UBattlefieldHoverboardJumpSettings::GetSettings(Player);
		GrindSettings = UBattlefieldHoverboardGrindingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardJumpToGrindActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		
		TOptional<FSplinePosition> ClosestSplinePos;

		// Dont want to early out if debug is active so it gets drawn
		if(IsDebugActive())
			ClosestSplinePos = GetMostValidSplinePosWithInputAndRange();

		if(!JumpComp.bWantToJump)
			return false;

		if(!HoverboardComp.IsOn())
			return false;

		if(GrindComp.IsGrinding()
		&& (!GrindComp.CurrentGrindSplineComp.bAllowJumpWhileOnGrind
		|| !GrindComp.CurrentGrindSplineComp.bAllowedToJumpToOtherGrind))
			return false;
		
		if(!IsDebugActive())
			ClosestSplinePos = GetMostValidSplinePosWithInputAndRange();

		if(!ClosestSplinePos.IsSet())
			return false;

		Params.SplinePosToJumpTo = ClosestSplinePos.Value;
		Params.GrindToLandOn = UBattlefieldHoverboardGrindSplineComponent::Get(ClosestSplinePos.Value.CurrentSpline.Owner);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!HoverboardComp.IsOn())
			return true;

		if(GrindComp.IsGrinding())
			return true;

		if(ActiveDuration > 0.2
		&& MoveComp.IsOnAnyGround())
			return true;

		if(MoveComp.HasWallContact())
			return true;

		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardJumpToGrindActivationParams Params)
	{
		JumpComp.ConsumeJumpInput();

		GrindSplineCompJumpingTo = Params.GrindToLandOn;
		GrindSplineCompJumpingTo.JumpingToGrind[Player] = true;

		float Speed = Math::Max(Player.ActorHorizontalVelocity.Size(), GrindSettings.JumpToGrindMinSpeed);
		FVector ActivationVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Player.ActorLocation, Params.SplinePosToJumpTo.WorldLocation, 
			MoveComp.GravityForce, Speed, MoveComp.WorldUp);

		TEMPORAL_LOG(Player, "Jump to Grind")
			.Sphere("Spline pos to jump to", Params.SplinePosToJumpTo.WorldLocation, 40, FLinearColor::Green, 5)
		;

		Player.SetActorVelocity(ActivationVelocity);

		if(GrindComp.IsGrinding())
			HoverboardComp.AnimParams.bIsJumpingBetweenGrinds = true;
		else
			HoverboardComp.AnimParams.bIsJumpingToGrind = true;

		GrindComp.bIsJumpingToGrind = true;
		JumpComp.bJumped = true;
		JumpComp.bAirborneFromJump = true;

		bIsFirstFrame = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GrindSplineCompJumpingTo.JumpingToGrind[Player] = false;
		if(GrindComp.IsGrinding())
			HoverboardComp.AnimParams.bIsJumpingBetweenGrinds = false;
		else
			HoverboardComp.AnimParams.bIsJumpingToGrind = false;
			
		GrindComp.bIsJumpingToGrind = false;
		JumpComp.bAirborneFromJump = false;
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
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			FName AnimTag = BattlefieldHoverboardLocomotionTags::HoverboardJumping;
			if(!bIsFirstFrame)
				AnimTag = BattlefieldHoverboardLocomotionTags::HoverboardAirMovement;
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);

			bIsFirstFrame = false;
		}
	}

	TOptional<FSplinePosition> GetMostValidSplinePosWithInputAndRange() const
	{
		TOptional<FSplinePosition> ValidSplinePos;

		FVector WorldMovementInput = HoverboardComp.GetMovementInputCameraSpace().ConstrainToPlane(FVector::UpVector);

		FVector ClampedActorVelocity = Player.ActorVelocity.GetClampedToSize(GrindSettings.JumpToGrindMinSpeed, BIG_NUMBER);
		FVector LocationAheadToCheck = Player.ActorLocation 
			+ (ClampedActorVelocity * GrindSettings.VelocityDurationForJumpToGrindPointSampling);
		FVector Start = LocationAheadToCheck;
		FVector End = Start + WorldMovementInput * GrindSettings.MaxDistanceToGrindForJump; 

		TEMPORAL_LOG(Player, "Jump to Grind")
			.Arrow("Input", Start, End, 10, 40, FLinearColor::Red)
		;

		if(IsDebugActive())
			Debug::DrawDebugArrow(Start, End, 40, FLinearColor::Red, 20, DebugDrawDuration);
		
		float ClosestDistSqrd = MAX_flt;
		for(auto GrindSpline : GrindComp.GrindSplineComps)
		{
			auto SplinePos = GrindSpline.SplineComp.GetPlaneConstrainedClosestSplinePositionToLineSegment(Start, End, FVector::UpVector);

			if(GrindComp.IsGrinding()
			&& GrindSpline.PlayerIsOnGrind(Player))
				continue;

			FVector DirToPoint = (SplinePos.WorldLocation - Start).GetSafeNormal();
			DirToPoint = DirToPoint.ConstrainToPlane(FVector::UpVector);
			float AngleBetweenDirAndCompareVector = DirToPoint.GetAngleDegreesTo(WorldMovementInput.ConstrainToPlane(FVector::UpVector));

			TEMPORAL_LOG(Player, "Jump to Grind")
				.Sphere(f"{GrindSpline.Owner} Spline Pos", SplinePos.WorldLocation, 20, FLinearColor::Blue)
			;
			if(IsDebugActive())
			{
				Debug::DrawDebugSolidSphere(SplinePos.WorldLocation, 20, FLinearColor::Blue, DebugDrawDuration);
				const float DirArrowLength = 500.0;
				Debug::DrawDebugString(Player.ActorLocation + DirToPoint * DirArrowLength + FVector::UpVector * 10.0, f"{AngleBetweenDirAndCompareVector :.0}°", FLinearColor::White, DebugDrawDuration, 1.0);
			}

			if(AngleBetweenDirAndCompareVector > GrindSettings.JumpToGrindAngleThreshold)
				continue;

			float DistSqrdToPoint = SplinePos.WorldLocation.DistSquared(Start);
			if(DistSqrdToPoint >= Math::Square(GrindSettings.MaxDistanceToGrindForJump))
				continue;

			if(DistSqrdToPoint > ClosestDistSqrd)
				continue;
			
			ClosestDistSqrd = DistSqrdToPoint;
			ValidSplinePos.Set(SplinePos);
		}

		if(ValidSplinePos.IsSet())
		{
			if(IsDebugActive())
			{
				Debug::DrawDebugSolidSphere(ValidSplinePos.Value.WorldLocation, 40, FLinearColor::Green, DebugDrawDuration);
				Debug::DrawDebugString(ValidSplinePos.Value.WorldLocation, "Best Jump to Location", FLinearColor::Green, DebugDrawDuration);
			}
		}

		return ValidSplinePos;
	}
};

struct FBattlefieldHoverboardJumpToGrindActivationParams
{
	FSplinePosition SplinePosToJumpTo;
	UBattlefieldHoverboardGrindSplineComponent GrindToLandOn;
}