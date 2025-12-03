struct FAcknowledgedLocalLaunch
{
	FInstigator Instigator;
	float CrumbTime;
	float ReceivedRealTime;
	FVector PlayerLocation;
}

class UPlayerLocalLaunchToCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"LaunchTo");
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 11;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	UPlayerLaunchToComponent LaunchToComp;
	UPlayerAirMotionComponent AirMotionComp;

	FInstigator LaunchToInstigator;
	FPlayerLaunchToParameters LaunchToParams;
	
	TArray<FAcknowledgedLocalLaunch> ControlAcknowledgedLaunches;

	FPlayerLaunchToMovementCalculator MovementCalculator;
	float AdjustedActiveDuration = 0.0;
	float TargetActiveDuration = 0.0;
	float PredictedCrumbTimeOfAcknowledgement = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		LaunchToComp = UPlayerLaunchToComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!LaunchToComp.bHasPendingLaunchTo)
			return false;
		if (LaunchToComp.PendingLaunchTo.NetworkMode == EPlayerLaunchToNetworkMode::Crumbed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (IsLaunchAcknowledged(LaunchToInstigator))
		{
			if (HasControl())
			{
				// Local launch on the control side
				if (AdjustedActiveDuration >= LaunchToParams.Duration)
					return true;
			}
			else
			{
				// If a simulated launch finished and was acknowledged
				if (TargetActiveDuration >= LaunchToParams.Duration && AdjustedActiveDuration >= LaunchToParams.Duration)
					return true;
			}
		}
		else
		{
			// If a simulated launch was not acknowledged in time
			if (ActiveDuration > 1.0 + Network::PingRoundtripSeconds)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AdjustedActiveDuration = 0.0;
		TargetActiveDuration = 0.0;
		LaunchToInstigator = LaunchToComp.PendingLaunchToInstigator;
		LaunchToParams = LaunchToComp.PendingLaunchTo;
		LaunchToComp.bHasPendingLaunchTo = false;

		if (HasControl())
		{
			NetAcknowledgeLaunch(
				LaunchToInstigator,
				Time::GetPlayerCrumbTrailTime(Player),
				Player.ActorLocation
			);
		}
		else
		{
			// If the launch was already acknowledged we know what our starting time and location should be
			if (IsLaunchAcknowledged(LaunchToInstigator))
			{
				Player.ActorLocation = GetPlayerLocationOfAcknowledgement(LaunchToInstigator);

				AdjustedActiveDuration = Math::Max(
					Time::GetPlayerCrumbTrailTime(Player) - GetCrumbTimeOfAcknowledgement(LaunchToInstigator),
					0.0);
			}
			else
			{
				PredictedCrumbTimeOfAcknowledgement = Time::GetPlayerCrumbTrailTime(Player) + Time::EstimatedCrumbReachedDelay;
			}
		}

		MovementCalculator.Start(Player, LaunchToParams, 0.0);

		if (!LaunchToParams.ShouldHaveCollision())
			Player.BlockCapabilities(CapabilityTags::Collision, this);

		if (LaunchToParams.LaunchRelativeToComponent != nullptr)
			MoveComp.ApplyCrumbSyncedRelativePosition(this, LaunchToParams.LaunchRelativeToComponent);
		
		//Set anim data for launch
		if(LaunchToParams.bPlayLaunchAnimations)
		{
			AirMotionComp.AnimData.bPlayerLaunchDetected = true;
			AirMotionComp.AnimData.LaunchDetectedFrameCount = Time::GetFrameNumber();
		}

		if(LaunchToParams.Type == EPlayerLaunchToType::LaunchWithImpulse)
		{
			AirMotionComp.AnimData.InitialLaunchImpulse = LaunchToParams.LaunchImpulse;
			AirMotionComp.AnimData.InitialLaunchDirection = LaunchToParams.LaunchImpulse.GetSafeNormal();
		}
		else
		{
			AirMotionComp.AnimData.InitialLaunchDirection = MovementCalculator.GetCurrentWorldVelocity(0.0);
		}
	}

	bool IsLaunchAcknowledged(FInstigator Instigator) const
	{
		for (FAcknowledgedLocalLaunch Launch : ControlAcknowledgedLaunches)
		{
			if (Launch.Instigator == Instigator)
				return true;
		}

		return false;
	}

	float GetCrumbTimeOfAcknowledgement(FInstigator Instigator) const
	{
		for (FAcknowledgedLocalLaunch Launch : ControlAcknowledgedLaunches)
		{
			if (Launch.Instigator == Instigator)
				return Launch.CrumbTime;
		}

		return 0.0;
	}

	FVector GetPlayerLocationOfAcknowledgement(FInstigator Instigator) const
	{
		for (FAcknowledgedLocalLaunch Launch : ControlAcknowledgedLaunches)
		{
			if (Launch.Instigator == Instigator)
				return Launch.PlayerLocation;
		}

		return FVector();
	}

	UFUNCTION(NetFunction)
	void NetAcknowledgeLaunch(FInstigator Instigator, float CrumbTime, FVector PlayerLocation)
	{
		FAcknowledgedLocalLaunch Launch;
		Launch.Instigator = Instigator;
		Launch.CrumbTime = CrumbTime;
		Launch.ReceivedRealTime = Time::RealTimeSeconds;
		Launch.PlayerLocation = PlayerLocation;
		ControlAcknowledgedLaunches.Add(Launch);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// If the control side did a local launch that never happened on our side,
		// perform the transition after a second or two so it doesn't get lost,
		// and just smooth teleport there.
		if (!HasControl())
		{
			for (int i = 0, Count = ControlAcknowledgedLaunches.Num(); i < Count; ++i)
			{
				const FAcknowledgedLocalLaunch& Launch = ControlAcknowledgedLaunches[i];
				if (!IsActive() && (Time::RealTimeSeconds - Launch.ReceivedRealTime) > 2.0)
				{
					Player.RootOffsetComponent.FreezeLocationAndLerpBackToParent(this, 0.25);
					ControlAcknowledgedLaunches.RemoveAt(i);
					--i; --Count;
					MoveComp.TransitionCrumbSyncedPosition(this);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (IsLaunchAcknowledged(LaunchToInstigator))
		{
			// This launch happened on both sides, so do a transition
			for (int i = 0, Count = ControlAcknowledgedLaunches.Num(); i < Count; ++i)
			{
				const FAcknowledgedLocalLaunch& Launch = ControlAcknowledgedLaunches[i];
				if (Launch.Instigator == LaunchToInstigator)
				{
					ControlAcknowledgedLaunches.RemoveAt(i);
					break;
				}
			}

			MoveComp.TransitionCrumbSyncedPosition(this);
		}

		// Smooth lerp back to the crumb trail
		auto SyncOffsetComp = UPlayerSyncLocationMeshOffsetComponent::GetOrCreate(Player);
		SyncOffsetComp.OffsetBackToCrumbTrail();

		if (!LaunchToParams.ShouldHaveCollision())
			Player.UnblockCapabilities(CapabilityTags::Collision, this);
		MoveComp.ClearCrumbSyncedRelativePosition(this);

		FVector ExitVelocity = MovementCalculator.GetExitVelocity();
		Player.SetActorVelocity(ExitVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			AdjustedActiveDuration += DeltaTime;
		}
		else
		{
			if (LaunchToParams.NetworkMode == EPlayerLaunchToNetworkMode::SimulateLocalImmediateTrajectory)
			{
				AdjustedActiveDuration += DeltaTime;
				TargetActiveDuration = AdjustedActiveDuration;
			}
			else
			{
				float AckCrumbTime;
				if (IsLaunchAcknowledged(LaunchToInstigator))
					AckCrumbTime = GetCrumbTimeOfAcknowledgement(LaunchToInstigator);
				else
					AckCrumbTime = PredictedCrumbTimeOfAcknowledgement;
				TargetActiveDuration = Time::GetPlayerCrumbTrailTime(Player) - AckCrumbTime;
				AdjustedActiveDuration += DeltaTime;

				float RemainingDuration = LaunchToParams.Duration - AdjustedActiveDuration;
				float AdjustThisFrame = 0;
				if (RemainingDuration > 0)
				{
					float AdjustAmount = TargetActiveDuration - AdjustedActiveDuration;
					AdjustThisFrame = Math::Clamp(AdjustAmount / RemainingDuration * DeltaTime, -0.5 * DeltaTime, 0.5 * DeltaTime);

					AdjustedActiveDuration += AdjustThisFrame;
				}

				TEMPORAL_LOG(this)
					.Value("ActiveDuration", ActiveDuration)
					.Value("AdjustedActiveDuration", AdjustedActiveDuration)
					.Value("TargetActiveDuration", TargetActiveDuration)
					.Value("IsAcknowledged", IsLaunchAcknowledged(LaunchToInstigator))
					.Value("AdjustThisFrame", AdjustThisFrame)
				;
			}
		}

		if (MoveComp.PrepareMove(Movement))
		{
			FVector WantedLocation = MovementCalculator.GetCurrentWorldLocation(AdjustedActiveDuration);
			FVector WantedVelocity = MovementCalculator.GetCurrentWorldVelocity(AdjustedActiveDuration);

			Movement.AddDeltaWithCustomVelocity(WantedLocation - Player.ActorLocation, WantedVelocity);

			if (LaunchToParams.bRotate)
				Movement.InterpRotationTo(MovementCalculator.GetCurrentTargetRotation(AdjustedActiveDuration), PI * 4.0);

			if(AirMotionComp.AnimData.bPlayerLaunchDetected)
			{
				if (Player.Mesh.CanRequestLocomotion())
					Player.Mesh.RequestLocomotion(n"Launch", this);
				AirMotionComp.AnimData.ResetLaunchData();
				MoveComp.ApplyMove(Movement);
			}
			else if (MoveComp.IsOnAnyGround())
				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
			else
				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
		}
	}
};