struct FGravityBikeBladeBarrelDropActivateParams
{
	AGravityBikeSpline GravityBike;
};

class UGravityBikeBladeBarrelDropCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeBladeBarrel Barrel;
	float VerticalSpeed = 0;
	AGravityBikeSpline GravityBike;

	const float DropAfterTime = 5;
	const float GameOverDelay = 1.5;
	const float Gravity = 2000;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Barrel = Cast<AGravityBikeBladeBarrel>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeBladeBarrelDropActivateParams& Params) const
	{
		// If we have ever attached
		if(Barrel.AttachTime < 0)
			return false;

		// But we are no longer attached, then drop
		if(!Barrel.IsGravityBikeAttached())
			return true;

		if(Time::GetGameTimeSince(Barrel.AttachTime) > DropAfterTime)
		{
			// And we should have grappled away by now but not done so, drop
			Params.GravityBike = Barrel.GravityBike;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > 20)
			return true;

		if(Barrel.ActorLocation.Z < 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeBladeBarrelDropActivateParams Params)
	{
		Barrel.bIsDropping = true;
		GravityBike = Params.GravityBike;

		if(GravityBike != nullptr)
		{
			// If we dropped from waiting too long, prevent the player from detaching and kill them later
			GravityBike.BlockCapabilities(GravityBikeBlade::Tags::GravityBikeBladeTrigger, this);
			GravityBike.BlockCapabilities(GravityBikeBlade::Tags::GravityBikeBladeThrow, this);
		}

		UGravityBikeBladeBarrelEventHandler::Trigger_OnDrop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Barrel.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Delta = 0;
		Acceleration::ApplyAccelerationToSpeed(VerticalSpeed, Gravity, DeltaTime, Delta);
		Delta += VerticalSpeed * DeltaTime;

		FVector Location = Barrel.ActorLocation;
		Location.Z -= Delta;
		Barrel.SetActorLocation(Location);

		if(GravityBike != nullptr && ActiveDuration > GameOverDelay && !GravityBike.GetDriver().IsPlayerDead())
		{
			GravityBike.GetDriver().KillPlayer();
		}
	}
};