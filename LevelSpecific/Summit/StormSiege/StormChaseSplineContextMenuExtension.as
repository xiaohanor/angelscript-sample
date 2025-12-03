#if EDITOR
class UStormChaseSplineContextMenuExtension : UHazeSplineContextMenuExtension
{
	FName SpikeGroupContextName = n"AddSpikeGroup";
	FName SerpentEventActivatorContextName = n"AddSerpentEventActivator";
	FName FallingObstacleAreaContextName = n"AddFallingObstacleArea";
	FName MetalSpearManagerContextName = n"AddMetalSpearManager";

	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if (!Spline.World.Name.PlainNameString.Contains("Summit", ESearchCase::IgnoreCase, ESearchDir::FromStart))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "Summit - StormChase";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;

		{
			FHazeContextOption AddSpikeGroup;
			AddSpikeGroup.DelegateParam = SpikeGroupContextName;
			AddSpikeGroup.Label = "Add Serpent Spike Group";
			AddSpikeGroup.Icon = n"Icons.Plus";
			AddSpikeGroup.Tooltip = "Add a spike group to this spline, which can place spikes on walls.";
			Menu.AddOption(AddSpikeGroup, MenuDelegate);

			FHazeContextOption AddSerpentEventActivator;
			AddSerpentEventActivator.DelegateParam = SerpentEventActivatorContextName;
			AddSerpentEventActivator.Label = "Add Serpent EventActivator";
			AddSerpentEventActivator.Icon = n"Icons.Plus";
			AddSerpentEventActivator.Tooltip = "Add a serpent eventactivator to the spline";
			Menu.AddOption(AddSerpentEventActivator, MenuDelegate);

			FHazeContextOption AddFallingObstacleArea;
			AddFallingObstacleArea.DelegateParam = FallingObstacleAreaContextName;
			AddFallingObstacleArea.Label = "Add FallingObstacle Area";
			AddFallingObstacleArea.Icon = n"Icons.Plus";
			AddFallingObstacleArea.Tooltip = "Add a FallingObstacle area to the spline point";
			Menu.AddOption(AddFallingObstacleArea, MenuDelegate);

			FHazeContextOption AddMetalSpearManager;
			AddMetalSpearManager.DelegateParam = MetalSpearManagerContextName;
			AddMetalSpearManager.Label = "Add MetalSpear Manager";
			AddMetalSpearManager.Icon = n"Icons.Plus";
			AddMetalSpearManager.Tooltip = "Add a MetalSpearManager Actor to the spline point";
			Menu.AddOption(AddMetalSpearManager, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
									UHazeSplineSelection Selection, float MenuClickedDistance,
									int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == SpikeGroupContextName)
		{
			FScopedTransaction Transaction("Spawn Spikegroup Actor on Spline");
			FString ObjectPath = "/Game/LevelSpecific/Summit/StormBoss/Chase/SpikeRollAttack/BP_SerpentSpikeGroup.BP_SerpentSpikeGroup_C";
			UClass SpikeGroupGenClass = Cast<UClass>(LoadObject(nullptr, ObjectPath));

			FAngelscriptGameThreadScopeWorldContext WorldScope(Spline.Owner);

			auto AddedGroup = SpawnActor(SpikeGroupGenClass);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedGroup.SetActorTransform(Transform);
			Editor::SelectActor(AddedGroup);
		}
		else if (OptionName == SerpentEventActivatorContextName)
		{
			//Make transaction so can undo/redo
			FScopedTransaction Transaction("Spawn SerpentEventActivator Actor on Spline");
			FAngelscriptGameThreadScopeWorldContext WorldScope(Spline.Owner);
			auto AddedActivator = SpawnActor(ASerpentEventActivator);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedActivator.SetActorTransform(Transform);
			Editor::SelectActor(AddedActivator);
		}
		else if (OptionName == FallingObstacleAreaContextName)
		{	
			FScopedTransaction Transaction("Spawn FallingObstacleArea Actor on Spline");
			FString ObjectPath = "/Game/LevelSpecific/Summit/StormBoss/Chase/LevelObstacles/FallingObstacles/BP_StormChaseFallingObstacleArea.BP_StormChaseFallingObstacleArea_C";
			UClass FallingObstacleAreaGenClass = Cast<UClass>(LoadObject(nullptr, ObjectPath));
			FAngelscriptGameThreadScopeWorldContext WorldScope(Spline.Owner);

			auto AddedFallingArea = SpawnActor(FallingObstacleAreaGenClass);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedFallingArea.SetActorTransform(Transform);
			Editor::SelectActor(AddedFallingArea);
		}
		else if (OptionName == MetalSpearManagerContextName)
		{
			FScopedTransaction Transaction("Spawn MetalSpearManager Actor on Spline");
			FString ObjectPath = "/Game/LevelSpecific/Summit/StormBoss/Chase/LevelObstacles/MetalSpear/BP_StormChaseMetalSpearManager.BP_StormChaseMetalSpearManager_C";
			UClass MetalSpearManagerGenClass = Cast<UClass>(LoadObject(nullptr, ObjectPath));
			FAngelscriptGameThreadScopeWorldContext WorldScope(Spline.Owner);

			auto AddedMetalSpearManager = SpawnActor(MetalSpearManagerGenClass);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedMetalSpearManager.SetActorTransform(Transform);
			Editor::SelectActor(AddedMetalSpearManager);
		}
	}
};
#endif