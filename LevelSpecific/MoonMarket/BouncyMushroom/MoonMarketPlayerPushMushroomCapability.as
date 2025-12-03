asset MoonMarketPushMushroomSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UMoonMarketPlayerPushMushroomCapability);
}
class UMoonMarketPlayerPushMushroomCapability : UInteractionCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 120;

	AMoonMarketGardenFatMushroom Mushroom;


	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);
		Mushroom = Cast<AMoonMarketGardenFatMushroom>(Params.Interaction.Owner);
		Mushroom.bIsPushed = true;
		Player.PlaySlotAnimation(Mushroom.PushAnim);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(n"MoonMarketInteractionCancel", this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Mushroom.bIsPushed = false;
		Player.StopSlotAnimation();
		Player.UnblockCapabilities(n"MoonMarketInteractionCancel", this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
	}
};