class USpaceWalkHackingCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(n"SpaceWalkHacking");

	ASpaceWalkEscapeDropshipFinal HackManager;
	USpaceWalkOxygenPlayerComponent OxygenComp;

	bool bStickMovedLeft;
	bool bStickMovedRight;
	bool bRemoteActive;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HackManager = TListedActors<ASpaceWalkEscapeDropshipFinal>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HackManager.HasEntered[Player])
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HackManager.HasEntered[Player])
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		OxygenComp = USpaceWalkOxygenPlayerComponent::Get(Player);
		OxygenComp.bTouchScreenGrounded = !HackManager.bStartedSecondPhase;

		bStickMovedLeft = false;
		bStickMovedRight = false;

		if (!HasControl() || !Network::IsGameNetworked())
			NetSetRemoteActive(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (!HasControl() || !Network::IsGameNetworked())
			NetSetRemoteActive(false);
	}

	UFUNCTION(NetFunction)
	void NetSetRemoteActive(bool bActive)
	{
		bRemoteActive = bActive;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.StopAllSlotAnimations();
		if (Player.Mesh.CanRequestLocomotion())
			Player.Mesh.RequestLocomotion(n"SpaceTouchScreen", this);

		if(HasControl() && bRemoteActive && HackManager.bHackingAllowed)
		{
			StickUpdate();

			if (WasActionStarted(ActionNames::Interaction) && HackManager.CanPlayerUseInput(Player))
				NetActivate();

			// if(Player.IsMio() && WasActionStarted(ActionNames::Cancel) && HackManager.bHackingAllowed)
			// 	HackManager.MioCancel();

			// if(Player.IsZoe() && WasActionStarted(ActionNames::Cancel) && HackManager.bHackingAllowed)
			// 	HackManager.ZoeCancel();			
		}
	}

	void StickUpdate()
	{
		float CurrentInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).X;

		if(bStickMovedLeft && CurrentInput > -0.2 && HackManager.bHackingAllowed)
			bStickMovedLeft = false;

		if(bStickMovedRight && CurrentInput < 0.2 && HackManager.bHackingAllowed)
			bStickMovedRight = false;		

		if(CurrentInput > 0.8 && !bStickMovedRight && HackManager.CanPlayerUseInput(Player))
			NetStickMoveRight();

		if(CurrentInput < -0.8 && !bStickMovedLeft && HackManager.CanPlayerUseInput(Player))
			NetStickMoveLeft();
	}

	UFUNCTION(NetFunction)
	void NetActivate()
	{
		HackManager.ActivateShape(Player);
		OxygenComp.AnimTouchScreenConfirm.Set();
	}

	UFUNCTION(NetFunction)
	void NetStickMoveRight()
	{
		bStickMovedRight = true;
		OxygenComp.AnimTouchScreenStepRight.Set();


		FSpaceWalkHackingEffectParams EffectParams;
		EffectParams.Player = Player;
		USpaceWalkHackingEffectHandler::Trigger_BrowseRight(HackManager, EffectParams);

		if(Player.IsMio())
			HackManager.ActionRightMio();
		else
			HackManager.ActionRightZoe();
	}

	UFUNCTION(NetFunction)
	void NetStickMoveLeft()
	{
		bStickMovedLeft = true;
		OxygenComp.AnimTouchScreenStepLeft.Set();

		FSpaceWalkHackingEffectParams EffectParams;
		EffectParams.Player = Player;
		USpaceWalkHackingEffectHandler::Trigger_BrowseLeft(HackManager, EffectParams);

		if(Player.IsMio())
			HackManager.ActionLeftMio();
		else
			HackManager.ActionLeftZoe();
	}
};