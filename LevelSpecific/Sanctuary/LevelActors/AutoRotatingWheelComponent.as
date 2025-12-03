#if EDITOR
class UAutoRotatingWheelComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UAutoRotatingWheelComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		FLinearColor Color = FLinearColor::Green;

		auto AutoRotatingWheelComponent = Cast<UAutoRotatingWheelComponent>(Component);
		if (!ensure((AutoRotatingWheelComponent != nullptr) && (AutoRotatingWheelComponent.GetOwner() != nullptr)))
			return;

		SetRenderForeground(true);

		float Radius = AutoRotatingWheelComponent.Radius;

		if (AutoRotatingWheelComponent.bApproximateRadiusFromBounds)
			Radius = AutoRotatingWheelComponent.ApproximatedRadius;

		DrawCircle(AutoRotatingWheelComponent.WorldLocation, Radius, Color, 5.0, AutoRotatingWheelComponent.WorldTransform.TransformVectorNoScale(AutoRotatingWheelComponent.Axis).GetSafeNormal(), 24);

		DrawWorldString("Radius: " + Radius, AutoRotatingWheelComponent.WorldLocation + AutoRotatingWheelComponent.ForwardVector * Radius, Color, 2.0, 5000.0);

		if (AutoRotatingWheelComponent.bUseFixedAxis)
			DrawArrow(AutoRotatingWheelComponent.WorldLocation, AutoRotatingWheelComponent.WorldLocation + AutoRotatingWheelComponent.WorldTransform.TransformVectorNoScale(AutoRotatingWheelComponent.Axis).GetSafeNormal() * Radius, Color, 10.0, 5.0);
	}
} 
#endif

class UAutoRotatingWheelComponent : USceneComponent
{
	// This is still not working well
	UPROPERTY(EditAnywhere)
	bool bApproximateRadiusFromBounds;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "!bApproximateRadiusFromBounds"))
	float Radius = 500.0;

	UPROPERTY(EditAnywhere)
	FVector ContactDirection = FVector(0.0, 0.0, -1.0);

	UPROPERTY(EditAnywhere)
	bool bUseFixedAxis;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseFixedAxis", EditConditionHides))
	FVector Axis = FVector(0.0, 1.0, 0.0);

	FVector PreviousLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PreviousLocation = WorldLocation;

		if (bApproximateRadiusFromBounds)
			Radius = ApproximatedRadius;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector DeltaMove = PreviousLocation - WorldLocation;

		if (bUseFixedAxis)
			DeltaMove = DeltaMove.ConstrainToPlane(WorldTransform.TransformVectorNoScale(Axis).GetSafeNormal());

		FVector RotationAxis = -DeltaMove.CrossProduct(ContactDirection).GetSafeNormal();

		float Angle = DeltaMove.Size() / Radius;

		AddWorldRotation(FQuat(RotationAxis, Angle));

		PreviousLocation = WorldLocation;
	}

	float GetApproximatedRadius() property
	{
		float ExtentRadius = 0.0;

		TArray<USceneComponent> Children;
		GetChildrenComponents(true, Children);

		for(auto Child : Children)
		{
			auto AsPrimitive = Cast<UPrimitiveComponent>(Child);
			if (AsPrimitive != nullptr)
			{
				FVector Offset = WorldLocation - AsPrimitive.WorldLocation;
				
				if (bUseFixedAxis)
					Offset = Offset.ConstrainToPlane(Axis.GetSafeNormal());

				// Not correct atm
				float NewExtent = Offset.Size() + AsPrimitive.BoundsExtent.AbsMax;

				if (NewExtent > ExtentRadius)
					ExtentRadius = NewExtent;
			}
		}

		return ExtentRadius;
	}
}