class UCentipedeSlidingLavaDummyComponent : UActorComponent
{
	//This component is here to fetch actor data for visualizer component
}

class UCentipedeSlidingLavaComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCentipedeSlidingLavaDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto Manager = Cast<ASanctuaryCentipedeSlidingLavaManager>(Component.Owner);

		DrawArrow(Manager.ActorLocation, Manager.ActorLocation + Manager.ActorUpVector * Manager.SlideLength, FLinearColor::Green, 100.0, 10.0);

		PrintToScreen("Selecting Manager");
	}
}

class ASanctuaryCentipedeSlidingLavaManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;
	
	UPROPERTY(DefaultComponent)
	UCentipedeSlidingLavaDummyComponent VisualizeComponent;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(Category = Settings, EditInstanceOnly)
	float SlideLength = 10000.0;

	private TArray<ASanctuaryCentipedeSlidingLava> LavaActorArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> Actors;
		GetAttachedActors(Actors, true);
		for (AActor Actor : Actors)
		{
			ASanctuaryCentipedeSlidingLava LavaActor = Cast<ASanctuaryCentipedeSlidingLava>(Actor);
			if (LavaActor != nullptr)
				LavaActorArray.Add(LavaActor);
		}

		for (auto LavaActor : LavaActorArray)
		{
			LavaActor.Manager = this;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		for (ASanctuaryCentipedeSlidingLava Lava : LavaActorArray)
			Lava.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		for (ASanctuaryCentipedeSlidingLava Lava : LavaActorArray)
			Lava.RemoveActorDisable(this);
	}
};