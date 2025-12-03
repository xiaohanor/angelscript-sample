class USanctuaryLightBirdShieldBirdAttachCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"LightBirdShield");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1;

	USanctuaryLightBirdShieldUserComponent UserComp;
	ULightBirdUserComponent LightBirdUserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USanctuaryLightBirdShieldUserComponent::Get(Owner);
		LightBirdUserComp = ULightBirdUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bIsActive)
			return false;

//		if (UserComp.InsideDarknessVolumes == 0)
//			return false;

		if (!Player.IsMio())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bIsActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(LightBird::Tags::LightBirdAim, this);
		Player.BlockCapabilities(LightBird::Tags::LightBirdRelease, this);
		Player.BlockCapabilities(LightBird::Tags::LightBirdFire, this);
		Player.BlockCapabilities(LightBird::Tags::LightBirdRecall, this);
		Player.BlockCapabilities(LightBird::Tags::LightBirdHover, this);
		Player.BlockCapabilities(LightBird::Tags::LightBirdLaunch, this);

		LightBirdUserComp.Companion.BlockCapabilities(LightBird::Tags::LightBirdAim, this);
		LightBirdUserComp.Companion.BlockCapabilities(LightBird::Tags::LightBirdRelease, this);
		LightBirdUserComp.Companion.BlockCapabilities(LightBird::Tags::LightBirdFire, this);
		LightBirdUserComp.Companion.BlockCapabilities(LightBird::Tags::LightBirdRecall, this);
		LightBirdUserComp.Companion.BlockCapabilities(LightBird::Tags::LightBirdHover, this);
		LightBirdUserComp.Companion.BlockCapabilities(LightBird::Tags::LightBirdLaunch, this);
		LightBirdUserComp.Companion.BlockCapabilities(BasicAITags::Behaviour, this);


		// Set LightBird State to aiming to place bird on hand
		LightBirdUserComp.State = ELightBirdState::Aiming;

		LightBirdUserComp.Companion.AttachToComponent(Player.Mesh, LightBirdUserComp.Companion.Settings.LaunchStartSocket, EAttachmentRule::SnapToTarget);
//		LightBirdUserComp.Companion.TeleportActor(Player.Mesh, FRotator::ZeroRotator, this);

		// TArray<ULightComponent> Lights;
		// LightBirdUserComp.Companion.GetComponentsByClass(Lights);
		// for (auto Light : Lights)
		// {
		// 	Light.SetHiddenInGame(true);
		// }
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(LightBird::Tags::LightBirdAim, this);
		Player.UnblockCapabilities(LightBird::Tags::LightBirdRelease, this);
		Player.UnblockCapabilities(LightBird::Tags::LightBirdFire, this);
		Player.UnblockCapabilities(LightBird::Tags::LightBirdRecall, this);
		Player.UnblockCapabilities(LightBird::Tags::LightBirdHover, this);
		Player.UnblockCapabilities(LightBird::Tags::LightBirdLaunch, this);

		LightBirdUserComp.Companion.UnblockCapabilities(LightBird::Tags::LightBirdAim, this);
		LightBirdUserComp.Companion.UnblockCapabilities(LightBird::Tags::LightBirdRelease, this);
		LightBirdUserComp.Companion.UnblockCapabilities(LightBird::Tags::LightBirdFire, this);
		LightBirdUserComp.Companion.UnblockCapabilities(LightBird::Tags::LightBirdRecall, this);
		LightBirdUserComp.Companion.UnblockCapabilities(LightBird::Tags::LightBirdHover, this);
		LightBirdUserComp.Companion.UnblockCapabilities(LightBird::Tags::LightBirdLaunch, this);
		LightBirdUserComp.Companion.UnblockCapabilities(BasicAITags::Behaviour, this);

		LightBirdUserComp.Companion.DetachFromActor();

		// TArray<ULightComponent> Lights;
		// LightBirdUserComp.Companion.GetComponentsByClass(Lights);
		// for (auto Light : Lights)
		// {
		// 	Light.SetHiddenInGame(false);
		// }
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		LightBirdUserComp.State = ELightBirdState::Aiming;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (LightBirdUserComp == nullptr)
			LightBirdUserComp = ULightBirdUserComponent::Get(Owner);
	}
};