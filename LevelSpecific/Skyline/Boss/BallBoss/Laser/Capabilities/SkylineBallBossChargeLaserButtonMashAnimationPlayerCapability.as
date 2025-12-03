class USkylineBallBossChargeLaserButtonMashAnimationPlayerCapability : UHazePlayerCapability
{
	USkylineBallBossChargeLaserButtonMashExtrudePlayerComponent ChargeMashComponent;

	default TickGroup = EHazeTickGroup::Movement;

	bool bSetBlendSpaceValue = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ChargeMashComponent = USkylineBallBossChargeLaserButtonMashExtrudePlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ChargeMashComponent.MashState != ESkylineBallBossPlayerMashState::Enter)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ChargeMashComponent.MashState == ESkylineBallBossPlayerMashState::None)
			return true;
		if (ChargeMashComponent.MashState == ESkylineBallBossPlayerMashState::Cancel)
			return true;
		if (ChargeMashComponent.bDoBackflip)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		if (ChargeMashComponent.AnimationSettings.CancelAnimation != nullptr)
		{
			Player.PlaySlotAnimation(
				OnBlendedIn =  FHazeAnimationDelegate(),
				OnBlendingOut = FHazeAnimationDelegate(this, n"HandleEnterBlendingOut"),
				Animation = ChargeMashComponent.AnimationSettings.EnterAnimation,
				BlendType = ChargeMashComponent.AnimationSettings.BlendType
			);
		}
		else
		{
			HandleEnterBlendingOut();
		}
	}

	UFUNCTION()
	private void HandleEnterBlendingOut()
	{
		if (!IsActive())
			return;

		// if (ChargeMashComponent.AnimationSettings.StruggleBlendSpace.BlendSpace != nullptr)
		// {
		// 	bSetBlendSpaceValue = true;
		// 	Player.PlayBlendSpace(
		// 		ChargeMashComponent.AnimationSettings.StruggleBlendSpace.BlendSpace,
		// 		ChargeMashComponent.AnimationSettings.BlendTime,
		// 		ChargeMashComponent.AnimationSettings.BlendType);
		// }
		// else if (ChargeMashComponent.AnimationSettings.MHAnimation != nullptr)
		// {
		// 	Player.PlaySlotAnimation(
		// 		OnBlendedIn =  FHazeAnimationDelegate(),
		// 		OnBlendingOut = FHazeAnimationDelegate(),
		// 		Animation = ChargeMashComponent.AnimationSettings.MHAnimation,
		// 		BlendType = ChargeMashComponent.AnimationSettings.BlendType,
		// 		BlendTime = ChargeMashComponent.AnimationSettings.BlendTime,
		// 		bLoop = true
		// 	);
		// }
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (ChargeMashComponent.MashState == ESkylineBallBossPlayerMashState::Cancel && ChargeMashComponent.AnimationSettings.CancelAnimation != nullptr)
		{
			Player.PlaySlotAnimation(
				OnBlendedIn =  FHazeAnimationDelegate(),
				OnBlendingOut = FHazeAnimationDelegate(this, n"HandleCancelBlendingOut"),
				Animation = ChargeMashComponent.AnimationSettings.CancelAnimation,
				BlendType = ChargeMashComponent.AnimationSettings.BlendType,
				BlendTime = ChargeMashComponent.AnimationSettings.BlendTime,
			);
		}
		else
		{
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		}

		if (ChargeMashComponent.AnimationSettings.StruggleBlendSpace.BlendSpace != nullptr)
		{
			bSetBlendSpaceValue = false;
			Player.StopBlendSpace();
		}

		// Stop any other animation we were playing if we were blocked
		if (ChargeMashComponent.MashState == ESkylineBallBossPlayerMashState::Enter && ChargeMashComponent.AnimationSettings.EnterAnimation != nullptr)
		{
			Player.StopSlotAnimationByAsset(ChargeMashComponent.AnimationSettings.EnterAnimation);
		}
		else if (ChargeMashComponent.MashState == ESkylineBallBossPlayerMashState::Mashing && ChargeMashComponent.AnimationSettings.MHAnimation != nullptr)
		{
			Player.StopSlotAnimationByAsset(ChargeMashComponent.AnimationSettings.MHAnimation);
		}

		ChargeMashComponent.MashState = ESkylineBallBossPlayerMashState::None;
	}

	UFUNCTION()
	private void HandleCancelBlendingOut()
	{
		if (ChargeMashComponent.AnimationSettings.CancelAnimation != nullptr)
			Player.StopSlotAnimationByAsset(ChargeMashComponent.AnimationSettings.CancelAnimation);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.RequestLocomotion(n"BladeChargeLaser", this);
		Player.SetAnimFloatParam(n"Charge", ChargeMashComponent.MashedLaser.TargetAlphaHit);
		// if (bSetBlendSpaceValue)
		// {
			// Player.SetBlendSpaceValues(ChargeMashComponent.MashedLaser.TargetAlphaHit, 0.0);
			// PrintToScreen("" + ChargeMashComponent.MashedLaser.TargetAlphaHit);
		// }
	}
};