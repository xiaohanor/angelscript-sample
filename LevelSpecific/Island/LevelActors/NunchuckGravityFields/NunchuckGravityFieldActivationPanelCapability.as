class UNunchuckGravityFieldActivationPanelCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 99;
	
	ANunchuckGravityFieldActivationPanel ActivationPanel;

	FVector2D MoveInput;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);
		ActivationPanel = Cast<ANunchuckGravityFieldActivationPanel>(ActiveInteraction.Owner);
		ActivationPanel.ProgressSyncComponent.OverrideControlSide(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		ActivationPanel.TickInput(MoveInput, DeltaTime);
	}
}