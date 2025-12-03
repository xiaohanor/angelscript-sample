
struct FInteractionExitCapabilityParams
{
	UInteractionComponent Interaction;
};

class UInteractionExitCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BlockedByCutscene");
	default CapabilityTags.Add(n"BlockedWhileDead");

	default DebugCategory = n"Interaction";
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 30;
	default SeparateInactiveTick(EHazeTickGroup::BeforeMovement, 11);

	UPlayerInteractionsComponent PlayerInteractionsComp;
	UHazeCapabilityComponent PlayerCapabilityComp;

	UInteractionComponent Interaction;

	UHazeCapabilitySheet ActiveSheet;
	TSubclassOf<UHazeCapability> ActiveCapability;

	bool bCancelPomptActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerInteractionsComp = UPlayerInteractionsComponent::GetOrCreate(Player);
		PlayerCapabilityComp = UHazeCapabilityComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FInteractionExitCapabilityParams& Params) const
	{
		if (PlayerInteractionsComp.ActiveInteraction == nullptr)
			return false;

		Params.Interaction = PlayerInteractionsComp.ActiveInteraction;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Interaction == nullptr)
			return true;
		if (!Interaction.IsInteracting(Player))
			return true;
		if (PlayerInteractionsComp.ActiveInteraction != Interaction)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionExitCapabilityParams Params)
	{
		Interaction = Params.Interaction;

		ActiveSheet = Interaction.GetPlayerInteractionSheet(Player);
		if (ActiveSheet == nullptr)
			ActiveSheet = PlayerInteractionsComp.DefaultInteractionSheet;

		Player.StartCapabilitySheet(ActiveSheet, this);

		ActiveCapability = Interaction.GetPlayerInteractionCapability(Player);
		if (ActiveCapability.IsValid())
			PlayerCapabilityComp.StartSingleRequestedCapability(this, ActiveCapability);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Note: InteractionEnterCapability can also stop interactions,
		// which it does when the interaction does not want to use a sheet

		if (Interaction != nullptr)
			Interaction.StopInteracting(Player);

		if (PlayerInteractionsComp.ActiveInteraction == Interaction)
			PlayerInteractionsComp.ActiveInteraction = nullptr;

		if (ActiveCapability.IsValid())
			PlayerCapabilityComp.StopSingleRequestedCapability(this, ActiveCapability);

		Player.StopCapabilitySheet(ActiveSheet, this);

		Player.RemoveCancelPromptByInstigator(this);
		bCancelPomptActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateCancelPrompt();
	}

	// Show or hide the cancel prompt depending on what the interaction wants right now
	void UpdateCancelPrompt()
	{
		if (IsValid(Interaction))
		{
			bool bShowCancelPrompt = Interaction.bShowCancelPrompt && Interaction.CanPlayerCancel(Player) && ActiveDuration > 0;
			if (bShowCancelPrompt != bCancelPomptActive)
			{
				if (bShowCancelPrompt)
				{
					if (Interaction.bOverrideCancelText)
						Player.ShowCancelPromptWithText(this, Interaction.CancelText);
					else
						Player.ShowCancelPrompt(this);
				}
				else
				{
					Player.RemoveCancelPromptByInstigator(this);
				}
				bCancelPomptActive = bShowCancelPrompt;
			}
		}
	}
};