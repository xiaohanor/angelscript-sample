class USkylineBallBossTelegraphRedEyeCapability : USkylineBallBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;
	UGravityWhipUserComponent WhipComponent;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (WhipComponent == nullptr)
			WhipComponent = UGravityWhipUserComponent::Get(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BallBoss.DetonatorSocketComp1.AttachedDetonator != nullptr)
			return true;

		if (BallBoss.DetonatorSocketComp1.AttachedDetonator != nullptr)
			return true;

		if (BallBoss.DetonatorSocketComp1.AttachedDetonator != nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BallBoss.DetonatorSocketComp1.AttachedDetonator != nullptr)
			return false;

		if (BallBoss.DetonatorSocketComp1.AttachedDetonator != nullptr)
			return false;

		if (BallBoss.DetonatorSocketComp1.AttachedDetonator != nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//BallBoss.OnBallBossCritFlickerStart.Broadcast();
		BallBoss.TelegraphEyeQueueComp.Event(BallBoss, n"PanikEyeOn");
		BallBoss.TelegraphEyeQueueComp.Idle(0.315);
		BallBoss.TelegraphEyeQueueComp.Event(BallBoss, n"PanikEyeOff");
		BallBoss.TelegraphEyeQueueComp.Idle(0.315);
		BallBoss.TelegraphEyeQueueComp.SetLooping(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		//BallBoss.OnBallBossCritFlickerEnd.Broadcast();
		BallBoss.TelegraphEyeQueueComp.Empty();
		BallBoss.TelegraphEyeQueueComp.SetLooping(false);
		BallBoss.bHasResetMaterials = true;
		BallBoss.ResetLampMaterials();
	}
}