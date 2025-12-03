struct FBrothersBenchPlayerActivateParams
{
	ABrothersBench BrothersBench;
};

class UBrothersBenchPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::BlockedWhileDead);

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 100;

	UBrothersBenchPlayerComponent PlayerComp;
	UPlayerInteractionsComponent InteractionsComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UBrothersBenchPlayerComponent::Get(Player);
		InteractionsComponent = UPlayerInteractionsComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBrothersBenchPlayerActivateParams& Params) const
	{
		if(InteractionsComponent.ActiveInteraction == nullptr)
			return false;

		auto BrothersBench = Cast<ABrothersBench>(InteractionsComponent.ActiveInteraction.Owner);
		if(BrothersBench == nullptr)
			return false;

		Params.BrothersBench = BrothersBench;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(InteractionsComponent.ActiveInteraction == nullptr)
			return true;

		if(InteractionsComponent.ActiveInteraction.Owner != PlayerComp.BrothersBench)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBrothersBenchPlayerActivateParams Params)
	{
		PlayerComp.BrothersBench = Params.BrothersBench;

		Player.BlockCapabilities(CapabilityTags::Outline, this);
		Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Outline, this);
		Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);

		PlayerComp.BrothersBench = nullptr;
	}
};