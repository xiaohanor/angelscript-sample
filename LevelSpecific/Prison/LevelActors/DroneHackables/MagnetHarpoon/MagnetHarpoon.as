event void FMagnetGunAttachEvent();
event void FMagnetGunDetachEvent();

enum EMagnetHarpoonState
{
	Aim,
	Launched,
	Attached,
	Retracting
};

struct FMagnetHarpoonAttachData
{
	private bool bHasHit = false;
	private bool bCanAttach = false;

	private AActor Actor_Internal;
	private FVector ImpactPoint_Internal;
	private FVector ImpactNormal;

	FMagnetHarpoonAttachData(FHitResult HitResult)
	{
		if(!HitResult.bBlockingHit)
			return;

		bHasHit = true;

		if(!HitResult.Component.HasTag(ComponentTags::MagnetHarpoonHittable))
			return;

		Actor_Internal = HitResult.Actor;
		ImpactPoint_Internal = HitResult.ImpactPoint;
		ImpactNormal = HitResult.ImpactNormal;

		bCanAttach = true;
	}

	void Invalidate()
	{
		bHasHit = false;
		bCanAttach = false;
	}

	bool HasHit() const
	{
		return bHasHit;
	}

	bool CanAttach() const
	{
		if(!HasHit())
			return false;

		return bCanAttach;
	}

	AActor GetActor() const property
	{
		return Actor_Internal;
	}

	FVector GetImpactPoint() const property
	{
		return ImpactPoint_Internal;
	}

	FVector GetImpactNormal() const
	{
		return ImpactNormal;
	}
}

UCLASS(Abstract)
class AMagnetHarpoon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = BaseComp)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UCableComponent CableComp;
	default CableComp.SolverIterations = 30;
	default CableComp.SubstepTime = 0.005;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent HarpoonRoot;

	UPROPERTY(DefaultComponent, Attach = HarpoonRoot)
	UHazeSphereCollisionComponent HarpoonDeathVol;

	UPROPERTY(DefaultComponent, Attach = HarpoonRoot)
	UHazeCameraComponent ZoeCameraComp;

	UPROPERTY()
	bool bRemoveTutorial;

	UPROPERTY(DefaultComponent, Attach = HarpoonRoot)
	UCapsuleComponent TraceCapsule;

	UPROPERTY(DefaultComponent, Attach = BaseComp) 
	USwarmDroneHijackTargetableComponent HijackTargetableComp;

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagneticSurfaceComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UMagnetHarpoonAimCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMagnetHarpoonAttachedCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMagnetHarpoonCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMagnetHarpoonLaunchedCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMagnetHarpoonRetractingCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMagnetHarpoonEnableMagnetsCapability);

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedAimRotator;
	default SyncedAimRotator.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 17000;

	UPROPERTY(EditDefaultsOnly)
	FAimingSettings AimSettings;
	default AimSettings.bShowCrosshair = true;
	default AimSettings.bUseAutoAim = false;

	UPROPERTY(EditDefaultsOnly)
	UPlayerAimingSettings CrosshairSettings;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> LaunchCameraShake;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> RetractCameraShake;

	UPROPERTY(EditDefaultsOnly)
	float LeftClamp = 12;

	UPROPERTY(EditDefaultsOnly)
	float RightClamp = 12;

	UPROPERTY(EditDefaultsOnly)
	float MaxPitch = 0.0;

	UPROPERTY(EditDefaultsOnly)
	float MinPitch = -15.0;

	UPROPERTY(EditDefaultsOnly)
	float AimSpeed = 20.0;

	UPROPERTY(EditDefaultsOnly)
	float LaunchSpeed = 30000.0;

	UPROPERTY(EditDefaultsOnly)
	float AutoRetractDistance = 15000.0;

	UPROPERTY(EditDefaultsOnly)
	float RegularFOVOffset = -15;

	UPROPERTY(EditDefaultsOnly)
	float ZoomFOVOffset = -42.0;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> ImpactDeathEffect;

	EMagnetHarpoonState State;
	FMagnetHarpoonAttachData AttachData;
	FVector DefaultHarpoonRelativeLocation;
	bool bHasLetGoOfPrimary = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Drone::SwarmDronePlayer);

		DefaultHarpoonRelativeLocation = HarpoonRoot.RelativeLocation;
		
		MagneticSurfaceComp.OnMagnetDroneAttached.AddUFunction(this, n"MagnetDroneAttach");
		MagneticSurfaceComp.OnMagnetDroneDetached.AddUFunction(this, n"MagnetDroneDetached");

		HarpoonDeathVol.OnComponentBeginOverlap.AddUFunction(this, n"DeathVolOverlap");
	}

	UFUNCTION()
	private void DeathVolOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                             UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                             const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		if (State == EMagnetHarpoonState::Launched)
		{
			
			FVector ImpactDirection = HarpoonDeathVol.WorldLocation - Player.ActorLocation;
			ImpactDirection.Normalize();

			Player.KillPlayer(FPlayerDeathDamageParams(ImpactDirection,2.5,false),ImpactDeathEffect);
		}
	}

	UFUNCTION()
	private void MagnetDroneAttach(FOnMagnetDroneAttachedParams Params)
	{
	//	Params.Player.ActivateCamera(ZoeCameraComp,1,this,EHazeCameraPriority::Medium);
	}

	UFUNCTION()
	private void MagnetDroneDetached(FOnMagnetDroneDetachedParams Params)
	{
	//	Params.Player.DeactivateCamera(ZoeCameraComp);
	}


	UFUNCTION(BlueprintCallable)
	void ForceRetractHarpoon()
	{
		if(State == EMagnetHarpoonState::Launched || State == EMagnetHarpoonState::Attached)
			State = EMagnetHarpoonState::Retracting;
	}

	FVector GetDefaultHarpoonWorldLocation() const property
	{
		return RotationRoot.WorldTransform.TransformPositionNoScale(DefaultHarpoonRelativeLocation);
	}
}