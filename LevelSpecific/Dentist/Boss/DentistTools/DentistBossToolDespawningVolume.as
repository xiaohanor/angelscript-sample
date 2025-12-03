class ADentistBossToolDespawningTrigger : AActorTrigger
{
	default ActorClasses.Add(ADentistBossToolDentures);
	default ActorClasses.Add(ADentistBossToolCup);

	default BrushColor = FLinearColor(0.52, 0.07, 0.07);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"OnActorEnter");
	}

	UFUNCTION()
	private void OnActorEnter(AHazeActor Actor)
	{
		auto Tool = Cast<ADentistBossTool>(Actor);
		if(Tool == nullptr)
			return;

		Tool.GetDestroyed();
	}
};