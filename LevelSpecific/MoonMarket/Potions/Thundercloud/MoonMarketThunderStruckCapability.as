class UMoonMarketThunderStruckCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	UMoonMarketThunderStruckComponent ThunderStruckComp;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ThunderStruckComp = UMoonMarketThunderStruckComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!ThunderStruckComp.bThunderStruck)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration >= ThunderStruckComp.StunDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		if(Player != nullptr)
		{
			Player.PlayForceFeedback(ThunderStruckComp.ThunderStruckForceFeedback, false, false, this);
			FKnockdown Knockdown;
			Knockdown.Move = ThunderStruckComp.ThunderDirection * 100;
			Knockdown.Duration = ThunderStruckComp.StunDuration;
			Player.ApplyKnockdown(Knockdown);
		}
		else
		{
			if(ThunderStruckComp.ThunderStruckAnimation.Animation != nullptr)
				Owner.PlaySlotAnimation(ThunderStruckComp.ThunderStruckAnimation);

			Owner.BlockCapabilities(CapabilityTags::Movement, this);
		}
		
		Owner.BlockCapabilities(CapabilityTags::MovementInput, this);
		Owner.BlockCapabilities(CapabilityTags::GameplayAction, this);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		if(Player == nullptr)
		{
			Owner.UnblockCapabilities(CapabilityTags::Movement, this);
			if(ThunderStruckComp.ThunderStruckAnimation.Animation != nullptr)
				Owner.StopSlotAnimation();
		}

		Owner.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		ThunderStruckComp.bThunderStruck = false;
	}
};