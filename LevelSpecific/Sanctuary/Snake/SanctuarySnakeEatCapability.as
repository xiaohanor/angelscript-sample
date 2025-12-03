class USanctuarySnakeEatCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default CapabilityTags.Add(n"SanctuarySnake");

	USanctuarySnakeSettings Settings;

	UHazeTeam Team;

	ASanctuarySnake Snake;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USanctuarySnakeSettings::GetSettings(Owner);
		Snake = Cast<ASanctuarySnake>(Owner);
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
		Team = HazeTeam::GetTeam(n"SnakeFood");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (Team == nullptr)
			return;

		for (auto Member : Team.GetMembers())
		{
			if (Member == nullptr)
				continue;
			if (Owner.GetDistanceTo(Member) <= Settings.EatDistance)
			{
				auto EatableComponent = USanctuarySnakeEatableComponent::Get(Member);
				EatableComponent.Consume();
			}
		}
	}
}