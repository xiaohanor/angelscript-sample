
class UScifiCopsGunMoveToWallCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CopsGun");
	default CapabilityTags.Add(n"CopsGunThrow");
	default CapabilityTags.Add(n"CopsGunMovement");

	default DebugCategory = n"CopsGun";

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 94;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AScifiCopsGun Weapon;
	AHazePlayerCharacter Player;
	UScifiPlayerCopsGunManagerComponent Manager;
	UScifiPlayerCopsGunSettings Settings;

	FHazeAcceleratedQuat AcceleratedMovementOrientation;
	float OriginalDistToTarget = 0;
	float MaxMoveTime = 0;

	UScifiCopsGunThrowTargetableComponent OriginalThrowAtTarget;
	UScifiCopsGunShootTargetableComponent OriginalShootAtTarget;
	bool bHadShootAtTarget = false;
	bool bForcedToDeactivate = false;

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
		if(!Weapon.IsThrown())
			return false;

		if(!Weapon.CurrentMoveToTargetIsWall())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Weapon.IsThrown())
			return true;
			
		if(!Weapon.CurrentMoveToTargetIsWall())
			return true;

		if(bForcedToDeactivate)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Weapon.BlockCapabilities(n"CopsGunHeat", this);
		Weapon.UnblockCapabilities(n"CopsGunHeat", this);

		if(HasControl())
		{
			OriginalThrowAtTarget = Weapon.GetCurrentThrowAtTarget();	
			OriginalShootAtTarget = Weapon.CurrentShootAtTarget;
			bHadShootAtTarget = OriginalShootAtTarget != nullptr;

			const FVector StartLocation = Weapon.GetActorLocation();
			FVector EndLocation = Weapon.InternalMoveToTarget.WorldLocation;

			FQuat MoveDir = (EndLocation - StartLocation).ToOrientationQuat();
			float Offset = Weapon.AttachType == EScifiPlayerCopsGunType::Left ? -1 : 1;
			MoveDir *= FQuat::MakeFromEuler(FVector(0.0, 0.0, 25.0 * Offset));

			Weapon.CurrentMovementOrientation = MoveDir;
			OriginalDistToTarget = EndLocation.Distance(StartLocation);

			AcceleratedMovementOrientation.SnapTo(Weapon.CurrentMovementOrientation);
			Weapon.CurrentMovementSpeed = Settings.WeaponInitialSpeed;

			MaxMoveTime = OriginalDistToTarget / Settings.WeaponSpeedMax;

			//Debug::DrawDebugDirectionArrow(Weapon.ActorCenterLocation, MoveDir.ForwardVector, 500, Thickness = 6, LineColor = FLinearColor::Red, Duration = 2.0);
		}

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(Weapon.bHasReachedMoveToTarget)
		{
			Weapon.bHasReachedMoveToTarget = false;
			Manager.DetachWeaponFromThrowAtTarget(Weapon, this);
		}

		Weapon.MeshOffset.RelativeTransform = Weapon.OrignalMeshOffsetTransform;
		//Weapon.ClearTargetFromWeapon(EScifiPlayerCopsGunMovementState::WorldPosition, EScifiPlayerCopsGunMovementState::MovingBackToPlayer);

		AcceleratedMovementOrientation = FHazeAcceleratedQuat();
		OriginalDistToTarget = 0;
		OriginalThrowAtTarget = nullptr;
		OriginalShootAtTarget = nullptr;

		if(bForcedToDeactivate)
		{
			Manager.RecallWeapons(this);
			bForcedToDeactivate = false;
		}
		
		if(bHadShootAtTarget)
		{
			// Reload the weapon when we are returning to hand
			//Weapon.ReloadTimeLeft = Settings.ReloadTime;
			bHadShootAtTarget = false;
		}	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Weapon.bHasReachedMoveToTarget)
		{
			ApplyMovement(DeltaTime);
		}
		else
		{
			UpdateAttachment(DeltaTime);
		}

		// // DEBUG
		// {
		// 	auto ThrowAtTarget = Weapon.GetCurrentThrowAtTarget();
		// 	if(ThrowAtTarget != nullptr)
		// 	{
		// 		Debug::DrawDebugCoordinateSystem(ThrowAtTarget.WorldLocation, ThrowAtTarget.WorldRotation, 500.0);
		// 		Debug::DrawDebugCoordinateSystem(Weapon.ActorLocation, Weapon.ActorRotation, 500.0);
		// 	}
		// }
	}

	void ApplyMovement(float DeltaTime)
	{
		Weapon.ApplyMeshRotation(DeltaTime);


		if(HasControl())
		{
			const float ActiveAlpha = Math::Clamp(ActiveDuration - (MaxMoveTime * 0.5), 0, MaxMoveTime * 0.5) / (MaxMoveTime * 0.5);

			Weapon.CurrentMovementSpeed += Settings.BulletSpeedAcceleration * DeltaTime;
			Weapon.CurrentMovementSpeed = Math::Min(Weapon.CurrentMovementSpeed, Settings.WeaponSpeedMax);
			Weapon.CurrentTurnSpeed += DeltaTime * 2;
			const float MoveAmount = DeltaTime * Weapon.CurrentMovementSpeed;

			FVector EndLocation = Weapon.InternalMoveToTarget.WorldLocation;
			FVector DeltaToTarget = (EndLocation - Weapon.GetActorLocation());

			float RotationSpeed = Math::Min(OriginalDistToTarget / Settings.WeaponThrowDistance, 1.0);
			RotationSpeed = Math::Lerp(0.2, 1.0, RotationSpeed);
			OriginalDistToTarget = Math::Max(OriginalDistToTarget - (DeltaTime * 10), 0.0); 

			FVector DirToTarget = DeltaToTarget.GetSafeNormal();
			FQuat OrientationToTarget = DirToTarget.ToOrientationQuat();
			if(OriginalDistToTarget < KINDA_SMALL_NUMBER)
				AcceleratedMovementOrientation.SnapTo(OrientationToTarget);
			else
				AcceleratedMovementOrientation.AccelerateTo(OrientationToTarget, RotationSpeed, DeltaTime);

			{
				//const float MaxTimeUntilLockOn = 1;	
				Weapon.CurrentMovementOrientation = Math::LerpShortestPath(AcceleratedMovementOrientation.Value.Rotator(), OrientationToTarget.Rotator(), ActiveAlpha).Quaternion();
			}

			//Debug::DrawDebugDirectionArrow(Weapon.ActorCenterLocation, DirToTarget, 500, Thickness = 6, LineColor = FLinearColor::Red);
			//Debug::DrawDebugDirectionArrow(Weapon.ActorCenterLocation, Weapon.CurrentMovementOrientation.ForwardVector, 500, Thickness = 6);
			//Debug::DrawDebugSphere(EndLocation, LineColor = FLinearColor::Red);
			
			float DistanceToTarget = Math::Max(DeltaToTarget.Size() - ((Player.ScaledCapsuleRadius * 2) + MoveAmount), 0.0);

			// Check if it's time to trigger pre-impact audio
			if(Weapon.CanApplyAudioPreImpact(DistanceToTarget))
			{
				//PrintToScreenScaled("Pre-impact!", Duration = 1, Scale = 2);
				UScifiPlayerCopsGunEventHandler::Trigger_ThrowPreImpact(Player);
				Weapon.bHasTriggeredAudioPreImpact = true;
			}

			if(DistanceToTarget <= KINDA_SMALL_NUMBER && !Weapon.bHasReachedMoveToTarget)
			{
				const bool bShouldAttach = Math::Abs(Manager.TimeLeftUntilReturn) > KINDA_SMALL_NUMBER;
				CrumbApplyImpact(bShouldAttach);
				Weapon.SyncedMovement.Value = Weapon.GetActorLocation();
			}
			else
			{
				FVector MoveDirection = Weapon.CurrentMovementOrientation.ForwardVector;
				FVector TravelToPosition = Weapon.GetActorLocation() + (MoveDirection * MoveAmount);

				TravelToPosition = Math::Lerp(TravelToPosition, Weapon.GetActorLocation() + DeltaToTarget, ActiveAlpha);
				Weapon.SetActorLocation(TravelToPosition);
				Weapon.SyncedMovement.Value = TravelToPosition;
			}
		}
		else
		{
			Weapon.SetActorLocation(Weapon.SyncedMovement.Value);
		}		
	}

	void UpdateAttachment(float DeltaTime)
	{
		check(Weapon.bHasReachedMoveToTarget);

		//Debug::DrawDebugSphere(Weapon.ActorLocation);

		if(Manager.TimeLeftUntilReturn < KINDA_SMALL_NUMBER && Manager.TimeLeftUntilReturn >= 0)
		{
			ForceDeactivation();
			return;
		}

		float CurrentDistSqToPlayer = Player.ActorLocation.DistSquared(Weapon.ActorLocation);
		if(CurrentDistSqToPlayer < Weapon.MaxDistSqToPlayerAfterReachingTarget)
		{
			Weapon.PlayerLocationWhenReachingTarget = Player.ActorLocation;
			Weapon.MaxDistSqToPlayerAfterReachingTarget = CurrentDistSqToPlayer;
		}
		
		if(Settings.MaxDistanceFromThrowPositionUntilAutoRecal > 0 
			&& Player.ActorLocation.DistSquared(Weapon.PlayerLocationWhenReachingTarget) > Math::Square(Settings.MaxDistanceFromThrowPositionUntilAutoRecal))
		{
			ForceDeactivation();
		}

		// if(bHadShootAtTarget && Weapon.BulletsLeftToReload == 0)
		// 	ForceDeactivation();
		// else if(Weapon.WeaponWantsToReload())
		//	ForceDeactivation();
		if(OriginalThrowAtTarget == nullptr || OriginalThrowAtTarget.IsDisabledForPlayer(Player))
			ForceDeactivation();
		else if(bHadShootAtTarget && (OriginalShootAtTarget == nullptr || OriginalShootAtTarget.IsDisabledForPlayer(Player)))
			ForceDeactivation();
		
		// Update the targeting rotation of the weapons
		if(!bForcedToDeactivate)
		{
			// Temp offset until we have the correct mesh rotation
			FRotator TargetRotation = OriginalThrowAtTarget.WorldRotation;
			TargetRotation.Pitch -= 90.0;
			TargetRotation.Yaw += 180.0;  
			Weapon.MeshOffset.SetWorldRotation(TargetRotation);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbApplyImpact(bool bShouldAttach)
	{
		Weapon.bHasReachedMoveToTarget = true;
		Weapon.PlayerLocationWhenReachingTarget = Player.ActorLocation;
		Weapon.MaxDistSqToPlayerAfterReachingTarget = Player.ActorLocation.DistSquared(Weapon.ActorLocation);

		auto ThrowAtTarget = Weapon.GetCurrentThrowAtTarget();
		if(bShouldAttach)
		{		
			Weapon.AttachToComponent(ThrowAtTarget, NAME_None, 
				EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);

			Weapon.CurrentState = EScifiPlayerCopsGunState::AttachedToTarget;
			Weapon.MeshRotation.ResetRelativeTransform();
			Weapon.MeshOffset.ResetRelativeTransform();

			Weapon.SetActorRotation(ThrowAtTarget.WorldRotation);	

			FVector AttachLocation = ThrowAtTarget.WorldLocation;
			AttachLocation += ThrowAtTarget.WorldRotation.ForwardVector * 20;
			Weapon.SetActorLocation(AttachLocation);

			FScifiPlayerCopsGunWeaponAttachEventData AttachEvent;
			AttachEvent.Type = EScifiPlayerCopsGunWeaponAttachEventType::Wall;
			AttachEvent.ImpactLocation = Weapon.ActorLocation;
			
			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
			AttachEvent.PhysMat = AudioTrace::GetPhysMaterialFromLocation(ThrowAtTarget.WorldLocation, ThrowAtTarget.ForwardVector, TraceSettings);

			UScifiCopsGunEventHandler::Trigger_OnWeaponAttach(Weapon, AttachEvent);

			if(Weapon.CurrentState == Weapon.OtherWeapon.CurrentState)
			{
				Manager.CurrentAttachmentStatus = AttachEvent.Type;
				UScifiPlayerCopsGunEventHandler::Trigger_OnWeaponsAttach(Weapon.PlayerOwner, AttachEvent);
				Manager.ActivateTurret(ThrowAtTarget);
				Weapon.bHasTriggeredAudioPreImpact = false;
			}
		}

		Manager.AttachWeaponToThrowAtTarget(FScifiPlayerCopsGunImpact(Weapon.AttachType, ThrowAtTarget), this);
	}

	void ForceDeactivation()
	{
		bForcedToDeactivate = true;
	}
};
