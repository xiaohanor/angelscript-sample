class USerpentHeadMovementSpeedCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 40;

	ASerpentHead SerpentHead;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SerpentHead = Cast<ASerpentHead>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SerpentHead.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SerpentHead.bIsActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SerpentHead.RubberbandSpeed = SerpentHead.MovementSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto Settings = USerpentMovementSettings::GetSettings(SerpentHead);
		if (SerpentHead.bRubberbanding)
		{
			float RubberbandModifier = 1.0;
			if (Game::GetClosestPlayer(SerpentHead.ActorLocation).GetDistanceTo(SerpentHead) < Settings.RubberbandMinDistance)
			{
				// Speed up
				RubberbandModifier = Settings.RubberbandMaxFast;
			}
			else if (Game::GetClosestPlayer(SerpentHead.ActorLocation).GetDistanceTo(SerpentHead) > Settings.RubberbandMaxDistance)
			{
				// Slow down
				RubberbandModifier = Settings.RubberbandMaxSlow;
			}

			float TargetRubberbanding = (SerpentHead.MovementSpeed * RubberbandModifier) - SerpentHead.MovementSpeed;
			SerpentHead.RubberbandSpeed = Math::FInterpConstantTo(SerpentHead.RubberbandSpeed, TargetRubberbanding, DeltaTime, Settings.BaseMovementSpeed / 2.0);
		}
		else
			SerpentHead.RubberbandSpeed = Math::FInterpConstantTo(SerpentHead.RubberbandSpeed, 0.0, DeltaTime, Settings.BaseMovementSpeed / 2.0);

		SerpentHead.MovementSpeed = Math::FInterpConstantTo(SerpentHead.MovementSpeed, Settings.BaseMovementSpeed, DeltaTime, SerpentHead.MovementInterpSpeed);
	}
};