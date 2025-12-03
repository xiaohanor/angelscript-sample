class UJetskiDriverAttachCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -90;
	
	default CapabilityTags.Add(CapabilityTags::BlockedByCutscene);

	UJetskiDriverComponent DriverComp;
	UTeleportResponseComponent TeleportComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UJetskiDriverComponent::Get(Player);
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
		Player.AttachToComponent(DriverComp.Jetski.DriverAttachment, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);

		TeleportComp.OnTeleported.AddUFunction(this, n"OnPlayerTeleported");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TeleportComp.OnTeleported.Unbind(this, n"OnPlayerTeleported");

		Player.DetachFromActor(EDetachmentRule::KeepWorld);
	}

	UFUNCTION()
	private void OnPlayerTeleported()
	{
#if !RELEASE
		TEMPORAL_LOG(this, Player, "Jetski")
			.Event("OnPlayerTeleported")
			.Transform("Player Transform", Player.ActorTransform)
			.Value("Player Attachment", Player.RootComponent.AttachParent)
			.Value("Jetski Transform", DriverComp.Jetski.ActorTransform)
		;
#endif

		DriverComp.Jetski.TeleportActor(Player.ActorLocation, Player.ActorRotation, this);
		Player.SetActorRelativeTransform(FTransform::Identity);
	}
};