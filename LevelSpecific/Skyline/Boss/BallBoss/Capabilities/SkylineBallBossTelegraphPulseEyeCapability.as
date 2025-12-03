class USkylineBallBossTelegraphPulseEyeCapability : USkylineBallBossChildCapability
{
	AHazeActor Zoe;
	UGravityWhipUserComponent WhipComponent;
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Zoe = Game::Zoe;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (WhipComponent == nullptr)
			WhipComponent = UGravityWhipUserComponent::Get(Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BallBoss.GetPhase() >= ESkylineBallBossPhase::TopMioOnEyeBroken)
			return false;

		if (WhipComponent == nullptr)
			return false;

		if (!WhipComponent.IsGrabbingAny() && !WhipComponent.bIsSlingThrowing)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOnEyeBroken)
			return true;

		if (!WhipComponent.IsGrabbingAny() && !WhipComponent.bIsSlingThrowing)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BallBoss.AddBlink(this, ESkylineBallBossBlinkExpression::StateOpen, ESkylineBallBossBlinkPriority::High);
		BallBoss.PulseOn();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.RemoveBlink(this);
		BallBoss.bHasResetMaterials = true;
		BallBoss.ResetLampMaterials();
	}
}