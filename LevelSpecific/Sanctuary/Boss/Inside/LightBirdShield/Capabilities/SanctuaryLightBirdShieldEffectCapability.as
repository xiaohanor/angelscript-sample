class USanctuaryLightBirdShieldEffectCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"LightBirdShield");

	default TickGroup = EHazeTickGroup::Gameplay;

	USanctuaryLightBirdShieldUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USanctuaryLightBirdShieldUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return false;

		// if (!UserComp.bIsActive)
		// 	return false;

//		if (UserComp.InsideDarknessVolumes == 0)
//			return false;

		// if (!Player.IsZoe())
		// 	return false;

		// return true;
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
		UserComp.EffectActor = SpawnActor(UserComp.Settings.EffectActorClass);
		UserComp.EffectActor.AttachToActor(Owner);
//		FinishSpawningActor(UserComp.EffectActor);

		TArray<UPrimitiveComponent> Primitives;
		UserComp.EffectActor.GetComponentsByClass(Primitives);
		for (auto Primitive : Primitives)
			Primitive.SetRenderedForPlayer(Player.OtherPlayer, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.EffectActor.SetAutoDestroyWhenFinished(true);
	}
};