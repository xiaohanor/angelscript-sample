class USkylineBallBossShieldShockwaveCapability : USkylineBallBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;
	
	bool bAlphaDone = false;
	bool bRadiusDone = false;
	bool bPeaked = false;
	bool bStartedShockwave = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		BallBoss.ShieldAlphaTimelike.BindUpdate(this, n"SetShieldMaterialFadeValue");
		BallBoss.ShieldRadiusTimelike.BindUpdate(this, n"SetShieldRadiusAlphaValue");
		BallBoss.ShieldAlphaTimelike.BindFinished(this, n"AlphaFinished");
		BallBoss.ShieldRadiusTimelike.BindFinished(this, n"RadiusFinished");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return BallBoss.GetPhase() == ESkylineBallBossPhase::TopShieldShockwave;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return bAlphaDone && bRadiusDone;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BallBoss.ResetTarget();
		
		bAlphaDone = false;
		bRadiusDone = false;
		bPeaked = false;

		Timer::SetTimer(this, n"DelayedActivate", 2.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.ShieldShockwave.CollisionEnabled = ECollisionEnabled::NoCollision;
		BallBoss.ShieldShockwave.SetVisibility(false);
	}

	UFUNCTION()
	private void DelayedActivate()
	{
		BallBoss.ShieldShockwave.SetVisibility(true);
		BallBoss.ShieldShockwave.SetWorldScale3D(FVector::OneVector * Settings.ShieldShockwaveMinRadius);
		BallBoss.ShieldAlphaTimelike.PlayFromStart();
		BallBoss.ShieldRadiusTimelike.PlayFromStart();
		BallBoss.ShieldShockwave.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	}

	UFUNCTION()
	private void SetShieldMaterialFadeValue(float NewAlpha)
	{	
		float Value = Math::Lerp(0.0, 500.0, NewAlpha);
		FVector VectorColor = FVector(BallBoss.ShieldColor.R,BallBoss.ShieldColor.G, BallBoss.ShieldColor.B);
		BallBoss.ShieldShockwave.SetVectorParameterValueOnMaterials(n"Color", VectorColor * Value);
	}

	UFUNCTION()
	private void SetShieldRadiusAlphaValue(float NewAlpha)
	{	
		float Radius = Math::Lerp(Settings.ShieldShockwaveMinRadius, Settings.ShieldShockwaveMaxRadius, NewAlpha);
		float CurrentRadius = BallBoss.ShieldShockwave.GetWorldScale().Size() * 0.5;
		BallBoss.ShieldShockwave.SetWorldScale3D(FVector::OneVector * Radius);
		if (NewAlpha > KINDA_SMALL_NUMBER && Radius > CurrentRadius + KINDA_SMALL_NUMBER && !bPeaked)
		{
			bPeaked = true;
			BallBoss.UnstickMioToBall();
			if (BallBoss.MioShieldGravityChangeVFXSystem != nullptr)
				Niagara::SpawnOneShotNiagaraSystemAttached(BallBoss.MioShieldGravityChangeVFXSystem, Game::Mio.RootComponent);
			BallBoss.ChangePhase(ESkylineBallBossPhase::TopMioOff2);
		}
	}

	UFUNCTION()
	private void AlphaFinished()
	{
		bAlphaDone = true;
	}
	
	UFUNCTION()
	private void RadiusFinished()
	{
		bRadiusDone = true;
	}
}