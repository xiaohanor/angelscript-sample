class UMeltdownScreenWalkStompCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	const float STOMP_DURATION = 0.5;
	const float EFFECT_DELAY = 0.2;
	
	UMeltdownScreenWalkUserComponent UserComp;
	UPlayerMovementComponent Movecomp;
	bool bHasTriggered = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UMeltdownScreenWalkUserComponent::Get(Player);
		Movecomp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Movecomp.IsOnAnyGround())
			return false;

		if (WasActionStarted(ActionNames::PrimaryLevelAbility))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < STOMP_DURATION)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasTriggered = false;
		Player.PlaySlotAnimation(Animation = UserComp.TempAnimation);

		UMeltdownScreenWalkStompEffectHandler::Trigger_StartedStomping(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto Manager = AMeltdownScreenWalkManager::Get();
		if (IsValid(Manager))
		{
			if (Manager.bPlayerIsStomping)
			{
				Manager.bPlayerIsStomping = false;
				Player.StopSlotAnimation(EHazeSlotAnimType::SlotAnimType_Default, 0.4);
				Game::Zoe.UnblockCapabilities(CapabilityTags::Movement, this);
				for (UMeltdownScreenWalkResponseComponent ResponseComp : Manager.ResponseComponents)
					ResponseComp.OnPlayerEndedStomp();
			}
		}

		UMeltdownScreenWalkStompEffectHandler::Trigger_StoppedStomping(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			if (!bHasTriggered && ActiveDuration >= EFFECT_DELAY)
			{
				CrumbTriggerStomp();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerStomp()
	{
		bHasTriggered = true;

		auto Manager = AMeltdownScreenWalkManager::Get();
		if (IsValid(Manager))
		{
			Manager.bPlayerIsStomping = true;
			Game::Zoe.BlockCapabilities(CapabilityTags::Movement, this);
			Manager.StompEffects();
			for (UMeltdownScreenWalkResponseComponent ResponseComp : Manager.ResponseComponents)
				ResponseComp.OnPlayerStartedStomp();

			UMeltdownScreenWalkStompEffectHandler::Trigger_StompHit(Player);
			Game::Zoe.PlayForceFeedback(UserComp.StompFF,false,false,this, 100.0);

		}
	}
};