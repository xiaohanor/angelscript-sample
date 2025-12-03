class ASummitWaterPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UBabyDragonTailClimbTargetable ClimbTargetable;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditInstanceOnly)
	ASummitWaterPlatformManager WaterPlatformManager;

	bool bOnSpline = false;
	float InvisibleDistance = 0.0;
	FSplinePosition Position;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WaterPlatformManager.AddWaterPlatform(this);
	}

	void UpdatePositionOnSpline()
	{
		FTransform SplineTransform = Position.WorldTransform;
		SetActorLocationAndRotation(
			SplineTransform.Location,
			FRotator::MakeFromXZ(
				SplineTransform.Rotation.UpVector,
				FVector::UpVector
			)
		);
	}
};