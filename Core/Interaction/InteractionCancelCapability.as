
struct FInteractionCancelCapabilityParams
{
	UInteractionComponent CancelInteraction;
};

class UInteractionCancelCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"InteractionCancel");

	default DebugCategory = n"Interaction";
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 29;

	UPlayerInteractionsComponent PlayerInteractionsComp;
	UInteractionComponent CancelInteraction;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerInteractionsComp = UPlayerInteractionsComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FInteractionCancelCapabilityParams& Params) const
	{
		if (PlayerInteractionsComp.ActiveInteraction == nullptr)
			return false;
		if (!PlayerInteractionsComp.ActiveInteraction.CanPlayerCancel(Player))
			return false;
		if (!WasActionStarted(ActionNames::Cancel))
			return false;

		Params.CancelInteraction = PlayerInteractionsComp.ActiveInteraction;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCancelCapabilityParams Params)
	{
		Params.CancelInteraction.StopInteracting(Player);
		PlayerInteractionsComp.ActiveInteraction = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
	}
};