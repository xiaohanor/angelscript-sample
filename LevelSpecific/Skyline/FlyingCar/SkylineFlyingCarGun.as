
UCLASS(Abstract)
class ASkylineFlyingCarGun : AHazeActor
{
	ASkylineFlyingCar CarOwner;

	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileLauncherComponent ProjectileLauncherComponent;
}


class USkylineFlyingCarGunRootComponent : USceneComponent
{
	UPROPERTY()
	ASkylineFlyingCarGun Gun;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SceneComponent::BindOnSceneComponentMoved(this, FOnSceneComponentMoved(this, n"OnMoved"));
	}

	UFUNCTION()
	private void OnMoved(USceneComponent MovedComponent, bool bIsTeleport)
	{
		if (Gun != nullptr)
			Gun.SetActorLocation(GetWorldLocation());
	}
}


class USkylineFlyingCarGunPivotComponent : USceneComponent
{
	
}

// Eman TODO: Use this once we have an actual turret mesh for the car!!!!!!
// #if EDITOR
// class USkylineFlyingCarGunRootComponentVisualizer : UHazeScriptComponentVisualizer
// {
// 	default VisualizedClass = USkylineFlyingCarGunRootComponent;

// 	UPROPERTY(Transient)
// 	UStaticMeshComponent PreviewGun;

// 	// Draw turret mesh
// 	UFUNCTION(BlueprintOverride)
// 	void VisualizeComponent(const UActorComponent Component)
// 	{
// 		USkylineFlyingCarGunRootComponent GunRootComponent = Cast<USkylineFlyingCarGunRootComponent>(Component);
// 		if (GunRootComponent == nullptr)
// 			return;

// 		ASkylineFlyingCar CarOwner = Cast<ASkylineFlyingCar>(Component.Owner);
// 		if (CarOwner == nullptr)
// 			return;

// 		if (!CarOwner.GunClass.IsValid())
// 			return;

// 		if (PreviewGun == nullptr)
// 		{
// 			PreviewGun = UStaticMeshComponent::GetOrCreate(CarOwner, n"PreviewGunMeshComponent");
// 			PreviewGun.SetStaticMesh()
// 			PreviewGun.AttachToComponent(GunRootComponent);
// 		}
// 	}
// }
// #endif