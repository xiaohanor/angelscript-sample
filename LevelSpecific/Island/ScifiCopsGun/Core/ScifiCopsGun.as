
UCLASS(Abstract)
class AScifiCopsGun : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshOffset;

	UPROPERTY(DefaultComponent, Attach = MeshOffset)
	USceneComponent MeshRotation;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent InternalMoveToTarget;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedMovement;
	default SyncedMovement.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;

	UPROPERTY(DefaultComponent, Attach = MeshRotation)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent MuzzlePoint;
	
	UPROPERTY(EditConst)
	EScifiPlayerCopsGunType AttachType = EScifiPlayerCopsGunType::MAX;

	UPROPERTY(EditConst)
	FName AttachSocket = NAME_None;

	UPROPERTY(EditConst)
	EScifiPlayerCopsGunState CurrentState = EScifiPlayerCopsGunState::MAX;

	UPROPERTY(EditConst)
	float CurrentStateActivationTime = 0.0;

	UPROPERTY(EditConst)
	TArray<FInstigator> UsageBlocked;

	// UPROPERTY(EditConst)
	// bool bIsReloading = false;

	UPROPERTY(EditConst)
	bool bIsShooting = false;

	AHazePlayerCharacter PlayerOwner;
	UScifiPlayerCopsGunSettings Settings;
	AScifiCopsGun OtherWeapon;
	float MeshRotationAmount = 0;

	FVector OriginalScale = FVector::OneVector;

	FQuat CurrentMovementOrientation = FQuat::Identity;
	float CurrentMovementSpeed = 0;
	float CurrentTurnSpeed = 0;

	float LastShotGameTime = 0;
	bool bHasReachedMoveToTarget = false;
	float MaxDistSqToPlayerAfterReachingTarget = 0;
	FVector PlayerLocationWhenReachingTarget = FVector::ZeroVector;

	private USceneComponent CurrentMoveToTargetInternal = nullptr;
	private UScifiCopsGunShootTargetableComponent CurrentShootAtTargetInternal = nullptr;

	FTransform OrignalMeshOffsetTransform;

	UPROPERTY(EditDefaultsOnly)
	float AudioPreImpactTriggerDistance = 1000.0;
	bool bHasTriggeredAudioPreImpact = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OrignalMeshOffsetTransform = MeshOffset.GetRelativeTransform();
		OriginalScale = GetActorRelativeScale3D();
		FHazeActorSizeChangeDelegate OnSizeChange;
		OnSizeChange.BindUFunction(this, n"OnSizeChange");
		BindToOnSizeChange(OnSizeChange);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSizeChange(USceneComponent InComponent)
	{
		// Since the copsgun get attached to stuf, it can change
		// size... so we always enforce it to be the original size
		if(!GetActorRelativeScale3D().Equals(OriginalScale))
		{
			SetActorRelativeScale3D(OriginalScale);
		}
	}

	bool IsLeftWeapon() const
	{
		return AttachType == EScifiPlayerCopsGunType::Left;
	}

	bool IsRightWeapon() const
	{
		return AttachType == EScifiPlayerCopsGunType::Right;
	}

	// bool WeaponWantsToReload() const
	// {
	// 	return bIsReloading || ReloadTimeLeft > 0;
	// }

	bool IsWeaponBlocked() const
	{
		return UsageBlocked.Num() > 0;
	}

	bool IsWeaponAttachedToPlayerHand() const
	{
		return CurrentState == EScifiPlayerCopsGunState::AttachToHand;
	}

	bool IsWeaponAttachedToPlayerThigh() const
	{
		return CurrentState == EScifiPlayerCopsGunState::AttachToThigh;
	}

	bool IsWeaponAttachedToPlayer() const
	{
		return IsWeaponAttachedToPlayerHand() || IsWeaponAttachedToPlayerThigh();
	}

	bool IsWeaponAttachedToTarget() const
	{
		return CurrentState == EScifiPlayerCopsGunState::AttachedToTarget;
	}

	bool IsThrown() const
	{
		return CurrentState == EScifiPlayerCopsGunState::MovingToTarget || CurrentState == EScifiPlayerCopsGunState::AttachedToTarget;
	}

	bool IsRecalling() const
	{
		return CurrentState == EScifiPlayerCopsGunState::Recalled;
	}

	bool IsInAir() const
	{
		if(CurrentState == EScifiPlayerCopsGunState::Recalled)
			return true;

		if(CurrentState == EScifiPlayerCopsGunState::MovingToTarget)
			return true;

		return false;
	}

	float GetInAirTime() const
	{
		if(!IsInAir())
			return 0;
		return Time::GetGameTimeSince(CurrentStateActivationTime);
	}
	
	bool HasMoveToTarget() const
	{
		if(CurrentState != EScifiPlayerCopsGunState::MovingToTarget 
		&& CurrentState != EScifiPlayerCopsGunState::AttachedToTarget)
			return false;

		if(CurrentMoveToTargetInternal == nullptr)
			return false;		

		return true;
	}

	bool CurrentMoveToTargetIsWall() const
	{
		if(CurrentMoveToTargetInternal == nullptr)
			return false;
		
		if(!CurrentMoveToTargetInternal.IsA(UScifiCopsGunInternalEnvironmentThrowTargetableComponent))
			return false;

		return true;
	}

	bool CanApplyAudioPreImpact(const float DistanceToTarget)
	{
		return IsLeftWeapon() && !bHasTriggeredAudioPreImpact && DistanceToTarget <= AudioPreImpactTriggerDistance;
	}

	void MoveWeaponToTarget(FScifiPlayerCopsGunWeaponTarget TargetData)
	{
		auto Target = TargetData.Target;
		bHasReachedMoveToTarget = false;
		CurrentState = EScifiPlayerCopsGunState::MovingToTarget;
		CurrentStateActivationTime = Time::GetGameTimeSeconds();

		auto ThrowAtTarget = Cast<UScifiCopsGunThrowTargetableComponent>(Target);
		if(ThrowAtTarget != nullptr)
		{
			InternalMoveToTarget.SetAbsolute(false, false, false);
			InternalMoveToTarget.AttachToComponent(ThrowAtTarget);
			InternalMoveToTarget.WorldLocation = ThrowAtTarget.WorldLocation;
			CurrentMoveToTargetInternal = ThrowAtTarget;
			SetShootAtTarget(ThrowAtTarget.GetLinkedShootAtTarget());
		}

		// Move to world position
		else
		{
			InternalMoveToTarget.SetAbsolute(true, true, false);
			InternalMoveToTarget.AttachToComponent(Root);
			InternalMoveToTarget.WorldLocation = TargetData.WorldLocation;
			CurrentMoveToTargetInternal = nullptr;
			SetShootAtTarget(nullptr);
		}
	}

	void RecallInternal()
	{
		FScifiPlayerCopsGunWeaponRecallEventData RecallEvent;
		
		InternalMoveToTarget.SetAbsolute(false, false, false);
		InternalMoveToTarget.AttachToComponent(PlayerOwner.Mesh, AttachSocket);
		InternalMoveToTarget.RelativeLocation = FVector::ZeroVector;

		RecallEvent.HandLocation = InternalMoveToTarget.WorldLocation;
		RecallEvent.bRecalledWhileInAir = IsInAir();

		CurrentState = EScifiPlayerCopsGunState::Recalled;
		CurrentStateActivationTime = Time::GetGameTimeSeconds();
		CurrentMoveToTargetInternal = PlayerOwner.Mesh;
		SetShootAtTarget(nullptr);

		UScifiCopsGunEventHandler::Trigger_OnRecall(this, RecallEvent);
	}

	void ClearMoveToTarget()
	{
		CurrentMoveToTargetInternal = nullptr;
	}

	float GetDistanceToCurrentTarget() const
	{
		if(CurrentMoveToTargetInternal == nullptr)
			return -1;

		return CurrentMoveToTargetInternal.GetWorldLocation().Distance(ActorLocation);
	}

	AActor GetAttachedToActor() const
	{
		if(CurrentState != EScifiPlayerCopsGunState::AttachedToTarget)
			return nullptr;

		if(CurrentMoveToTargetInternal == nullptr)
			return nullptr;

		return CurrentMoveToTargetInternal.Owner;
	}

	void SetShootAtTarget(UScifiCopsGunShootTargetableComponent Target)
	{
		if(CurrentShootAtTargetInternal != Target)
			CurrentShootAtTargetInternal = Target;
	}

	void ApplyMeshRotation(float DeltaTime)
	{
		float Dir = AttachType == EScifiPlayerCopsGunType::Left ? 1.0 : -1.0;
		MeshRotationAmount += DeltaTime * 1600 * Dir;
		MeshRotation.SetWorldRotation(FRotator( 0.0, MeshRotationAmount, 0.0));	
	}

	UScifiCopsGunThrowTargetableComponent GetCurrentThrowAtTarget() const
	{
		return Cast<UScifiCopsGunThrowTargetableComponent>(CurrentMoveToTargetInternal);
	}

	USceneComponent GetCurrentMoveToTarget() const
	{
		return CurrentMoveToTargetInternal;
	}

	UScifiCopsGunShootTargetableComponent GetCurrentShootAtTarget() const property
	{
		return CurrentShootAtTargetInternal;
	}
}

