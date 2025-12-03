

UCLASS()
class APropLineProgression  : AHazeActor 
{
    UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    UBillboardComponent Billboard;
	
	UPROPERTY(EditAnywhere)
	APropLine Target;

	UPROPERTY(EditAnywhere)
	AActor ProgressionActor;

	UPROPERTY(EditAnywhere)
	float Progression;

	UPROPERTY(EditAnywhere)
	float Strength;

	UPROPERTY(EditAnywhere)
	bool bInverted = false;

	UPROPERTY()
	float LastProgression;

	private TArray<UStaticMeshComponent> StaticMeshes;

	UFUNCTION()
	void HandlePropLineUpdated(UObject InObject)
	{
		InitializeStaticMeshes();
	}
	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(ProgressionActor != nullptr)
		{
			auto PropSpline = Spline::GetGameplaySpline(Target);
			if(PropSpline != nullptr)
			{
				FSplinePosition SplinePos = PropSpline.GetClosestSplinePositionToWorldLocation(ProgressionActor.GetActorLocation());
				Progression = SplinePos.CurrentSpline.GetClosestSplineDistanceToWorldLocation(ProgressionActor.GetActorLocation()) / SplinePos.CurrentSpline.GetSplineLength();
			}
		}

		Progression = Math::Saturate(Progression);
		Strength = Math::Saturate(Strength);
		StaticMeshes.Empty();
		
		if(Target == nullptr)
			return;

		if(Target.MergedMeshes.Num() > 0)
		{
			devError(f"PropLine progression does not support Merged PropLine Meshes, yet. Please Unmerge {Target.ActorNameOrLabel}");
			return;
		}

		Target.OnPropLineUpdated.UnbindObject(this);
		Target.OnPropLineUpdated.AddUFunction(this, n"HandlePropLineUpdated");
		InitializeStaticMeshes();
	}


	void InitializeStaticMeshes()
	{
		TArray<UStaticMeshComponent> StaticMeshesTemp;
		Target.GetComponentsByClass(StaticMeshesTemp);

		// Sort meshes by their primitive ID
		StaticMeshes.SetNum(StaticMeshesTemp.Num());
		for (int j = 0; j < StaticMeshes.Num(); j++)
		{
			if(StaticMeshesTemp[j] == nullptr)
				continue;

			if(StaticMeshesTemp[j].GetNumDefaultCustomPrimitiveDataFloats() <= 2)
				continue;

			const int Index = int(StaticMeshesTemp[j].GetDefaultCustomPrimitiveDataFloat(2));
			if (StaticMeshes.IsValidIndex(Index))
				StaticMeshes[Index] = StaticMeshesTemp[j];
		}

		// Set progression value for preview purposes
		for (int j = 0; j < StaticMeshes.Num(); j++)
		{
			if(StaticMeshes[j] == nullptr)
				continue;

			StaticMeshes[j].SetScalarParameterValueOnMaterials(n"PropLineProgressionValueStart", (float(j)) / float(StaticMeshes.Num()));
			StaticMeshes[j].SetScalarParameterValueOnMaterials(n"PropLineProgressionValueEnd", float(j+1.0) / float(StaticMeshes.Num()));
			StaticMeshes[j].SetScalarParameterValueOnMaterials(n"PropLineProgressionValueNormalized", Progression);
			StaticMeshes[j].SetScalarParameterValueOnMaterials(n"PropLineProgressionStrength", Strength);
			
			float UnNormalizedProgression = Progression * StaticMeshes.Num();
			StaticMeshes[j].SetScalarParameterValueOnMaterials(n"PropLineProgressionValue", UnNormalizedProgression - j);
			StaticMeshes[j].SetScalarParameterValueOnMaterials(n"PropLineProgressionSign", bInverted ? -1 : 1);
		}
	}


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitializeStaticMeshes();
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Target == nullptr)
			return;

		if(ProgressionActor != nullptr)
		{
			auto PropSpline = Spline::GetGameplaySpline(Target);
			if(PropSpline != nullptr)
			{
				FSplinePosition SplinePos = PropSpline.GetClosestSplinePositionToWorldLocation(ProgressionActor.GetActorLocation());
				Progression = SplinePos.CurrentSpline.GetClosestSplineDistanceToWorldLocation(ProgressionActor.GetActorLocation()) / SplinePos.CurrentSpline.GetSplineLength();
			}
		}

		if(LastProgression != Progression)
		{
			LastProgression = Progression;

			// TODO, Perf, update only the meshes that actually need to change.
			for (int j = 0; j < StaticMeshes.Num(); j++)
			{
				if(StaticMeshes[j] == nullptr)
					continue;

				StaticMeshes[j].SetScalarParameterValueOnMaterials(n"PropLineProgressionValueStart", (float(j)) / float(StaticMeshes.Num()));
				StaticMeshes[j].SetScalarParameterValueOnMaterials(n"PropLineProgressionValueEnd", float(j+1.0) / float(StaticMeshes.Num()));
				StaticMeshes[j].SetScalarParameterValueOnMaterials(n"PropLineProgressionValueNormalized", Progression);
				StaticMeshes[j].SetScalarParameterValueOnMaterials(n"PropLineProgressionStrength", Strength);
			
				float UnNormalziedProgression = Progression * StaticMeshes.Num();
				StaticMeshes[j].SetScalarParameterValueOnMaterials(n"PropLineProgressionValue", UnNormalziedProgression - j);
				StaticMeshes[j].SetScalarParameterValueOnMaterials(n"PropLineProgressionValueNormalized", Progression);
			}
		}
	}
}
