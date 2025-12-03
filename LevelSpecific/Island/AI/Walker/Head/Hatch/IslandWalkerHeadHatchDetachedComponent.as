class UIslandWalkerHeadHatchDetachedComponent : UStaticMeshComponent
{
	default CollisionProfileName = n"NoCollision";

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddComponentVisualsAndCollisionAndTickBlockers(this);
	}

	void DetachFromHead(FVector Impulse)
	{
		RemoveComponentVisualsAndCollisionAndTickBlockers(this);
		SetCollisionProfileName(n"Destructible");
		SetSimulatePhysics(true);
		AddImpulse(Impulse);
	}
};