UCLASS(Abstract)
class AScifiCopsGunBullet : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// [LUCAS]: No longer supported, but shield buster is gone anyway
	//UPROPERTY(DefaultComponent)
	//UHazeMovementZoneResponseComponent MovementZoneResponseComponent;

	UScifiPlayerCopsGunSettings Settings;
	EScifiPlayerCopsGunType WeaponInstigator = EScifiPlayerCopsGunType::MAX;
	float ActivationTime = 0;
	FVector MoveDirection = FVector::ZeroVector;
	float CurrentMovementSpeed = 0;
	ECopsGunBulletMoveType MoveType;

	FScifiPlayerCopsGunImpact MovementImpact;
	UScifiCopsGunShootTargetableComponent PendingImpactTarget;
	TArray<AActor> MovementIgnoreActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//MovementZoneResponseComponent.OnPlayerEnter.AddUFunction(this, n"OnZoneEnter");
		//MovementZoneResponseComponent.OnPlayerLeave.AddUFunction(this, n"OnZoneExit");
	}

	/*UFUNCTION(NotBlueprintCallable)
	void OnZoneEnter(UHazeMovementZoneComponentBase Zone)
	{
		auto ShieldBusterZone = Cast<UScifiShieldBusterInteralWallCutterComponent>(Zone);
		if(ShieldBusterZone != nullptr)
		{
			MovementIgnoreActors.Add(ShieldBusterZone.GetEnergyWall());
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnZoneExit(UHazeMovementZoneComponentBase Zone)
	{
		auto ShieldBusterZone = Cast<UScifiShieldBusterInteralWallCutterComponent>(Zone);
		if(ShieldBusterZone != nullptr)
		{
			MovementIgnoreActors.RemoveSingleSwap(ShieldBusterZone.GetEnergyWall());
		}
	}*/

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		MoveDirection = FVector::ZeroVector;
		CurrentMovementSpeed = 0;
		MovementImpact = FScifiPlayerCopsGunImpact();
		PendingImpactTarget = nullptr;
		WeaponInstigator = EScifiPlayerCopsGunType::MAX;
	}

	void Move(float DeltaTime)
	{
		const float MoveSpeedMax = Settings.BulletSpeedMax;
		const float Acc = Settings.BulletSpeedAcceleration * DeltaTime;
		CurrentMovementSpeed = Math::Min(CurrentMovementSpeed + Acc, MoveSpeedMax);
		
		FVector CurrentLocation = GetActorLocation();
		if(MoveType == ECopsGunBulletMoveType::Seeking)
		{
			FVector MoveDir = PendingImpactTarget.GetWorldLocation() - CurrentLocation;
			if(MoveDir.SizeSquared() > KINDA_SMALL_NUMBER)
				MoveDirection = MoveDir.GetSafeNormal();
		}
		FVector Velocity = MoveDirection * CurrentMovementSpeed;
		FVector PendingLocation = CurrentLocation + (Velocity * DeltaTime);

		auto TraceSettings = Trace::InitChannel(Settings.TraceChannel);
		TraceSettings.IgnoreActors(MovementIgnoreActors);
		TraceSettings.SetReturnPhysMaterial(true);
		//TraceSettings.DebugDrawOneFrame();

		FHitResult HitResult = TraceSettings.QueryTraceSingle(CurrentLocation, PendingLocation);
		if(HitResult.bBlockingHit)
		{
			SetActorLocation(HitResult.Location);
			FVector ToBullet = CurrentLocation - PendingLocation;
			MovementImpact = FScifiPlayerCopsGunImpact(WeaponInstigator, HitResult, PendingImpactTarget, ToBullet, TraceSettings);
			return;
		}
		
		SetActorLocation(PendingLocation);
	}

	void Reset()
	{
		MoveType = ECopsGunBulletMoveType::Direction;
	}

	bool HasImpact() const
	{
		return MovementImpact.bIsValid;
	}
}

