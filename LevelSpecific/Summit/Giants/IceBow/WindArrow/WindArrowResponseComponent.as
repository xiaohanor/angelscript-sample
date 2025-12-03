event void FHitByWindArrow(FWindArrowHitEventData IcicleHitData);
event void FWindEventData();

class UWindArrowResponseComponentContainer : UActorComponent
{
	TArray<UWindArrowResponseComponent> ResponseComponents;
}

UCLASS(HideCategories = "Rendering Debug Activation Cooking Physics LOD Collision")
class UWindArrowResponseComponent : USceneComponent
{
	access WindArrow = private, AWindArrow;

	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere, Category = "Wind Arrow Response Component")
	float WindArrowImpulseScale = 1.0;

	UPROPERTY(Category = "Wind Arrow Response Component", meta = (BPCannotCallEvent))
	FHitByWindArrow OnHitByWindArrow;

	UPROPERTY(Category = "Wind Arrow Response Component", meta = (BPCannotCallEvent))
	FWindEventData OnComponentEnterWindZone;

	UPROPERTY(Category = "Wind Arrow Response Component", meta = (BPCannotCallEvent))
	FWindEventData OnComponentExitWindZone;

	UPROPERTY(EditAnywhere, Category = "Wind Arrow Response Component")
	bool bHitAnywhere = false;

	UPROPERTY(EditAnywhere, Category = "Wind Arrow Response Component", Meta = (EditCondition = "!bHitAnywhere"))
	FHazeShapeSettings CollisionSettings;
	default CollisionSettings.Type = EHazeShapeType::Sphere;
	default CollisionSettings.SphereRadius = 50.0;
	default CollisionSettings.BoxExtents = FVector(50.0);
	EHazeShapeType PreviousType = EHazeShapeType::Sphere;

	TArray<AWindArrow> OverlappedWindZoneArrows;

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

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Container = UWindArrowResponseComponentContainer::GetOrCreate(Game::Mio);
		Container.ResponseComponents.AddUnique(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto Container = UWindArrowResponseComponentContainer::GetOrCreate(Game::Mio);
		Container.ResponseComponents.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		auto Container = UWindArrowResponseComponentContainer::GetOrCreate(Game::Mio);
		Container.ResponseComponents.AddUnique(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		auto Container = UWindArrowResponseComponentContainer::GetOrCreate(Game::Mio);
		Container.ResponseComponents.RemoveSingleSwap(this);
	}

	void EnterWindZone(AWindArrow Arrow)
	{
		bool bWasInWindZone = IsInWindZone();
		OverlappedWindZoneArrows.AddUnique(Arrow);
		bool bIsInWindZone = IsInWindZone();

		if(!bWasInWindZone && bIsInWindZone)
			OnComponentEnterWindZone.Broadcast();
	}

	void ExitWindZone(AWindArrow Arrow)
	{
		bool bWasInWindZone = IsInWindZone();
		OverlappedWindZoneArrows.RemoveSingleSwap(Arrow);
		bool bIsInWindZone = IsInWindZone();

		if(bWasInWindZone && !bIsInWindZone)
			OnComponentExitWindZone.Broadcast();
	}

	bool IsInWindZone()
	{
		return OverlappedWindZoneArrows.Num() > 0;
	}
}

class UWindArrowResponseComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UWindArrowResponseComponent;

    UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		const auto Component = Cast<UWindArrowResponseComponent>(InComponent);
		if(Component == nullptr)
			return;

		SetRenderForeground(false);
		DrawWireShapeSettings(Component.CollisionSettings, Component.WorldLocation, Component.ComponentQuat, FLinearColor::LucBlue);
	}
}