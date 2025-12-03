class USummitTailCatapultBasketResetCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	ASummitTailCatapultBasket Basket;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Basket = Cast<ASummitTailCatapultBasket>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Basket.bTailIsAttached)
			return false;

		if(Basket.bIsReleasing)
			return false;

		if(Time::GameTimeSeconds < Basket.GoBackTimeStamp)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Basket.bTailIsAttached)
			return true;

		if(Basket.bIsReleasing)
			return true;

		if(Time::GameTimeSeconds > Basket.GoBackTimeStamp + Basket.IdleGoBackDuration)
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		USummitTailCatapultBasketEventHandler::Trigger_OnResetStart(Basket);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Basket.CatapultRotateRoot.WorldRotation = Basket.ActorRotation;
		USummitTailCatapultBasketEventHandler::Trigger_OnResetEnd(Basket);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Basket.AccRotation.AccelerateTo(Basket.ActorRotation, Basket.IdleGoBackDuration, DeltaTime);
		Basket.CatapultRotateRoot.SetWorldRotation(Basket.AccRotation.Value);
	}
};