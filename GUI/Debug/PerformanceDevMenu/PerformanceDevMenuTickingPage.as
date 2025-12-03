enum EPerformanceDevMenuTickingMode
{
	Actors,
	Components,
};

enum EPerformanceDevMenuTickingSort
{
	TickCount,
	ObjectCount,
};

struct FPerformanceDevMenuTickingEntry
{
	TWeakObjectPtr<UClass> Class;
	FName Name;
	TMap<FName, int> SubTicks;
	int TotalTickCount = 0;
	int ObjectCount = 0;
	float DisableRange = -1.0;
	int LinkedObjectCount = 0;

	EPerformanceDevMenuTickingSort Sort = EPerformanceDevMenuTickingSort::TickCount;

	int opCmp(FPerformanceDevMenuTickingEntry Other) const
	{
		switch(Sort)
		{
			case EPerformanceDevMenuTickingSort::TickCount:
			{
				if (TotalTickCount > Other.TotalTickCount)
					return -1;
				else if (TotalTickCount < Other.TotalTickCount)
					return 1;
				else if (ObjectCount > Other.ObjectCount)
					return -1;
				else if (ObjectCount < Other.ObjectCount)
					return 1;
				else
					return 0;
			}

			case EPerformanceDevMenuTickingSort::ObjectCount:
			{
				if (ObjectCount > Other.ObjectCount)
					return -1;
				else if (ObjectCount < Other.ObjectCount)
					return 1;
				else if (TotalTickCount > Other.TotalTickCount)
					return -1;
				else if (TotalTickCount < Other.TotalTickCount)
					return 1;
				else
					return 0;
			}
		}
	}
};

class UPerformanceDevMenuTickingPage : UPerformanceDevMenuPage
{
	TArray<FPerformanceDevMenuTickingEntry> Entries;

	EPerformanceDevMenuTickingMode Mode = EPerformanceDevMenuTickingMode::Actors;
	EPerformanceDevMenuTickingSort Sort = EPerformanceDevMenuTickingSort::ObjectCount;

	void UpdateButtonBar(FHazeImmediateHorizontalBoxHandle ButtonBar) override
	{
		ButtonBar.Spacer(50, 30);

		ButtonBar.SlotVAlign(EVerticalAlignment::VAlign_Center).Text("Display: ").Scale(1.0);
		ButtonBar.SlotVAlign(EVerticalAlignment::VAlign_Fill)
			.BorderBox()
				.MinDesiredWidth(250)
				.MinDesiredHeight(40)
			.ComboBox()
				.ChooseEnum(Mode);
		
		ButtonBar.Spacer(50, 30);
		
		ButtonBar.SlotVAlign(EVerticalAlignment::VAlign_Center).Text("Sort: ").Scale(1.0);
		ButtonBar.SlotVAlign(EVerticalAlignment::VAlign_Fill)
			.BorderBox()
				.MinDesiredWidth(250)
				.MinDesiredHeight(40)
			.ComboBox()
				.ChooseEnum(Sort);
	}

	void UpdateState() override
	{
		switch(Mode)
		{
			case EPerformanceDevMenuTickingMode::Actors:
				UpdateActorEntries();
				break;

			case EPerformanceDevMenuTickingMode::Components:
				UpdateComponentEntries();
				break;
		}
	}

