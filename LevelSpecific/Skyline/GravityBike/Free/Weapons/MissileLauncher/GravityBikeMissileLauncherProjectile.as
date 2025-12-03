struct FGravityBikeMissileLauncherProjectileSettings
{
	UPROPERTY()
	FVector2D RotationSpeedSpan = FVector2D(400.0, 800.0);

	UPROPERTY()
	FVector2D RotationRadiusSpan = FVector2D(50.0, 400.0);

	UPROPERTY()
	TArray<FGravityBikeWeaponProjectilePhaseData> Phases;
};

struct FGravityBikeWeaponProjectilePhaseData
{
	UPROPERTY(EditDefaultsOnly)
	FVector Force = FVector::ZeroVector;

	UPROPERTY(EditDefaultsOnly)
	FVector Impulse = FVector::ZeroVector;

	UPROPERTY(EditDefaultsOnly)
	float Drag = 0.0;

	UPROPERTY(EditDefaultsOnly)
	bool bLocalSpace = true;

	UPROPERTY(EditDefaultsOnly)
	bool bHomingActive = false;

	UPROPERTY(EditDefaultsOnly)
	float Duration = 0.0;
}

UCLASS(Abstract)
class AGravityBikeMissileLauncherProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationPivot;

	UPROPERTY(DefaultComponent, Attach = RotationPivot)
	USceneComponent MeshPivot;

	UPROPERTY(DefaultComponent)
	UHazeActorLocalSpawnPoolEntryComponent SpawnPoolEntryComp;

	UPROPERTY(EditDefaultsOnly)
	FGravityBikeMissileLauncherProjectileSettings HomingSettings;

	UPROPERTY(EditDefaultsOnly)
	FGravityBikeMissileLauncherProjectileSettings NoTargetSettings;

	UPROPERTY(EditDefaultsOnly)
	float Damage = 1.0;

	AHazePlayerCharacter PlayerInstigator;
	FGravityBikeWeaponTargetData TargetData;
	float StartTime;
	int PhaseIndex = 0;
	float DestroyTime = 0;

	float TargetRotationSpeed = 0.0;
	FHazeAcceleratedFloat AccRotationSpeed;

	float TargetRotationRadius = 0.0;
	FHazeAcceleratedFloat AccRotationRadius;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnPoolEntryComp.OnSpawned.AddUFunction(this, n"OnSpawned");
		SpawnPoolEntryComp.OnUnspawned.AddUFunction(this, n"OnUnspawned");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Time::GameTimeSeconds > DestroyTime)
		{
			SpawnPoolEntryComp.Unspawn();
			return;
		}

		FVector PrevMeshPivotLocation = MeshPivot.WorldLocation;

		AccRotationSpeed.AccelerateTo(TargetRotationSpeed, 3.0, DeltaSeconds);
		RotationPivot.AddLocalRotation(FRotator(0.0, 0.0, AccRotationSpeed.Value * DeltaSeconds));
		AccRotationRadius.AccelerateTo(TargetRotationRadius, 2.0, DeltaSeconds);
		MeshPivot.RelativeLocation = FVector::UpVector * AccRotationRadius.Value;

		while (GetCurrentPhase().Duration > 0.0 && Time::GetGameTimeSince(StartTime) > GetCurrentPhase().Duration)
		{
			PhaseIndex++;
			
			if (GetSettings().Phases.IsValidIndex(PhaseIndex))
			{
				// Set new Phase
				ActivatePhase(GetCurrentPhase());
			}
			else
				break; 
		}

		FVector Force = GetCurrentPhase().Force;

		if (GetCurrentPhase().bLocalSpace)
			Force = ActorTransform.TransformVectorNoScale(Force);

		if (GetCurrentPhase().bHomingActive)
		{
			if (TargetData.IsHoming())
			{
//				Debug::DrawDebugPoint(TargetData.WorldLocation, 50.0, FLinearColor::Green, 0.0);

				FVector ToTarget = TargetData.GetWorldLocation() - ActorLocation;
				Force = ToTarget.SafeNormal * GetCurrentPhase().Force.Size();

				float ProximityPrecision = 1.0 - Math::GetPercentageBetweenClamped(0.0, 5000.0, ToTarget.Size());

				ActorVelocity = ActorVelocity.SlerpTowards(ToTarget.SafeNormal, ProximityPrecision * 50.0 * DeltaSeconds);
			
				MeshPivot.RelativeLocation = FVector::UpVector * AccRotationRadius.Value * (1.0 - ProximityPrecision);
			}
		}

		FVector Acceleration = Force
							 - ActorVelocity * GetCurrentPhase().Drag;

		ActorVelocity += Acceleration * DeltaSeconds;

		FQuat TargetRotation = ActorQuat;

		if (!Force.IsNearlyZero())
			TargetRotation = Force.ToOrientationQuat();

		FQuat Rotation = FQuat::Slerp(ActorQuat, TargetRotation, 5.0 * DeltaSeconds);
		SetActorRotation(Rotation);

		FVector DeltaMove = ActorVelocity * DeltaSeconds;

		Move(DeltaMove);

		// Update MeshPivot Rotation
		FVector MeshPivotDeltaMove = MeshPivot.WorldLocation - PrevMeshPivotLocation;
