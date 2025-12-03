class USanctuaryWeeperLightBirdPlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 190;

	USanctuaryWeeperLightBirdUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USanctuaryWeeperLightBirdUserComponent::Get(Owner);
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
		if (devEnsure(UserComp.LightBirdClass != nullptr, "No light bird class has been selected."))
		{
			FRotator Rotation = FRotator::MakeFromZX(Player.MovementWorldUp, Player.ActorForwardVector);
			UserComp.LightBird = Cast<ASanctuaryWeeperLightBird>(
				SpawnActor(UserComp.LightBirdClass, Player.ActorLocation, Rotation, bDeferredSpawn = true)
			);
			UserComp.LightBird.Player = Player;
			FinishSpawningActor(UserComp.LightBird);
		}

		if (UserComp.bStartTransformed)
		{
			UserComp.Transform(UserComp.StartTransformedName);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (UserComp.LightBird != nullptr)
		{
			UserComp.LightBird.DestroyActor();
			UserComp.LightBird = nullptr;
		}
	}
}