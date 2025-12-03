class USanctuaryGhostAttackPlayerResponseCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	UCameraUserComponent CameraUserComp;

	USanctuaryGhostAttackResponseComponent AttackResponseComp;

	float MaximumSpeedSpeed = 0.0;
	float SpeedScale = 1.0;
	float Rate = 0.4;
	
	bool bIsLifted = false;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUserComp = UCameraUserComponent::Get(Player);
		MaximumSpeedSpeed = Player.GetSettings(UPlayerFloorMotionSettings).MaximumSpeed;
		AttackResponseComp = USanctuaryGhostAttackResponseComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AttackResponseComp.bIsAttacked.Get())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AttackResponseComp.bIsAttacked.Get())
			return true;

		if (SpeedScale >= 1.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SpeedScale = 1.0;

		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);
		Player.BlockCapabilities(PlayerMovementTags::Sprint, this);

		Player.PlayCameraShake(AttackResponseComp.CameraShake, this);
		Player.PlayForceFeedback(AttackResponseComp.ForceFeedbackEffect, true, true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
		Player.UnblockCapabilities(PlayerMovementTags::Sprint, this);

		Player.StopCameraShakeByInstigator(this);
		Player.StopForceFeedback(this);

		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (AttackResponseComp.bIsAttacked.Get())
			SpeedScale -= DeltaTime * Rate;
		else
			SpeedScale += DeltaTime * Rate;

		SpeedScale = Math::Clamp(SpeedScale, AttackResponseComp.SpeedScaleMin + SMALL_NUMBER, 1.0);

		UPlayerFloorMotionSettings::SetMaximumSpeed(Player, SpeedScale * MaximumSpeedSpeed, this);
//		UPlayerStrafeSettings::SetStrafeMoveScale(Player, SpeedScale, this);
	
	}
};