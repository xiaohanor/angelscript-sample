class UTundraGnapeGrabbedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(n"GnapeThrow");
	default TickGroup = EHazeTickGroup::InfluenceMovement;

	UTundraGnatComponent GnapeComp;
	UPlayerSnowMonkeyThrowGnapeComponent ThrowerComp;
	UHazeSkeletalMeshComponentBase ThrowerMesh;
	UBasicAIAnimationComponent AnimComp;
	UTundraGnatSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = UTundraGnatSettings::GetSettings(Owner);
		GnapeComp = UTundraGnatComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Player might be set up to be a snow monkey after our setup, so we need to check this stuff here
		if (ThrowerComp != nullptr)
			return;
		auto MonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Game::Mio);
		if (MonkeyComp == nullptr)
			return;
		ThrowerComp = UPlayerSnowMonkeyThrowGnapeComponent::Get(Game::Mio);
		if (ThrowerComp == nullptr)
			return;

		// Allow snow monkey to grab us
		ThrowerComp.RegisterThrowableGnape(Owner);
		ThrowerMesh = MonkeyComp.SnowMonkeyActor.Mesh;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (ThrowerComp != nullptr)
			ThrowerComp.UnregisterThrowableGnape(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ThrowerComp == nullptr)
			return false;
		if (ThrowerComp.GrabbedGnape != Owner)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ThrowerComp.GrabbedGnape != Owner)
			return true;
		if (GnapeComp.bThrownByMonkey)
		 	return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		Owner.AttachToComponent(ThrowerMesh, n"Align", EAttachmentRule::KeepWorld);
		Owner.SmoothTeleportActor(ThrowerMesh.GetSocketLocation(n"Align"), ThrowerMesh.GetSocketRotation(n"Align"), this, 0.2);
		AnimComp.RequestFeature(TundraGnatTags::GrabbedByMonkey, EBasicBehaviourPriority::Medium, this);

		UTundraGnatEffectEventHandler::Trigger_OnGrabbedByMonkey(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		Owner.DetachRootComponentFromParent(true);
		AnimComp.ClearFeature(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ThrowerComp.bThrow)	
		{
			// Player has started throw (this is crumb synced by player capability)
			AnimComp.RequestFeature(TundraGnatTags::ThrownByMonkey, EBasicBehaviourPriority::Medium, this);
		}

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugSphere(Owner.ActorLocation, 50.0, 4, FLinearColor::Green);
#endif		
	}
}
