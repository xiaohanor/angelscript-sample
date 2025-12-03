class USummitTopDownCameraFocusPlayerVerticalLocationUpdateCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;

	ASummitTopDownCameraFocusActor FocusActor;
	USummitTopDownCameraFocusPlayerComponent FocusComp;

	UPlayerTeenDragonComponent DragonComp;

	float LastJumpStartHeight = -MAX_flt;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FocusComp = USummitTopDownCameraFocusPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(FocusActor == nullptr)
			return false;

		if(DragonComp == nullptr)
			return false;

		// if(!DragonComp.bTopDownMode)
		// 	return false;

		if(!DragonComp.bIsInAirFromJumping)
			return true;

		if(Player.ActorCenterLocation.Z < LastJumpStartHeight)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if(!DragonComp.bTopDownMode)
		// 	return true;

		if(!DragonComp.bIsInAirFromJumping)
			return false;

		if(Player.ActorCenterLocation.Z < LastJumpStartHeight)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastJumpStartHeight = -MAX_flt;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LastJumpStartHeight = Player.ActorCenterLocation.Z;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(FocusActor == nullptr
		&& FocusComp.FocusActor != nullptr)
			FocusActor = FocusComp.FocusActor;

		if(DragonComp == nullptr)
			DragonComp = UPlayerTeenDragonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Player.IsPlayerDead())
			return;

		FocusActor.PlayerLocation[Player].Z = Player.ActorCenterLocation.Z;
	}
};