UCLASS(NotBlueprintable, NotPlaceable)
class UTreeGuardianRangedShootIgnoreOcclusionCollisionContainerComponent : UActorComponent
{
	TSet<AActor> IgnoreOcclusionActors;
	TSet<UPrimitiveComponent> IgnoreOcclusionComponents;
}

class UTreeGuardianRangedShootIgnoreOcclusionCollisionComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	bool bIsPrimitiveParentExclusive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Register();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Unregister();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		Register();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		Unregister();
	}

	void Register()
	{
		auto Container = UTreeGuardianRangedShootIgnoreOcclusionCollisionContainerComponent::GetOrCreate(Game::Mio);

		if(bIsPrimitiveParentExclusive)
		{
			if(AttachParent.IsA(UPrimitiveComponent))
				Container.IgnoreOcclusionComponents.Add(Cast<UPrimitiveComponent>(AttachParent));
		}
		else
			Container.IgnoreOcclusionActors.Add(Owner);
	}

	void Unregister()
	{
		auto Container = UTreeGuardianRangedShootIgnoreOcclusionCollisionContainerComponent::GetOrCreate(Game::Mio);
		if(bIsPrimitiveParentExclusive)
		{
			if(AttachParent.IsA(UPrimitiveComponent))
				Container.IgnoreOcclusionComponents.Remove(Cast<UPrimitiveComponent>(AttachParent));
		}
		else
			Container.IgnoreOcclusionActors.Remove(Owner);
	}
}