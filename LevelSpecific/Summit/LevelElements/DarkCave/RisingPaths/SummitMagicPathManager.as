class USummitMagicPathManagerVisualiser : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitMagicPathManagerVisualiserDud;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        auto Manager = Cast<ASummitMagicPathManager>(Component.Owner);

        if (Manager == nullptr)
            return;		

		for (ASummitMagicPath Path : Manager.MagicPaths)
		{
			DrawLine(Manager.ActorLocation, Path.ActorLocation, FLinearColor::Green, 10.0);
		}
    }
}

class USummitMagicPathManagerVisualiserDud : UActorComponent
{

}

class ASummitMagicPathManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(5));
#endif

	UPROPERTY(DefaultComponent)
	USummitMagicPathManagerVisualiserDud Visualiser;

	UPROPERTY(EditAnywhere)
	float DelayBetweenPaths = 0.4;

	UPROPERTY(EditAnywhere)
	TArray<ASummitMagicPath> MagicPaths;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(CallInEditor)
	void FindTargets()
	{
		MagicPaths.Empty();
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Attached : AttachedActors)
		{
			ASummitMagicPath Path = Cast<ASummitMagicPath>(Attached);
			if (Path == nullptr)
				continue;
			MagicPaths.AddUnique(Path);
		}		
	}

	UFUNCTION()
	void ActivateMagicPaths()
	{
		float DelayTime = 0.0;
		for (ASummitMagicPath Path : MagicPaths)
		{
			Path.ActivatePlatform(DelayTime);
			DelayTime += DelayBetweenPaths;
		}		
	}
};