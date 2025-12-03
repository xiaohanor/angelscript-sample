event void FASummitActivationPlateListenerSignature();

class USummitActivationPlateComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Setup")
	FHazeShapeSettings PlateZoneShapeSetting;
}

class ASummitActivationPlateListener : AHazeActor
{

	UPROPERTY(DefaultComponent, ShowOnActor)
	USummitPathCrystalComponent PlatesControlZone;

	UPROPERTY()
	FASummitActivationPlateListenerSignature OnFinished;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitActivationPlate> Children;
	bool bBeingEdited = false;

	UPROPERTY()
	bool bFinished;
	int ChildCount;
	int ChildrenActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ChildCount = Children.Num();
		for (auto Child : Children)
		{
			Child.Parent = this;
			
		}
	}

	UFUNCTION()
	void CheckChildren()
	{
		
		for (auto Child : Children)
		{
			if(Child.bActivated)
			{
				bFinished = true;
				ChildrenActivated++;
			}
			if(Child.bActivated == false)
			{
				bFinished = false;
			}
		}
		for (auto Child : Children)
		{
			if(Child.bActivated == false)
			{
				bFinished = false;
			}
		}

		if(!bFinished)
			return;

		if(bFinished) 
		{
			for (auto Child : Children)
			{
				Child.bCompleted = true;
				Child.BP_OnFinished();
			}
			OnFinished.Broadcast();
		}
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	void AddPlatesInZone()
	{
		TArray<ASummitActivationPlate> PlateActorsInLevel = Editor::GetAllEditorWorldActorsOfClass(ASummitActivationPlate);

		for(auto PlateActor : PlateActorsInLevel)
		{
			if(PlatesControlZone.PathCrystalZoneShapeSetting.IsPointInside(PlatesControlZone.WorldTransform, PlateActor.ActorLocation))
			{
				auto Plate = Cast<ASummitActivationPlate>(PlateActor);
				Children.AddUnique(Plate);
			}
		}
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	void SetPlatesInZone()
	{
		TArray<ASummitActivationPlate> PlateActorsInLevel = Editor::GetAllEditorWorldActorsOfClass(ASummitActivationPlate);

		Children.Empty();
		for(auto PlateActor : PlateActorsInLevel)
		{
			if(PlatesControlZone.PathCrystalZoneShapeSetting.IsPointInside(PlatesControlZone.WorldTransform, PlateActor.ActorLocation))
			{
				auto Plate = Cast<ASummitActivationPlate>(PlateActor);
				Children.AddUnique(Plate);
			}
		}
	}
}