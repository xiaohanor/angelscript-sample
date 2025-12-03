
struct FInteractionCapabilityParams
{
	UInteractionComponent Interaction;
};

class UInteractionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Interaction");
	default CapabilityTags.Add(n"BlockedByCutscene");
	default CapabilityTags.Add(n"BlockedWhileDead");

	default DebugCategory = n"Interaction";
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerInteractionsComponent PlayerInteractionsComp;
	UInteractionComponent ActiveInteraction;

	/**
	 * Determine whether this capability responds to the given interaction.
	 * Should be overridden from a subclass.
	 */
	bool SupportsInteraction(UInteractionComponent CheckInteraction) const
	{
		return true;
	}

	// Cause the player to forcably leave the interaction
	void LeaveInteraction()
	{
		PlayerInteractionsComp.KickPlayerOutOfInteraction(ActiveInteraction);
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerInteractionsComp = UPlayerInteractionsComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FInteractionCapabilityParams& Params) const final
	{
		if (PlayerInteractionsComp.ActiveInteraction == nullptr)
			return false;
		if (!SupportsInteraction(PlayerInteractionsComp.ActiveInteraction))
			return false;

		Params.Interaction = PlayerInteractionsComp.ActiveInteraction;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		ActiveInteraction = Params.Interaction;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const final
	{
		if (!IsValid(ActiveInteraction))
			return true;
		if (PlayerInteractionsComp.ActiveInteraction != ActiveInteraction)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ActiveInteraction = nullptr;
	}
};