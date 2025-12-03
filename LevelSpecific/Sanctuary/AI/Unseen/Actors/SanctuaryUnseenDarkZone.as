class ASanctuaryUnseenDarkZone : AActorTrigger
{
	default ActorClasses.Add(AAISanctuaryUnseen);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"OnActorEnter");
		OnActorLeave.AddUFunction(this, n"OnActorLeave");
	}

	UFUNCTION()
	private void OnActorEnter(AHazeActor Actor)
	{
		auto Chase = USanctuaryUnseenChaseComponent::Get(Actor);
		Chase.bDarkness = true;
	}

	UFUNCTION()
	private void OnActorLeave(AHazeActor Actor)
	{
		auto Chase = USanctuaryUnseenChaseComponent::Get(Actor);
		Chase.bDarkness = false;
	}
}