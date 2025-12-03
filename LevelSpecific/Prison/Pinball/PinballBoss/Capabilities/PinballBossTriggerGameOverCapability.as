class UPinballBossTriggerGameOverCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	APinballBoss Boss;

	const float BlockMovementDuration = 1.0;

	bool bGameOverOn = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<APinballBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		switch(Boss.BossState)
		{
			case EPinballBossState::Idle:
				return false;

			case EPinballBossState::Ball:
				return false;

			case EPinballBossState::Dying:
				return false;

			default:
				break;
		}

		if(!Pinball::GetBallPlayer().IsPlayerDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Pinball::GetBallPlayer().IsPlayerDead())
			return false;

		// Wait until we have fully faded in again
		if(SceneView::GetFullScreenPlayer().GetFadeOutPercentage() > 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerHealth::TriggerGameOver();

		AHazePlayerCharacter BallPlayer = Pinball::GetBallPlayer();
		BallPlayer.BlockCapabilities(CapabilityTags::MovementInput, this);
		BallPlayer.BlockCapabilities(CapabilityTags::Input, this);
		BallPlayer.BlockCapabilities(CapabilityTags::StickInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AHazePlayerCharacter BallPlayer = Pinball::GetBallPlayer();
		BallPlayer.UnblockCapabilities(CapabilityTags::MovementInput, this);
		BallPlayer.UnblockCapabilities(CapabilityTags::Input, this);
		BallPlayer.UnblockCapabilities(CapabilityTags::StickInput, this);
	}
};