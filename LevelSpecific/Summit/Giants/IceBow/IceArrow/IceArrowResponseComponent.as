event void FHitByIceArrow(FIceArrowHitEventData IcicleHitData);

UCLASS(HideCategories = "Rendering Debug Activation Cooking Physics LOD Collision")
class UIceArrowResponseComponent : USceneComponent
{
	access IceArrow = private, AIceArrow;

	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere, Category = "Ice Arrow Response Component")
	float IceArrowImpulseScale = 1.0;

	UPROPERTY(Category = "Ice Arrow Response Component", meta = (BPCannotCallEvent))
	FHitByIceArrow OnHitByIceArrow;

	UPROPERTY(EditAnywhere, Category = "Ice Arrow Response Component")
	bool bHitAnywhere = false;

	UPROPERTY(EditAnywhere, Category = "Ice Arrow Response Component", Meta = (EditCondition = "!bHitAnywhere"))
	FHazeShapeSettings CollisionSettings;
	default CollisionSettings.Type = EHazeShapeType::Sphere;
	default CollisionSettings.SphereRadius = 50.0;
	default CollisionSettings.BoxExtents = FVector(50.0);
	EHazeShapeType PreviousType = EHazeShapeType::Sphere;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		switch(CollisionSettings.Type)
		{
			case EHazeShapeType::Sphere:
				CollisionSettings.SphereRadius = Math::Max(CollisionSettings.SphereRadius, KINDA_SMALL_NUMBER);
				break;

			case EHazeShapeType::Box:
				CollisionSettings.BoxExtents = CollisionSettings.BoxExtents.ComponentMax(FVector(KINDA_SMALL_NUMBER));
				break;

			default:
				CollisionSettings.Type = PreviousType;
				PrintError("Only Sphere and Box collision types are supported!", 5.0, FLinearColor::Red);
				break;
		}

		PreviousType = CollisionSettings.Type;
	}
}

class UIceArrowResponseComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIceArrowResponseComponent;

    UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		const auto Component = Cast<UIceArrowResponseComponent>(InComponent);
		if(Component == nullptr)
			return;

		if(Component.bHitAnywhere)
			return;

		SetRenderForeground(false);

		const FVector Location = Component.WorldLocation;

		switch(Component.CollisionSettings.Type)
		{
			case EHazeShapeType::Sphere:
				DrawWireSphere(Location, Component.CollisionSettings.SphereRadius, FLinearColor::LucBlue);
				break;

			case EHazeShapeType::Box:
				DrawWireBox(Location, Component.CollisionSettings.BoxExtents, Component.WorldRotation.Quaternion(), FLinearColor::LucBlue);
				break;
			default:
				devError("Forgot to add case");
				break;
		}
	}
}