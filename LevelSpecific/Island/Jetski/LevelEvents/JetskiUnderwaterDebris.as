class AJetskiUnderwaterDebris : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 50.0;

	UPROPERTY(EditAnywhere)
	FRotator RotationDirection;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.SetRelativeRotation(RotationDirection * (RotationSpeed * Time::PredictedGlobalCrumbTrailTime));
	}

	FRotator GetRandomRotator(float Min, float Max)
	{
		FRotator Range;
		Range.Roll = Math::RandRange(Min, Max); 
		Range.Pitch = Math::RandRange(Min, Max); 
		Range.Yaw = Math::RandRange(Min, Max); 
		return Range;
	}

#if EDITOR
	UFUNCTION(CallInEditor)
	void RandomizeRotation()
	{
		RotationDirection = GetRandomRotator(-1.0, 1.0).Normalized;
	}
#endif
};