class UDarkMassPlacementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(DarkMass::Tags::DarkMass);
	default CapabilityTags.Add(DarkMass::Tags::DarkMassPlacement);
	
	default DebugCategory = DarkMass::Tags::DarkMass;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 52;

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

		if (UserComp.MassActor == nullptr)
			return false;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AimComp.IsAiming(UserComp))
			return true;

		if (UserComp.MassActor == nullptr)
			return true;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// if (UserComp.MassActor.DetachFromSurface())
		// {
		// 	const auto& CurrentSurface = UserComp.MassActor.CurrentSurface;
		// 	auto ResponseComp = UDarkMassResponseComponent::Get(CurrentSurface.Actor);
		// 	if (ResponseComp != nullptr)
		// 		ResponseComp.Detach(UserComp.MassActor, CurrentSurface);
		// 	Player.TriggerEffectEvent(n"DarkMass.Detached", CurrentSurface);
		// }
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// if (UserComp.MassActor != nullptr && 
		// 	UserComp.MassActor.AttachToSurface())
		// {
		// 	const auto& CurrentSurface = UserComp.MassActor.CurrentSurface;
		// 	auto ResponseComp = UDarkMassResponseComponent::Get(CurrentSurface.Actor);
		// 	if (ResponseComp != nullptr)
		// 		ResponseComp.Attach(UserComp.MassActor, CurrentSurface);
		// 	Player.TriggerEffectEvent(n"DarkMass.Attached", CurrentSurface);
		// }
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto SurfaceData = UserComp.GetAimSurfaceData();
		UserComp.MassActor.CurrentSurface = SurfaceData;
		// UserComp.MassActor.SetActorLocationAndRotation(
		// 	SurfaceData.WorldLocation,
		// 	FRotator::MakeFromX(SurfaceData.WorldNormal)
		// );
	}
}