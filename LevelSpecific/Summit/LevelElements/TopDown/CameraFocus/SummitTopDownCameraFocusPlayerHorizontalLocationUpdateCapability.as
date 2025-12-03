class USummitTopDownCameraFocusPlayerHorizontalLocationUpdateCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;

	ASummitTopDownCameraFocusActor FocusActor;
	USummitTopDownCameraFocusPlayerComponent FocusComp;

	UPlayerTeenDragonComponent DragonComp;

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

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if(!DragonComp.bTopDownMode)
		// 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
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
		FocusActor.PlayerLocation[Player].X = Player.ActorCenterLocation.X;
		FocusActor.PlayerLocation[Player].Y = Player.ActorCenterLocation.Y;
	}
};