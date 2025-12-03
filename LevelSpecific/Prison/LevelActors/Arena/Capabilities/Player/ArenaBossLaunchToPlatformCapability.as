class UArenaBossLaunchToPlatformCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UArenaBossLaunchToPlatformUserComponent UserComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UArenaBossLaunchToPlatformUserComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		
		if (!UserComp.bIsLaunched)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < 0.5)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return true;

		// if (MoveComp.VerticalSpeed < 0.0)
			// return true;

		if (MoveComp.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.bIsLaunched = false;

		FVector Delta = UserComp.LaunchVelocity * Time::GetActorDeltaSeconds(Player);

		if (MoveComp.PrepareMove(Movement))
		{
			Movement.AddDeltaWithCustomVelocity(Delta, UserComp.LaunchVelocity);
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
		}

		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
		Player.BlockCapabilities(PlayerMovementTags::AirJump, this);

		UPlayerAirMotionSettings::SetAirControlMultiplier(Player, 0.0, this);
		UPlayerAirMotionSettings::SetDragOfExtraHorizontalVelocity(Player, 0.0, this);

		Player.FlagForLaunchAnimations(UserComp.LaunchVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);

		UPlayerAirMotionSettings::ClearAirControlMultiplier(Player, this);
		UPlayerAirMotionSettings::ClearDragOfExtraHorizontalVelocity(Player, this);

		Player.PlayCameraShake(UserComp.LandCamShake, this);
		Player.PlayForceFeedback(UserComp.LandFF, false, true, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};