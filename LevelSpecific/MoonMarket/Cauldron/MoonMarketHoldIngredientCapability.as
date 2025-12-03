class UMoonMarketHoldIngredientCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMoonMarketWitchCauldronPlayerComponent PlayerComp;

	bool bPickedUp = false;

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

		if(PlayerComp.bThrowingIngredient)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerComp.HeldIngredient == nullptr)
			return true;

		if(PlayerComp.bThrowingIngredient)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bPickedUp = false;
		PlayerComp.HeldIngredient.InteractComp.bPlayerCanCancelInteraction = false;
		PlayerComp.HeldIngredient.AddActorVisualsBlock(this);
		FHazeAnimationDelegate OnBlendOut;
		OnBlendOut.BindUFunction(this, n"PlayHold");
		Player.PlayOverrideAnimation(OnBlendOut, PlayerComp.PickupAnim, PlayerComp.BoneFilter);
	}

	UFUNCTION()
	private void PlayHold()
	{
		if(!IsActive())
			return;
		
		Player.StopOverrideAnimation(PlayerComp.PickupAnim);
		Player.PlayOverrideAnimation(FHazeAnimationDelegate(), PlayerComp.HoldAnim, PlayerComp.BoneFilter, bLoop = true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopAllOverrideAnimations(0.4);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bPickedUp && ActiveDuration >= 0.1)
		{
			Player.PlayForceFeedback(ForceFeedback::Default_Light_Tap, this);
			PlayerComp.HeldIngredient.InteractComp.bPlayerCanCancelInteraction = true;
			PlayerComp.HeldIngredient.RemoveActorVisualsBlock(this);
			bPickedUp = true;
		}
	}
};