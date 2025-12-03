class USanctuaryLightBirdShieldCapability : UHazePlayerCapability
{
//	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"LightBirdShield");

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

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
		if (!IsValid(UserComp.LightBirdShield))
			UserComp.LightBirdShield = SpawnActor(UserComp.Settings.LightBirdShieldClass);
//		UserComp.LightBirdShield.AttachToActor(Owner, n"LeftHand");

//		UserComp.LightBirdShield.AttachToActor(LightBirdUserComp.Companion);

		LightBirdUserComp.Companion.AnimComp.RequestFeature(LightBirdCompanionAnimTags::Shield, EBasicBehaviourPriority::High, this);

		TArray<ULightComponent> Lights;
		LightBirdUserComp.Companion.GetComponentsByClass(Lights);
		for (auto Light : Lights)
		{
			Light.SetHiddenInGame(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		//UserComp.LightBirdShield.SetAutoDestroyWhenFinished(true);
		UserComp.LightBirdShield.DestroyActor();

		LightBirdUserComp.Companion.AnimComp.ClearFeature(this);

		TArray<ULightComponent> Lights;
		LightBirdUserComp.Companion.GetComponentsByClass(Lights);
		for (auto Light : Lights)
		{
			Light.SetHiddenInGame(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.bIsControlledByCutscene && Player.Mesh.CanRequestOverrideFeature())
			Player.Mesh.RequestOverrideFeature(n"LightBird", this);

		LightBirdUserComp.State = ELightBirdState::Aiming;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (LightBirdUserComp == nullptr)
			LightBirdUserComp = ULightBirdUserComponent::Get(Owner);
	}
};