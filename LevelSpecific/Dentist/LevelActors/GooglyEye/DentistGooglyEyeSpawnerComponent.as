class UDentistGooglyEyeSpawnerComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ADentistGooglyEye> GooglyEyeClass;

	UPROPERTY(EditAnywhere, Category = "Dimensions")
	float BoundaryRadius = 25;

	UPROPERTY(EditAnywhere, Category = "Dimensions", Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float PupilPercentage = 0.5;

	ADentistGooglyEye GooglyEye;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GooglyEye = SpawnActor(GooglyEyeClass, WorldLocation, WorldRotation, NAME_None, false, Owner.Level);
		GooglyEye.AttachToComponent(this);
		
		GooglyEye.BoundaryRadius = BoundaryRadius;
		GooglyEye.PupilPercentage = PupilPercentage;
		GooglyEye.UpdateMeshScale();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		GooglyEye.RemoveActorDisable(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		GooglyEye.AddActorDisable(Owner);
	}

	float GetPupilRadius() const
	{
		return BoundaryRadius * PupilPercentage;
	}

	FVector GetCylinderScale(float Radius, float ZScale) const
	{
		const float EyeScale = Radius / 50;
		return FVector(EyeScale, EyeScale, ZScale);
	}
};

#if EDITOR
class UDentistGooglyEyeSpawnerVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UDentistGooglyEyeSpawnerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Spawner = Cast<UDentistGooglyEyeSpawnerComponent>(Component);
		if(Spawner == nullptr)
			return;

		if(!Spawner.GooglyEyeClass.IsValid())
			return;

		auto GooglyEye = Cast<ADentistGooglyEye>(Spawner.GooglyEyeClass.Get().DefaultObject);
		if(GooglyEye == nullptr)
			return;

		FTransform EyeTransform = Spawner.WorldTransform * GooglyEye.EyeMesh.WorldTransform;
		FTransform PupilTransform = Spawner.WorldTransform * GooglyEye.PupilMesh.WorldTransform;

		DrawWireCylinder(Spawner.WorldLocation, FRotator::MakeFromZ(EyeTransform.Rotation.ForwardVector), FLinearColor::White, Spawner.BoundaryRadius, 5, 32);
        DrawWireCylinder(Spawner.WorldLocation, FRotator::MakeFromZ(PupilTransform.Rotation.ForwardVector), FLinearColor::Black, Spawner.GetPupilRadius(), 5, 32);
	}
};
#endif