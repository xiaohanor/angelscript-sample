UCLASS(HideCategories = "Physics Collision Lighting Rendering Navigation Debug Activation Cooking Tags Lod TextureStreaming")
class UBombTossTriggerImpactComponent : UHazeEditorRenderedComponent
{
	default SetHiddenInGame(true);
	
	UPROPERTY(EditAnywhere)
	FHazeShapeSettings Shape = FHazeShapeSettings::MakeBox(FVector(100.0, 100.0, 100.0));

	UPROPERTY(EditAnywhere, Category = "Editor Rendering")
	bool bAlwaysShowShapeInEditor = true;

	UPROPERTY(EditAnywhere, Category = "Editor Rendering")
	float EditorLineThickness = 2.0;

	private TArray<FInstigator> DisableInstigators;
	private UBombTossResponseComponent BombTossResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BombTossResponseComp = UBombTossResponseComponent::Get(Owner);
		devCheck(BombTossResponseComp != nullptr, "A trigger impact component can't exist without a power ball response comp");
	}

	void DisableTrigger(FInstigator Instigator)
	{
		DisableInstigators.AddUnique(Instigator);
	}

	void EnableTrigger(FInstigator Instigator)
	{
		DisableInstigators.RemoveSingleSwap(Instigator);
	}

	bool IsDisabled()
	{
		return DisableInstigators.Num() > 0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TListedActors<ABombToss_Bomb> BombTosss;
		for(ABombToss_Bomb BombToss : BombTosss)
		{
			if(IsDisabled())
				continue;

			if(BombToss.IsActorDisabled())
				continue;

			if(Overlap::QueryShapeOverlap(BombToss.Collision.GetCollisionShape(), BombToss.Collision.WorldTransform, Shape.GetCollisionShape(), WorldTransform))
			{
				BombTossResponseComp.TryApplyImpact(this, BombToss.ActorLocation, FVector::ZeroVector);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		if(!bAlwaysShowShapeInEditor)
			return;

		SetActorHitProxy();

		if (!Shape.IsZeroSize())
		{
			switch (Shape.Type)
			{
				case EHazeShapeType::Box:
					DrawWireBox(
						WorldLocation,
						Shape.BoxExtents,
						ComponentQuat,
						FLinearColor::Green,
						EditorLineThickness
					);
				break;
				case EHazeShapeType::Sphere:
					DrawWireSphere(
						WorldLocation,
						Shape.SphereRadius,
						FLinearColor::Green,
						EditorLineThickness
					);
				break;
				case EHazeShapeType::Capsule:
					DrawWireCapsule(
						WorldLocation,
						WorldRotation,
						FLinearColor::Green,
						Shape.CapsuleRadius,
						Shape.CapsuleHalfHeight,
						16, EditorLineThickness
					);
				break;
				default: break;
			}
		}

#endif
	}
}

class UBombTossTriggerImpactComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UBombTossTriggerImpactComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Trigger = Cast<UBombTossTriggerImpactComponent>(Component);

		if (!Trigger.Shape.IsZeroSize())
		{
			switch (Trigger.Shape.Type)
			{
				case EHazeShapeType::Box:
					DrawWireBox(
						Trigger.WorldLocation,
						Trigger.Shape.BoxExtents,
						Trigger.ComponentQuat,
						FLinearColor::Green,
						2.0
					);
				break;
				case EHazeShapeType::Sphere:
					DrawWireSphere(
						Trigger.WorldLocation,
						Trigger.Shape.SphereRadius,
						FLinearColor::Green,
					);
				break;
				case EHazeShapeType::Capsule:
					DrawWireCapsule(
						Trigger.WorldLocation,
						Trigger.WorldRotation,
						FLinearColor::Green,
						Trigger.Shape.CapsuleRadius,
						Trigger.Shape.CapsuleHalfHeight,
						16, 2.0
					);
				break;

				default: break;
			}
		}
	}
}