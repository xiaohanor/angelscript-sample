class ASanctuaryLightBirdShieldDarknessVolume : APlayerTrigger
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityOnPlayerComp;

	UPROPERTY(EditAnywhere)
	float DarknessRate = 0.25;

	void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerEnter(Player);
		
		auto UserComp = USanctuaryLightBirdShieldUserComponent::Get(Player);
		UserComp.DarknessRate.Apply(DarknessRate, this);
		UserComp.DarknessVolumes.AddUnique(this);
		UserComp.InsideDarknessVolumes++;
	}

	void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerLeave(Player);

		auto UserComp = USanctuaryLightBirdShieldUserComponent::Get(Player);
		UserComp.DarknessRate.Clear(this);
		UserComp.DarknessVolumes.Remove(this);
		UserComp.InsideDarknessVolumes--;
	}
};