struct FScifiPlayerCopsGunImpact
{
	EScifiPlayerCopsGunType Gun = EScifiPlayerCopsGunType::MAX;
	bool bIsValid = false;
	FVector ImpactLocation;
	FVector ImpactNormal;
	FVector Direction;
	AActor Actor;
	private UScifiCopsGunShootTargetableComponent CustomBulletTarget;
	private UScifiCopsGunThrowTargetableComponent CustomWeaponTarget;
	UPhysicalMaterial PhysMat;

	FScifiPlayerCopsGunImpact()
	{

	}

	FScifiPlayerCopsGunImpact(EScifiPlayerCopsGunType InFromGun, FHitResult FromHitResult, UScifiCopsGunShootTargetableComponent CustomTarget, FVector ToBullet, FHazeTraceSettings TraceSettings)
	{
		if(FromHitResult.bBlockingHit && FromHitResult.Actor != nullptr)
		{
			bIsValid = true;
			Gun = InFromGun;
			ImpactLocation = FromHitResult.ImpactPoint;
			ImpactNormal = FromHitResult.ImpactNormal;
			Actor = FromHitResult.Actor;
			CustomBulletTarget = CustomTarget;;
			Direction = ToBullet;

			// Get PhysMat for audio
			if(FromHitResult.PhysMaterial == nullptr)
				PhysMat = AudioTrace::GetPhysMaterialFromHit(FromHitResult, TraceSettings);
			else
				PhysMat = FromHitResult.PhysMaterial;				
		}
	}

