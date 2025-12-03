

class UScifiCopsGunMoveToNothingAndBack : UHazeCapability
{
	default CapabilityTags.Add(n"CopsGun");
	default CapabilityTags.Add(n"CopsGunMovement");

	default DebugCategory = n"CopsGun";

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 96;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AScifiCopsGun Weapon;
	AHazePlayerCharacter Player;
	UScifiPlayerCopsGunManagerComponent Manager;
	UScifiPlayerCopsGunSettings Settings;

	float MovementLeftToDeactivation = 0;
	bool bForceDeactivationWithRecal = false;

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

		if(Weapon.HasMoveToTarget())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bForceDeactivationWithRecal)
			return true;
		
		if(!Weapon.IsThrown())
			return true;

		if(Weapon.HasMoveToTarget())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Weapon.BlockCapabilities(n"CopsGunHeat", this);
		Weapon.UnblockCapabilities(n"CopsGunHeat", this);

		const FVector StartLocation = Weapon.GetActorLocation();
		//Weapon.CurrentMovementState = EScifiPlayerCopsGunMovementState::WorldPosition;	

		if(HasControl())
		{
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

			MovementLeftToDeactivation = EndLocation.Distance(StartLocation);
			Weapon.CurrentMovementSpeed = Settings.WeaponInitialSpeed;
			Weapon.CurrentTurnSpeed = 1.0;

			//Debug::DrawDebugDirectionArrow(Player.ActorCenterLocation, MoveDir.ForwardVector, 500, Duration = 2.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(bForceDeactivationWithRecal)
		{
			Manager.RecallWeapons(this);
			bForceDeactivationWithRecal = false;
		}
		//Weapon.ClearTargetFromWeapon(EScifiPlayerCopsGunMovementState::WorldPosition, EScifiPlayerCopsGunMovementState::MovingBackToPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			Weapon.CurrentMovementSpeed += Settings.BulletSpeedAcceleration * DeltaTime;
			Weapon.CurrentMovementSpeed = Math::Min(Weapon.CurrentMovementSpeed, Settings.WeaponSpeedMax);
			Weapon.CurrentTurnSpeed += DeltaTime * 2;
			const float MoveAmount = DeltaTime * Weapon.CurrentMovementSpeed;
			MovementLeftToDeactivation -= MoveAmount;
			 
			FVector EndLocation = Weapon.InternalMoveToTarget.WorldLocation;
			FVector DirToTarget = (EndLocation - Weapon.GetActorLocation()).GetSafeNormal();

			FQuat OrientationToTarget = DirToTarget.ToOrientationQuat();
			Weapon.CurrentMovementOrientation = Math::QInterpTo(Weapon.CurrentMovementOrientation, 
				OrientationToTarget, 
				DeltaTime, 
				Weapon.CurrentTurnSpeed);

			//Debug::DrawDebugDirectionArrow(Weapon.ActorCenterLocation, DirToTarget, 500);
			// Debug::DrawDebugDirectionArrow(Weapon.ActorCenterLocation, Weapon.CurrentMovementOrientation.ForwardVector, 500);
			// Debug::DrawDebugSphere(EndLocation);

			FVector MoveDirection = Weapon.CurrentMovementOrientation.ForwardVector;
			FVector TravelToPosition = Weapon.GetActorLocation() + (MoveDirection * MoveAmount);
			Weapon.SetActorLocation(TravelToPosition);
	
			const float DistanceLeftToTarget = Weapon.ActorLocation.Distance(EndLocation);
			if(DistanceLeftToTarget < 100.0 || MovementLeftToDeactivation <= 0)
			{
				bForceDeactivationWithRecal = true;
				//Manager.RecallWeapons(this);
				//Weapon.ClearTargetFromWeapon(EScifiPlayerCopsGunMovementState::WorldPosition, EScifiPlayerCopsGunMovementState::MovingBackToPlayer);
			}
			
			Weapon.SyncedMovement.Value = Weapon.GetActorLocation();
		}
		else
		{
			Weapon.SetActorLocation(Weapon.SyncedMovement.Value);
		}

		Weapon.ApplyMeshRotation(DeltaTime);	
	}

};