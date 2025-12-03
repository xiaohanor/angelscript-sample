class USanctuaryWeeperLightBirdTransformCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 80;

	ASanctuaryWeeperLightBird LightBird;
	USanctuaryWeeperLightBirdUserComponent UserComp;
	UTeleportResponseComponent TeleportComp;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightBird = Cast<ASanctuaryWeeperLightBird>(Owner);
		Player = LightBird.Player;
		UserComp = USanctuaryWeeperLightBirdUserComponent::Get(Player);
		TeleportComp = UTeleportResponseComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.ShouldTransform())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.ShouldTransform())
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.bIsPlayerTransformed = true;

		FRotator Rotation = FRotator::MakeFromZX(Player.MovementWorldUp, Player.ActorForwardVector);
		LightBird.TeleportActor(Player.ActorLocation, Rotation, this, false);
		
		Player.AttachToComponent(LightBird.RootComponent);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::Visibility, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);

		TeleportComp.OnTeleported.AddUFunction(this, n"HandlePlayerTeleported");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.bIsPlayerTransformed = false;

		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(CapabilityTags::Visibility, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		TeleportComp.OnTeleported.Unbind(this, n"HandlePlayerTeleported");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	UFUNCTION()
	private void HandlePlayerTeleported()
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		FRotator Rotation = FRotator::MakeFromZX(Player.MovementWorldUp, Player.ActorForwardVector);
		LightBird.TeleportActor(Player.ActorLocation, Rotation, this, false);
		Player.AttachToComponent(LightBird.RootComponent);
	}
}