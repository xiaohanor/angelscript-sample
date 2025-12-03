struct FCentipedeBiteCapabilityActivationParams
{
	UCentipedeBiteResponseComponent BiteResponseComponent = nullptr;
}

class UCentipedeBiteCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

	default CapabilityTags.Add(CentipedeTags::Centipede);
	default CapabilityTags.Add(CentipedeTags::CentipedeBite);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	// Must tick after CentipedeBiteActivationCapability
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 101;

	default DebugCategory = CentipedeTags::Centipede;

	UPlayerCentipedeComponent CentipedeComponent;
	UCentipedeBiteComponent CentipedeBiteComponent;
	UPlayerTargetablesComponent TargetablesComponent;
	UCentipedeLavaIntoleranceComponent LavaIntoleranceComponent;

	const float RumbleDuration = 0.2;
	private UCentipedeBiteResponseComponent CachedBiteResponse = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
		CentipedeBiteComponent = UCentipedeBiteComponent::Get(Owner);
		TargetablesComponent = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCentipedeBiteCapabilityActivationParams& ActivationParams) const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		if (CentipedeBiteComponent.GetPendingBiteResponseComponent() == nullptr)
			return false;

		ActivationParams.BiteResponseComponent = CentipedeBiteComponent.GetPendingBiteResponseComponent();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		if (CentipedeBiteComponent.GetPendingBiteResponseComponent() == nullptr)
			return true;

		if (LavaIntoleranceComponent.bIsRespawning)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCentipedeBiteCapabilityActivationParams ActivationParams)
	{
		CachedBiteResponse = ActivationParams.BiteResponseComponent;
		CentipedeBiteComponent.Bite(CachedBiteResponse);

		// Add extra bite flare if centipede has target
		UCentipedeEventHandler::Trigger_OnBiteResponseComponentBitten(Player);

		// Flag must be true when centipede closes jaw, even if nothing was caught
		CentipedeBiteComponent.bBiting = true;

		// Fire away!
		auto Data = FSanctuaryCentipedeBiteEventData(Player, CachedBiteResponse);
		UCentipedeEventHandler::Trigger_OnBiteStarted(Player, Data);
		UCentipedeEventHandler::Trigger_OnBiteStarted(CentipedeComponent.Centipede, Data);

		if (CentipedeComponent.Centipede != nullptr)
			LavaIntoleranceComponent = UCentipedeLavaIntoleranceComponent::Get(CentipedeComponent.Centipede);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CentipedeBiteComponent.StopBiting();

		// Don't open jaw if player is still engaging
		if (!CentipedeBiteComponent.GetBiteActioning(this) && HasControl())
			CrumbSetBiting(false);
	}

	// Handle visuals
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!HasControl())
			return;

		if (IsActive())
			return;

		if (IsBlocked())
			return;

		if (CentipedeBiteComponent.bBiting)
		{
			if (!CentipedeBiteComponent.GetBiteActioning(this))
				CrumbSetBiting(false);
		}
		else
		{
			if (CentipedeBiteComponent.GetBiteActionStarted(this))
			{
				CrumbSetBiting(true);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Play some FF
		float Alpha = Math::Pow(Math::Saturate(ActiveDuration / RumbleDuration), 2.0);
		const float Intensity = Math::Lerp(1.0, 0.0, Alpha);
		Player.SetFrameForceFeedback(0.0, 0.3, 0.0, 0.2, Intensity);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetBiting(bool bBiting)
	{
		if (bBiting)
		{
			CentipedeBiteComponent.bBiting = true;
			auto Data = FSanctuaryCentipedeBiteEventData(Player, CachedBiteResponse);
			UCentipedeEventHandler::Trigger_OnBiteStarted(Player, Data);
			UCentipedeEventHandler::Trigger_OnBiteStarted(CentipedeComponent.Centipede, Data);
		}
		else
		{
			CentipedeBiteComponent.bBiting = false;
			auto Data = FSanctuaryCentipedeBiteEventData(Player, CachedBiteResponse);
			UCentipedeEventHandler::Trigger_OnBiteStopped(CentipedeComponent.Centipede, Data);
		}
	}
}