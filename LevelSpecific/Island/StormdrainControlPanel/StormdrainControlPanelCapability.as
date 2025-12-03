class UStormdrainControlPanelCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 99;
	AStormdrainControlPanel Stormdrain;
	

	FVector2D MoveInput;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);
		Stormdrain = Cast<AStormdrainControlPanel>(ActiveInteraction.Owner);
		Stormdrain.HologramRotationSyncComponent.OverrideControlSide(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			Stormdrain.RotationInput(MoveInput, DeltaTime);
		}
	}
}