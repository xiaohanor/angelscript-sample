class ASkylinePatrolCombatDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditInstanceOnly)
	TArray<AHazeActorSpawnerBase> Spawners;

	UPROPERTY(EditAnywhere)
	float Delay = 4.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceComp.AddDisabler(this);

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		InterfaceComp.OnActivated.Unbind(this, n"HandleActivated");

		Timer::SetTimer(this, n"OpenDoor", Delay);

//		Timer::SetTimer(this, n"CloseDoor", 2.0);
	}

	UFUNCTION()
	private void OpenDoor()
	{
		ForceComp.RemoveDisabler(this);

		Timer::SetTimer(this, n"ActivateSpawners", 1.0);
	}

	UFUNCTION()
	private void CloseDoor()
	{
		ForceComp.Force *= -1.0;
	}

	UFUNCTION()
	private void ActivateSpawners()
	{
		for (auto Spawner : Spawners)
			Spawner.ActivateSpawner();
	}
};