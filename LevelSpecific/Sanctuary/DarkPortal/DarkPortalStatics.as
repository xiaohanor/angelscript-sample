namespace DarkPortal
{
	void TriggerHierarchyGrab(ADarkPortalActor PortalActor,
		UDarkPortalTargetComponent TargetComponent)
	{
		if (PortalActor == nullptr || TargetComponent == nullptr)
			return;

		TArray<UDarkPortalResponseComponent> ResponseComponents;
		GetHierarchyResponseComponents(ResponseComponents, TargetComponent.Owner);

		for (auto ResponseComponent : ResponseComponents)
			ResponseComponent.Grab(PortalActor, TargetComponent);

		// TODO: Reimplement events
		// PortalActor.TriggerEffectEvent(n"DarkPortal.Grabbed", TargetComponent);
	}

	void TriggerHierarchyRelease(ADarkPortalActor PortalActor,
		UDarkPortalTargetComponent TargetComponent)
	{
		if (PortalActor == nullptr || TargetComponent == nullptr)
			return;

		TArray<UDarkPortalResponseComponent> ResponseComponents;
		GetHierarchyResponseComponents(ResponseComponents, TargetComponent.Owner);

		for (auto ResponseComponent : ResponseComponents)
			ResponseComponent.Release(PortalActor, TargetComponent);

		// PortalActor.TriggerEffectEvent(n"DarkPortal.Released", TargetComponent);
	}

	void TriggerHierarchyAttach(ADarkPortalActor PortalActor,
		USceneComponent AttachComponent)
	{
		if (PortalActor == nullptr || AttachComponent == nullptr)
			return;

		TArray<UDarkPortalResponseComponent> ResponseComponents;
		GetHierarchyResponseComponents(ResponseComponents, AttachComponent.Owner);

		for (auto ResponseComponent : ResponseComponents)
			ResponseComponent.Attach(PortalActor, AttachComponent);

		// PortalActor.TriggerEffectEvent(n"DarkPortal.Attached");
	}

	void TriggerHierarchyDetach(ADarkPortalActor PortalActor,
		USceneComponent AttachComponent)
	{
		if (PortalActor == nullptr || AttachComponent == nullptr)
			return;

		TArray<UDarkPortalResponseComponent> ResponseComponents;
		GetHierarchyResponseComponents(ResponseComponents, AttachComponent.Owner);

		for (auto ResponseComponent : ResponseComponents)
			ResponseComponent.Detach(PortalActor, AttachComponent);

		// PortalActor.TriggerEffectEvent(n"DarkPortal.Detached");
	}

	void TriggerHierarchyPush(ADarkPortalActor PortalActor,
		USceneComponent PushedComponent,
		const FVector& WorldLocation,
		const FVector& Impulse)
	{
		if (PortalActor == nullptr || PushedComponent == nullptr)
			return;

		TArray<UDarkPortalResponseComponent> ResponseComponents;
		GetHierarchyResponseComponents(ResponseComponents, PushedComponent.Owner);

		for (auto ResponseComponent : ResponseComponents)
			ResponseComponent.Push(PortalActor, PushedComponent, WorldLocation, Impulse);
	}

	void GetHierarchyTargetComponents(
		TArray<UTargetableComponent>& TargetComponents,
		TSubclassOf<UTargetableComponent> Class,
		AActor EntryActor)
	{
		if (!Class.IsValid())
			return;
		
		auto Outermost = GetOutermostActor(EntryActor);
		if (Outermost == nullptr)
			return;

		TArray<AActor> Actors;
		Actors.Add(Outermost);
		Outermost.GetAttachedActors(Actors, false, true);

		for (auto Actor : Actors)
		{
			Actor.GetComponentsByClass(Class.Get(), TargetComponents);
		}
	}

	void GetHierarchyResponseComponents(
		TArray<UDarkPortalResponseComponent>& ResponseComponents,
		AActor EntryActor)
	{
		auto Outermost = GetOutermostActor(EntryActor);
		if (Outermost == nullptr)
			return;

		TArray<AActor> Actors;
		Actors.Add(Outermost);
		Outermost.GetAttachedActors(Actors, false, true);
		
		for (auto Actor : Actors)
		{
			auto ResponseComponent = UDarkPortalResponseComponent::Get(Actor);
			if (ResponseComponent != nullptr)
				ResponseComponents.Add(ResponseComponent);
		}
	}

	UDarkPortalResponseComponent GetFirstHierarchyResponseComponent(AActor EntryActor)
	{
		auto Outermost = GetOutermostActor(EntryActor);
		if (Outermost == nullptr)
			return nullptr;

		auto OuterResponseComponent = UDarkPortalResponseComponent::Get(Outermost);
		if (OuterResponseComponent != nullptr)
			return OuterResponseComponent;

		TArray<AActor> Actors;
		Outermost.GetAttachedActors(Actors, false, true);

		for (auto Actor : Actors)
		{
			auto ResponseComponent = UDarkPortalResponseComponent::Get(Actor);
			if (ResponseComponent != nullptr)
				return ResponseComponent;
		}

		return nullptr;
	}

	USceneComponent GetParentForceAnchor(USceneComponent Child)
	{
		if (Child == nullptr)
			return nullptr;

		auto Component = Child;
		while (Component.AttachParent != nullptr)
		{
			auto Anchor = Cast<UDarkPortalForceAnchorComponent>(Component);
			if (Anchor != nullptr)
				return Anchor;

			Component = Component.AttachParent;
		}

		return Child;
	}

	AActor GetOutermostActor(AActor EntryActor)
	{
		if (EntryActor == nullptr)
			return nullptr;

		auto Outermost = EntryActor;
		while (Outermost.AttachParentActor != nullptr)
			Outermost = Outermost.AttachParentActor;

		return Outermost;
	}
}