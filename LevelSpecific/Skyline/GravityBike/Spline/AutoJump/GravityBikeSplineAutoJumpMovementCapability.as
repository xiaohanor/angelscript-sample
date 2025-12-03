class UGravityBikeSplineAutoJumpMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;
	UGravityBikeSplineMovementData MoveData;

	UGravityBikeSplineAutoJumpComponent AutoJumpComp;
	FTraversalTrajectory OriginalTrajectory;
	FTraversalTrajectory AutoJumpTrajectory;

	UGravityBikeSplineJumpComponent JumpComp;
	bool bJumped = false;
	float32 InitialFrameDeltaTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = UGravityBikeSplineMovementComponent::Get(GravityBike);
		MoveData = MoveComp.SetupMovementData(UGravityBikeSplineMovementData);

		AutoJumpComp = UGravityBikeSplineAutoJumpComponent::Get(GravityBike);

		JumpComp = UGravityBikeSplineJumpComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!AutoJumpComp.HasTarget())
			return false;

		if(MoveComp.HasAnyValidBlockingContacts())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!AutoJumpComp.HasTarget())
			return true;

		if(MoveComp.HasAnyValidBlockingContacts())
			return true;

		if(ActiveDuration > AutoJumpTrajectory.GetTotalTime())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		InitialFrameDeltaTime = GetCapabilityDeltaTime();
		if(HasControl())
		{
			OriginalTrajectory = FTraversalTrajectory();
			OriginalTrajectory.LaunchLocation = GravityBike.ActorLocation;
			OriginalTrajectory.LaunchVelocity = GravityBike.ActorVelocity;
			OriginalTrajectory.Gravity = MoveComp.GetGravity();
			OriginalTrajectory.LandLocation = AutoJumpTrajectory.LandLocation;
			OriginalTrajectory.LandArea = AutoJumpTrajectory.LandArea;

			AutoJumpTrajectory = AutoJumpComp.PlotTrajectory(
				OriginalTrajectory.LaunchLocation,
				OriginalTrajectory.LaunchVelocity,
				GravityBike.GetGlobalWorldUp(),
				MoveComp.GravityForce
			);

			bJumped = false;
		}
		else
		{

		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AutoJumpComp.Reset();

		if(bJumped)
			JumpComp.StopJumping(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(MoveData, GravityBike.GetSplineUp()))
			return;

		if (HasControl())
		{
			if(ShouldJump())
			{
				// We jumped while still in coyote time!
				Jump();
			}

			const float Time = ActiveDuration + InitialFrameDeltaTime;

			const FVector OriginalTrajectoryLocation = OriginalTrajectory.GetLocation(Time);

			// If we are giving input, adjust in that direction
			AutoJumpComp.AdjustTrajectory(OriginalTrajectory, AutoJumpTrajectory, GravityBike.ActorForwardVector, GravityBike.GetGlobalWorldUp());

			const FVector AutoJumpTrajectoryLocation = AutoJumpTrajectory.GetLocation(Time);

			// OriginalTrajectory.DrawDebug(FLinearColor::Green, 0, 10);
			// AutoJumpTrajectory.DrawDebug(FLinearColor::Red, 0, 10);

			float Alpha = Math::Saturate(Time / (AutoJumpTrajectory.GetTotalTime()));
			Alpha = Math::EaseInOut(0, 1, Alpha, 2);

			// Lerp between the original trajectory and the auto jump trajectory to smoothly transition to the new trajectory
			const FVector Location = Math::Lerp(OriginalTrajectoryLocation, AutoJumpTrajectoryLocation, Alpha);

			MoveData.AddDeltaFromMoveTo(Location);

			GravityBike.TurnBike(MoveData, DeltaTime);
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		TemporalLog.Section("OriginalTrajectory")
			.Point("Launch Location", OriginalTrajectory.LaunchLocation)
			.DirectionalArrow("Launch Velocity", OriginalTrajectory.LaunchLocation, OriginalTrajectory.LaunchVelocity)
			.DirectionalArrow("Gravity", GravityBike.ActorLocation, OriginalTrajectory.Gravity)
			.Point("Land Location", OriginalTrajectory.LandLocation)
			.Value("Land Area", OriginalTrajectory.LandArea)
		;

		TemporalLog.Section("AutoJumpTrajectory")
			.Point("Launch Location", AutoJumpTrajectory.LaunchLocation)
			.DirectionalArrow("Launch Velocity", AutoJumpTrajectory.LaunchLocation, AutoJumpTrajectory.LaunchVelocity)
			.DirectionalArrow("Gravity", GravityBike.ActorLocation, AutoJumpTrajectory.Gravity)
			.Point("Land Location", AutoJumpTrajectory.LandLocation)
			.Value("Land Area", AutoJumpTrajectory.LandArea)
		;

		TemporalLog.Section("Jump")
			.Value("Jumped", bJumped)
		;
	}

	bool ShouldJump() const
	{
		if(!WasActionStartedDuringTime(ActionNames::MovementJump, 0.2))
			return false;

		if(JumpComp.IsJumping())
			return false;

		if(GravityBike.IsAirborne.Get())
			return false;

		return true;
	}

	void Jump()
	{
		GravityBike.GetDriver().ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

		FVector JumpImpulse;
		if(JumpComp.Settings.bCanApplyJumpImpulse && JumpComp.GetImpulseToApply(JumpImpulse))
		{
			// Adjust the auto jump trajectory as if we jumped all along
			AutoJumpTrajectory = AutoJumpComp.PlotTrajectory(
				OriginalTrajectory.LaunchLocation,
				OriginalTrajectory.LaunchVelocity + JumpImpulse,
				GravityBike.GetGlobalWorldUp(),
				MoveComp.GravityForce
			);

#if !RELEASE
			TEMPORAL_LOG(this).DirectionalArrow("Jump Impulse", GravityBike.ActorLocation, JumpImpulse);
#endif
		}

		CrumbJump();
	}

	UFUNCTION(CrumbFunction)
	void CrumbJump()
	{
		JumpComp.StartJumping(this);
		bJumped = true;
	}
};