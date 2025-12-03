class USanctuaryLightBirdLightUpVolumeVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuaryLightBirdLightUpVolumeVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto LightUpVolume = Cast<ASanctuaryLightBirdLightUpVolume>(InComponent.Owner);
	}
}

class USanctuaryLightBirdLightUpVolumeVisualizerComponent : UHazeEditorRenderedComponent
{
	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		auto LightUpVolume = Cast<ASanctuaryLightBirdLightUpVolume>(Owner);
		if (LightUpVolume == nullptr)
			return;

		float Thickness = 5.0;
		FLinearColor Color = FLinearColor::Yellow;

		FTransform Transform = LightUpVolume.ActorTransform;
		FCollisionShape Shape = LightUpVolume.Shape.CollisionShape;

		SetActorHitProxy();
		switch (LightUpVolume.Shape.Type)
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
}
UCLASS(Abstract)
class ASanctuaryLightBirdLightUpVolume : AHazeActor
{
	default bRunConstructionScriptOnDrag = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	USanctuaryLightBirdLightUpVolumeVisualizerComponent VisualizerComp;

	UPROPERTY(EditAnywhere)
	FHazeShapeSettings Shape;
	default Shape.Type = EHazeShapeType::Sphere;
	default Shape.BoxExtents = FVector::OneVector * 1000.0;
	default Shape.SphereRadius = 1000.0;
	default Shape.CapsuleRadius = 1000.0;
	default Shape.CapsuleHalfHeight = 2000.0;
};