	FScifiPlayerCopsGunImpact(EScifiPlayerCopsGunType InFromGun, FHitResult FromHitResult, UScifiCopsGunShootTargetableComponent CustomTarget)
	{
		if(FromHitResult.bBlockingHit && FromHitResult.Actor != nullptr)
		{
			bIsValid = true;
			Gun = InFromGun;
			ImpactLocation = FromHitResult.ImpactPoint;
			ImpactNormal = FromHitResult.ImpactNormal;
			Actor = FromHitResult.Actor;
			CustomBulletTarget = CustomTarget;
			PhysMat = FromHitResult.PhysMaterial;
		}
	}

	FScifiPlayerCopsGunImpact(EScifiPlayerCopsGunType InFromGun, UScifiCopsGunThrowTargetableComponent CustomTarget)
	{
		if(CustomTarget != nullptr)
		{
			bIsValid = true;
			Gun = InFromGun;
			ImpactLocation = CustomTarget.WorldLocation;
			ImpactNormal = FVector::UpVector;
			Actor = CustomTarget.Owner;
			CustomWeaponTarget = CustomTarget;
		}
	}

	UScifiCopsGunShootTargetableComponent GetBulletTarget() const property
	{
		if(CustomBulletTarget != nullptr)
			return CustomBulletTarget;
		else if(Actor == nullptr)
			return nullptr;
		else
			return UScifiCopsGunShootTargetableComponent::Get(Actor);
	}

	UScifiCopsGunThrowTargetableComponent GetWeaponTarget() const property
	{
		if(CustomWeaponTarget != nullptr)
			return CustomWeaponTarget;
		else if(Actor == nullptr)
			return nullptr;
		else
			return UScifiCopsGunThrowTargetableComponent::Get(Actor);
	}
}

struct FCopsGunShootCapabilityActivationParams
{
	AScifiCopsGunBullet Bullet;
	FVector ShootDir;
	UScifiCopsGunShootTargetableComponent Target;
	float HeatIncrease = 0;
}

// struct FCopsGunBulletImpactParams
// {
// 	ECopsGunBulletImpactType ImpactType = ECopsGunBulletImpactType::Default;
// }

// enum ECopsGunBulletImpactType
// {
// 	Default,
// 	InstaKill
// }

enum ECopsGunBulletMoveType
{
	Direction,
	Seeking
}