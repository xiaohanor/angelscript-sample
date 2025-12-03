class UMoonMarketNPCPolymorphCheeseCapability : UMoonMarketNPCWalkCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::BeforeMovement;

	AMoonMarketCheese Cheese;
	

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if(PolymorphComp.ShapeshiftComp.ShapeshiftShape == nullptr)
			return false;

		if(Cast<AMoonMarketCheese>(PolymorphComp.ShapeshiftComp.ShapeshiftShape.CurrentShape) == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		if(PolymorphComp.ShapeshiftComp.ShapeshiftShape == nullptr)
			return true;
		
		if(PolymorphComp.ShapeshiftComp.ShapeshiftShape.CurrentShape != Cheese)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		Cheese = Cast<AMoonMarketCheese>(PolymorphComp.ShapeshiftComp.ShapeshiftShape.CurrentShape);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		Cheese = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);
		float RotationAmount = MoveDeltaThisFrame.VectorPlaneProject(FVector::UpVector).Size();
		float RotationSpeed = 2;
		Cheese.Cheese.AddLocalRotation(FRotator(-RotationAmount * RotationSpeed, 0, 0));
	}
};