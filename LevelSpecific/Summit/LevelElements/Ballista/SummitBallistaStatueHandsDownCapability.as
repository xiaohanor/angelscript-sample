struct FSummitBallistaStatueHandsDownActivationParams
{
	bool bBasketIsInLastPart = false;
}

class USummitBallistaStatueHandsDownCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroupOrder = 90;

	ASummitBallista Ballista;

	const float HandsWidth = 100.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ballista = Cast<ASummitBallista>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitBallistaStatueHandsDownActivationParams& Params) const
	{
		if(!Ballista.bHandsAreDown)
			return false;

		Params.bBasketIsInLastPart = Ballista.IsInHeldPart();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Ballista.bHandsAreDown)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitBallistaStatueHandsDownActivationParams Params)
	{
		if(Params.bBasketIsInLastPart)
		{
			Ballista.BasketRoot.MinX = Ballista.StatueHandsDownMaxMove + HandsWidth;
			Ballista.BasketRoot.MaxX = Ballista.StatueHandsUpMaxMove;
			Ballista.bIsHeld = true;
			Ballista.OnSummitBallistaLockedAndLoaded.Broadcast();
		}
		else
		{
			Ballista.BasketRoot.MinX = 0;
			Ballista.BasketRoot.MaxX = Ballista.StatueHandsDownMaxMove;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(Ballista.bIsHeld)
		{
			Ballista.bIsHeld = false;
			Ballista.bIsLaunching = true;
		}

		Ballista.BasketRoot.MaxX = Ballista.StatueHandsUpMaxMove;
		Ballista.BasketRoot.MinX = 0.0;
	}
};