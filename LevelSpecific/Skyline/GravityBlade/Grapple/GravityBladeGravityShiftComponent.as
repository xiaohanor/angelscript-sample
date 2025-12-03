class UGravityBladeGravityShiftVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBladeGravityShiftComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto Actor = InComponent.Owner;
		auto ShiftComp = Cast<UGravityBladeGravityShiftComponent>(InComponent);

		const FVector Origin = Actor.ActorLocation;
		const float ArrowSize = 25.0;
		const float ArrowLength = 250.0;
		const FVector Normal = ShiftComp.UpVector;

		FVector ArrowEnd = Origin + (Normal * (ArrowLength + ArrowSize));
		DrawArrow(Origin, ArrowEnd, FLinearColor::Blue, ArrowSize, 5.0);

		if (ShiftComp.bForceCameraForward)
		{
			FVector CameraDirection = Actor.ActorTransform.TransformVector(ShiftComp.CameraTargetForward) * 200.0;
			DrawArrow(ArrowEnd, ArrowEnd + CameraDirection, FLinearColor::DPink, 25.0, 5.0);
		}

		switch (ShiftComp.Type)
		{
			case EGravityBladeGravityShiftType::Plane:
			{
				DrawCircleWithLines(Origin, Normal, 0.0, ArrowLength, 10);
				break;
			}

			case EGravityBladeGravityShiftType::Spherical:
			{
				FVector CrossVector = Actor.ActorUpVector;
				if (Math::Abs(CrossVector.DotProduct(Normal)) > 0.99)
					CrossVector = Actor.ActorRightVector;

				const FVector Perpendicular = Normal.CrossProduct(CrossVector);
				DrawCircleWithLines(Origin, Normal, 0.0, ArrowLength, 10);
				DrawCircleWithLines(Origin, Perpendicular, 0.0, ArrowLength, 10);
				break;
			}
			default: break;
		}
	}

	void DrawCircleWithLines(const FVector& Origin, const FVector& Direction, float Length, float Radius, int NumSegments)
	{
		const FVector Perpendicular = Math::GetSafePerpendicular(Direction, FVector::ForwardVector);
		const FVector CircleOrigin = Origin + (Direction * Length);

		for (int i = 0; i < NumSegments; ++i)
		{
			const float Angle = ((PI * 2.0) / NumSegments) * i;
			const FVector EndLocation = CircleOrigin + (Perpendicular.RotateAngleAxis(Math::RadiansToDegrees(Angle), Direction) * Radius);

			DrawDashedLine(Origin, EndLocation, FLinearColor::Gray);
		}

		DrawCircle(CircleOrigin, Radius, FLinearColor::Yellow, 5.0, Direction, NumSegments);
	}
}

enum EGravityBladeGravityShiftType
{
	// Shifts gravity only on the specified axis.
	Axis,

	// Shifts gravity constrained to the plane from actor center pointing towards the component's axis.
	Plane,

	// Shifts gravity in any direction towards actor center, component axis is irrelevant.
	Spherical,

	// Shifts gravity according to primitives surface normal beneath the player.
	Surface
}

class UGravityBladeGravityShiftComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	/**
	 * Enable automatically shifting to this shift component's gravity when the player walks on it.
	 * If disabled, the shift component will only apply when the player grapples.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Gravity Shift")
	bool bEnableAutoShift = true;

	UPROPERTY(EditAnywhere, BlueprintHidden, Category = "Gravity Shift")
	EGravityBladeGravityShiftType Type;

	UPROPERTY(EditAnywhere, BlueprintHidden, Category = "Gravity Shift")
	FVector Axis = FVector::UpVector;

	/** 
	 * Force the camera forward in a particular direction when shifting to this gravity with a grapple.
	 */
	UPROPERTY(EditAnywhere, BlueprintHidden, Category = "Gravity Shift")
	bool bForceCameraForward = false;

	UPROPERTY(EditAnywhere, BlueprintHidden, Category = "Gravity Shift", Meta = (EditCondition = "bForceCameraForward", EditConditionHides))
	FVector CameraTargetForward = FVector::ForwardVector;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Gravity Shift")
	bool bWorldSpace = false;
	
	// Inverts the shift direction, because walking on the inside of tubes; no warranty included.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Gravity Shift")
	bool bInvertDirection = false;

	// TEMP: Case where we don't want to exit shifting when we leave the surface
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Gravity Shift")
	bool bForceSticky = false;

	UPROPERTY(VisibleAnywhere, Category = "Eject")
	bool bEjectPlayer = false;
	UPROPERTY(EditAnywhere, Category = "Eject")
	FGravityBladeGrappleEjectData EjectData;

	UPlayerInheritMovementComponent CachedInheritMoveComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CachedInheritMoveComp = UPlayerInheritMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintPure)
	FVector GetUpVector() const property
	{
		if (bWorldSpace)
			return Axis;

		return Owner.ActorTransform.TransformVector(Axis).GetSafeNormal();
	}

	UFUNCTION(BlueprintPure)
	FVector GetShiftDirection(const FVector& PlayerLocation) const
	{
		FVector Direction = UpVector;

		FVector CenterLocation = Owner.ActorLocation;
		if (CachedInheritMoveComp != nullptr)
			CenterLocation = CachedInheritMoveComp.WorldLocation;

		if (Type == EGravityBladeGravityShiftType::Plane)
			Direction = (PlayerLocation - CenterLocation).ConstrainToPlane(Direction).GetSafeNormal();

		if (Type == EGravityBladeGravityShiftType::Spherical)
			Direction = (PlayerLocation - CenterLocation).GetSafeNormal();

		if (bInvertDirection)
			Direction *= -1.0;

		return Direction;
	}
}
