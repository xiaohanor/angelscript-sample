class USummitDragDrawBridgePulleyInteractionCapability : UInteractionCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(n"CraftTempleBridgePulley");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::LastMovement;

	ASummitDragDrawBridgePulley Pulley;

	UPlayerMovementComponent MoveComp;
	UPlayerTeenDragonComponent DragonComp;

	float LastFrameMoveInputAlignment;
	float LastTimeYanked = -MAX_flt;

	float InputSuccessTime;
	float MaxInputSuccessTime = 2.5;
	bool bRemovedTutorialPrompts;

	UInteractionComponent InteractionComp;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);
		
		MoveComp = UPlayerMovementComponent::Get(Player);
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		Pulley = Cast<ASummitDragDrawBridgePulley>(Params.Interaction.Owner);

		Player.AttachToComponent(Params.Interaction);
		Player.AddActorWorldOffset(-Pulley.ActorForwardVector * 150);

		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonAcidSprayFire, this);

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::MovementVerticalDown;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_Down;
		TutorialPrompt.MaximumDuration = -1;
		TutorialPrompt.Mode = ETutorialPromptMode::Default;
		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, Params.Interaction);

		Pulley.IsInteracting[Player] = true;
		if(Pulley.IsInteracting[Player.OtherPlayer])
		{
			Pulley.OnBothPlayersInteracted.Broadcast();
			Pulley.LeftPulleyInteractionComp.bPlayerCanCancelInteraction = false;
			Pulley.RightPulleyInteractionComp.bPlayerCanCancelInteraction = false;
		}
		InteractionComp = Params.Interaction;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.DetachFromActor(EDetachmentRule::KeepWorld);
		Pulley.KickPlayersFromInteraction();
		Pulley.IsInteracting[Player] = false;
		InteractionComp.DisableForPlayer(Player, this);
		Timer::SetTimer(this, n"ReEnableInteraction", 0.5);
		Player.RemoveTutorialPromptByInstigator(this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonAcidSprayFire, this);
	}

	UFUNCTION()
	private void ReEnableInteraction()
	{
		InteractionComp.EnableForPlayer(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector MoveInput;
		if(HasControl())
			MoveInput = MoveComp.MovementInput;
		else
			MoveInput = MoveComp.GetSyncedMovementInputForAnimationOnly();
		Pulley.MovementInput[Player] = MoveInput; 

		if (!Pulley.MovementInput[Player].IsNearlyZero(0.1) && !Pulley.MovementInput[Player.OtherPlayer].IsNearlyZero(0.1))
		{
			InputSuccessTime += DeltaTime;
			if (InputSuccessTime > MaxInputSuccessTime && !bRemovedTutorialPrompts)
			{
				bRemovedTutorialPrompts = true;
				Player.RemoveTutorialPromptByInstigator(this);
			}
		}

		if(HasControl())
		{
			HandleYankImpulse(MoveInput, DeltaTime);
		}

		DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::TaillTeenPull);

	}

	void HandleYankImpulse(FVector MovementInput, float DeltaTime)
	{
		float MoveInputPulleyAlignment = MovementInput.DotProduct(-Pulley.ActorForwardVector);
		float TempLastFrameMoveInputAlignment = LastFrameMoveInputAlignment;
		LastFrameMoveInputAlignment = MoveInputPulleyAlignment;

		TEMPORAL_LOG(Player, "Drag Draw Bridge Pulley")
			.Value("Move Input Pulley Alignment", MoveInputPulleyAlignment)
		;
		if(MoveInputPulleyAlignment < 0.5)
			return;

		if(!Math::IsNearlyZero(TempLastFrameMoveInputAlignment, 0.4))
			return;

		if(Time::GetGameTimeSince(LastTimeYanked) < 0.5)
			return;

		FVector OtherPlayerMovementInput = Pulley.MovementInput[Player.OtherPlayer];
		if(!OtherPlayerMovementInput.IsNearlyZero(0.1))
		{
			if(OtherPlayerMovementInput.DotProduct(MovementInput) > 0.3)
				return;

		}

		Pulley.CrumbAddYankImpulse();
		LastTimeYanked = Time::GameTimeSeconds;
	}
};