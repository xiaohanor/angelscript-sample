struct FPerformanceDevMenuMovingOverlapsEntry
{
	TWeakObjectPtr<UClass> ActorClass;

	TArray<FName> ActorNames;
	int ActorCount = 0;

	TArray<FName> ComponentNames;
	int ComponentCount = 0;

	int TotalOverlapCount = 0;

	FPerformanceDevMenuMovingOverlapsEntry(UPrimitiveComponent Primitive)
	{
		ActorClass = Primitive.Owner.Class;

		ActorNames.Add(Primitive.Owner.Name);
		ActorCount = 1;

		ComponentNames.Add(Primitive.Name);
		ComponentCount = 1;

		TotalOverlapCount = 1;
	}

	void AddMovableOverlap(UPrimitiveComponent Primitive)
	{
		ComponentNames.AddUnique(Primitive.Name);
		if(ActorNames.AddUnique(Primitive.Owner.Name))
			ActorCount++;
		
		ComponentNames.AddUnique(Primitive.Name);
		ComponentCount = ComponentNames.Num();

		TotalOverlapCount = ActorCount * ComponentCount;
	}

	int opCmp(FPerformanceDevMenuMovingOverlapsEntry Other) const
	{
		if (TotalOverlapCount > Other.TotalOverlapCount)
			return -1;
		else if (TotalOverlapCount < Other.TotalOverlapCount)
			return 1;
		else
			return 0;
	}
}

class UPerformanceDevMenuMovingOverlapsPage : UPerformanceDevMenuPage
{
	TArray<FPerformanceDevMenuMovingOverlapsEntry> Entries;

	void UpdateButtonBar(FHazeImmediateHorizontalBoxHandle ButtonBar) override
	{
	}

	void UpdateState() override
	{
		Entries.Reset();

		TMap<UClass, int> EntryIndices;
		TArray<UPrimitiveComponent> Primitives = Debug::GetComponentsWithMovableOverlaps();
		for(UPrimitiveComponent Primitive : Primitives)
		{
			int EntryIndex = 0;
			if(EntryIndices.Find(Primitive.Owner.Class, EntryIndex))
			{
				Entries[EntryIndex].AddMovableOverlap(Primitive);
			}
			else
			{
				EntryIndex = Entries.Num();
				EntryIndices.Add(Primitive.Owner.Class, EntryIndex);
				Entries.Add(FPerformanceDevMenuMovingOverlapsEntry(Primitive));
			}
		}

		Entries.Sort();
	}

	void UpdateList(FHazeImmediateVerticalBoxHandle RootBox) override
	{
		auto List = RootBox.SlotFill().ListView(Entries.Num());
		for (int ItemIndex : List)
		{
			auto Item = List.Item();
			auto Row = Item.HorizontalBox();
			const FPerformanceDevMenuMovingOverlapsEntry& Entry = Entries[ItemIndex];

			if (Entry.ActorClass.IsValid())
			{
				auto Buttons = Row.BorderBox().MinDesiredWidth(110).SlotPadding(0).HorizontalBox();
				if (Entry.ActorClass.Get().IsA(UBlueprintGeneratedClass))
				{
					if (Buttons.SlotVAlign(EVerticalAlignment::VAlign_Top).Button("🍝").Tooltip("Go to blueprint for class"))
						Editor::OpenEditorForClass(Entry.ActorClass);

					UClass CodeClass = Entry.ActorClass;
					while (CodeClass != nullptr && CodeClass.IsA(UBlueprintGeneratedClass))
						CodeClass = CodeClass.SuperClass;

					if (Buttons.SlotVAlign(EVerticalAlignment::VAlign_Top).Button("📜").Tooltip("Go to code for class"))
						Editor::OpenEditorForClass(CodeClass);
				}
				else
				{
					if (Buttons.SlotVAlign(EVerticalAlignment::VAlign_Top).Button("📜").Tooltip("Go to code for class"))
						Editor::OpenEditorForClass(Entry.ActorClass);
				}
			}

			Row.SlotPadding(4, 8).SlotFill(0.5).Text(f"{Entry.ActorClass.Get().Name}").Bold();

			Row.SlotPadding(4, 8).SlotFill(1.0).Text(f"{Entry.ActorCount} Actors");
			Row.SlotPadding(4, 8).SlotFill(1.0).Text(f"{Entry.ComponentCount} Overlaps per Actor");
			Row.SlotPadding(4, 8).SlotFill(1.0).Text(f"{Entry.TotalOverlapCount} Total Overlaps");

			FString SubTickText;
			for (int i = 0, Count = Entry.ComponentNames.Num(); i < Count; ++i)
			{
				if (i != 0)
					SubTickText += ", ";
				SubTickText += f"{Entry.ComponentNames[i]}";
			}

			Row.SlotPadding(4, 8).SlotFill(1.0).Text(SubTickText).AutoWrapText();
		}
	}
}