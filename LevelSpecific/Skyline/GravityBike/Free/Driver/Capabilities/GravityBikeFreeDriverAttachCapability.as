class UGravityBikeFreeDriverAttachCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -80;

	default CapabilityTags.Add(CapabilityTags::BlockedByCutscene);

	UGravityBikeFreeDriverComponent DriverComp;
	UPlayerHealthComponent DriverHealthComp;
	UTeleportResponseComponent TeleportComp;

	AGravityBikeFree GravityBike;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		DriverHealthComp = UPlayerHealthComponent::Get(Player);
		TeleportComp = UTeleportResponseComponent::GetOrCreate(Player);

		GravityBike = GravityBikeFree::GetGravityBike(Player);
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
		Player.AttachToComponent(GravityBike.DriverAttachment);
		CapabilityInput::LinkActorToPlayerInput(GravityBike, Player);
		UGravityBikeFreeEventHandler::Trigger_OnMount(GravityBike);
		DriverComp.OnMounted.Broadcast(GravityBike);

		TeleportComp.OnTeleported.AddUFunction(this, n"OnPlayerTeleported");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CapabilityInput::LinkActorToPlayerInput(GravityBike, nullptr);
		Player.DetachFromActor();

		TeleportComp.OnTeleported.Unbind(this, n"OnPlayerTeleported");
	}

	UFUNCTION()
	private void OnPlayerTeleported()
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Status("OnTeleported", FLinearColor::LucBlue);
#endif

		FTransform TeleportTransform = Player.ActorTransform;
		GravityBike.SnapToTransform(TeleportTransform);
		Player.SetActorRelativeTransform(FTransform(FQuat::Identity, FVector::ZeroVector, Player.ActorRelativeScale3D));
		GravityBike.OnTeleported.Broadcast();
	}
};