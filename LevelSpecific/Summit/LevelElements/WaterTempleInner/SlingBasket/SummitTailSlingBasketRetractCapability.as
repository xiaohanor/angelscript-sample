class USummitTailSlingBasketRetractCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitTailSlingBasket Basket;

	UPlayerTailBabyDragonComponent DragonComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Basket = Cast<ASummitTailSlingBasket>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DragonComp == nullptr)
			return false;

		if(!Basket.bTailIsAttached)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DragonComp == nullptr)
			return true;

		if(!Basket.bTailIsAttached)
			return true;

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
		if(DragonComp == nullptr)
			DragonComp = UPlayerTailBabyDragonComponent::Get(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector WorldAttachLocation = DragonComp.AttachmentComponent.WorldTransform.TransformPosition(DragonComp.RelativeTailEndLocation);
		FauxPhysics::ApplyFauxForceToActorAt(Basket, WorldAttachLocation,-DragonComp.ClimbLaunchForce * Basket.TailPullBackForceMultiplier);
	}
};