class UMoonMarketPendingInteractionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMoonMarketPlayerInteractionComponent InteractComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		InteractComp = UMoonMarketPlayerInteractionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(InteractComp.PendingInteractions.IsEmpty())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(auto Interaction : InteractComp.PendingInteractions)
		{
			Interaction.OnInteractionStarted(Interaction.InteractComp, Player);
		}
		
		InteractComp.PendingInteractions.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};