	void UpdateList(FHazeImmediateVerticalBoxHandle RootBox) override
	{
		auto List = RootBox.SlotFill().ListView(Entries.Num());
		for (int ItemIndex : List)
		{
			auto Item = List.Item();
			auto Row = Item.HorizontalBox();
			const FPerformanceDevMenuTickingEntry& Entry = Entries[ItemIndex];

			if (Entry.Class.IsValid())
			{
				auto Buttons = Row.BorderBox().MinDesiredWidth(110).SlotPadding(0).HorizontalBox();
				if (Entry.Class.Get().IsA(UBlueprintGeneratedClass))
				{
					if (Buttons.SlotVAlign(EVerticalAlignment::VAlign_Top).Button("🍝").Tooltip("Go to blueprint for class"))
						Editor::OpenEditorForClass(Entry.Class);

					UClass CodeClass = Entry.Class;
					while (CodeClass != nullptr && CodeClass.IsA(UBlueprintGeneratedClass))
						CodeClass = CodeClass.SuperClass;

					if (Buttons.SlotVAlign(EVerticalAlignment::VAlign_Top).Button("📜").Tooltip("Go to code for class"))
						Editor::OpenEditorForClass(CodeClass);
				}
				else
				{
					if (Buttons.SlotVAlign(EVerticalAlignment::VAlign_Top).Button("📜").Tooltip("Go to code for class"))
						Editor::OpenEditorForClass(Entry.Class);
				}
			}

			Row.SlotPadding(4, 8).SlotFill(0.5).Text(f"{Entry.Name}").Bold();

			if (Entry.DisableRange != -1)
			{
				if (Entry.DisableRange > 0)
					Row.SlotPadding(4, 8).SlotFill(0.5).Text(f"Auto Disable: {Entry.DisableRange}").Color(FLinearColor::Green);
				else if(Entry.LinkedObjectCount > 0)
					Row.SlotPadding(4, 8).SlotFill(0.5).Text(f"Auto Disable: Linked by {Entry.LinkedObjectCount}").Color(FLinearColor::Yellow);
				else
					Row.SlotPadding(4, 8).SlotFill(0.5).Text(f"Auto Disable: No").Color(FLinearColor::Red);
			}

			if (Entry.ObjectCount == 0)
				Row.SlotPadding(4, 8).SlotFill(1.0).Text(f"{Entry.TotalTickCount} Ticks");
			else
				Row.SlotPadding(4, 8).SlotFill(1.0).Text(f"{Entry.ObjectCount} Objects, {Entry.TotalTickCount} Ticks");

			FString SubTickText;
			bool bFirst = true;
			for (auto SubTick : Entry.SubTicks)
			{
				if (!bFirst)
					SubTickText += ", ";

				SubTickText += f"{SubTick.Key} ({SubTick.Value})";
				bFirst = false;
			}

			Row.SlotPadding(4, 8).SlotFill(1.0).Text(SubTickText).AutoWrapText();
		}
	}

	private void UpdateComponentEntries()
	{
		Entries.Reset();

		TMap<UClass, int> EntryIndices;
		TArray<UActorComponent> TickingComponents = Debug::GetComponentsWithActiveTicks();
		for (UActorComponent Component : TickingComponents)
		{
			if (Component.Class == UDisableComponent)
				continue;
			
			if (Component.Class == UHazeComposableSettingsComponent)
				continue;

			int EntryIndex = 0;
			if (EntryIndices.Find(Component.Class, EntryIndex))
			{
				Entries[EntryIndex].TotalTickCount += 1;
			}
			else
			{
				FPerformanceDevMenuTickingEntry Entry;
				Entry.Name = Component.Class.Name;
				Entry.TotalTickCount = 1;
				Entry.Sort = Sort;
				Entry.Class = Component.Class;

				EntryIndices.Add(Component.Class, Entries.Num());
				EntryIndex = Entries.Num();
				Entries.Add(Entry);
			}

			FPerformanceDevMenuTickingEntry& Entry = Entries[EntryIndex];
			FName ActorName = Component.Owner.Class.Name;
			int& SubTickCount = Entry.SubTicks.FindOrAdd(ActorName);
			SubTickCount += 1;
		}

		Entries.Sort();
	}

