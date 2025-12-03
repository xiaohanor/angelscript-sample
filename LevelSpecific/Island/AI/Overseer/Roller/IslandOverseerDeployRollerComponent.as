class UIslandOverseerDeployRollerComponent : UStaticMeshComponent
{
	default bHiddenInGame = true;
	default CollisionProfileName = CollisionProfile::NoCollision;

	UPROPERTY()
	TSubclassOf<AIslandOverseerRoller> RollerClass;
	AIslandOverseerRoller Roller;
	UIslandOverseerRollerComponent RollerComp;

	void SetupRoller(EIslandForceFieldType Color)
	{
		if(Roller != nullptr)
			return;
		Roller = SpawnActor(RollerClass, bDeferredSpawn = true, Level = Owner.Level);
		Roller.MakeNetworked(Owner, this);
		Roller.SetColor(Color);
		RollerComp = UIslandOverseerRollerComponent::GetOrCreate(Roller);
		RollerComp.OwningActor = Cast<AHazeActor>(Owner);
		RollerComp.DeployComp = this;
		RollerComp.SetupRoller();
		FinishSpawningActor(Roller);
		Attach();
	}

	void Detach()
	{
		Roller.DetachFromActor();
		UIslandOverseerRollerEventHandler::Trigger_OnDeployRoller(Roller, FIslandOverseerRollerEventHandlerOnDeployRollerData(AttachParent.GetSocketLocation(AttachSocketName), AttachSocketName));
	}

	void Attach()
	{
		Roller.AttachToComponent(this);
	}
}