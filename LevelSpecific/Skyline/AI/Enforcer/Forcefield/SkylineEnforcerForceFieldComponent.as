class USkylineEnforcerForceFieldComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<ASkylineEnforcerForceField> ForceFieldClass;

	ASkylineEnforcerForceField ForceField;

	bool bBroken;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceField = SpawnActor(ForceFieldClass, bDeferredSpawn = true);
		ForceField.HazeOwner = Cast<AHazeActor>(Owner);
		FinishSpawningActor(ForceField);
		ForceField.AttachToActor(Owner);

		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{		
		Restore();
	}

	void Break()
	{
		bBroken = true;
		ForceField.AddActorCollisionBlock(this);
		ForceField.AddActorVisualsBlock(this);
	}

	void Restore()
	{
		ForceField.RemoveActorCollisionBlock(this);
		ForceField.RemoveActorVisualsBlock(this);
		ForceField.bEnabled = true;
	}
}