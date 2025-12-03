class USkylineBallBossDisintegratePulseCapability : USkylineBallBossChildCapability
{
	bool bAlphaDone = false;
	bool bRadiusDone = false;
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		BallBoss.DisintegratePulseAlphaTimelike.BindUpdate(this, n"UpdatePulseAlpha");
		BallBoss.DisintegratePulseRadiusTimelike.BindUpdate(this, n"UpdatePulseRadius");
		BallBoss.DisintegratePulseAlphaTimelike.BindFinished(this, n"AlphaFinished");
		BallBoss.DisintegratePulseRadiusTimelike.BindFinished(this, n"RadiusFinished");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return BallBoss.bTriggerDisintegrationPulse;
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
		//BallBoss.DisintegrationSphere.SetVisibility(true);
		BallBoss.DisintegrationSphere.SetWorldScale3D(FVector::OneVector * Settings.DisintegratePulseMinRadius);
		BallBoss.DisintegratePulseAlphaTimelike.PlayFromStart();
		BallBoss.DisintegratePulseRadiusTimelike.PlayFromStart();
		bAlphaDone = false;
		bRadiusDone = false;
		BallBoss.bTriggerDisintegrationPulse = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.DisintegrationSphere.SetVisibility(false);
		BallBoss.DisintegrationRadius = 0.0;
	}

	UFUNCTION()
	private void UpdatePulseAlpha(float NewAlpha)
	{	
		float Value = Math::Lerp(0.0, 25.0, 1.0);
		float Hue = Math::Lerp(0.0, 255.0, Time::GameTimeSeconds % 1.0);
		FLinearColor IntenseColor = FLinearColor::MakeFromHSV8(uint8(Hue), 255, 255);
		FVector VectorColor = FVector(IntenseColor.R,IntenseColor.G, IntenseColor.B);
		BallBoss.DisintegrationSphere.SetVectorParameterValueOnMaterials(n"Color", VectorColor * Value);
		// FLinearColor LerpedColor = Math::Lerp(ColorDebug::Black, ColorDebug::Fern, NewAlpha);
		// Debug::DrawDebugSphere(BallBoss.ActorLocation, BallBoss.DisintegrationSphere.GetWorldScale().X * 50.0, 12, LerpedColor, 5.0, 0.0, true);
	}

	UFUNCTION()
	private void UpdatePulseRadius(float NewAlpha)
	{	
		float Radius = Math::Lerp(Settings.DisintegratePulseMinRadius, Settings.DisintegratePulseMaxRadius, NewAlpha);
		BallBoss.DisintegrationSphere.SetWorldScale3D(FVector::OneVector * Radius);
		BallBoss.DisintegrationRadius = Radius * 50.0; // Sphere mesh is 50 big
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