	private void UpdateActorEntries()
	{
		Entries.Reset();

		TArray<AActor> TickingActors = Debug::GetActorsWithActiveTicks();
		TMap<UClass, int> EntryIndices;
		TSet<AActor> CountedActors;
		for (AActor Actor : TickingActors)
		{
			int EntryIndex = 0;
			if (EntryIndices.Find(Actor.Class, EntryIndex))
			{
				Entries[EntryIndex].TotalTickCount += 1;
				Entries[EntryIndex].ObjectCount += 1;
				Entries[EntryIndex].SubTicks[n"Actor Tick"] += 1;
			}
			else
			{
				FPerformanceDevMenuTickingEntry Entry;
				Entry.Name = Actor.Class.Name;
				Entry.SubTicks.Add(n"Actor Tick", 1);
				Entry.TotalTickCount += 1;
				Entry.ObjectCount += 1;
				Entry.Sort = Sort;
				Entry.Class = Actor.Class;

				auto DisableComp = UDisableComponent::Get(Actor);
				if (DisableComp != nullptr && DisableComp.bAutoDisable)
					Entry.DisableRange = DisableComp.AutoDisableRange;
				else
					Entry.DisableRange = 0.0;

				EntryIndices.Add(Actor.Class, Entries.Num());
				Entries.Add(Entry);
			}

			CountedActors.Add(Actor);
		}

		TArray<UActorComponent> TickingComponents = Debug::GetComponentsWithActiveTicks();
		TArray<UDisableComponent> DisableComponents;
		for (UActorComponent Component : TickingComponents)
		{
			if (Component.Class == UDisableComponent)
			{
				auto DisableComp = Cast<UDisableComponent>(Component);
				DisableComponents.Add(DisableComp);
				continue;
			}

			if (Component.Class == UHazeComposableSettingsComponent)
				continue;

			int EntryIndex = 0;
			if (EntryIndices.Find(Component.Owner.Class, EntryIndex))
			{
				Entries[EntryIndex].TotalTickCount += 1;
			}
			else
			{
				FPerformanceDevMenuTickingEntry Entry;
				Entry.Name = Component.Owner.Class.Name;
				Entry.TotalTickCount += 1;
				Entry.Sort = Sort;
				Entry.Class = Component.Owner.Class;

				auto DisableComp = UDisableComponent::Get(Component.Owner);
				if (DisableComp != nullptr && DisableComp.bAutoDisable)
					Entry.DisableRange = DisableComp.AutoDisableRange;
				else
					Entry.DisableRange = 0.0;

				EntryIndices.Add(Component.Owner.Class, Entries.Num());
				EntryIndex = Entries.Num();
				Entries.Add(Entry);
			}

			FPerformanceDevMenuTickingEntry& Entry = Entries[EntryIndex];
			FName ComponentName = Component.Class.Name;

			int& SubTickCount = Entry.SubTicks.FindOrAdd(ComponentName);
			SubTickCount++;

			auto CapabilityComp = Cast<UHazeCapabilityComponent>(Component);
			if (CapabilityComp != nullptr)
			{
				int CapabilityTicks = Debug::GetNumTickingCapabilitiesOnCapabilityComponent(CapabilityComp);
				Entry.SubTicks.FindOrAdd(n"Capability Ticks") += CapabilityTicks;
				Entry.TotalTickCount += CapabilityTicks;
			}

			if (!CountedActors.Contains(Component.Owner))
			{
				Entry.ObjectCount += 1;
				CountedActors.Add(Component.Owner);
			}
		}

		// Iterate through all ticking DisableComponents to find what actors they are linked to
		for(auto DisableComp : DisableComponents)
		{
			if(!DisableComp.bAutoDisable)
				continue;

			for(TSoftObjectPtr<AHazeActor> LinkedSoftActor : DisableComp.AutoDisableLinkedActors)
			{
				AHazeActor LinkedActor = LinkedSoftActor.Get();
				if(LinkedActor == nullptr)
					continue;

				int EntryIndex = 0;
				if (EntryIndices.Find(LinkedActor.Class, EntryIndex))
					Entries[EntryIndex].LinkedObjectCount++;
			}
		}

		Entries.Sort();
	}
};