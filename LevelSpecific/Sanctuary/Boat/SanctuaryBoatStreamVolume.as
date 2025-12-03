class USanctuaryBoatStreamVolumeVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuaryBoatStreamVolumeVisualizerComponent;

	bool bIsHandleSelected = false;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto BoatStreamVolume = Cast<ASanctuaryBoatStreamVolume>(InComponent.Owner);

		DrawDashedLine(BoatStreamVolume.ActorLocation, BoatStreamVolume.ActorTransform.TransformPositionNoScale(BoatStreamVolume.TargetLocation), FLinearColor::LucBlue, 10.0, 5.0, false, 40);

		SetHitProxy(n"TargetProxy", EVisualizerCursor::CardinalCross);
		DrawWireDiamond(BoatStreamVolume.ActorTransform.TransformPositionNoScale(BoatStreamVolume.TargetLocation), BoatStreamVolume.ActorRotation, 100.0, FLinearColor::Blue, 5.0);
		ClearHitProxy();
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		if(HitProxy.IsEqual(n"TargetProxy", bCompareNumber = false))
		{
			bIsHandleSelected = true;
			return true;
		}

		bIsHandleSelected = false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		auto BoatStreamVolume = Cast<ASanctuaryBoatStreamVolume>(EditingComponent.Owner);

		if(bIsHandleSelected)
		{
			OutLocation = BoatStreamVolume.ActorTransform.TransformPositionNoScale(BoatStreamVolume.TargetLocation);
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		auto BoatStreamVolume = Cast<ASanctuaryBoatStreamVolume>(EditingComponent.Owner);

		if(bIsHandleSelected)
		{
			BoatStreamVolume.TargetLocation += BoatStreamVolume.ActorTransform.InverseTransformVectorNoScale(DeltaTranslate);
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		bIsHandleSelected = false;
	}
}

class USanctuaryBoatStreamVolumeVisualizerComponent : UHazeEditorRenderedComponent
{
	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		auto BoatStreamVolume = Cast<ASanctuaryBoatStreamVolume>(Owner);
		if (BoatStreamVolume == nullptr)
			return;

		float Thickness = 5.0;
		FLinearColor Color = FLinearColor::Blue;

		FTransform Transform = BoatStreamVolume.ActorTransform;
		FCollisionShape Shape = BoatStreamVolume.Shape.CollisionShape;

		SetActorHitProxy();
		switch (BoatStreamVolume.Shape.Type)
		{
			case EHazeShapeType::Sphere : 
			{
			//	DrawWireSphere(Transform.Location, Shape.SphereRadius * Transform.Scale3D.X, Color, Thickness, 24);
				DrawCircle(Transform.Location, Shape.SphereRadius * Transform.Scale3D.X, Color, Thickness, Transform.Rotation.UpVector, 24);
				DrawCircle(Transform.Location, Shape.SphereRadius * Transform.Scale3D.X, Color, Thickness, Transform.Rotation.RightVector, 24);
				DrawCircle(Transform.Location, Shape.SphereRadius * Transform.Scale3D.X, Color, Thickness, Transform.Rotation.ForwardVector, 24);
				break;
			}
			case EHazeShapeType::Box : 
			{
				DrawWireBox(Transform.Location, Shape.Extent * Transform.Scale3D, Transform.Rotation, Color, Thickness);
				break;
			}
			case EHazeShapeType::Capsule : 
			{
				DrawWireCapsule(Transform.Location, Transform.Rotator(), Color, Shape.CapsuleRadius * Transform.Scale3D.X, Shape.CapsuleHalfHeight * Transform.Scale3D.Z, 24, Thickness);
				break;
			}
			case EHazeShapeType::None:
				break;
		}
		ClearHitProxy();
#endif
	}

	UFUNCTION(BlueprintOverride, Meta = (BlueprintThreadSafe))
	void CalcBounds(FVector& OutOrigin, FVector& OutBoxExtent, float& OutSphereRadius) const
	{
		auto BoatStreamVolume = Cast<ASanctuaryBoatStreamVolume>(Owner);
		if (BoatStreamVolume == nullptr)
			return;

		OutSphereRadius = BoatStreamVolume.ActorScale3D.AbsMax * BoatStreamVolume.Shape.EncapsulatingSphereRadius;
	}
}
UCLASS(Abstract)
class ASanctuaryBoatStreamVolume : AHazeActor
{
	default bRunConstructionScriptOnDrag = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	USanctuaryBoatStreamVolumeVisualizerComponent VisualizerComp;

	UPROPERTY(EditAnywhere)
	float Force = 500.0;

	UPROPERTY(EditAnywhere)
	FHazeShapeSettings Shape;
	default Shape.Type = EHazeShapeType::Sphere;
	default Shape.BoxExtents = FVector::OneVector * 1000.0;
	default Shape.SphereRadius = 1000.0;
	default Shape.CapsuleRadius = 1000.0;
	default Shape.CapsuleHalfHeight = 2000.0;

	// Location the stream flows to
	UPROPERTY(EditAnywhere)
	FVector TargetLocation;

	// Use a target Actor location - will override TargetLocation
	UPROPERTY(EditAnywhere)
	AActor TargetActor;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (TargetActor != nullptr)
			TargetLocation = ActorTransform.InverseTransformPositionNoScale(TargetActor.ActorLocation);
	}

	FVector GetStreamTargetLocation() property
	{
		return ActorTransform.TransformPositionNoScale(TargetLocation);
	}
};