class UGravityBikeMachineGunCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Input;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeWeaponUserComponent WeaponComp;
	UGravityBikeMachineGunComponent MachineGunComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Owner);
		WeaponComp = UGravityBikeWeaponUserComponent::Get(Owner);
		MachineGunComp = UGravityBikeMachineGunComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WeaponComp.HasEquipWeaponOfType(EGravityBikeWeaponType::MachineGun))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WeaponComp.HasEquipWeaponOfType(EGravityBikeWeaponType::MachineGun))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MachineGunComp.SpawnAndEquip();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MachineGunComp.UnequipAndDestroy();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MachineGunComp.AimTarget.IsHoming())
		{
			RotateTowardsTarget();
		}
		else
		{
			RotateTowardsForward(DeltaTime);
		}
	}
	
	private void RotateTowardsTarget()
	{
		FVector Direction = (MachineGunComp.AimTarget.GetWorldLocation() - MachineGunComp.MachineGun.ActorLocation).SafeNormal;
		Direction = Direction.ConstrainToCone(MachineGunComp.MachineGun.AttachParentActor.ActorForwardVector, Math::DegreesToRadians(90));
		FVector UpVector = MachineGunComp.MachineGun.AttachParentActor != nullptr ? MachineGunComp.MachineGun.AttachParentActor.ActorUpVector : MachineGunComp.MachineGun.ActorUpVector;
		FQuat Rotation = FQuat::MakeFromXZ(Direction, UpVector);
		MachineGunComp.MachineGun.SetActorRotation(Rotation);
	}

	private void RotateTowardsForward(float DeltaTime)
	{
		FRotator RelativeRotation = MachineGunComp.MachineGun.ActorRelativeRotation;
		RelativeRotation = Math::RInterpConstantShortestPathTo(RelativeRotation, FRotator::ZeroRotator, DeltaTime, 10);
		MachineGunComp.MachineGun.SetActorRelativeRotation(RelativeRotation);
	}
};