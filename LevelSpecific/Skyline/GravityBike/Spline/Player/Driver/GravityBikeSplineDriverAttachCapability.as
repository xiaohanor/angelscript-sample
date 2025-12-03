class UGravityBikeSplineDriverAttachCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -80;

	default CapabilityTags.Add(CapabilityTags::BlockedByCutscene);

	UGravityBikeSplineDriverComponent DriverComp;
	UPlayerHealthComponent DriverHealthComp;
	UTeleportResponseComponent TeleportComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeSplineDriverComponent::Get(Player);
		DriverHealthComp = UPlayerHealthComponent::Get(Player);
		TeleportComp = UTeleportResponseComponent::GetOrCreate(Player);
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
		Player.AttachToComponent(DriverComp.GravityBike.DriverAttachment);
		CapabilityInput::LinkActorToPlayerInput(DriverComp.GravityBike, Player);
		UGravityBikeSplineEventHandler::Trigger_OnMount(DriverComp.GravityBike);
		DriverComp.OnPlayerMounted.Broadcast(DriverComp.GravityBike);

		TeleportComp.OnTeleported.AddUFunction(this, n"OnPlayerTeleported");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CapabilityInput::LinkActorToPlayerInput(DriverComp.GravityBike, nullptr);
		Player.DetachFromActor();

		TeleportComp.OnTeleported.Unbind(this, n"OnPlayerTeleported");
	}

	UFUNCTION()
	private void OnPlayerTeleported()
	{
		FTransform ClosestTransform;
		AGravityBikeSplineActor SplineActor = GravityBikeSpline::GetClosestGravityBikeSplineActor(Player.ActorLocation, ClosestTransform);
		FTransform TeleportTransform = FTransform(ClosestTransform.Rotation, Player.ActorLocation);
		
		DriverComp.GravityBike.SetSpline(SplineActor);
		DriverComp.GravityBike.SnapToTransform(TeleportTransform, EGravityBikeSplineSnapToTransformVelocityMode::Zero);

		DriverComp.GravityBike.GetDriver().SetActorRelativeTransform(FTransform::Identity);
		DriverComp.GravityBike.GetPassenger().SetActorRelativeTransform(FTransform::Identity);
	}
};