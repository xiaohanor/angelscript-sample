class UDeliveryRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DeliveryRotationCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ADeliveryMechanism Delivery;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Delivery = Cast<ADeliveryMechanism>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Delivery.bStartSplineMove)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Delivery.bStartSplineMove)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Delivery.MeshRoot.AddLocalRotation(FRotator(0.0, 0.0, Delivery.RotationSpeed * DeltaTime));
	}
}