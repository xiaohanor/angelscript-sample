class UPirateShipFollowShipPlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerMovementComponent MoveComp;
	UCameraUserComponent CameraUserComp;
	
	APirateShip Ship;
	FRotator ShipRotationLastFrame;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MoveComp.IsOnAnyGround())
			return false;

		if(!Pirate::IsActorPartOfShip(MoveComp.GroundContact.Actor))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.IsOnAnyGround())
		{
			if(!Pirate::IsActorPartOfShip(MoveComp.GroundContact.Actor))
				return true;
		}

		if(Player.IsSwimming())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Ship = Pirate::GetShip();
		MoveComp.FollowComponentMovement(Pirate::GetShip().Root, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Low);
		ShipRotationLastFrame = Ship.ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.UnFollowComponentMovement(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator ShipRotation = Ship.ActorRotation;
		FRotator DeltaRotation = ShipRotation - ShipRotationLastFrame;

		DeltaRotation.Pitch = 0;
		DeltaRotation.Roll = 0;

		CameraUserComp.AddDesiredRotation(DeltaRotation, this);
		
		ShipRotationLastFrame = ShipRotation;
	}
};