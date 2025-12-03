class USanctuarySnakePlayerDamageCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default CapabilityTags.Add(n"SanctuarySnakePlayerDamage");

	USanctuarySnakeSettings Settings;

	USanctuarySnakeComponent SanctuarySnakeComponent;
	USanctuarySnakeTailComponent TailComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USanctuarySnakeSettings::GetSettings(Owner);

		SanctuarySnakeComponent = USanctuarySnakeComponent::Get(Owner);
		TailComponent = USanctuarySnakeTailComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		CheckPlayerOverlap(Owner.ActorLocation, Settings.PlayerDamageRadius * 2.0);

		for (auto Segment : TailComponent.TailSegments)
		{
			FVector Location = Segment.WorldLocation + Segment.UpVector * 100.0;
			CheckPlayerOverlap(Location, Settings.PlayerDamageRadius * Owner.ActorScale3D.Z);
		}
	}

	void CheckPlayerOverlap(FVector Location, float Radius)
	{
	//	Debug::DrawDebugSphere(Location, Radius, 6, FLinearColor::Red, 5.0, 0.0);

		for (auto Player : Game::Players)
		{
			if (Player.ActorLocation.IsWithinDist(Location, Radius))
			{	
				auto HealthComponent = UPlayerHealthComponent::Get(Player);
				if (!HealthComponent.bIsDead)
				{
					PrintScaled("Kill: " + Player, 1.0, FLinearColor::Green, 4.0);
					Player.KillPlayer();
					SanctuarySnakeComponent.bBurrow = true;
				}
			}
		}
	}
}