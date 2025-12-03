class UPirateShipMooredCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 0;

	APirateShip PirateShip;
	UPirateShipMovementComponent MoveComp;
	UPirateWaterHeightComponent WaterHeightComp;
	FVector InitialForward;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PirateShip = Cast<APirateShip>(Owner);
		MoveComp = UPirateShipMovementComponent::Get(Owner);
		WaterHeightComp = UPirateWaterHeightComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PirateShip.CanShipMove())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PirateShip.CanShipMove())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		InitialForward = PirateShip.ActorForwardVector.VectorPlaneProject(FVector::UpVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector UpVector = WaterHeightComp.GetWaterUpVector();
		FQuat WaterRotation = FQuat::MakeFromZX(UpVector, InitialForward);

		MoveComp.AccWaterRotation.SpringTo(WaterRotation, Pirate::Ship::SpringStiffness, Pirate::Ship::SpringDamping, DeltaTime);
		MoveComp.ApplyMoveDelta(FVector::ZeroVector, MoveComp.AccWaterRotation.Value);
	}
};