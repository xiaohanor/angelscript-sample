class ASkylineBikeTowerCollisionTrigger : AActorTrigger
{
	default ActorClasses.Add(AGravityBikeFree);

	UPROPERTY(EditInstanceOnly)
	TArray<TSoftObjectPtr<AActor>> Actors;

	UPROPERTY(EditInstanceOnly)
	bool bDisableTriggerOnLeave = true;

	TArray<AActor> ExcludedActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"HandleActorEnter");
		OnActorLeave.AddUFunction(this, n"HandleActorLeave");
	}

	UFUNCTION()
	private void HandleActorEnter(AHazeActor EnteringActor)
	{
		if (ExcludedActors.Contains(EnteringActor))
			return;

		auto MoveComp = UHazeMovementComponent::Get(EnteringActor);

		for (auto Actor : Actors)
		{
			MoveComp.AddMovementIgnoresActor(this, Actor.Get());
			Actor.Get().AddActorCollisionBlock(this);
		}
	}

	UFUNCTION()
	private void HandleActorLeave(AHazeActor LeavingActor)
	{
		auto MoveComp = UHazeMovementComponent::Get(LeavingActor);
		MoveComp.RemoveMovementIgnoresActor(this);

		for (auto Actor : Actors)
		{
			Actor.Get().RemoveActorCollisionBlock(this);
		}

		if (bDisableTriggerOnLeave)
			ExcludedActors.Add(LeavingActor);
	}
};