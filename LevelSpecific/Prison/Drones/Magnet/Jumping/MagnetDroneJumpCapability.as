class UMagnetDroneJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneJump);

	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttraction);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttached);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80;
	default TickGroupSubPlacement = 100;

	UMagnetDroneComponent DroneComp;
	UMagnetDroneJumpComponent JumpComp;
	UMagnetDroneBounceComponent BouncedComp;

	UHazeMovementComponent MoveComp;

	private float JumpGraceTimer = BIG_NUMBER;
	private FVector LastGroundNormal;
	private float LastJumpTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		JumpComp = UMagnetDroneJumpComponent::Get(Player);
		BouncedComp = UMagnetDroneBounceComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!JumpComp.WasJumpInputStartedDuringTime(DroneComp.MovementSettings.JumpInputBufferTime))
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

  		if(!IsInJumpGracePeriod())
			return false;

		if(JumpComp.IsJumping())
			return false;

		// Don't allow jumping if our last ground (which could have been magnetic) was facing towards the ground
		// This prevents being able to jump in the grace window after detaching from a ceiling
		if(LastGroundNormal.Z < -0.1)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.IsOnWalkableGround())
			return true;

		if(BouncedComp.bIsInBounceState)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		JumpComp.ConsumeJumpInput();

		JumpComp.ApplyIsJumping(this);
		JumpComp.AddJumpImpulse(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JumpComp.ClearIsJumping(this);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("JumpGraceTimer", JumpGraceTimer);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MoveComp.IsOnWalkableGround() || MoveComp.HasUnstableGroundContactEdge())
		{
			JumpGraceTimer = 0.0;
			LastGroundNormal = MoveComp.GroundContact.ImpactNormal;
		}
		else
		{
			JumpGraceTimer += DeltaTime;
		}
	}

	bool IsInJumpGracePeriod() const
	{
		// We can always jump after bouncing
		if(BouncedComp.bIsInBounceState)
			return true;
		
		return JumpGraceTimer <= DroneComp.MovementSettings.JumpGraceTime;
	}
};