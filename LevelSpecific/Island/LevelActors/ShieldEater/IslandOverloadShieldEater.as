event void FAIslandOverloadShieldEaterSignature();

class AIslandOverloadShieldEater : AHazeActor
{

	UPROPERTY()
	FAIslandGrenadeLockListenerSignature OnCompleted;

	UPROPERTY()
	FAIslandGrenadeLockListenerSignature OnImpact;

	UPROPERTY()
	FAIslandGrenadeLockListenerSignature OnOvercharged;
	
	UPROPERTY()
	FAIslandGrenadeLockListenerSignature OnDischarging;

	UPROPERTY()
	FAIslandGrenadeLockListenerSignature OnReset;

	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent ShootMesh;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueTargetableComponent TargetComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactOverchargeResponseComponent OverchargeComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditAnywhere)
	UIslandRedBlueImpactOverchargeResponseComponentSettingsDataAsset MioSettings;

	UPROPERTY(EditAnywhere)
	UIslandRedBlueImpactOverchargeResponseComponentSettingsDataAsset ZoeSettings;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UMaterialInterface MioMaterial;

	UPROPERTY()
	UMaterialInterface ZoeMaterial;

	UPROPERTY()
	UMaterialInterface ImpactMaterial;
	
	UPROPERTY()
	UMaterialInterface CompletedMaterial;

	UPROPERTY()
	UMaterialInterface RechargingMaterial;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer UsableByPlayer;
	default UsableByPlayer = EHazePlayer::Mio;

	UPROPERTY(EditInstanceOnly)
	AIslandRedBlueForceField ForceFieldRef;

	UPROPERTY(EditInstanceOnly)
	AIslandShieldEaterContainer ContainerRef;

	UPROPERTY(EditAnywhere)
	float Range = 500.0;

	// Don't check for overlaps every frame
	UPROPERTY(EditAnywhere)
	float OverlapCheckInterval = 0.1;

	private float LastOverlapCheckTime;

	UPROPERTY(EditAnywhere)
	bool bDoOnce;

	UPROPERTY(EditAnywhere)
	bool bBossEncounter = true;

	UPROPERTY(EditAnywhere)
	bool bResetShield;

	UPROPERTY()
	bool bIsOvercharged;

	FRotator RotationSpeed = FRotator(0,1,0);
	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			ShootMesh.SetMaterial(1, MioMaterial);
			ShootMesh.SetMaterial(4, MioMaterial);
			OverchargeComp.SettingsDataAsset_Property = MioSettings;
		}

		else
		{
			ShootMesh.SetMaterial(1, ZoeMaterial);
			ShootMesh.SetMaterial(4, ZoeMaterial);
			OverchargeComp.SettingsDataAsset_Property = ZoeSettings;
		}

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OverchargeComp.OnImpactEvent.AddUFunction(this, n"HandleImpact");
		OverchargeComp.OnFullCharge.AddUFunction(this, n"HandleFullAlpha");
		OverchargeComp.OnStartDischarging.AddUFunction(this, n"HandleDischarging");
		OverchargeComp.OnZeroCharge.AddUFunction(this, n"HandleOnZeroCharge");

		OverchargeComp.BlockImpactForPlayer(Game::GetOtherPlayer(UsableByPlayer), this);
		TargetComp.DisableForPlayer(Game::GetOtherPlayer(UsableByPlayer), this);
	}

	UFUNCTION()
	void HandleFullAlpha(bool bWasOvercharged)
	{
		if (bIsOvercharged)
			return;

		UIslandOverloadShieldEaterEffectHandler::Trigger_OnExplode(this);
		SpawnVFXBeam(GetShieldEaterMeshLocation(), GetVFXSpawnLocation());

		bIsOvercharged = true;
		TimeOfOvercharged = Time::GetGameTimeSeconds();

		if (ForceFieldRef != nullptr)
		{
			ForceFieldRef.MakeNewHole(nullptr, ForceFieldRef.GetActorLocation(), 300);
			// ForceFieldRef.SetForceFieldActive(false);
		}

		OnOvercharged.Broadcast();
		OnCompleted.Broadcast();
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			ShootMesh.SetMaterial(1, MioMaterial);
			ShootMesh.SetMaterial(4, MioMaterial);
		}

		else
		{
			ShootMesh.SetMaterial(1, ZoeMaterial);
			ShootMesh.SetMaterial(4, ZoeMaterial);
		}

		TargetComp.DisableForPlayer(Game::GetPlayer(UsableByPlayer), this);
		if (bDoOnce)
		{
			ShootMesh.SetMaterial(1, CompletedMaterial);
			ShootMesh.SetMaterial(4, CompletedMaterial);
		}
		else
		{
			ShootMesh.SetMaterial(1, RechargingMaterial);
			ShootMesh.SetMaterial(4, RechargingMaterial);
		}

		if (CameraShake != nullptr)
			Game::GetPlayer(UsableByPlayer).PlayCameraShake(CameraShake, this, 1.0);

		TryEatEnemyShield();

		if (ContainerRef != nullptr)
			ContainerRef.ResetContainer();

		BP_HandleFullAlpha();
	}

	private void SpawnVFXBeam(USceneComponent Start, USceneComponent End)
	{
		FIslandOverloadShieldEaterCreateBeamEffectParams EffectParams;
		EffectParams.StartPoint = Start;
		EffectParams.EndPoint = End;
		UIslandOverloadShieldEaterEffectHandler::Trigger_OnCreateBeam(this, EffectParams);
		// Debug::DrawDebugSphere(EffectParams.StartPoint.WorldLocation, 50.0, LineColor = FLinearColor::Red, Duration = 3.0);
		// Debug::DrawDebugSphere(EffectParams.EndPoint.WorldLocation, 50.0, LineColor = FLinearColor::Green, Duration = 3.0);
	}

	UFUNCTION(BlueprintEvent, BlueprintPure)
	USceneComponent GetVFXSpawnLocation() { return nullptr; }

	UFUNCTION(BlueprintEvent, BlueprintPure)
	USceneComponent GetShieldEaterMeshLocation() { return nullptr; }

	// Dissipates a single shield per actor in range.
	TArray<AActor> PreviouslyHitActors;
	private void TryEatEnemyShield()
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::EnemyCharacter);
		Trace = Trace::InitProfile(n"EnemyCharacter");
		Trace.UseSphereShape(Range);

		LastOverlapCheckTime = Time::GetGameTimeSeconds();
		//Debug::DrawDebugSphere(ActorCenterLocation, Range, Duration = 0.1);
		
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(ActorCenterLocation);
		for (FOverlapResult Overlap : Overlaps.OverlapResults)
		{
			if (Overlap.Actor == nullptr)
				continue;
			if (PreviouslyHitActors.Contains(Overlap.Actor))
				continue;

			PreviouslyHitActors.Add(Overlap.Actor);

			UIslandForceFieldBubbleComponent ForceFieldBubbleComp = UIslandForceFieldBubbleComponent::Get(Overlap.Actor);
			if (ForceFieldBubbleComp != nullptr && !ForceFieldBubbleComp.IsDepleted())
			{
				if (ForceFieldBubbleComp.GetCurrentForceFieldType() != IslandForceField::GetPlayerForceFieldType(Game::GetPlayer(UsableByPlayer)) )
					continue;
				FVector ClosestPoint;
				FVector OverlapActorCenterLocation = Cast<AHazeActor>(Overlap.Actor).ActorCenterLocation;
				// TODO: fix impact point
				Overlap.Component.GetClosestPointOnCollision(OverlapActorCenterLocation, ClosestPoint);
				ForceFieldBubbleComp.TakeDamage(10.0, ClosestPoint);
				SpawnVFXBeam(TargetComp, Overlap.Component);
			}
			else
			{
				UIslandForceFieldComponent ForceFieldComp = UIslandForceFieldComponent::Get(Overlap.Actor);
				if (ForceFieldComp != nullptr && ForceFieldComp.IsEnabled() && !ForceFieldComp.IsDepleted())
				{
					if (ForceFieldComp.CurrentType != IslandForceField::GetPlayerForceFieldType(Game::GetPlayer(UsableByPlayer)) )
						continue;
					FVector ClosestPoint;
					FVector OverlapActorCenterLocation = Cast<AHazeActor>(Overlap.Actor).ActorCenterLocation;
					// TODO: fix impact point
					Overlap.Component.GetClosestPointOnCollision(OverlapActorCenterLocation, ClosestPoint);
					ForceFieldComp.TakeDamage(10.0, ClosestPoint, this);
					SpawnVFXBeam(TargetComp, Overlap.Component);
				}
			}
		}
	}

	UFUNCTION()
	void HandleImpact(FIslandRedBlueImpactResponseParams ImpactData)
	{
		OnImpact.Broadcast();

		if (bIsOvercharged)
			return;

		// AddActorLocalRotation(FRotator)
		// AddActorLocalRotation(FRotator(0,10,0));
		RotationSpeed = FRotator(0,100,0);

		BP_HandleImpact();
	}

	UFUNCTION()
	void HandleDischarging(bool bCurrentlyAtFullCharge)
	{
		if (!bCurrentlyAtFullCharge)
			return;

		
		OnDischarging.Broadcast();
			RotationSpeed = FRotator(0,1,0);

		
		if (bDoOnce)
		{
			ShootMesh.SetMaterial(1, CompletedMaterial);
			ShootMesh.SetMaterial(4, CompletedMaterial);
		}
		else
		{
			ShootMesh.SetMaterial(1, RechargingMaterial);
			ShootMesh.SetMaterial(4, RechargingMaterial);
		}
	}

	UFUNCTION()
	void HandleOnZeroCharge(bool bCurrentlyAtFullCharge)
	{
		if (bDoOnce)
			return;

		if (bCurrentlyAtFullCharge)
		{
			OnReset.Broadcast();
			UIslandOverloadShieldEaterEffectHandler::Trigger_OnRecharge(this);

			bIsOvercharged = false;
			PreviouslyHitActors.Empty();
			TargetComp.EnableForPlayer(Game::GetPlayer(UsableByPlayer), this);
			if(UsableByPlayer == EHazePlayer::Mio)
			{
				ShootMesh.SetMaterial(1, MioMaterial);
				ShootMesh.SetMaterial(4, MioMaterial);
			}

			else
			{
				ShootMesh.SetMaterial(1, ZoeMaterial);
				ShootMesh.SetMaterial(4, ZoeMaterial);
			}

			BP_HandleReset();

			if (!bResetShield)
				return;

			if (ForceFieldRef != nullptr)
				ForceFieldRef.SetForceFieldActive(true);

		}

	}

	UFUNCTION()
	void DisablePanel()
	{
		bDoOnce = true;
		TargetComp.DisableForPlayer(Game::GetPlayer(UsableByPlayer), this);
		ShootMesh.SetMaterial(1, CompletedMaterial);
		ShootMesh.SetMaterial(4, CompletedMaterial);
	}

	UFUNCTION(BlueprintEvent)
	void BP_HandleImpact()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_HandleFullAlpha()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_HandleReset()
	{}


	// Temp effect for overcharged range
	private float TimeOfOvercharged = -100.0;
	private const float DebugSphereRadiusLerpDuration = 0.1;
	private const float DebugSpherePersistDuration = 0.75;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

			ShootMesh.AddLocalRotation(RotationSpeed);

		if(!bBossEncounter)
			return;
		
		if(bIsOvercharged)
		{
			// Intermittently check for overlaps
			if (Time::GetGameTimeSince(LastOverlapCheckTime) > OverlapCheckInterval)
			{
				TryEatEnemyShield();
			}


			float TimeSinceExplosion = Time::GetGameTimeSince(TimeOfOvercharged);

			float RadiusAlpha;
			if(TimeSinceExplosion < DebugSpherePersistDuration)
				RadiusAlpha = Math::Saturate(TimeSinceExplosion / DebugSphereRadiusLerpDuration);
			else
				RadiusAlpha = 1.0 - Math::Saturate((TimeSinceExplosion - DebugSpherePersistDuration) / DebugSphereRadiusLerpDuration);

			if(RadiusAlpha == 0.0)
				return;

			
			FLinearColor Col = UsableByPlayer == EHazePlayer::Zoe ? FLinearColor::Blue : FLinearColor::Red;
			// Debug::DrawDebugSolidSphere(ActorLocation, Range * RadiusAlpha,FLinearColor(Col.R, Col.G, Col.B, 0.2), 0.0, 12);
		}
	}

}