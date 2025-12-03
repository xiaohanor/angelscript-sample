class UIslandJetpackPickupInteractionCapability : UInteractionCapability
{
	default CapabilityTags.Add(n"Jetpack");

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		auto JetpackComp = UIslandJetpackComponent::Get(Player);
		if(JetpackComp.IsOn())
			return;
		
		JetpackComp.ToggleJetpack(true);
		Params.Interaction.Owner.DestroyActor();

		LeaveInteraction();
	}
};