class UPlayerCrumbedLaunchToCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"LaunchTo");
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 10;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	UPlayerLaunchToComponent LaunchToComp;
	UPlayerAirMotionComponent AirMotionComp;

	FPlayerLaunchToParameters LaunchToParams;
	FPlayerLaunchToMovementCalculator MovementCalculator;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		LaunchToComp = UPlayerLaunchToComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerLaunchToParameters& ActivationParameters) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!LaunchToComp.bHasPendingLaunchTo)
			return false;
		if (LaunchToComp.PendingLaunchTo.NetworkMode != EPlayerLaunchToNetworkMode::Crumbed)
			return false;

		ActivationParameters = LaunchToComp.PendingLaunchTo;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (ActiveDuration > LaunchToParams.Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsBlocked())
			LaunchToComp.bHasPendingLaunchTo = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerLaunchToParameters ActivationParameters)
	{
		LaunchToParams = ActivationParameters;
		LaunchToComp.bHasPendingLaunchTo = false;

		MovementCalculator.Start(Player, LaunchToParams, GetCapabilityDeltaTime());
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

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (!LaunchToParams.ShouldHaveCollision())
			Player.UnblockCapabilities(CapabilityTags::Collision, this);
		MoveComp.ClearCrumbSyncedRelativePosition(this);
		Player.SetActorVelocity(MovementCalculator.GetExitVelocity());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector WantedLocation = MovementCalculator.GetCurrentWorldLocation(ActiveDuration);
				FVector WantedVelocity = MovementCalculator.GetCurrentWorldVelocity(ActiveDuration);

				Movement.AddDeltaWithCustomVelocity(WantedLocation - Player.ActorLocation, WantedVelocity);
				
				if (LaunchToParams.bRotate)
					Movement.InterpRotationTo(MovementCalculator.GetCurrentTargetRotation(ActiveDuration), PI * 4.0);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

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