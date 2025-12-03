class UGravityBikeSplineDriverDeathCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UGravityBikeSplineDriverComponent DriverComp;
	AGravityBikeSpline RespawnGravityBike;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeSplineDriverComponent::Get(Player);
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
		auto HealthComp = UPlayerHealthComponent::Get(Player);
		HealthComp.OnStartDying.AddUFunction(this, n"OnPlayerStartDying");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto HealthComp = UPlayerHealthComponent::Get(Player);
		HealthComp.OnStartDying.UnbindObject(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto GravityBike = DriverComp.GravityBike;
		auto MoveComp = UGravityBikeSplineMovementComponent::Get(GravityBike);
		const FVector Velocity = MoveComp.Velocity;

		if(HasControl())
		{
			if(GravityBike.DeathFromWallThisFrame())
				Player.KillPlayer();
		}

		// Moving deaths
		if(!Velocity.IsNearlyZero())
		{
			if(MoveComp.HasWallContact())
			{
				const FVector SplineDirection = GravityBike.GetSplineForward();

				FGravityBikeSplineOnWallImpactEventData EventData;
				EventData.ImpactPoint = MoveComp.WallContact.ImpactPoint.PointPlaneProject(GravityBike.MeshPivot.WorldLocation, GravityBike.ActorUpVector);
				FVector Normal = Math::Lerp(-GravityBike.ActorVelocity, MoveComp.WallContact.ImpactNormal, 0.3);
				EventData.ImpactNormal = Normal;
				EventData.ImpactStrength = Math::Abs(MoveComp.Velocity.DotProduct(Normal));
				UGravityBikeSplineEventHandler::Trigger_OnWallImpact(GravityBike, EventData);
			}
		}	
	}

	UFUNCTION()
	private void OnPlayerStartDying()
	{
		RespawnGravityBike = DriverComp.GravityBike;
		Player.OtherPlayer.BlockCapabilities(CapabilityTags::Visibility, this);
		Player.OtherPlayer.BlockCapabilities(CapabilityTags::GameplayAction, this);
		
		PlayerHealth::TriggerGameOver();
	}
};