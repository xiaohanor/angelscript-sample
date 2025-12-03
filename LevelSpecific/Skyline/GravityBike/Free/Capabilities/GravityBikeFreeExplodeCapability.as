class UGravityBikeFreeExplodeCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Death);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	AGravityBikeFree GravityBike;

	AHazePlayerCharacter Player;
	UPlayerHealthComponent HealthComp;
	UCameraUserComponent CameraUserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);

		Player = GravityBike.GetDriver();
		HealthComp = UPlayerHealthComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HealthComp.bIsDead)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HealthComp.bIsDead)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UGravityBikeFreeEventHandler::Trigger_OnExplode(GravityBike);

		GravityBike.AddActorCollisionBlock(this);
		GravityBike.AddActorVisualsBlock(this);

		GravityBike.BlockCapabilities(GravityBikeFree::Tags::GravityBikeFree, this);
		GravityBike.BlockCapabilities(CapabilityTags::Movement, this);
		GravityBike.BlockCapabilities(CapabilityTags::Input, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GravityBike.RemoveActorCollisionBlock(this);
		GravityBike.RemoveActorVisualsBlock(this);
		
		GravityBike.UnblockCapabilities(GravityBikeFree::Tags::GravityBikeFree, this);
		GravityBike.UnblockCapabilities(CapabilityTags::Movement, this);
		GravityBike.UnblockCapabilities(CapabilityTags::Input, this);

		CameraUserComp.SnapCamera();

		FVector Forward = Player.ActorForwardVector.ConstrainToPlane(FVector::UpVector);
		GravityBike.SetActorVelocity(Forward * GravityBike.Settings.MaxSpeed);
	}
};