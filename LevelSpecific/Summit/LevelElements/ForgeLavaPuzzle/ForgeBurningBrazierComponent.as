class UForgeBurningBrazierComponent : USceneComponent
{	
	UPROPERTY()
	float BurnPower = 0.0;

	float BurnDecay = 50.0;
	float HitBurnIncrease = 2;

	UPROPERTY(EditAnywhere)
	float BurnThreshold = 50.0;

	UPROPERTY(EditAnywhere)
	float BurningRadius = 1000.0;

	UPROPERTY(EditAnywhere)
	TArray<AActor> TargetBraziers;

	TArray<UForgeBurningBrazierComponent> TargetBurningComponents;

	UPROPERTY(EditAnywhere)
	bool bIsBurning;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto AcidResponseComponent = UAcidResponseComponent::Get(Owner);
		if (AcidResponseComponent != nullptr)
			AcidResponseComponent.OnAcidHit.AddUFunction(this, n"HandleAcidHit");

		for (auto TargetBrazier : TargetBraziers)
		{
			if(TargetBrazier == nullptr)
				continue;
			
			auto TargetBurningComponent = UForgeBurningBrazierComponent::Get(TargetBrazier);
			if (TargetBurningComponent != nullptr)
				TargetBurningComponents.Add(TargetBurningComponent);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		if (!bIsBurning)
			return;

		BurnPower = Math::Clamp(BurnPower - BurnDecay * DeltaSeconds, 0.0, 100.0);
		for (auto TargetBurningComponent : TargetBurningComponents)
		{
			if(!TargetBurningComponent.bIsBurning && TargetBurningComponent.WorldLocation.Distance(WorldLocation) - TargetBurningComponent.BurningRadius <= BurningRadius && BurnPower >= BurnThreshold)
				TargetBurningComponent.bIsBurning = true;
		}

		
	}

	UFUNCTION()
	private void HandleAcidHit(FAcidHit Hit)
	{
		BurnPower += HitBurnIncrease;
	}

}