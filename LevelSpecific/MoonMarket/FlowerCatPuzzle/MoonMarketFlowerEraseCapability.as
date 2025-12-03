class UMoonMarketFlowerEraseCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	UMoonMarketPlayerFlowerSpawningComponent FlowerSpawnerComp;
	UHazeMovementComponent MoveComp;

	FVector PositionLastFrame;
	float DistSinceLastFlower;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlowerSpawnerComp = UMoonMarketPlayerFlowerSpawningComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(FlowerSpawnerComp.PaintingVolume == nullptr)
			return false;

		if(FlowerSpawnerComp.Hat == nullptr)
			return false;

		if(!MoveComp.IsOnWalkableGround())
			return false;

		if(!IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		if(IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(FlowerSpawnerComp.PaintingVolume == nullptr)
			return true;

		if(FlowerSpawnerComp.Hat == nullptr)
			return true;

		if(!MoveComp.IsOnWalkableGround())
			return true;

		if(!IsActioning(ActionNames::SecondaryLevelAbility))
			return true;
		
		if(IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PositionLastFrame = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		DistSinceLastFlower += Owner.ActorLocation.Dist2D(PositionLastFrame);
		PositionLastFrame = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;
		
		if(DistSinceLastFlower > 10)
		{
			FlowerSpawnerComp.CrumbEraseFlowers();
			DistSinceLastFlower = 0;
		}
	}
};