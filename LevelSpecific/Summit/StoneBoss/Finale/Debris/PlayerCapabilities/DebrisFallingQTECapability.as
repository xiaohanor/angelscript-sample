class UDebrisFallingQTECapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"DebrisFalling");

	default TickGroup = EHazeTickGroup::Gameplay;

	UDebrisFallingPlayerComponent UserComp;
	UDebrisFallingPlayerComponent OtherUserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDebrisFallingPlayerComponent::Get(Player);
		OtherUserComp = UDebrisFallingPlayerComponent::Get(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.HasControl())
			if (UserComp.bPlayersHaveGrappled && OtherUserComp.bPlayersHaveGrappled)
				return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = UserComp.FallingAnimation;
		Player.PlaySlotAnimation(Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopAllSlotAnimations();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::Grapple) && !UserComp.bPlayersHaveGrappled)
		{
			UserComp.bPlayersHaveGrappled = true;
			FHazePlaySlotAnimationParams Params;
			Params.Animation = UserComp.GrappleAnimation;
			Player.PlaySlotAnimation(Params);
		}
	}
};