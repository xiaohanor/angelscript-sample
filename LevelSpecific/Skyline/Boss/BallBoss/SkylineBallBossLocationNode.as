enum ESkylineBallBossLocationNode
{
	Unassigned,
	Center,
	ThrowCarLeft1,
	ThrowCarLeft2,
	ThrowCarRight1,
	ThrowCarRight2,
	ThrowBus1,
	ThrowBus2,
	SmashCars,
	Motorcycles,
	Laser1,
	Laser2,
	Laser3,
	MotorcycleSun
}

class ASkylineBallBossLocationNode : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	USkylineBallBossLocationVisualizerComponent EditorVisualizer;

	UPROPERTY(EditInstanceOnly)
	ESkylineBallBossLocationNode Placement = ESkylineBallBossLocationNode::Unassigned;
}

class USkylineBallBossLocationVisualizerComponent : UActorComponent
{
}

#if EDITOR
class USkylineBallBossLocationActorVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineBallBossLocationVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		TListedActors<ASkylineBallBossLocationNode> Locations;
		for (int i = 0; i < Locations.Num(); ++i)
		{
			auto Location = Locations[i];
			for (int j = i +1; j < Locations.Num(); ++j)
			{
				auto OtherLocation = Locations[j];
				DrawDashedLine(Location.ActorLocation, OtherLocation.ActorLocation, ColorDebug::Magenta, 100.0, 5.0);
			}
		}

		float Radius = 900.0;
		DrawWireSphere(Component.Owner.ActorLocation,  Radius, ColorDebug::Lavender, 3.0, 12);
	}
}
#endif
