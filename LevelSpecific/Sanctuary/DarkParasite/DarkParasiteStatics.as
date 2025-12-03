namespace DarkParasite
{
	void TriggerHierarchyAttach(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData TargetData)
	{
		if (Instigator == nullptr || !TargetData.IsValid())
			return;

		TArray<UDarkParasiteResponseComponent> ResponseComponents;
		GetHierarchyResponseComponents(ResponseComponents, TargetData.Actor);

		for (auto ResponseComponent : ResponseComponents)
			ResponseComponent.Attach(Instigator, TargetData);

		UDarkParasiteEventHandler::Trigger_Attached(Instigator, TargetData);
	}

	void TriggerHierarchyDetach(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData TargetData)
	{
		if (Instigator == nullptr || !TargetData.IsValid())
			return;

		TArray<UDarkParasiteResponseComponent> ResponseComponents;
		GetHierarchyResponseComponents(ResponseComponents, TargetData.Actor);

		for (auto ResponseComponent : ResponseComponents)
			ResponseComponent.Detach(Instigator, TargetData);

		UDarkParasiteEventHandler::Trigger_Detached(Instigator, TargetData);
	}

	void TriggerHierarchyFocus(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData TargetData)
	{
		if (Instigator == nullptr || !TargetData.IsValid())
			return;

		TArray<UDarkParasiteResponseComponent> ResponseComponents;
		GetHierarchyResponseComponents(ResponseComponents, TargetData.Actor);

		for (auto ResponseComponent : ResponseComponents)
			ResponseComponent.Focus(Instigator, TargetData);

		UDarkParasiteEventHandler::Trigger_Focused(Instigator, TargetData);
	}

	void TriggerHierarchyUnfocus(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData TargetData)
	{
		if (Instigator == nullptr || !TargetData.IsValid())
			return;

		TArray<UDarkParasiteResponseComponent> ResponseComponents;
		GetHierarchyResponseComponents(ResponseComponents, TargetData.Actor);

		for (auto ResponseComponent : ResponseComponents)
			ResponseComponent.Unfocus(Instigator, TargetData);

		UDarkParasiteEventHandler::Trigger_Unfocused(Instigator, TargetData);
	}

	void TriggerHierarchyGrab(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData AttachedData,
		FDarkParasiteTargetData TargetData)
	{
		// NOTE: We call this response on both source and target response components
		TArray<UDarkParasiteResponseComponent> ResponseComponents;
		GetHierarchyResponseComponents(ResponseComponents, AttachedData.Actor);
		GetHierarchyResponseComponents(ResponseComponents, TargetData.Actor);

		for (auto ResponseComponent : ResponseComponents)
			ResponseComponent.Grab(Instigator, AttachedData, TargetData);

		UDarkParasiteEventHandler::Trigger_Grabbed(Instigator, FDarkParasiteGrabData(AttachedData, TargetData));
	}

	void TriggerHierarchyRelease(AHazePlayerCharacter Instigator,
		FDarkParasiteTargetData AttachedData,
		FDarkParasiteTargetData TargetData)
	{
		// NOTE: We call this response on both source and target response components
		TArray<UDarkParasiteResponseComponent> ResponseComponents;
		GetHierarchyResponseComponents(ResponseComponents, AttachedData.Actor);
		GetHierarchyResponseComponents(ResponseComponents, TargetData.Actor);

		for (auto ResponseComponent : ResponseComponents)
			ResponseComponent.Release(Instigator, AttachedData, TargetData);

		UDarkParasiteEventHandler::Trigger_Released(Instigator, FDarkParasiteGrabData(AttachedData, TargetData));
	}

	void GetHierarchyTargetComponents(
		TArray<UTargetableComponent>& TargetComponents,
		TSubclassOf<UTargetableComponent> Class,
		AActor EntryActor)
	{
		if (Class == nullptr || EntryActor == nullptr)
			return;

		AActor Outermost = EntryActor;
		while (Outermost.AttachParentActor != nullptr)
			Outermost = Outermost.AttachParentActor;

		TArray<AActor> Unvisited;
		Unvisited.Add(Outermost);

		while (Unvisited.Num() != 0)
		{
			Unvisited[0].GetAttachedActors(Unvisited, false);
			Unvisited[0].GetComponentsByClass(Class.Get(), TargetComponents);
			Unvisited.RemoveAt(0);
		}
	}

	void GetHierarchyResponseComponents(
		TArray<UDarkParasiteResponseComponent>& ResponseComponents,
		AActor EntryActor)
	{
		if (EntryActor == nullptr)
			return;

		AActor Outermost = EntryActor;
		while (Outermost.AttachParentActor != nullptr)
			Outermost = Outermost.AttachParentActor;

		TArray<AActor> Unvisited;
		Unvisited.Add(Outermost);

		while (Unvisited.Num() != 0)
		{
			Unvisited[0].GetAttachedActors(Unvisited, false);

			auto ResponseComponent = UDarkParasiteResponseComponent::Get(Unvisited[0]);
			if (ResponseComponent != nullptr)
				ResponseComponents.Add(ResponseComponent);

			Unvisited.RemoveAt(0);
		}
	}
}