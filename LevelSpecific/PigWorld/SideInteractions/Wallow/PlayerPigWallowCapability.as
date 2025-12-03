struct FPigWallowCapabilityActivationParams
{
	UAnimSequence WallowSequence = nullptr;
}

struct FPigWallowCapabilityDeactivationParams
{
	// Something tried to move the piggy
	bool bImpulseDeactivation = false;
}

class UPlayerPigWallowCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	UPlayerPigWallowComponent PigWallowComponent;
	UPlayerMovementComponent MovementComponent;

	UAnimSequence CurrentSequence = nullptr;

	float LastDeactivationTimeStamp;

	bool bTutorialActive = false;
	bool bTutorialCompleted = false;
	bool bBlendingOut;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PigWallowComponent = UPlayerPigWallowComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPigWallowCapabilityActivationParams& ActivationParams) const
	{
		// Check for button press
		if (!IsActioning(ActionNames::Interaction))
			return false;

		if (!CanWallow())
			return false;

		ActivationParams.WallowSequence = PigWallowComponent.GetRandomWallowSequence();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPigWallowCapabilityDeactivationParams& DeactivationParams) const
	{
		if (!IsActioning(ActionNames::Interaction))
			return true;

		// Something tried to move the piggy
		if (!MovementComponent.Velocity.IsZero())
		{
			DeactivationParams.bImpulseDeactivation = true;
			return true;
		}

		// ...or animation finishes first
		if (bBlendingOut)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPigWallowCapabilityActivationParams ActivationParams)
	{
		bBlendingOut = false;

		CurrentSequence = ActivationParams.WallowSequence;
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"OnSequenceBlendingOut"), CurrentSequence, FHazeSlotAnimSettings());

		MovementComponent.Reset();

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		if (PigWallowComponent.WallowCameraShakeClass != nullptr)
			Player.PlayCameraShake(PigWallowComponent.WallowCameraShakeClass, this);

		UPlayerPigWallowEffectEventHandler::Trigger_StartWallowing(Player);

		FPlayerPigWallowEffectEventParams EffectEventParams;
		EffectEventParams.Player = Player;
		if (CurrentSequence != PigWallowComponent.AnimationData.Wallow1)
			EffectEventParams.bWallow = false;
		UPlayerPigWallowVOEffectEventHandler::Trigger_StartWallowing(Game::Mio, EffectEventParams);

		bTutorialCompleted = true;
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPigWallowCapabilityDeactivationParams DeactivationParams)
	{
		if (!bBlendingOut)
			Player.StopSlotAnimationByAsset(CurrentSequence);

		LastDeactivationTimeStamp = Time::GameTimeSeconds;

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::Interaction);

		// Something tried to move piggy but vel was reset during activation....
		// Restore forward!
		if (DeactivationParams.bImpulseDeactivation)
			Player.SetActorVelocity(MovementComponent.Velocity + Player.ActorForwardVector);

		Player.StopCameraShakeByInstigator(this, false);

		UPlayerPigWallowEffectEventHandler::Trigger_StopWallowing(Player);

		FPlayerPigWallowEffectEventParams EffectEventParams;
		EffectEventParams.Player = Player;
		if (CurrentSequence != PigWallowComponent.AnimationData.Wallow1)
			EffectEventParams.bWallow = false;
		UPlayerPigWallowVOEffectEventHandler::Trigger_StopWallowing(Game::Mio, EffectEventParams);

		CurrentSequence = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (CanWallow())
		{
			if (!bTutorialCompleted && !bTutorialActive)
			{
				bTutorialActive = true;
				Player.ShowTutorialPrompt(PigWallowComponent.TutorialPrompt, this);
			}
		}
		else
		{
			if (!bTutorialCompleted && bTutorialActive)
			{
				Player.RemoveTutorialPromptByInstigator(this);
				bTutorialActive = false;
			}
		}

		PigWallowComponent.UpdateMudHeight(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = (Math::PerlinNoise1D(ActiveDuration));
		FF.RightMotor = (Math::PerlinNoise1D(ActiveDuration * 1.618));
		Player.SetFrameForceFeedback(FF, 0.2);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSequenceBlendingOut()
	{
		bBlendingOut = true;
	}

	bool CanWallow() const
	{
		if (!MovementComponent.IsOnWalkableGround())
			return false;

		if (!PigWallowComponent.IsInWallowMud())
			return false;

		// Avoid (network) spamming
		float TimeWithoutWallowing = Time::GameTimeSeconds - LastDeactivationTimeStamp;
		if (TimeWithoutWallowing < 0.3)
			return false;

		return true;
	}
}