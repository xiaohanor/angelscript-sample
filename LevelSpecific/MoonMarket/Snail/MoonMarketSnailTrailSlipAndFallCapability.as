//don't question it
class UMoonMarketSnailTrailSlipAndFallCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SnailSlip");

	default TickGroup = EHazeTickGroup::Gameplay;

	UMoonMarketSnailTrailSlipAndFallComponent SlipComp;

	bool bIsStanding = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SlipComp = UMoonMarketSnailTrailSlipAndFallComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SlipComp.bIHaveFallenAndICantGetUp)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > SlipComp.SlipDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UMoonMarketSnailRiderEventHandler::Trigger_OnSlippedOnSlime(Player, FMoonMarketSlipOnSlimeParams(Player, Player.ActorLocation));
		bIsStanding = false;
		Player.PlaySlotAnimation(SlipComp.SlipAnimation);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.PlayForceFeedback(SlipComp.FFSlip, false, false, this);
		Player.PlayCameraShake(SlipComp.CameraShake, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopSlotAnimation();
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		SlipComp.StopSlipping();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bIsStanding && ActiveDuration > 0.8)
		{
			Player.PlaySlotAnimation(SlipComp.RiseAnimation);
			bIsStanding = true;
		}
	}
};