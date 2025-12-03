namespace HackableSniperTurret
{
	const FName CooldownInstigator = n"CooldownInstigator";
}

struct FHackableSniperTurretHitEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector TraceDirection;
	
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactNormal;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactPoint;
}

event void FHackableSniperTurretHitEvent(FHackableSniperTurretHitEventData EventData);

struct FHackableSniperTurretFireEventData
{
	UPROPERTY(BlueprintReadOnly)
	bool bHit;
}

event void FHackableSniperTurretFireEvent(FHackableSniperTurretFireEventData EventData);

event void FHackableSniperTurretZoomEvent();

class UHackableSniperTurretResponseComponent : UActorComponent
{
	UPROPERTY()
	FHackableSniperTurretHitEvent OnHackableSniperTurretHit;
}

UCLASS(Abstract)
class AHackableSniperTurret : AHazeActor
{
	const bool DEBUG_DRAW = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = BaseComp)
	USceneComponent YawRoot;

	UPROPERTY(DefaultComponent, Attach = YawRoot)
	USceneComponent StartUpPitchRoot;

	UPROPERTY(DefaultComponent, Attach = StartUpPitchRoot)
	USceneComponent PitchRoot;

	UPROPERTY(DefaultComponent, Attach = PitchRoot)
	USceneComponent PitchWiggleRoot;

	UPROPERTY(DefaultComponent, Attach = PitchWiggleRoot)
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent, Attach = PitchRoot)
	UArrowComponent MuzzleComp;

	UPROPERTY(DefaultComponent)
	USwarmDroneHijackTargetableComponent HijackTargetableComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(HackableSniperTurretSheet);

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent PlayerCapabilityRequestComponent;
	default PlayerCapabilityRequestComponent.InitialStoppedSheets_Mio.Add(HackableSniperTurretPlayerDeactivationSheet);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedDistanceAlongSpline;
	default SyncedDistanceAlongSpline.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedAimRotation;
	default SyncedAimRotation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> KillZoeDeathEffect;

	UPROPERTY(EditAnywhere)
	float Range = 100000;

	UPROPERTY(EditAnywhere)
	float ReloadTime = 1;

	UPROPERTY(EditAnywhere, Category = "Spline")
	ASplineActor SplineToFollow;

	UPROPERTY(EditAnywhere, Category = "Spline")
	float MoveAlongSplineSpeed = 15.0;

	UPROPERTY(EditAnywhere, Category = "Spline")
	bool bFollowSplineRotation = true;

	UPROPERTY(EditAnywhere, Category = "Spline", meta = (EditCondition = "bFollowSplineRotation"))
	bool bCompensateRotationOnTurret = true;
	FQuat RelativeRotationToSpline;

	UPROPERTY(EditAnywhere, Category = "Spline")
	float MovementAccelerateSpeed = 4.0;

	UPROPERTY(EditDefaultsOnly)
	FAimingSettings AimSettings;
	default AimSettings.bShowCrosshair = true;
	default AimSettings.bUseAutoAim = true;
	default AimSettings.OverrideAutoAimTarget = UHackableSniperTurretTargetComponent;

	UPROPERTY(EditDefaultsOnly)
	FPostProcessSettings PostProcessSettings;

	UPROPERTY(EditDefaultsOnly)
	UPlayerAimingSettings CrosshairSettings;

	UPROPERTY(EditAnywhere, Category = "Aiming")
	float MaxYaw = 170.0;

	UPROPERTY(EditAnywhere, Category = "Aiming")
	float MaxPitch = 65.0;

	UHackableSniperTurretResponseComponent CurrentResponseComp;

	UPROPERTY(EditAnywhere, Category = "Aiming")
	float CameraSensitivity = 1.0;

	UPROPERTY(EditAnywhere, Category = "Aiming")
	float AimFOV = 60.0;

	UPROPERTY(EditAnywhere, Category = "Aiming")
	bool bDrawLaserPointer = false;
	
	UPROPERTY(EditAnywhere, Category = "Aiming|Zoom")
	float ZoomedFOV = 15.0;

	UPROPERTY(EditAnywhere, Category = "Aiming|Zoom")
	float ZoomedSensitivityMultiplier = 0.25;

	UPROPERTY(EditAnywhere, Category = "Audio")
	FSoundDefReference SoundDef;

	UPROPERTY(BlueprintReadOnly)
	FHazeAcceleratedFloat ZoomAlpha;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AHackableSniperTurretProjectile> ProjectileClass;
	AHackableSniperTurretProjectile CurrentProjectile;

	const float FOV_BLENDTIME = 0.5;
	float HackedDuration;

	UPlayerAimingComponent AimingComp;

	UPROPERTY()
	FSwarmHijackStartEvent OnHackingStarted;
	UPROPERTY()
	FSwarmHijackStopEvent OnHackingStopped;

	// Widget Params

	UPROPERTY(BlueprintReadOnly)
	float DistanceToTarget;

	UFUNCTION(BlueprintPure)
	bool GetJustFired() const property{ return FiredFrame == Time::FrameNumber;}
	uint FiredFrame = 0;

	UPROPERTY(BlueprintReadOnly)
	bool bIsReloading;

	UPROPERTY(BlueprintReadOnly)
	FHackableSniperTurretFireEvent OnSniperTurretFire;

	UPROPERTY(BlueprintReadOnly)
	bool bIsZooming;

	bool bHasZoomed = true;

	bool bCanMove = true;

	UPROPERTY(BlueprintReadOnly)
	FHackableSniperTurretZoomEvent OnSniperTurretStartZoom;
	UPROPERTY(BlueprintReadOnly)
	FHackableSniperTurretZoomEvent OnSniperTurretEndZoom;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Drone::SwarmDronePlayer);

		HijackTargetableComp.OnHijackStartEvent.AddUFunction(this, n"HackingStarted");
		HijackTargetableComp.OnHijackStopEvent.AddUFunction(this, n"HackingStopped");

		SyncedDistanceAlongSpline.SetValue(SplineToFollow.Spline.GetClosestSplineDistanceToWorldLocation(GetActorLocation()));

		FTransform SplineTransform = SplineToFollow.Spline.GetWorldTransformAtSplineDistance(SyncedDistanceAlongSpline.GetValue());
		RelativeRotationToSpline = FQuat(SplineTransform.InverseTransformRotation(GetActorRotation()));

		MoveToSplineAtDistance(SyncedDistanceAlongSpline.GetValue());

		SoundDef.SpawnSoundDefAttached(this);		
	}

	void MoveToSplineAtDistance(float SplineDistance)
	{
		const FTransform ClosestSplineTransform = SplineToFollow.Spline.GetWorldTransformAtSplineDistance(SplineDistance);
		
		if(bFollowSplineRotation)
		{
			const float PreviousYaw = GetActorRotation().Yaw;
			const FQuat NewRotation = FQuat::MakeFromXZ(ClosestSplineTransform.TransformRotation(RelativeRotationToSpline).ForwardVector, FVector::UpVector);
			SetActorLocationAndRotation(ClosestSplineTransform.GetLocation(), NewRotation);
			if(bCompensateRotationOnTurret)
			{
				float YawDiff = GetActorRotation().Yaw - PreviousYaw;
				ControlAddToSniperRotation(-YawDiff ,0.0);
			}
		}
		else
			SetActorLocation(ClosestSplineTransform.GetLocation());
	}

	UFUNCTION(BlueprintCallable)
	void MoveTurretToClosestSplineToLocation(FVector Location, bool bResetRotation, bool bTeleport)
	{
		SyncedDistanceAlongSpline.SetValue(SplineToFollow.Spline.GetClosestSplineDistanceToWorldLocation(Location));

		if(bTeleport)
			SyncedDistanceAlongSpline.SnapRemote();

		MoveToSplineAtDistance(SyncedDistanceAlongSpline.GetValue());

		if(bResetRotation)
		{
			// TODO: Interpolate?
			YawRoot.SetRelativeRotation(FRotator::ZeroRotator);
		}
	}

	void ControlAddToSniperRotation(float InYaw, float InPitch)
	{
		check(HasControl());

		FRotator Rotation = SyncedAimRotation.Value;

		const float Yaw = Math::Clamp(Rotation.Yaw + InYaw, -MaxYaw, MaxYaw);
		const float Pitch = Math::Clamp(Rotation.Pitch + InPitch, -MaxPitch, MaxPitch);

		FRotator SyncedRotation = FRotator(Pitch, Yaw, 0);
		SyncedAimRotation.SetValue(SyncedRotation);
	}

	void ApplySniperRotation()
	{
		const FRotator SyncedRotation = SyncedAimRotation.Value;
		FRotator YawRotation = FRotator(0, SyncedRotation.Yaw, 0);
		FRotator PitchRotation = FRotator(SyncedRotation.Pitch, 0, 0);
		YawRoot.SetRelativeRotation(YawRotation);
		PitchRoot.SetRelativeRotation(PitchRotation);
	}

	FHitResult Trace() const
	{
		if(!ensure(AimingComp.IsAiming(this)))
			return FHitResult();

		FHazeTraceSettings Trace = GetTraceSettings();
		const FAimingResult AimResult = AimingComp.GetAimingTarget(this);

		const FHitResult StraightHit = Trace.QueryTraceSingle(AimResult.AimOrigin, AimResult.AimOrigin + (AimResult.AimDirection * Range));

		// If a straight hit hits a player or response component target, return that straight hit
		if(StraightHit.IsValidBlockingHit())
		{
			if(StraightHit.Actor.IsA(AHazePlayerCharacter))
				return StraightHit;

			const auto ResponseComp = UHackableSniperTurretResponseComponent::Get(StraightHit.Actor);
			if(ResponseComp != nullptr)
				return StraightHit;
		}

		// If a straight hit didn't hit anything special, see if we have an auto aim target
		if(AimResult.AutoAimTarget != nullptr)
		{
			// If we found an auto aim target, try to trace against that instead
			// If we hit it, return this hit, if we missed, try just tracing forward instead
			// Since the auto aiming isn't visible, this should not be noticable
			const FVector DirToAutoAimTarget = (AimResult.AutoAimTargetPoint - AimResult.AimOrigin).GetSafeNormal();
			const FHitResult AutoAimHit = Trace.QueryTraceSingle(AimResult.AimOrigin, AimResult.AimOrigin + (DirToAutoAimTarget * Range));
			if(AutoAimHit.IsValidBlockingHit())
				return AutoAimHit;
		}

		// No auto aim hits and no special straight hit, just return the straight hit as is
		return StraightHit;
	}

	FHazeTraceSettings GetTraceSettings() const
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(this);
		Trace.IgnoreActor(Drone::GetSwarmDronePlayer());
		Trace.UseLine();
		return Trace;
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackingStarted(FSwarmDroneHijackParams HijackParams)
	{
		OnHackingStarted.Broadcast(HijackParams);
		
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackingStopped()
	{
		PlayerCapabilityRequestComponent.StartInitialSheetsAndCapabilities(Drone::SwarmDronePlayer, this);

		OnHackingStopped.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void EnableTurotial()
	{
		//bHasZoomed = false;
	}

	UFUNCTION(BlueprintCallable)
	void DisableMovement()
	{
		bCanMove = false;
	}
}

asset HackableSniperTurretSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UHackableSniperTurretCapability);
	Capabilities.Add(UHackableSniperTurretFireCapability);
	Capabilities.Add(UHackableSniperTurretCameraCapability);
	Capabilities.Add(UHackableSniperTurretMovementCapability);
};

asset HackableSniperTurretPlayerDeactivationSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UHackableSniperTurretDeactivationCapability);
};