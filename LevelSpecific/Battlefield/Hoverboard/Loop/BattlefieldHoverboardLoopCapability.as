struct FBattlefieldHoverboardLoopActivationParams
{
	UBattlefieldLoopComponent LoopComp;
	FSplinePosition StartSplinePosition;
}

class UBattlefieldHoverboardLoopCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 50;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardLoopComponent HoverboardLoopComp;
	UBattlefieldHoverboardLevelRubberbandingComponent RubberbandingComp;
	UPlayerMovementComponent MoveComp;

	UTeleportingMovementData Movement;

	UBattlefieldHoverboardGroundMovementSettings GroundMovementSettings;

	const float BaseForwardSpeed = 2500.0;
	const float SidewaysAcceleration = 140.0;
	const float SidewaysFriction = 4.8;
	const float SidewaysMaxSpeed = 300.0;
	const float SidewaysCounterVelocityAlphaPercent = 0.75;
	const float RotationAccelerationDuration = 0.5;
	const float OffsetUpwardsFromSpline = 50;

	FVector StartOffset;

	FHazeAcceleratedRotator AccRotation;

	FSplinePosition CurrentSplinePos;

	float SidewaysSpeed;
	float DistanceToRight;

	bool bTargetHasReachedEnd = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		HoverboardLoopComp = UBattlefieldHoverboardLoopComponent::Get(Player);
		RubberbandingComp = UBattlefieldHoverboardLevelRubberbandingComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();

		GroundMovementSettings = UBattlefieldHoverboardGroundMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardLoopActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!HoverboardComp.IsOn())
			return false;

		if(!MoveComp.HasGroundContact())
			return false;

		if(DeactiveDuration < 0.5)
			return false;

		FMovementHitResult GroundHit = MoveComp.GroundContact;
		auto LoopComp = UBattlefieldLoopComponent::Get(GroundHit.Actor);

		if(LoopComp == nullptr)
			return false;

		Params.LoopComp = LoopComp;

		FSplinePosition StartSplinePosition = LoopComp.SplineComp.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
		float SplineAlignment = StartSplinePosition.WorldForwardVector.DotProduct(Player.ActorForwardVector);

		if(SplineAlignment < 0)
			StartSplinePosition.ReverseFacing();

		Params.StartSplinePosition = StartSplinePosition;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!HoverboardComp.IsOn())
			return true;

		if(bTargetHasReachedEnd)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardLoopActivationParams Params)
	{
		HoverboardLoopComp.CurrentLoopComp = Params.LoopComp;
		CurrentSplinePos = Params.StartSplinePosition;

		AccRotation.SnapTo(Player.ActorRotation);
		SidewaysSpeed = 0.0;
			
		FVector DeltaToPlayer = Player.ActorLocation - CurrentSplinePos.WorldLocation;
		DistanceToRight = CurrentSplinePos.WorldRightVector.DotProduct(DeltaToPlayer);

		FVector TargetSplinePos = GetSplineTargetLocation(DistanceToRight);
		StartOffset = Player.ActorLocation - TargetSplinePos;

		HoverboardLoopComp.bIsInLoop = true;
		bTargetHasReachedEnd = false;

		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		HoverboardLoopComp.CurrentLoopComp.OnPlayerEnteredLoop.Broadcast(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FRotator FlatRotation = Player.ActorRotation;
		FlatRotation.Pitch = 0.0;
		FlatRotation.Roll = 0.0;

		Player.SetActorRotation(FlatRotation);
		HoverboardComp.ResetWantedRotationToCurrentRotation();
		HoverboardComp.AccRotation.SnapTo(FlatRotation);

		HoverboardLoopComp.bIsInLoop = false;
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		HoverboardLoopComp.CurrentLoopComp.OnPlayerExitedLoop.Broadcast(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Speed = GroundMovementSettings.BaseSpeed + 500.0;
		float TotalForwardSpeed = Speed + RubberbandingComp.RubberbandingSpeed + HoverboardComp.TrickBoostSpeed;

		float RemainingDistance = 0.0;
		bTargetHasReachedEnd = !CurrentSplinePos.Move(TotalForwardSpeed * DeltaTime, RemainingDistance);

		if (MoveComp.PrepareMove(Movement, CurrentSplinePos.WorldUpVector))
		{
			if (HasControl())
			{
				AccRotation.AccelerateTo(CurrentSplinePos.WorldForwardVector.Rotation(), RotationAccelerationDuration, DeltaTime);
				Movement.SetRotation(AccRotation.Value);

				DistanceToRight = UpdateDistanceToRight(DeltaTime);
				FVector TargetLocation = GetSplineTargetLocation(DistanceToRight);

				StartOffset = Math::VInterpTo(StartOffset, FVector::ZeroVector, DeltaTime, 10);
				TargetLocation += StartOffset;

				FVector Velocity = CurrentSplinePos.WorldForwardVector * TotalForwardSpeed * DeltaTime
					+ CurrentSplinePos.WorldRightVector * SidewaysSpeed * DeltaTime;

				if(bTargetHasReachedEnd)
					Movement.AddDelta(Velocity);
				else
					Movement.AddDeltaFromMoveToPositionWithCustomVelocity(TargetLocation, Velocity);

				FRotator FlatRotation = Player.ActorRotation;
				FlatRotation.Pitch = 0.0;
				FlatRotation.Roll = 0.0;
				HoverboardComp.CameraWantedRotation = FlatRotation;

				TEMPORAL_LOG(HoverboardLoopComp)
					.Sphere("Target Location", TargetLocation, 50, FLinearColor::Red, 5)
					.DirectionalArrow("Velocity", Player.ActorLocation, Velocity, 5, 40, FLinearColor::Black)
				;

			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			FName AnimTag = n"Hoverboard";
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
			TEMPORAL_LOG(HoverboardLoopComp)
				.Sphere("Current Spline Position", CurrentSplinePos.WorldLocation, 50, FLinearColor::Blue, 5)
				.Value("Remaining Distance", RemainingDistance)
				.Value("Total Forward Speed", TotalForwardSpeed)
			;
		}
	}

	FVector GetSplineTargetLocation(float CurrentDistanceToRight) const
	{
		return CurrentSplinePos.WorldLocation
			+ CurrentSplinePos.WorldRightVector * CurrentDistanceToRight
			+ CurrentSplinePos.WorldUpVector * OffsetUpwardsFromSpline;
	}

	float UpdateDistanceToRight(float DeltaTime)
	{
		FVector MovementInput = MoveComp.MovementInput;

		SidewaysSpeed += MovementInput.Y * SidewaysAcceleration * DeltaTime;
		SidewaysSpeed -= SidewaysSpeed * SidewaysFriction * DeltaTime;
		SidewaysSpeed = Math::Clamp(SidewaysSpeed, -SidewaysMaxSpeed, SidewaysMaxSpeed);

		float CounterSidewaysSpeed = 0;

		if(HoverboardLoopComp.CurrentLoopComp.bRestrictSideways)
		{
			float MaxDistFromSpline = HoverboardLoopComp.CurrentLoopComp.LoopSize;
			float PercentDistanceToSpline = Math::Abs(DistanceToRight) / MaxDistFromSpline;

			if(PercentDistanceToSpline > SidewaysCounterVelocityAlphaPercent
				&& Math::Sign(DistanceToRight) == Math::Sign(SidewaysSpeed))
			{
				// Speed is going towards the closest clamp
				float WeightedPercentDistanceFromSpline = Math::NormalizeToRange(Math::Abs(DistanceToRight), MaxDistFromSpline * SidewaysCounterVelocityAlphaPercent, MaxDistFromSpline);
				CounterSidewaysSpeed = -SidewaysSpeed * WeightedPercentDistanceFromSpline;
				TEMPORAL_LOG(HoverboardLoopComp)
					.Value("Percent Distance to Spline", WeightedPercentDistanceFromSpline)
					.Value("Counter Sideways Speed", CounterSidewaysSpeed)
				;
			}
		}

		return DistanceToRight + SidewaysSpeed + CounterSidewaysSpeed;
	}
};