//		Debug::DrawDebugLine(MeshPivot.WorldLocation, MeshPivot.WorldLocation - MeshPivotDeltaMove, FLinearColor::Green, 10.0, 1.0);
		MeshPivot.ComponentQuat = MeshPivotDeltaMove.ToOrientationQuat();

#if EDITOR
		TickTemporalLog();
#endif
	}

	UFUNCTION()
	private void OnSpawned(AHazeActor Actor)
	{
		RotationPivot.AddLocalRotation(FRotator(0.0, 0.0, Math::RandRange(0.0, 360.0)));

		StartTime = Time::GameTimeSeconds;

		PhaseIndex = 0;
		ActivatePhase(GetCurrentPhase());

		DestroyTime = Time::GameTimeSeconds + 5;

		UGravityBikeMissileLauncherProjectileEventHandler::Trigger_OnSpawn(this);
	}

	UFUNCTION()
	private void OnUnspawned(AHazeActor Actor)
	{
		UGravityBikeMissileLauncherProjectileEventHandler::Trigger_OnUnSpawn(this);
	}

	void Initialize(AHazePlayerCharacter InPlayerInstigator, FVector InInheritVelocity, FGravityBikeWeaponTargetData InTargetData, FVector InDirection)
	{
		PlayerInstigator = InPlayerInstigator;
		TargetData = InTargetData;

		// Inherit Velocity In Launch Direction
		ActorVelocity = InDirection * Math::Max(0.0, InInheritVelocity.DotProduct(InDirection));

		auto Settings = GetSettings();
		TargetRotationSpeed = Math::RandRange(Settings.RotationSpeedSpan.X, Settings.RotationSpeedSpan.Y);
		TargetRotationRadius = Math::RandRange(Settings.RotationRadiusSpan.X, Settings.RotationRadiusSpan.Y);

		AccRotationSpeed.SnapTo(0);
		AccRotationRadius.SnapTo(0);
	}

	FGravityBikeMissileLauncherProjectileSettings GetSettings() const
	{
		if(TargetData.IsHoming())
			return HomingSettings;
		else
			return NoTargetSettings;
	}

	FGravityBikeWeaponProjectilePhaseData GetCurrentPhase() const
	{
		return GetSettings().Phases[PhaseIndex];
	}

	void ActivatePhase(FGravityBikeWeaponProjectilePhaseData PhaseData)
	{
		// Apply Impulse
		FVector Impulse = PhaseData.Impulse;

		if (PhaseData.bLocalSpace)
			Impulse = ActorTransform.TransformVectorNoScale(Impulse);

		if (PhaseData.bHomingActive)
		{
			if (TargetData.IsHoming())
			{
				FVector ToTarget = TargetData.GetWorldLocation() - ActorLocation;
				Impulse = ToTarget.SafeNormal * PhaseData.Impulse.Size();
			}
		}

		ActorVelocity += Impulse;


		FGravityBikeMissileLauncherProjectilePhaseActivatedEventData EventData;
		EventData.PhaseIndex = PhaseIndex;
		UGravityBikeMissileLauncherProjectileEventHandler::Trigger_OnPhaseActivated(this, EventData);
	}

	void Move(FVector DeltaMove)
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		auto HitResult = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMove);

		if (HitResult.bBlockingHit)
			HandleImpact(HitResult);
		else
			ActorLocation += DeltaMove;
	}

	void HandleImpact(FHitResult HitResult)
	{
		if(HasControl())
		{
			if (HitResult.IsValidBlockingHit())
			{
				const FTransform ComponentTransform = HitResult.Component.WorldTransform;
				CrumbOnHit(
					HitResult.Component,
					ComponentTransform.InverseTransformPositionNoScale(HitResult.ImpactPoint),
					ComponentTransform.InverseTransformVectorNoScale(HitResult.ImpactNormal)
				);
			}
		}

		FGravityBikeMissileLauncherProjectileImpactEventData ImpactData;
		ImpactData.ImpactPoint = HitResult.ImpactPoint;
		ImpactData.ImpactNormal = HitResult.ImpactNormal;
		UGravityBikeMissileLauncherProjectileEventHandler::Trigger_OnImpact(this, ImpactData);

		SpawnPoolEntryComp.Unspawn();
	}

	UFUNCTION(CrumbFunction)
	void CrumbOnHit(UPrimitiveComponent HitComponent, FVector RelativeImpactPoint, FVector RelativeImpactNormal)
	{
		if(HitComponent == nullptr)
			return;

		auto ResponseComp = UGravityBikeWeaponProjectileResponseComponent::Get(HitComponent.Owner);
		if (ResponseComp != nullptr)
		{
			const FTransform ComponentTransform = HitComponent.WorldTransform;
			auto ImpactData = FGravityBikeWeaponImpactData(
				HitComponent,
				ComponentTransform.TransformPositionNoScale(RelativeImpactPoint),
				ComponentTransform.TransformVectorNoScale(RelativeImpactNormal),
				EGravityBikeWeaponType::MissileLauncher,
				Damage,
				PlayerInstigator
			);
			
			ResponseComp.OnImpact.Broadcast(ImpactData);
		}
	}

