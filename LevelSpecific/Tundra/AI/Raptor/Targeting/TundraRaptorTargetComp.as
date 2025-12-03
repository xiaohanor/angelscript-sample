class UTundraRaptorTargetComp : UActorComponent
{
	TArray<AHazeActor> Targets;

	UBasicAITargetingComponent TargetComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetComp = UBasicAITargetingComponent::GetOrCreate(Owner);
	}

	UFUNCTION()
	void AddTarget(AHazeActor Target)
	{
		Targets.AddUnique(Target);
		TargetComp.SetPotentialTargets(Targets);
	}

	UFUNCTION()
	void RemoveTarget(AHazeActor Target)
	{
		Targets.Remove(Target);
		TargetComp.SetPotentialTargets(Targets);
		if(TargetComp.Target == Target)
			TargetComp.SetTarget(nullptr);
	}
}