

UCLASS(Abstract, Meta = (HideCategories = "Physics AssetUserData Collision Cooking Activation Replication Actor Tick"))
class AIslandNunchuck : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UIslandNunchuckMeshComponent WeaponComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent IdleComponent;
	default IdleComponent.SetCollisionProfileName(n"NoCollision", false);
	default IdleComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default IdleComponent.bCanEverAffectNavigation = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		IdleComponent.AddComponentVisualsBlocker(this);
		WeaponComponent.AddComponentVisualsBlocker(this);
	}

	void ShowWeapon()
	{
		IdleComponent.RemoveComponentVisualsBlocker(this);
         WeaponComponent.RemoveComponentVisualsBlocker(this);
	}

	void HideWeapon()
	{
		IdleComponent.AddComponentVisualsBlocker(this);
		WeaponComponent.AddComponentVisualsBlocker(this);
	}
}

UCLASS(Meta = (HideCategories = "Physics ClothingSimulation Clothing Navigation Skin Weights VirtualTexture Activation Cooking"))
class UIslandNunchuckMeshComponent  : UHazeSkeletalMeshComponentBase
{
	default SetCollisionProfileName(n"NoCollision", false);
	default SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default bUseBoundsFromLeaderPoseComponent = true;
	default bSkipBoundsUpdateWhenInterpolating = true;
	default bComponentUseFixedSkelBounds = true;
	default bDisableClothSimulation = true;

	UPROPERTY(Category = "Melee")
	FHazeShapeSettings TriggerShape;
	default TriggerShape.InitializeAsCapsule(30, 60);

	UPROPERTY(Category = "Melee")
	FVector LocalShapeOffset = FVector::ZeroVector;

	AHazePlayerCharacter PlayerOwner;
}


#if EDITOR
class UIslandNunchuckVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UIslandNunchuckMeshComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent InComponent)
    {
        UIslandNunchuckMeshComponent Component = Cast<UIslandNunchuckMeshComponent>(InComponent);
		if(Component == nullptr)
			return;

		auto NunChuckOwner = Cast<AIslandNunchuck>(Component.Owner);
		if(NunChuckOwner == nullptr)
			return;

		FVector LeftLocation = Component.GetSocketLocation(n"LeftHandle");
		FVector RightLocation = Component.GetSocketLocation(n"RightHandle");

	 	FVector WeaponLocation = (LeftLocation + RightLocation) / 2;
		FQuat WeaponRotation = Component.GetComponentQuat();
	
		FCollisionShape WeaponShape = Component.TriggerShape.GetCollisionShape();
		WeaponShape.SetCapsule(WeaponShape.CapsuleRadius, LeftLocation.Distance(RightLocation));

		DrawWireShape(WeaponShape, WeaponLocation, WeaponRotation);
    }   
} 
#endif
