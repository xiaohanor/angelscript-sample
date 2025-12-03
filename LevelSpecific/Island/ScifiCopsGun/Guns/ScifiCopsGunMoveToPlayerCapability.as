


class UScifiCopsGunMoveToPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CopsGun");
	default CapabilityTags.Add(n"CopsGunMovement");

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AScifiCopsGun Weapon;
	AHazePlayerCharacter Player;
	UScifiPlayerCopsGunManagerComponent Manager;
	UScifiPlayerCopsGunSettings Settings;
	//float OriginalDistToTarget = 0;
	float RotationAcceleration = 0;
	FQuat AcceleratedMovementOrientation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Weapon = Cast<AScifiCopsGun>(Owner);
		Player = Weapon.PlayerOwner;
		Manager = UScifiPlayerCopsGunManagerComponent::Get(Player);
		Settings = Weapon.Settings;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Weapon.IsRecalling())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Weapon.IsRecalling())
			return true;

		if(Weapon.bHasReachedMoveToTarget)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Weapon.BlockCapabilities(n"CopsGunHeat", this);
		Weapon.UnblockCapabilities(n"CopsGunHeat", this);

		//FScifiPlayerCopsGunWeaponTarget PlayerTarget;
		//PlayerTarget.Target = Player.Mesh;
		//Weapon.ApplyTargetToWeapon(PlayerTarget);
		//AcceleratedMovementOrientation.SnapTo(Weapon.CurrentMovementOrientation);
		AcceleratedMovementOrientation = Weapon.CurrentMovementOrientation;
		Weapon.CurrentMovementSpeed = Settings.WeaponInitialSpeed; // Restart the speed
		Weapon.bHasReachedMoveToTarget = false;

		float OriginalDistToTarget = Player.Mesh.WorldLocation.Distance(Weapon.ActorLocation);
		float RotationSpeedAlpha = Math::Min(OriginalDistToTarget / Settings.WeaponThrowDistance, 1.0);
		Weapon.CurrentTurnSpeed = Math::Lerp(20.0, 10.0, RotationSpeedAlpha);

		// // If the other weapon is not moving back to the player, we need to enforce that
		// if(Weapon.OtherWeapon.IsRecalling())
		// {
		// 	Weapon.OtherWeapon.BlockCapabilities(n"CopsGunMovement", this);
		// 	Weapon.OtherWeapon.UnblockCapabilities(n"CopsGunMovement", this);
		// }
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		//Weapon.ClearTargetFromWeapon(EScifiPlayerCopsGunMovementState::MovingBackToPlayer, EScifiPlayerCopsGunMovementState::Unset);
		Weapon.MeshRotationAmount = 0;
		Weapon.MeshRotation.SetRelativeRotation(FRotator::ZeroRotator);
		Manager.AttachWeaponToPlayerThigh(Weapon, this);
		Weapon.SetShootAtTarget(nullptr);
		Weapon.ClearMoveToTarget();
		Weapon.bHasReachedMoveToTarget = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			Weapon.CurrentMovementSpeed += Settings.BulletSpeedAcceleration * DeltaTime * Settings.TravelBackToPlayerAccelerationMultiplier;
			Weapon.CurrentMovementSpeed = Math::Min(Weapon.CurrentMovementSpeed, Settings.WeaponSpeedMax * Settings.TravelBackToPlayerMoveSpeedMultiplier);
			
			const float MoveAmount = DeltaTime * Weapon.CurrentMovementSpeed;
			FVector EndLocation = Weapon.InternalMoveToTarget.WorldLocation;
			FVector DeltaToTarget = (EndLocation - Weapon.GetActorLocation());



			// float RotationSpeed = Math::Min(OriginalDistToTarget / Settings.WeaponThrowDistance, 1.0);
			// RotationSpeed = Math::Lerp(0.1, 0.5, RotationSpeed);
			// OriginalDistToTarget = Math::Max(OriginalDistToTarget - (MoveAmount * 2.0), 0.0); 
			// RotationSpeed -=

			FVector DirToTarget = DeltaToTarget.GetSafeNormal();
			FQuat OrientationToTarget = DirToTarget.ToOrientationQuat();

			Weapon.CurrentMovementOrientation = Math::QInterpTo(Weapon.CurrentMovementOrientation, 
				OrientationToTarget, 
				DeltaTime, 
				Weapon.CurrentTurnSpeed);

			Weapon.CurrentTurnSpeed += Weapon.CurrentTurnSpeed * DeltaTime * 0.5;
			Weapon.CurrentTurnSpeed += DeltaTime * 2;

		
			// if(MoveAmount < KINDA_SMALL_NUMBER || RotationSpeed < 0)
			// 	AcceleratedMovementOrientation.SnapTo(OrientationToTarget);
			// else
			// 	AcceleratedMovementOrientation.AccelerateTo(OrientationToTarget, RotationSpeed + (ActiveDuration * 2.0), DeltaTime);
			// Weapon.CurrentMovementOrientation = AcceleratedMovementOrientation.Value;

			//Debug::DrawDebugDirectionArrow(Weapon.ActorCenterLocation, DirToTarget, 500, Thickness = 6, LineColor = FLinearColor::Red);
			//Debug::DrawDebugDirectionArrow(Weapon.ActorCenterLocation, Weapon.CurrentMovementOrientation.ForwardVector, 500, Thickness = 6);
			//Debug::DrawDebugSphere(EndLocation, LineColor = FLinearColor::Red);
			
			float DistanceToTarget = Math::Max(DeltaToTarget.Size() - ((Player.ScaledCapsuleRadius * 2) + MoveAmount), 0.0);
			if(DistanceToTarget <= KINDA_SMALL_NUMBER)
			{
				Weapon.bHasReachedMoveToTarget = true;
				//Weapon.ClearTargetFromWeapon(EScifiPlayerCopsGunMovementState::MovingBackToPlayer, EScifiPlayerCopsGunMovementState::Unset);
			}

			FVector MoveDirection = Weapon.CurrentMovementOrientation.ForwardVector;
			FVector TravelToPosition = Weapon.GetActorLocation() + (MoveDirection * MoveAmount);
			Weapon.SetActorLocation(TravelToPosition);

			Weapon.SyncedMovement.Value = TravelToPosition;
		}
		else
		{
			Weapon.SetActorLocation(Weapon.SyncedMovement.Value);
		}

		Weapon.ApplyMeshRotation(DeltaTime);	
	}				
}