class UDragonSwordPinToGroundCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordPinToGround);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	UDragonSwordPinToGroundComponent PinComp;
	UPlayerMovementComponent MoveComp;

	bool bHasAttached = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PinComp = UDragonSwordPinToGroundComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		//this sheet is only added from a volume in the stonebeasthead section, few requirements needed to activate
		if (!MoveComp.HasGroundContact())
			return false;

		// if (!MoveComp.GetGroundContact().bIsWalkable)
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PinComp.State == EDragonSwordPinToGroundState::Exit)
		{
			if (PinComp.bIsExitFinished)
				return true;
		}
		else if (PinComp.State == EDragonSwordPinToGroundState::None)
		{
			if (!MoveComp.HasGroundContact())
				return true;
		}
		// else
		// {
		// 	if (MoveComp.HasGroundContact() && !MoveComp.GroundContact.bIsWalkable)
		// 		return true;
		// }
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PinComp.ExitState = EDragonSwordPinToGroundExitAnimState::None;
		PinComp.State = EDragonSwordPinToGroundState::None;

		PinComp.TimeOnPinnableGround = 0;
		bHasAttached = false;
		PinComp.bCanAttach = true;

		Player.BlockCapabilities(DragonSwordCapabilityTags::DragonSword, this);
		if (PinComp.bIsTutorialComplete)
			return;

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		TutorialPrompt.Text = NSLOCTEXT("StoneBossHeadQTE", "HoldRT", "Cling");
		if (Player.IsMio())
			TutorialPrompt.OverrideControlsPlayer = EHazeSelectPlayer::Mio;
		TutorialPrompt.AlternativeDisplayType = ETutorialAlternativePromptDisplay::Keyboard_LeftRight;
		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(DragonSwordCapabilityTags::DragonSword, this);
		PinComp.bCanAttach = false;
		Player.RemoveTutorialPromptByInstigator(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!PinComp.IsPlayerPinnedToGround() && PinComp.bIsExitFinished && Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"SwordWindWalk", this);

		PinComp.TimeOnPinnableGround = ActiveDuration;
	}
};