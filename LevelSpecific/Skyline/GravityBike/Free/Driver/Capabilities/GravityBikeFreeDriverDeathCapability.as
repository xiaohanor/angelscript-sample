class UGravityBikeFreeDriverDeathCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	UGravityBikeFreeDriverComponent DriverComp;
	UPlayerHealthComponent HealthComp;
	UPlayerRespawnComponent RespawnComp;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		HealthComp = UPlayerHealthComponent::Get(Player);
		RespawnComp = UPlayerRespawnComponent::Get(Player);

		GravityBike = GravityBikeFree::GetGravityBike(Player);
		MoveComp = GravityBike.MoveComp;
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
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			if(GravityBike.DeathFromWallThisFrame())
			{
				KillPlayerFromWallImpact(GravityBike.DeathFromWallHitResult);
				return;
			}
		}

		const FVector Velocity = MoveComp.Velocity;
		if(!Velocity.IsNearlyZero())
		{
			if(MoveComp.HasWallContact())
			{
				FGravityBikeFreeOnWallImpactEventData EventData;
				EventData.ImpactPoint = MoveComp.WallContact.ImpactPoint.PointPlaneProject(GravityBike.MeshPivot.WorldLocation, GravityBike.ActorUpVector);
				FVector Normal = Math::Lerp(-Velocity, MoveComp.WallContact.ImpactNormal, 0.3);
				EventData.ImpactNormal = Normal;
				EventData.ImpactStrength = Math::Abs(Velocity.DotProduct(Normal));
				UGravityBikeFreeEventHandler::Trigger_OnWallImpact(GravityBike, EventData);
			}
		}
	}

	private void KillPlayerFromWallImpact(FHitResult WallImpact)
	{
		check(WallImpact.bBlockingHit);
		
		if(WallImpact.bBlockingHit)
		{
			FGravityBikeFreeOnWallImpactEventData EventData;
			EventData.ImpactPoint = WallImpact.ImpactPoint;
			EventData.ImpactNormal = WallImpact.ImpactNormal;
			UGravityBikeFreeEventHandler::Trigger_OnWallImpact(GravityBike, EventData);
		}

		Player.KillPlayer();
	}
};