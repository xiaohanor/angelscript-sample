class USkylineBallBossFlashShieldCapability : USkylineBallBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BallBoss.GetPhase() == ESkylineBallBossPhase::TopShieldShockwave)
			return false;

		if (BallBoss.ShieldVFXDatas.Num() == 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BallBoss.GetPhase() == ESkylineBallBossPhase::TopShieldShockwave)
			return true;

		if (BallBoss.ShieldVFXDatas.Num() == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BallBoss.ShieldShockwave.SetVisibility(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.ShieldShockwave.SetVisibility(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ShieldAlpha = 0.0;
		for (int i = 0; i < BallBoss.ShieldVFXDatas.Num(); ++i)
		{
			BallBoss.ShieldVFXDatas[i].VFXLifetime += DeltaTime;
			float UpDownAlpha = Math::Clamp(BallBoss.ShieldVFXDatas[i].VFXLifetime / Settings.DetonatorOffShieldFlashDuration, 0.0, 1.0) * 2.0;
			float EffectAlpha = 0.0;
			if (UpDownAlpha <= 1.0)
			{
				EffectAlpha = Math::EaseOut(0.0, 1.0, UpDownAlpha, 4.0);
			}
			if (UpDownAlpha > 1.0)
			{
				UpDownAlpha = 1.0 - (UpDownAlpha - 1.0);
				EffectAlpha = Math::EaseIn(0.0, 1.0, UpDownAlpha, 2.0);
			}
			ShieldAlpha = Math::Max(ShieldAlpha, EffectAlpha);
		}
		SetShieldMaterialFadeValue(ShieldAlpha);

		for (int i = 0; i < BallBoss.ShieldVFXDatas.Num(); ++i)
		{
			if (BallBoss.ShieldVFXDatas[i].VFXLifetime >= Settings.DetonatorOffShieldVFXDuration)
			{
				BallBoss.ShieldVFXDatas[i].VFXComp.Deactivate();
				BallBoss.ShieldVFXDatas[i].VFXComp.DestroyComponent(BallBoss);
				BallBoss.ShieldVFXDatas.RemoveAt(i);
				break;
			}
		}
	}

	private void SetShieldMaterialFadeValue(float NewAlpha)
	{	
		float Value = Math::Lerp(0.0, 100.0, NewAlpha);
		FVector VectorColor = FVector(BallBoss.ShieldColor.R,BallBoss.ShieldColor.G, BallBoss.ShieldColor.B);
		BallBoss.ShieldShockwave.SetVectorParameterValueOnMaterials(n"Color", VectorColor * Value);
	}
}