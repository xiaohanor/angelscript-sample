class UIslandOverseerReturnGrenadePlayerCapability : UHazeCapability
{
	UIslandOverseerReturnGrenadePlayerComponent GrenadeComp;
	AHazePlayerCharacter Player;
	FHazeAcceleratedRotator AccRotation;

	default TickGroup = EHazeTickGroup::BeforeMovement;

	const float Multiplier = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrenadeComp = UIslandOverseerReturnGrenadePlayerComponent::GetOrCreate(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GrenadeComp.bReturnLeft)
			return true;
		if(GrenadeComp.bReturnRight)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > 1.2 * Multiplier)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		Owner.BlockCapabilities(CapabilityTags::MovementInput, this);
		Owner.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Owner.BlockCapabilities(IslandRedBlueWeapon::IslandRedBlueEquipped, this);
		AccRotation.SnapTo(Player.ActorRotation);
		Player.AddDamageInvulnerability(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);	
		Owner.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Owner.UnblockCapabilities(IslandRedBlueWeapon::IslandRedBlueEquipped, this);
		GrenadeComp.bReturnLeft = false;
		GrenadeComp.bReturnRight = false;
		GrenadeComp.bThrow = false;
		Player.Mesh.ClearLocomotionFeatureByInstigator(this);
		Player.RemoveDamageInvulnerability(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.Mesh.RequestLocomotion(n"BarrelThrow", this);

		FVector DirVector = Player.ViewRotation.RightVector;
		if(GrenadeComp.bReturnLeft)
			DirVector = -DirVector;
		AccRotation.AccelerateTo(DirVector.Rotation(), 0.5 * Multiplier, DeltaTime);
		Player.ActorRotation = AccRotation.Value;
	}
}