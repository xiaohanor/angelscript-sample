class USkylineBallBossPhaseAudioCapability : UHazeCapability
{
	ASkylineBallBoss BallBoss;
	ESkylineBallBossPhase TrackedPhase = ESkylineBallBossPhase::Chase;

	const FHazeAudioID IsMioInsideOrOnRTPCID = FHazeAudioID("Rtpc_Character_Boss_Skyline_BallBoss_IsMioOnOrInside");

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBoss = Cast<ASkylineBallBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AudioComponent::SetGlobalRTPC(IsMioInsideOrOnRTPCID, 0.0, 0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const ESkylineBallBossPhase CurrentPhase = BallBoss.GetPhase();
		if(CurrentPhase == TrackedPhase)
			return;

		const bool bIsInsideOrOn = IsInsideOrOnPhase(CurrentPhase);
		const bool bWasInsideOrOn = IsInsideOrOnPhase(TrackedPhase);

		if(bWasInsideOrOn != bIsInsideOrOn)
		{
			const int IsInsideOrOnValue = bIsInsideOrOn ? 1 : 0;
			AudioComponent::SetGlobalRTPC(IsMioInsideOrOnRTPCID, IsInsideOrOnValue, 0);

			TrackedPhase = CurrentPhase;
		}
	}

	bool IsInsideOrOnPhase(const ESkylineBallBossPhase InPhase)
	{
		if(InPhase >= ESkylineBallBossPhase::TopMioOn1 
		&& InPhase < ESkylineBallBossPhase::TopMioOff2)
			return true;

		if(InPhase >= ESkylineBallBossPhase::TopMioOn1
		&& InPhase < ESkylineBallBossPhase::TopMioOff2)
			return true;

		if(InPhase >= ESkylineBallBossPhase::TopMioIn
		&& InPhase < ESkylineBallBossPhase::TopDeath)
			return true;

		return false;
	}
}