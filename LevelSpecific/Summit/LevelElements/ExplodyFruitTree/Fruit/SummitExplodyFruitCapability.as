class USummitExplodyFruitCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;

	ASummitExplodyFruit Fruit;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Fruit = Cast<ASummitExplodyFruit>(Owner);
		Fruit.AddActorVisualsBlock(this);
		Fruit.AddActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Fruit.bIsEnabled)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Fruit.bIsEnabled)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Fruit.RemoveActorVisualsBlock(this);
		Fruit.RemoveActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Fruit.AddActorVisualsBlock(this);
		Fruit.AddActorCollisionBlock(this);
	}
};