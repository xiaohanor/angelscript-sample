class UDarkMassSpawnCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(DarkMass::Tags::DarkMass);
	default CapabilityTags.Add(DarkMass::Tags::DarkMassSpawn);
	
	default DebugCategory = DarkMass::Tags::DarkMass;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 51;

	UDarkMassUserComponent UserComp;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkMassUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AimComp.IsAiming(UserComp))
			return false;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AimComp.IsAiming(UserComp))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto SurfaceData = UserComp.GetAimSurfaceData();

		if (SurfaceData.IsValid())
		{
			UserComp.MassActor = ADarkMassActor::Spawn(
				SurfaceData.WorldLocation,
				SurfaceData.WorldNormal.Rotation()
			);
			UDarkMassEventHandler::Trigger_Created(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (int i = UserComp.MassActor.CurrentGrabs.Num() - 1; i >= 0; --i)
		{
			auto Grab = UserComp.MassActor.CurrentGrabs[i];

			if (Grab != nullptr && Grab.Owner != nullptr)
			{
				auto ResponseComp = UDarkMassResponseComponent::Get(Grab.Owner);
				if (ResponseComp != nullptr)
					ResponseComp.Release(UserComp.MassActor, FDarkMassGrabData(Grab));
			}
		}

		UserComp.MassActor.DestroyActor();
		UserComp.MassActor = nullptr;

		UDarkMassEventHandler::Trigger_Destroyed(Player);
	}
}