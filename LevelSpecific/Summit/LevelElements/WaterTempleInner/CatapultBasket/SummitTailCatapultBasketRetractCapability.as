class USummitTailCatapultBasketRetractCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitTailCatapultBasket Basket;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Basket = Cast<ASummitTailCatapultBasket>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Basket.bTailIsAttached)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Basket.bTailIsAttached)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		USummitTailCatapultBasketEventHandler::Trigger_OnRetractStart(Basket);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(Basket.PulledBackAlpha > 0)
			Basket.bIsReleasing = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Basket.AccRotation.AccelerateTo(Basket.PulledBackRotation, Basket.PullBackDuration, DeltaTime);
		Basket.CatapultRotateRoot.SetWorldRotation(Basket.AccRotation.Value);
	}
};