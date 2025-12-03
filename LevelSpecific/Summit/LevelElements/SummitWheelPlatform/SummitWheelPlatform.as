class ASummitWheelPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;
	
#if EDITOR
	UPROPERTY(DefaultComponent)
	USummitWheelPlatformVisualizerComponent Visualizer;
#endif

	UPROPERTY(EditAnywhere, Category = "Rotation")
	float RotationRate = 20.0;

	UPROPERTY(EditAnywhere, Category = "Rotation")
	float ValidAngleStart = 0.0;

	UPROPERTY(EditAnywhere, Category = "Rotation")
	float ValidAngleEnd = 180.0;

	// Speed at which the spokes cross their rotation when going between valid and invalid areas
	UPROPERTY(EditAnywhere, Category = "Rotation")
	float CrossRotationDuration = 1.0;

	private TArray<FSummitWheelPlatformChild> Children;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		int NumChildren = RotationRoot.NumChildrenComponents;
		for (int i = 0; i < NumChildren; ++i)
		{
			auto ChildComp = RotationRoot.GetChildComponent(i);

			FSummitWheelPlatformChild Child;
			Child.Component = ChildComp;
			Child.StartRotation = ChildComp.RelativeRotation;

			Children.Add(Child);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Angle = Math::Wrap(RotationRate * Time::GlobalCrumbTrailTime, 0.0, 360.0);

		for (FSummitWheelPlatformChild& Child : Children)
		{
			FRotator ChildRotation = Child.StartRotation;
			ChildRotation.Yaw += Angle;

			bool bInsideValidArea = Math::IsWithin(Math::Wrap(ChildRotation.Yaw, 0.0, 360.0), ValidAngleStart, ValidAngleEnd);
			
			if((Child.bIsInsideValidArea && !bInsideValidArea) // Was inside area and is no longer
			|| (!Child.bIsInsideValidArea && bInsideValidArea)) // Was outside area and is now inside
			{
				auto MeshRoot = Child.Component.GetChildComponent(0);
				FSummitWheelPLatformStartedTiltingParams EventParams;
				EventParams.ComponentWhichStartedTilting = MeshRoot;
				USummitWheelPlatformEventHandler::Trigger_OnPlatformStartedTilting(this, EventParams);
			}
			Child.bIsInsideValidArea = bInsideValidArea;

			if (bInsideValidArea)
				Child.CrossAngle.AccelerateTo(0.0, CrossRotationDuration, DeltaSeconds);
			else
				Child.CrossAngle.AccelerateTo(90.0, CrossRotationDuration, DeltaSeconds);
			ChildRotation.Roll += Child.CrossAngle.Value;

			Child.Component.SetRelativeRotation(ChildRotation);
			
		}
	}
}

struct FSummitWheelPlatformChild
{
	USceneComponent Component;
	FRotator StartRotation;
	FHazeAcceleratedFloat CrossAngle;
	bool bIsInsideValidArea = true;
};

#if EDITOR
class USummitWheelPlatformVisualizerComponent : USceneComponent {}
class USummitWheelPlatformVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = USummitWheelPlatformVisualizerComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent InComponent)
    {
		auto WheelPlatform = Cast<ASummitWheelPlatform>(InComponent.Owner);
		if (WheelPlatform == nullptr)
			return;

		FVector RotationNormal = WheelPlatform.RotationRoot.UpVector;
		FVector Center = WheelPlatform.RotationRoot.WorldLocation;

		FVector Forward = Center + WheelPlatform.RotationRoot.ForwardVector * 300.0;
		FVector PrevPos = Forward;

		float Angle = 0.0;
		while (Angle <= 360.0)
		{
			Angle += 3.0;
			FVector NewPos = Center + FQuat(RotationNormal, Math::DegreesToRadians(Angle)).RotateVector(
				WheelPlatform.RotationRoot.ForwardVector * 300.0);

			FLinearColor Color = FLinearColor::Red;
			if (Math::IsWithin(Angle, WheelPlatform.ValidAngleStart, WheelPlatform.ValidAngleEnd))
				Color = FLinearColor::Green;

			DrawLine(
				PrevPos,
				NewPos,
				Color, 5.0
			);

			PrevPos = NewPos;
		}

		int NumChildren = WheelPlatform.RotationRoot.NumChildrenComponents;
		for (int i = 0; i < NumChildren; ++i)
		{
			auto Child = WheelPlatform.RotationRoot.GetChildComponent(i);
			if (Child == nullptr)
				continue;

			FVector OffsetOnPlane = Child.ForwardVector.ConstrainToPlane(RotationNormal).GetSafeNormal();
			DrawLine(
				Center,
				Center + OffsetOnPlane * 300.0,
				FLinearColor::Blue, 10.0
			);
		}
	}
}

#endif