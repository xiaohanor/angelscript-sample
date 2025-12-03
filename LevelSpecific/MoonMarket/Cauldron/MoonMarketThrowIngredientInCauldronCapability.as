class UMoonMarketThrowIngredientInCauldronCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMoonMarketWitchCauldronPlayerComponent PlayerComp;

	bool bThrown = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UMoonMarketWitchCauldronPlayerComponent::Get(Player);
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerComp.HeldIngredient == nullptr)
			return false;

		if(!PlayerComp.bThrowingIngredient)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bThrown && ActiveDuration >= PlayerComp.ThrowAnim.Animation.PlayLength)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bThrown = false;
		PlayerComp.Cauldron.InteractComp.DisableForPlayer(Player, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.PlaySlotAnimation(PlayerComp.ThrowAnim);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerComp.bThrowingIngredient = false;
		PlayerComp.Cauldron.InteractComp.EnableForPlayer(Player, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration > 0.3 && !bThrown)
		{
			bThrown = true;
			PlayerComp.ThrowIngredient();
		}
	}
};