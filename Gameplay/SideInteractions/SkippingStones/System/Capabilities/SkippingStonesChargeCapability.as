struct FSkippingStonesChargeDeactivateParams
{
	bool bThrow = false;
	FVector ThrowVelocity = FVector::ZeroVector;
};

class USkippingStonesChargeCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 110;

	USkippingStonesPlayerComponent PlayerComp;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USkippingStonesPlayerComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerComp.State != ESkippingStonesState::Aim)
			return false;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSkippingStonesChargeDeactivateParams& Params) const
	{
		if(PlayerComp.State != ESkippingStonesState::Aim)
			return true;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
		{
			Params.bThrow = true;

			const float ChargeAlpha = Math::Max(PlayerComp.ChargeAlpha, 0.1);
			Params.ThrowVelocity = AimComp.GetAimingTarget(PlayerComp).AimDirection * SkippingStones::MaxThrowSpeed * ChargeAlpha;
			
			if(Params.ThrowVelocity.Size() < SkippingStones::MinThrowSpeed)
				Params.ThrowVelocity = Params.ThrowVelocity.GetSafeNormal() * SkippingStones::MinThrowSpeed;

			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerComp.ChargeAlpha = 0;
		PlayerComp.bIsCharging = true;
		Player.PlayForceFeedback(PlayerComp.HoldFeedbackWeak, true, true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSkippingStonesChargeDeactivateParams Params)
	{
		if(Params.bThrow)
		{
			PlayerComp.ThrowVelocity = Params.ThrowVelocity;
			PlayerComp.State = ESkippingStonesState::Throw;
		}
		PlayerComp.bIsCharging = false;
		Player.StopForceFeedback(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float ChargeX = (ActiveDuration * SkippingStones::ChargeCurveSpeed) % 1;
		PlayerComp.ChargeAlpha = SkippingStonesChargeCurve.GetFloatValue(ChargeX);
		Player.SetAnimFloatParam(n"SkippingStoneCharge", ChargeX);

		float IntensityAlpha = Math::Pow(PlayerComp.ChargeAlpha, 3);
		Player.PlayForceFeedback(PlayerComp.HoldFeedbackStrong, false, true, this, IntensityAlpha * 2);
	}
};