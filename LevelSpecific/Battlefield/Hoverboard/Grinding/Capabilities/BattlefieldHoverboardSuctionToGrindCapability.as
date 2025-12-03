struct FBattlefieldHoverboardSuctionToGrindActivationParams
{
	FSplinePosition SplinePos;
}

class UBattlefieldHoverboardSuctionToGrindCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::Hoverboard);
	default CapabilityTags.Add(BattlefieldHoverboardLocomotionTags::HoverboardGrinding);

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 70;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardJumpComponent JumpComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;
	UBattlefieldHoverboardLevelRubberbandingComponent LevelRubberbandingComp;

	USteppingMovementData Movement;

	UBattlefieldHoverboardAirMovementSettings AirMovementSettings;
	UBattlefieldHoverboardGroundMovementSettings GroundMovementSettings;
	UBattlefieldHoverboardJumpSettings JumpSettings;
	UBattlefieldHoverboardGrindingSettings GrindSettings;

	const float MinSpeed = 0.0;

	float HorizontalSpeed;
	float SuctionSpeed;
	
	float PreviousDistToSplinePos;

	// bool b

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		JumpComp = UBattlefieldHoverboardJumpComponent::Get(Player);
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
		LevelRubberbandingComp = UBattlefieldHoverboardLevelRubberbandingComponent::GetOrCreate(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		AirMovementSettings = UBattlefieldHoverboardAirMovementSettings::GetSettings(Player);
		GroundMovementSettings = UBattlefieldHoverboardGroundMovementSettings::GetSettings(Player);
		JumpSettings = UBattlefieldHoverboardJumpSettings::GetSettings(Player);
		GrindSettings = UBattlefieldHoverboardGrindingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardSuctionToGrindActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!HoverboardComp.IsOn())
			return false;

		if(MoveComp.IsOnWalkableGround())
			return false;

		float TimeSinceLeftGrindByJump = Time::GetGameTimeSince(GrindComp.TimeLastLeftGrindWithJump);
		if(TimeSinceLeftGrindByJump < 0.5)
			return false;

		auto SplinePos = GetMostValidSplinePosWithInputAndRange();
		if(!SplinePos.IsSet())
			return false;

		Params.SplinePos = SplinePos.Value;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!HoverboardComp.IsOn())
			return true;

		if(MoveComp.IsOnWalkableGround())
			return true;

		float TimeSinceLeftGrindByJump = Time::GetGameTimeSince(GrindComp.TimeLastLeftGrindWithJump);
		if(TimeSinceLeftGrindByJump < 0.5)
			return true;
		
		auto SplinePos = GetMostValidSplinePosWithInputAndRange();
		if(!SplinePos.IsSet())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardSuctionToGrindActivationParams Params)
	{
		FVector Velocity = Player.ActorVelocity + MoveComp.PendingImpulse;
		if(Velocity.IsNearlyZero(MinSpeed))
			Velocity = Player.ActorForwardVector * MinSpeed;
		
		bool bIsGoingUpwards = Velocity.DotProduct(MoveComp.WorldUp) > 0.0;
		FVector VerticalVelocityDir = bIsGoingUpwards ? MoveComp.WorldUp : MoveComp.GravityDirection;
		FVector VerticalVelocity = Velocity.ConstrainToDirection(VerticalVelocityDir);
		FVector HorizontalVelocity = Velocity - VerticalVelocity;


		HorizontalSpeed = HorizontalVelocity.Size();

		FVector DeltaToSplinePos = (Params.SplinePos.WorldLocation - Player.ActorLocation);

		// FVector DirToSplinePos = DeltaToSplinePos.GetSafeNormal();
		// FVector FlatVelocity = Velocity.ConstrainToPlane(FVector::UpVector);
		SuctionSpeed = 0;
		// SuctionSpeed = Math::Max(FlatVelocity.DotProduct(DirToSplinePos), 0);
		PreviousDistToSplinePos = Params.SplinePos.WorldLocation.Distance(Player.ActorLocation);
		auto TemporalLog = TEMPORAL_LOG(Player, "Suction to Grind")
			.DirectionalArrow("Delta to Spline Pos", Player.ActorLocation, DeltaToSplinePos, 10, 5000, FLinearColor::White)
			.Value("Speed towards Spline Pos", SuctionSpeed)
		;

		if(JumpComp.bJumped)
			JumpComp.bAirborneFromJump = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JumpComp.bAirborneFromJump = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				auto TemporalLog = TEMPORAL_LOG(Player, "Suction to Grind");

				auto MaybeSplinePos = GetMostValidSplinePosWithInputAndRange();
				if(MaybeSplinePos.IsSet())
				{
					auto SplinePos = MaybeSplinePos.Value;
					FVector MovementInput = MoveComp.MovementInput;
					float InputSize = MovementInput.Size();

					UpdateRotation(DeltaTime, MovementInput);
					Movement.SetRotation(HoverboardComp.AccNudgeRotation.Value + HoverboardComp.AccRotation.Value);

					FRotator VelocityRot = GetVelocityRotation();
					VelocityRot = RotateVelocityRotation(VelocityRot, DeltaTime, InputSize);				
					HorizontalSpeed = UpdateHorizontalSpeed(DeltaTime);
					float TotalSpeed = HorizontalSpeed + LevelRubberbandingComp.RubberbandingSpeed + HoverboardComp.TrickBoostSpeed;

					FVector ForwardVelocity = VelocityRot.ForwardVector * TotalSpeed;
					FVector VerticalVelocity = MoveComp.VerticalVelocity + (MoveComp.GravityDirection * MoveComp.GravityForce * DeltaTime);
					
					FVector WantedLocation = Player.ActorLocation + ((ForwardVelocity + VerticalVelocity) * DeltaTime); 

					FVector DeltaToSplinePos = SplinePos.WorldLocation - WantedLocation;
					bool bDeltaIsUpwards = DeltaToSplinePos.DotProduct(FVector::DownVector) > 0;
					if(bDeltaIsUpwards)
						DeltaToSplinePos = DeltaToSplinePos.ConstrainToPlane(FVector::UpVector);
					FVector DirToSplinePos = DeltaToSplinePos.GetSafeNormal();
					float DistToSplinePos = DeltaToSplinePos.Size();
					if(DistToSplinePos < GrindSettings.SuctionToGrindOverrideDistance)
						DistToSplinePos = Math::Min(PreviousDistToSplinePos, DistToSplinePos);
					float DistanceAlpha = 1 - Math::Saturate(DistToSplinePos / GrindSettings.MaxHorizontalSuctionDistance);
					float TargetSuctionSpeed = GrindSettings.SuctionSpeed.Lerp(DistanceAlpha);
					float SuctionAcceleration = GrindSettings.SuctionAcceleration.Lerp(DistanceAlpha);
					SuctionSpeed = Math::FInterpTo(SuctionSpeed, TargetSuctionSpeed,DeltaTime, SuctionAcceleration);
					DistToSplinePos = Math::FInterpConstantTo(DistToSplinePos, 0, DeltaTime, TargetSuctionSpeed);
					WantedLocation = SplinePos.WorldLocation - DirToSplinePos * DistToSplinePos;

					PreviousDistToSplinePos = DistToSplinePos;

					FVector DeltaToWantedLocation = WantedLocation - Player.ActorLocation;
					DeltaToWantedLocation = DeltaToWantedLocation.ConstrainToPlane(FVector::UpVector);
					Movement.AddDelta(DeltaToWantedLocation);

					Movement.AddOwnerVerticalVelocity();
					Movement.AddGravityAcceleration();

					// Movement.AddDeltaFromMoveTo(WantedLocation);
					TemporalLog
						.DirectionalArrow("Velocity", Player.ActorLocation, MoveComp.Velocity, 10, 5000, FLinearColor::White)
						.DirectionalArrow("Forward Velocity", Player.ActorLocation, ForwardVelocity, 10, 5000, FLinearColor::Red)
						.Value("Dist to Spline Pos", DistToSplinePos)
						.Value("Dist Alpha", DistanceAlpha)
						.Value("Suction Speed", SuctionSpeed)
						.Value("Suction Acceleration", SuctionAcceleration)
						.Value("Target Suction Speed", TargetSuctionSpeed)
					;
				}
				else
				{
					Movement.AddOwnerVelocity();
					Movement.AddGravityAcceleration();
				}

				HoverboardComp.AnimParams.VerticalSpeedWhileAirborne = MoveComp.VerticalSpeed;
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			FName AnimTag = BattlefieldHoverboardLocomotionTags::HoverboardAirMovement;
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}
	}

	private FRotator GetVelocityRotation()
	{
		FRotator VelocityRot;
		if(Player.ActorHorizontalVelocity.IsNearlyZero())
			VelocityRot = HoverboardComp.AccRotation.Value;
		else
			VelocityRot = Player.ActorHorizontalVelocity.Rotation();

		return VelocityRot;
	}	

	private FRotator RotateVelocityRotation(FRotator VelocityRot, float DeltaTime, float InputSize)
	{
		float TurnSpeed = AirMovementSettings.HorizontalConstantVelocityTurnSpeed + AirMovementSettings.HorizontalInputVelocityTurnSpeed * InputSize;
		FRotator RotatedVelocityRot = Math::RInterpConstantTo(VelocityRot, HoverboardComp.AccRotation.Value, DeltaTime, TurnSpeed);

		return RotatedVelocityRot;
	}

	private float UpdateHorizontalSpeed(float DeltaTime)
	{
		HorizontalSpeed = Math::FInterpConstantTo(HorizontalSpeed, AirMovementSettings.MaxHorizontalSpeed, DeltaTime, AirMovementSettings.HorizontalAcceleration);
		return HorizontalSpeed;
	}

	private void UpdateRotation(float DeltaTime, FVector MovementInput)
	{
		HoverboardComp.AddWantedRotation(AirMovementSettings.WantedRotationSpeed, MovementInput, DeltaTime);
		HoverboardComp.SetCameraWantedRotationToWantedRotation();
		float TargetRotationDuration = MovementInput.IsNearlyZero() 
			? AirMovementSettings.RotationDuration 
			: AirMovementSettings.RotationDurationDuringInput;
		HoverboardComp.RotateTowardsWantedRotation(TargetRotationDuration, DeltaTime);
	}

	const float DebugDrawDuration = 0.0;
	TOptional<FSplinePosition> GetMostValidSplinePosWithInputAndRange() const
	{
		auto TemporalLog = TEMPORAL_LOG(Player, "Suction to Grind");

		TOptional<FSplinePosition> ValidSplinePos;

		FVector WorldMovementInput = HoverboardComp.GetMovementInputCameraSpace().ConstrainToPlane(FVector::UpVector);

		// FVector ClampedActorVelocity = Player.ActorVelocity.GetClampedToSize(GrindSettings.JumpToGrindMinSpeed, BIG_NUMBER);
		// FVector LocationAheadToCheck = Player.ActorLocation 
		// 	+ (ClampedActorVelocity * GrindSettings.VelocityDurationForJumpToGrindPointSampling);
		// FVector Start = LocationAheadToCheck;
		FVector Start = Player.ActorLocation;
		FVector End = Start + WorldMovementInput * GrindSettings.MaxDistanceToGrindForJump; 

		TemporalLog.Arrow("Input", Start, End, 10, 40, FLinearColor::Red);

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

			TemporalLog.Sphere(f"{GrindSpline.Owner} Spline Pos", SplinePos.WorldLocation, 20, FLinearColor::Blue);
			if(IsDebugActive())
			{
				Debug::DrawDebugSolidSphere(SplinePos.WorldLocation, 20, FLinearColor::Blue, DebugDrawDuration);
				const float DirArrowLength = 500.0;
				Debug::DrawDebugString(Player.ActorLocation + DirToPoint * DirArrowLength + FVector::UpVector * 10.0, f"{AngleBetweenDirAndCompareVector :.0}°", FLinearColor::White, DebugDrawDuration, 1.0);
			}

			if(AngleBetweenDirAndCompareVector > GrindSettings.JumpToGrindAngleThreshold)
				continue;

			float DistSqrdToPoint = SplinePos.WorldLocation.DistSquared2D(Start);
			if(DistSqrdToPoint >= Math::Square(GrindSettings.MaxHorizontalSuctionDistance))
				continue;

			if (SplinePos.WorldLocation.Z < Start.Z && Math::Abs(SplinePos.WorldLocation.Z - Start.Z) > GrindSettings.MaxVerticalSuctionDistance)
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

	TOptional<FSplinePosition> GetMostValidSplinePosForRangeOverride() const
	{
		auto TemporalLog = TEMPORAL_LOG(Player, "Suction to Grind Range Override");
		TOptional<FSplinePosition> ValidSplinePos;

		FVector Start = Player.ActorLocation;
		FVector End = Start + (Player.ActorVelocity * GrindSettings.SuctionToGrindLandLocationVelocityEstimationDuration);

		TemporalLog.Arrow("Input", Start, End, 10, 40, FLinearColor::Red);

		if(IsDebugActive())
			Debug::DrawDebugArrow(Start, End, 40, FLinearColor::Red, 20, DebugDrawDuration);
		
		float ClosestDistSqrd = MAX_flt;
		for(auto GrindSpline : GrindComp.GrindSplineComps)
		{
			auto SplinePos = GrindSpline.SplineComp.GetClosestSplinePositionToLineSegment(Start, End);

			if(GrindComp.IsGrinding()
			&& GrindSpline.PlayerIsOnGrind(Player))
				continue;

			if(SplinePos.IsAtEnd())
				continue;

			TemporalLog.Sphere(f"{GrindSpline.Owner} Spline Pos", SplinePos.WorldLocation, 20, FLinearColor::Blue);
			if(IsDebugActive())
			{
				Debug::DrawDebugSolidSphere(SplinePos.WorldLocation, 20, FLinearColor::Blue, DebugDrawDuration);
			}

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