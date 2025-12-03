UCLASS(Abstract)
class AIceLakeMast : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent MastMesh;

    UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent RotatingComp;

    UPROPERTY(DefaultComponent, Attach = "RotatingComp")
	UStaticMeshComponent RotatingMesh;

	UPROPERTY(DefaultComponent)
	UWindDirectionResponseComponent WindDirectionResponseComp;

	UPROPERTY(EditAnywhere, Category = "Ice Lake Mast")
	float MaxAffectDistance = 3000.0;

	UPROPERTY(EditAnywhere, Category = "Ice Lake Mast")
	float SailTurnStiffness = 3.0;

	UPROPERTY(EditAnywhere, Category = "Ice Lake Mast")
	float SailTurnDamping = 0.4;

    UPROPERTY(EditAnywhere, Category = "Ice Lake Mast|Perch Spline")
	TSubclassOf<APerchSpline> PerchSplineClass;
	APerchSpline PerchSpline;

    UPROPERTY(EditAnywhere, Category = "Ice Lake Mast|Perch Spline")
    FTransform PerchSplineRelativeTransform;

    UPROPERTY(EditAnywhere, Category = "Ice Lake Mast|Perch Spline")
    float PerchSplineLength = 750.0;

    UPROPERTY(EditAnywhere, Category = "Ice Lake Mast|Perch Spline")
    float PerchSplineActivationRange = 500.0;

    UPROPERTY(EditAnywhere, Category = "Ice Lake Mast|Perch Spline")
    float PerchSplineAdditionalVisibleRange = 500.0;

	FVector WindDirection;
	FRotator TargetRotation;
    FRotator StartRotation;
	FHazeAcceleratedRotator AccMastRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WindDirectionResponseComp.OnWindDirectionChanged.AddUFunction(this, n"OnWindDirectionChanged");
		TargetRotation = RotatingComp.WorldRotation;
        StartRotation = RotatingComp.WorldRotation;
        AccMastRotation.Value = StartRotation;

        FVector PerchSplineLocation = RotatingComp.WorldTransform.TransformPositionNoScale(PerchSplineRelativeTransform.Location);
        FQuat PerchSplineRotation = RotatingComp.WorldTransform.TransformRotation(PerchSplineRelativeTransform.Rotation);

        PerchSpline = SpawnActor(PerchSplineClass, PerchSplineLocation, PerchSplineRotation.Rotator(), NAME_None, true);
		PerchSpline.SetActorHiddenInGame(true);
        PerchSpline.bAllowGrappleToPoint = false;
        PerchSpline.ActivationRange = PerchSplineActivationRange;
        PerchSpline.AdditionalVisibleRange = PerchSplineAdditionalVisibleRange;
        PerchSpline.Spline.SplinePoints[1].RelativeLocation = FVector(0, PerchSplineLength, 0);

		PerchSpline.AttachToComponent(RotatingComp, NAME_None, EAttachmentRule::KeepWorld);

		FinishSpawningActor(PerchSpline);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(WindDirection.SizeSquared() > KINDA_SMALL_NUMBER)
			TargetRotation = FRotator::MakeFromX(WindDirection);
        else
            TargetRotation = StartRotation;

		AccMastRotation.SpringTo(TargetRotation, SailTurnStiffness, SailTurnDamping, DeltaSeconds);

		RotatingComp.SetWorldRotation(AccMastRotation.Value);
	}

	UFUNCTION()
	void OnWindDirectionChanged(FVector InWindDirection, FVector InLocation)
	{
		WindDirection = InWindDirection;
	}
};