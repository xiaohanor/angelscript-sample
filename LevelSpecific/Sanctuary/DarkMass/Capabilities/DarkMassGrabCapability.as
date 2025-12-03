class UDarkMassGrabCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(DarkMass::Tags::DarkMass);
	default CapabilityTags.Add(DarkMass::Tags::DarkMassGrab);

	default DebugCategory = DarkMass::Tags::DarkMass;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 54;

	UDarkMassUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkMassUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.MassActor == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (UserComp.MassActor == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// opting tbd :^)
		auto MassActor = UserComp.MassActor;

		// Fetch all targetables for our category
		TArray<UTargetableComponent> Targetables;
		TargetablesComp.GetPossibleTargetables(UDarkMassTargetComponent, Targetables);

		// Filter by distance and whether we can grab
		const float GrabRangeSqr = Math::Square(DarkMass::GrabRange);
		for (int i = Targetables.Num() - 1; i >= 0; --i)
		{
			const float DistSqr = MassActor.ActorLocation.DistSquared(Targetables[i].WorldLocation);
			const bool bIsSurfaceActor = (MassActor.CurrentSurface.Actor == Targetables[i].Owner);

			if (DistSqr > GrabRangeSqr || (!DarkMass::bCanGrabSurface && bIsSurfaceActor))
				Targetables.RemoveAt(i);
		}

		// Sort by ascending distance
		for (int i = 0; i < Targetables.Num(); ++i)
		{
			const float DistSqr = MassActor.ActorLocation.DistSquared(Targetables[i].WorldLocation);

			for (int j = 0; j < i; ++j)
			{
				const float OtherDistSqr = MassActor.ActorLocation.DistSquared(Targetables[j].WorldLocation);

				if (OtherDistSqr > DistSqr)
					Targetables.Swap(i, j);
			}
		}

		// Remove further away target components that belong
		//  to the same actor as a closer target component
		if (DarkMass::bSingleActorGrab)
		{
			for (int i = Targetables.Num() - 2; i >= 0; --i)
			{
				for (int j = Targetables.Num() - 1; j >= i + 1; --j)
				{
					if (Targetables[i].Owner == Targetables[j].Owner)
						Targetables.RemoveAt(j);
				}
			}
		}

		// Resize the array to get rid of excess targetables
		Targetables.SetNum(Math::Min(Targetables.Num(), DarkMass::MaxGrabs));

		// Grab those that haven't been grabbed
		for (int i = Targetables.Num() - 1; i >= 0; --i)
		{
			if (!MassActor.CurrentGrabs.Contains(Targetables[i]))
			{
				auto ResponseComp = UDarkMassResponseComponent::Get(Targetables[i].Owner);
				if (ResponseComp != nullptr)
					ResponseComp.Grab(MassActor, FDarkMassGrabData(Targetables[i]));
			}
		}

		// Release no longer grabbed ones
		for (int i = MassActor.CurrentGrabs.Num() - 1; i >= 0; --i)
		{
			if (!Targetables.Contains(MassActor.CurrentGrabs[i]))
			{
				auto ResponseComp = UDarkMassResponseComponent::Get(MassActor.CurrentGrabs[i].Owner);
				if (ResponseComp != nullptr)
					ResponseComp.Release(MassActor, FDarkMassGrabData(MassActor.CurrentGrabs[i]));
			}	
		}

		MassActor.CurrentGrabs = Targetables;
	}
}