#if EDITOR
	void TickTemporalLog()
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		TemporalLog.Value("Phases;Phase Index", PhaseIndex);

		if(GetSettings().Phases.IsValidIndex(PhaseIndex))
		{
			auto ProjectilePhase = GetCurrentPhase();
			TemporalLog.Value("Phases;ProjectilePhase;Drag", ProjectilePhase.Drag);
			TemporalLog.Value("Phases;ProjectilePhase;Duration", ProjectilePhase.Duration);
			TemporalLog.Value("Phases;ProjectilePhase;Force", ProjectilePhase.Force);
			TemporalLog.Value("Phases;ProjectilePhase;Impulse", ProjectilePhase.Impulse);
			TemporalLog.Value("Phases;ProjectilePhase;bHomingActive", ProjectilePhase.bHomingActive);
			TemporalLog.Value("Phases;ProjectilePhase;bLocalSpace", ProjectilePhase.bLocalSpace);
		}

		TemporalLog.Value("TargetData;IsValid()", TargetData.IsHoming());

		if(TargetData.IsHoming())
		{
			TemporalLog.Value("TargetData;TargetComponent", TargetData.TargetComponent);
			TemporalLog.Point("TargetData;RelativeLocation", TargetData.RelativeLocation);
			TemporalLog.Value("TargetData;RelativeRotation", TargetData.RelativeRotation);

			TemporalLog.Point("TargetData;World Location", TargetData.GetWorldLocation());
			TemporalLog.Value("TargetData;World Rotation", TargetData.GetWorldRotation());

			TemporalLog.Arrow("TargetData;To Target", ActorLocation, TargetData.GetWorldLocation(), 20);
		}
	}
#endif
}