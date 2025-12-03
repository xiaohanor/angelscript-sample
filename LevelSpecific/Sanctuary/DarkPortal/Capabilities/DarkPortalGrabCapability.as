class UDarkPortalGrabCapability : UHazeCapability
{
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalGrab);

	default TickGroupOrder = 105;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADarkPortalActor Portal;
	AHazePlayerCharacter Player;
	UDarkPortalUserComponent UserComp;
	UPlayerTargetablesComponent TargetablesComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Portal = Cast<ADarkPortalActor>(Owner);
		Player = Portal.Player;
		UserComp = UDarkPortalUserComponent::Get(Portal.Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Portal.Player);
		DevTogglesDarkPortal::DebugDraw.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Portal.IsSettled())
			return false;

		if (!Portal.bPlayerWantsGrab)
			return false;
		
		float SpawnEndTime = (DarkPortal::Timings::SpawnDelay + DarkPortal::Timings::SpawnDuration);
		if (Time::GetGameTimeSince(Portal.StateTimestamp) <= SpawnEndTime)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Portal.IsSettled())
			return true;

		if (!Portal.bPlayerWantsGrab)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (HasControl())
		{
			// Get filtered targetables and grab them
			TArray<UTargetableComponent> Targetables;
			TargetablesComp.GetRegisteredTargetables(n"DarkPortal", Targetables);
			FilterTargetables(Targetables, DarkPortal::Grab::SpawnExtendedRange);

			for (int i = 0; i < Targetables.Num(); ++i)
			{
				UDarkPortalTargetComponent DarkPortalTarget = Cast<UDarkPortalTargetComponent>(Targetables[i]);
				if (ensure(DarkPortalTarget != nullptr, "Dark Portal Grab Target isn't of class UDarkPortalTargetComponent!"))
				{
					Portal.CrumbGrab(DarkPortalTarget);
				}
			}
		}

		for (auto Arm : Portal.SpawnedArms)
			Arm.Extend();

		Portal.bIsGrabActive = true;
		UDarkPortalEventHandler::Trigger_GrabActivated(Portal);
		UDarkPortalPlayerEventHandler::Trigger_GrabActivated(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Portal.PushAndReleaseAll();
		
		for (auto Arm : Portal.SpawnedArms)
			Arm.Contract();

		if(HasControl())
		{
			for (int i = Portal.Grabs.Num() - 1; i >= 0; --i)
			{			
				auto& Grab = Portal.Grabs[i];	
				for (int j = Grab.TargetComponents.Num() - 1; j >= 0; --j)
				{
					auto TargetComponent = Grab.TargetComponents[j];					
					Portal.CrumbRelease(TargetComponent);					
				}
			}
		}		
		
		Portal.bIsGrabActive = false;
		UDarkPortalEventHandler::Trigger_GrabDeactivated(Portal);
		UDarkPortalPlayerEventHandler::Trigger_GrabDeactivated(Player);

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Make sure all arms are extended
		// Sometimes due to the way the effect handler works the arms aren't spawned yet when the grab starts
		for (auto Arm : Portal.SpawnedArms)
			Arm.Extend();

		if (!HasControl())
			return;

		for (int i = Portal.Grabs.Num() - 1; i >= 0; --i)
		{
			auto& Grab = Portal.Grabs[i];

			for (int j = Grab.TargetComponents.Num() - 1; j >= 0; --j)
			{
				auto TargetComponent = Grab.TargetComponents[j];

				if (DevTogglesDarkPortal::DebugDraw.IsEnabled())
					Debug::DrawDebugSphere(TargetComponent.WorldLocation);

				// Release target components that no longer fit our criteria
				if (Portal.ShouldRelease(TargetComponent))
				{
					Portal.CrumbRelease(TargetComponent);
					continue;
				}
			}
		}

		for (int i = Portal.Grabs.Num() - 1; i >= 0; --i)
		{
			auto& Grab = Portal.Grabs[i];

			bool bWasEventTriggered = Grab.bHasTriggeredResponse;
			if (!bWasEventTriggered && Time::GetGameTimeSince(Grab.Timestamp) >= DarkPortal::Timings::GrabDuration)
				Grab.bHasTriggeredResponse = true;

			// Trigger grab event if we flipped the ole bool :^)
			if (!bWasEventTriggered && Grab.bHasTriggeredResponse)
				CrumbTriggerGrabResponse(Grab.Actor);
		}

		TArray<UTargetableComponent> Targetables;
		TargetablesComp.GetRegisteredTargetables(UDarkPortalTargetComponent, Targetables);
		FilterTargetables(Targetables, 0.0);

		for (int i = 0; i < Targetables.Num(); ++i)
			Portal.CrumbGrab(Cast<UDarkPortalTargetComponent>(Targetables[i]));
	}

	void FilterTargetables(TArray<UTargetableComponent>&inout Targetables, float ExtendedRange) const
	{
		int GrabsRemaining = (DarkPortal::Grab::MaxGrabs - Portal.GetNumGrabbedComponents());

		if (GrabsRemaining <= 0)
		{
			Targetables.Empty();
			return;
		}

		// Filter out ungrabbable targetables
		for (int i = Targetables.Num() - 1; i >= 0; --i)
		{
			auto Targetable = Cast<UDarkPortalTargetComponent>(Targetables[i]);
			if (!Portal.ShouldGrab(Targetable, ExtendedRange))
				Targetables.RemoveAt(i);
		}

		// Sort by ascending distance
		for (int i = 0; i < Targetables.Num(); ++i)
		{
			const float DistSqr = Portal.ActorLocation.DistSquared(Targetables[i].WorldLocation);

			for (int j = 0; j < i; ++j)
			{
				const float OtherDistSqr = Portal.ActorLocation.DistSquared(Targetables[j].WorldLocation);

				if (OtherDistSqr > DistSqr)
					Targetables.Swap(i, j);
			}
		}

		// Remove further away target components that belong to the same actor
		//  as a closer target component if multi-grabbing is disallowed
		for (int i = Targetables.Num() - 2; i >= 0; --i)
		{
			auto OutermostActor = DarkPortal::GetOutermostActor(Targetables[i].Owner);

			auto ResponseComp = UDarkPortalResponseComponent::Get(OutermostActor);
			if (ResponseComp == nullptr || !ResponseComp.bAllowMultiComponentGrab)
			{
				for (int j = Targetables.Num() - 1; j >= i + 1; --j)
				{
					auto OtherOutermostActor = DarkPortal::GetOutermostActor(Targetables[j].Owner);

					if (OutermostActor == OtherOutermostActor)
						Targetables.RemoveAt(j);
				}
			}
		}

		// Resize the array to get rid of excess targetables
		Targetables.SetNum(Math::Min(Targetables.Num(), GrabsRemaining));
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerGrabResponse(AActor GrabbedActor)
	{
		int GrabIndex = Portal.GetActorGrabIndex(GrabbedActor);
		if (GrabIndex == -1)
		{
			// Shouldn't happen, but if it does...
			devError(f"Unable to find grab for actor {GrabbedActor.Name}");
			return;
		}
		
		auto& Grab = Portal.Grabs[GrabIndex];
		for (int j = Grab.TargetComponents.Num() - 1; j >= 0; --j)
		{
			auto TargetComponent = Grab.TargetComponents[j];
			DarkPortal::TriggerHierarchyGrab(Portal, TargetComponent);
		}
		Grab.bHasTriggeredResponse = true;			
	}
}