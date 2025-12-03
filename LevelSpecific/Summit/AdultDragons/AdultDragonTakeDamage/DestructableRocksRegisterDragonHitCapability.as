class UDestructableRocksRegisterDragonHitCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	TArray<UStaticMeshComponent> MeshComps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Owner.GetComponentsByClass(MeshComps);
		for (UStaticMeshComponent Comp : MeshComps)
		{
			Comp.OnComponentHit.AddUFunction(this, n"OnComponentHit");
		}
	}

	UFUNCTION()
	private void OnComponentHit(UPrimitiveComponent HitComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, FVector NormalImpulse,
	                            const FHitResult&in Hit)
	{
	}
};