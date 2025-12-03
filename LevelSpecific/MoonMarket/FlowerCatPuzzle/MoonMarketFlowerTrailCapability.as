class UMoonMarketFlowerTrailCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;


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
		if(FlowerSpawnerComp.Hat == nullptr)
			return false;
		
		if(!MoveComp.IsOnWalkableGround())
			return false;

		if(Cast<AWitchBouncyMushroomActor>(MoveComp.GetGroundContact().Actor) != nullptr)
			return false;

		if(Cast<AMoonMarketSnail>(MoveComp.GetGroundContact().Actor) != nullptr)
			return false;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(FlowerSpawnerComp.Hat == nullptr)
			return true;

		if(!MoveComp.IsOnWalkableGround())
			return true;

		if(!MoveComp.GetGroundContact().bIsWalkable)
			return true;

		if(Cast<AWitchBouncyMushroomActor>(MoveComp.GetGroundContact().Actor) != nullptr)
			return true;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplySettings(FlowerSpawnerComp.FloorMotionSetting, this);
		Player.BlockCapabilities(PlayerMovementTags::Sprint, this);
		PositionLastFrame = Owner.ActorLocation;
		FlowerSpawnerComp.bIsDancing = true;
		//UPlayerPerchComponent::GetOrCreate(Player).Data.bInPerchSpline = true;

		UMoonMarketFlowerHatEventHandler::Trigger_OnPlayerStartedAbility(FlowerSpawnerComp.Hat, FMoonMarketFlowerHatEffectParams(Player, PositionLastFrame));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::Sprint, this);
		Player.ClearSettingsByInstigator(this);
		FlowerSpawnerComp.bIsDancing = false;

		if(FlowerSpawnerComp.Hat != nullptr)
			UMoonMarketFlowerHatEventHandler::Trigger_OnPlayerStoppedAbility(FlowerSpawnerComp.Hat, FMoonMarketFlowerHatEffectParams(Player, PositionLastFrame));
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
		if(HasControl())
		{
			if(DistSinceLastFlower >= FlowerSpawnerComp.DistanceBetweenFlowerSpawns)
			{
				TArray<FVector> SpawnLocations;
				for(int i = 0; i < FlowerSpawnerComp.FlowersPerSpawn; i++)
				{
					SpawnLocations.Add(Math::GetRandomPointInCircle_XY() * FlowerSpawnerComp.FlowerSpawnRadius);
				}

				FlowerSpawnerComp.CrumbSpawnFlowers(SpawnLocations, Owner.ActorLocation, FlowerSpawnerComp.Hat.Type);
				DistSinceLastFlower = 0;
			}
		}

		float FFFrequency = 10.0;
		FHazeFrameForceFeedback FF;
		FF.RightMotor = 0.5 + Math::Sin(Time::GameTimeSeconds * FFFrequency);
		FF.LeftMotor = 0.2 + Math::Sin(Time::GameTimeSeconds * -FFFrequency);
		Player.SetFrameForceFeedback(FF, 0.01);

		if(Player.Mesh.CanRequestLocomotion())
			Player.Mesh.RequestLocomotion(n"FlowerHat", this);
	}
};