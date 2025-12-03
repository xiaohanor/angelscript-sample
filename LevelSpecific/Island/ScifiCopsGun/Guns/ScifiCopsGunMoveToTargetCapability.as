struct FCopsGunMoveToTargetActivationParams
{
	UScifiCopsGunThrowTargetableComponent ThrowAtTarget;
}

class UScifiCopsGunMoveToTargetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CopsGun");
	default CapabilityTags.Add(n"CopsGunMovement");

	default DebugCategory = n"CopsGun";

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 95;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	const float KeepDistanceToTarget = 150.0;

	AScifiCopsGun Weapon;
	AHazePlayerCharacter Player;
	UScifiPlayerCopsGunManagerComponent Manager;
	UScifiPlayerCopsGunSettings Settings;

	UScifiCopsGunThrowTargetableComponent ThrowAtTarget;
	float MaxMoveTime = 0;
	
	FHazeAcceleratedQuat AcceleratedMovementOrientation;
	float OriginalDistToTarget = 0;
	bool bHasAttachedToTarget = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Weapon = Cast<AScifiCopsGun>(Owner);
		Player = Weapon.PlayerOwner;
		Manager = UScifiPlayerCopsGunManagerComponent::Get(Player);
		Settings = Weapon.Settings;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCopsGunMoveToTargetActivationParams& ActivationParams) const
	{
		if(!Weapon.IsThrown())
			return false;

		if(!Weapon.HasMoveToTarget())
			return false;

		if(Weapon.CurrentMoveToTargetIsWall())
			return false;
		
		ActivationParams.ThrowAtTarget = Weapon.GetCurrentThrowAtTarget();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Weapon.IsThrown())
			return true;

		if(!Weapon.HasMoveToTarget())
			return true;

		if(Weapon.CurrentMoveToTargetIsWall())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCopsGunMoveToTargetActivationParams ActivationParams)
	{
		Weapon.BlockCapabilities(n"CopsGunHeat", this);
		Weapon.UnblockCapabilities(n"CopsGunHeat", this);
		ThrowAtTarget = ActivationParams.ThrowAtTarget;

		if(HasControl())
		{
			const FVector StartLocation = Weapon.GetActorLocation();
			
			FVector EndLocation = Weapon.InternalMoveToTarget.WorldLocation;
			FVector WorldUp = Player.MovementWorldUp;

			auto GroundTraceSettings = Trace::InitChannel(Settings.TraceChannel);
			FVector TraceStart = EndLocation.VectorPlaneProject(WorldUp);
			TraceStart += Player.ActorCenterLocation.ProjectOnToNormal(WorldUp);
			auto HitResult = GroundTraceSettings.QueryTraceSingle(TraceStart, EndLocation);

			// Make sure the internal target is not under ground
			if(HitResult.bBlockingHit && !HitResult.bStartPenetrating)
			{
				EndLocation = HitResult.ImpactPoint;
				EndLocation += WorldUp * Player.GetScaledCapsuleHalfHeight();
				Weapon.InternalMoveToTarget.WorldLocation = EndLocation;		
			}	

			FQuat MoveDir = (EndLocation - StartLocation).ToOrientationQuat();
			float Offset = Weapon.AttachType == EScifiPlayerCopsGunType::Left ? -1 : 1;
			MoveDir *= FQuat::MakeFromEuler(FVector(0.0, 0.0, 25.0 * Offset));

			Weapon.CurrentMovementOrientation = MoveDir;
			AcceleratedMovementOrientation.SnapTo(Weapon.CurrentMovementOrientation);
			Weapon.CurrentMovementSpeed = Settings.WeaponInitialSpeed;
			Weapon.CurrentTurnSpeed = 1.0;
			OriginalDistToTarget = EndLocation.Distance(StartLocation);

			MaxMoveTime = OriginalDistToTarget / Settings.WeaponSpeedMax;

			//Debug::DrawDebugDirectionArrow(Player.ActorCenterLocation, MoveDir.ForwardVector, 500, Duration = 2.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(bHasAttachedToTarget)
		{
			bHasAttachedToTarget = false;
			Manager.DetachWeaponFromThrowAtTarget(Weapon, this);
		}

		ThrowAtTarget = nullptr;
		Weapon.bHasReachedMoveToTarget = false;
		AcceleratedMovementOrientation = FHazeAcceleratedQuat();

		// Reload the weapon when we are returning to hand
		//Weapon.ReloadTimeLeft = Math::Max(Settings.ReloadTime, KINDA_SMALL_NUMBER);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			const float ActiveAlpha = Math::Clamp(ActiveDuration - (MaxMoveTime * 0.5), 0, MaxMoveTime * 0.5) / (MaxMoveTime * 0.5);

			Weapon.CurrentMovementSpeed += Settings.BulletSpeedAcceleration * DeltaTime;
			Weapon.CurrentMovementSpeed = Math::Min(Weapon.CurrentMovementSpeed, Settings.WeaponSpeedMax);
			
			const float MoveAmount = DeltaTime * Weapon.CurrentMovementSpeed;
			FVector EndLocation = Weapon.InternalMoveToTarget.WorldLocation;
			FVector DeltaToTarget = (EndLocation - Weapon.GetActorLocation());

			const float DistanceLeftToTarget = Weapon.ActorLocation.Distance(EndLocation);
			if(!Weapon.bHasReachedMoveToTarget && DistanceLeftToTarget < MoveAmount)
			{
				const bool bShouldAttach = (Math::Abs(Manager.TimeLeftUntilReturn) > KINDA_SMALL_NUMBER 
					&& ThrowAtTarget.ReachedTargetMovementType == EScifiPlayerCopsGunTargetMovementType::None);
				CrumbReachTarget(bShouldAttach);
			}
			
			if(!Weapon.bHasReachedMoveToTarget)
			{
				Weapon.CurrentTurnSpeed = Math::Min(OriginalDistToTarget / Settings.WeaponThrowDistance, 1.0);
				Weapon.CurrentTurnSpeed = Math::Lerp(0.2, 1.0, Weapon.CurrentTurnSpeed);
				OriginalDistToTarget = Math::Max(OriginalDistToTarget - (DeltaTime * 10), 0.0); 

				FVector DirToTarget = DeltaToTarget.GetSafeNormal();
				FQuat OrientationToTarget = DirToTarget.ToOrientationQuat();
				if(OriginalDistToTarget < KINDA_SMALL_NUMBER)
					AcceleratedMovementOrientation.SnapTo(OrientationToTarget);
				else
					AcceleratedMovementOrientation.AccelerateTo(OrientationToTarget, Weapon.CurrentTurnSpeed, DeltaTime);

				Weapon.CurrentMovementOrientation = AcceleratedMovementOrientation.Value;
				Weapon.CurrentMovementOrientation = Math::LerpShortestPath(AcceleratedMovementOrientation.Value.Rotator(), OrientationToTarget.Rotator(), ActiveAlpha).Quaternion();
			}
			else if(ThrowAtTarget.ReachedTargetMovementType == EScifiPlayerCopsGunTargetMovementType::RotateAround)
			{
				Weapon.CurrentTurnSpeed = 5;
				FVector DirToTarget = (EndLocation - Weapon.GetActorLocation()).GetSafeNormal();
				FQuat OrientationToTarget = DirToTarget.ToOrientationQuat();
				Weapon.CurrentMovementOrientation = Math::QInterpTo(Weapon.CurrentMovementOrientation, 
					OrientationToTarget, 
					DeltaTime, 
					Weapon.CurrentTurnSpeed);
			}

			//Debug::DrawDebugDirectionArrow(Weapon.ActorCenterLocation, DirToTarget, 500);
			// Debug::DrawDebugDirectionArrow(Weapon.ActorCenterLocation, Weapon.CurrentMovementOrientation.ForwardVector, 500);
			// Debug::DrawDebugSphere(EndLocation);
			if(!bHasAttachedToTarget)
			{
				FVector MoveDirection = Weapon.CurrentMovementOrientation.ForwardVector;
				FVector TravelToPosition = Weapon.GetActorLocation() + (MoveDirection * MoveAmount);
				TravelToPosition = Math::Lerp(TravelToPosition, Weapon.GetActorLocation() + DeltaToTarget, ActiveAlpha);
				Weapon.SetActorLocation(TravelToPosition);	
				Weapon.SyncedMovement.Value = Weapon.GetActorLocation();
				Weapon.ApplyMeshRotation(DeltaTime);
			}

			if(Weapon.bHasReachedMoveToTarget)
			{		
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

				if(Manager.TimeLeftUntilReturn < KINDA_SMALL_NUMBER && Manager.TimeLeftUntilReturn >= 0)
				{
					ForceDeactivation();
				}

				// if(Weapon.WeaponWantsToReload())
				// 	ForceDeactivation();
			}

			if(ThrowAtTarget == nullptr || ThrowAtTarget.IsDisabledForPlayer(Player))
			{
				ForceDeactivation();
			}
		}
		else
		{
			Weapon.SetActorLocation(Weapon.SyncedMovement.Value);

			if(!bHasAttachedToTarget)
				Weapon.ApplyMeshRotation(DeltaTime);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbReachTarget(bool bShouldAttach)
	{
		Weapon.bHasReachedMoveToTarget = true;
		Weapon.PlayerLocationWhenReachingTarget = Player.ActorLocation;
		Weapon.MaxDistSqToPlayerAfterReachingTarget = Player.ActorLocation.DistSquared(Weapon.ActorLocation);

		if(bShouldAttach)
		{		
			bHasAttachedToTarget = true;
			Weapon.AttachToComponent(ThrowAtTarget, NAME_None, 
				EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
				
			Weapon.CurrentState = EScifiPlayerCopsGunState::AttachedToTarget;
			Weapon.MeshRotation.ResetRelativeTransform();
			Weapon.MeshOffset.ResetRelativeTransform();
			Weapon.SetActorLocation(ThrowAtTarget.GetWorldLocation() + (ThrowAtTarget.GetForwardVector() * 10));
			Weapon.SetActorRotation((-ThrowAtTarget.GetForwardVector()).ToOrientationRotator());

			FScifiPlayerCopsGunWeaponAttachEventData AttachEvent;
			AttachEvent.Type = EScifiPlayerCopsGunWeaponAttachEventType::Target;
			if(ThrowAtTarget.Type == EScifiPlayerCopsGunAttachTargetType::Hacking)
				AttachEvent.Type = EScifiPlayerCopsGunWeaponAttachEventType::Hackpoint;

			AttachEvent.ImpactLocation = Weapon.ActorLocation;
			AttachEvent.AttachTarget = ThrowAtTarget;
			UScifiCopsGunEventHandler::Trigger_OnWeaponAttach(Weapon, AttachEvent);

			// Both weapons are donw
			if(Weapon.CurrentState == Weapon.OtherWeapon.CurrentState)
			{
				Manager.CurrentAttachmentStatus = AttachEvent.Type;
				UScifiPlayerCopsGunEventHandler::Trigger_OnWeaponsAttach(Weapon.PlayerOwner, AttachEvent);
				Manager.ActivateTurret(AttachEvent.AttachTarget);
			}
		}

		Manager.AttachWeaponToThrowAtTarget(FScifiPlayerCopsGunImpact(Weapon.AttachType, ThrowAtTarget), this);	
	}

	void ForceDeactivation()
	{
		Manager.bForceRecal = true;	
	}
};
