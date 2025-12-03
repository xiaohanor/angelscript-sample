class UMeltdownWorldSpinFauxPhysicsResponseComponent : UActorComponent
{
	AMeltdownWorldSpinManager Manager;
	TArray<UFauxPhysicsWeightComponent> Weights;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Owner.GetComponentsByClass(Weights);
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
		if (Manager == nullptr)
			Manager = AMeltdownWorldSpinManager::GetWorldSpinManager();
		if (Manager == nullptr)
			return;
        
		const FVector GravityDir = -Manager.WorldSpinRotation.UpVector;
		for(auto Weight : Weights)
			Weight.SetGravityDir(GravityDir);
    }
}