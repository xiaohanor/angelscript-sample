class USummitRisingPathManagerVisualiser : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitRisingPathManagerVisualiserDud;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        auto Manager = Cast<ASummitRisingPathManager>(Component.Owner);

        if (Manager == nullptr)
            return;		

		for (ASummitRisingPath Path : Manager.RisingPaths)
		{
			DrawLine(Manager.ActorLocation, Path.ActorLocation, FLinearColor::Green, 10.0);
		}
    }
}

class USummitRisingPathManagerVisualiserDud : UActorComponent
{

}

class ASummitRisingPathManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(5));
#endif

	UPROPERTY(DefaultComponent)
	USummitRisingPathManagerVisualiserDud Visualiser;

	UPROPERTY(EditAnywhere)
	float DelayBetweenPaths = 0.3;

	UPROPERTY(EditAnywhere)
	TArray<ASummitRisingPath> RisingPaths;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(CallInEditor)
	void FindTargets()
	{
		RisingPaths.Empty();
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Attached : AttachedActors)
		{
			ASummitRisingPath Path = Cast<ASummitRisingPath>(Attached);
			if (Path == nullptr)
				continue;
			RisingPaths.AddUnique(Path);
		}		

		Print(f"{RisingPaths.Num()=}");
	}

	UFUNCTION()
	void ActivateRisingPaths()
	{
		float DelayTime = 0.0;
		for (ASummitRisingPath Path : RisingPaths)
		{
			Path.StartRise(DelayTime);
			DelayTime += DelayBetweenPaths;
		}		
	}
};