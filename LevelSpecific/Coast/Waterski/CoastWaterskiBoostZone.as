class ACoastWaterskiBoostZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	UHazeMovablePlayerTriggerComponent TriggerComp;

	/* How fast (in addition to the train speed) to accelerate up to additional max speed. */
	UPROPERTY(EditAnywhere)
	float AdditionalAcceleration = 2500.0;

	/* How fast (in addition to the train speed) to move when fully accelerated. */
	UPROPERTY(EditAnywhere)
	float AdditionalMaxSpeed = 5500.0;

	/* This impulse will be added on top of the base jump impulse when the player is in this zone. */
	UPROPERTY(EditAnywhere)
	float AdditionalJumpImpulse = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		TriggerComp.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		auto WaterskiComp = UCoastWaterskiPlayerComponent::Get(Player);
		if(WaterskiComp == nullptr)
			return;

		WaterskiComp.OverlappedBoostZones.Add(this);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		auto WaterskiComp = UCoastWaterskiPlayerComponent::Get(Player);
		if(WaterskiComp == nullptr)
			return;

		WaterskiComp.OverlappedBoostZones.Remove(this);
	}
}