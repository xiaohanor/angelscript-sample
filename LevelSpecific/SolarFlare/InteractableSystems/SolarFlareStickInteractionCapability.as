class USolarFlareStickInteractionCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 150;

	UButtonMashComponent ButtonMashComp;
	ASolarFlareStickInteraction StickInteraction;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);
		StickInteraction = Cast<ASolarFlareStickInteraction>(ActiveInteraction.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		StickInteraction.OnSolarFlareMovementStickStop.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Run from control side
		// if (HasControl())
		StickInteraction.OnSolarFlareMovementStickApplied.Broadcast(GetAttributeVector2D(AttributeVectorNames::LeftStickRaw));
		StickInteraction.StickRotation(GetAttributeVector2D(AttributeVectorNames::LeftStickRaw));
	}
}