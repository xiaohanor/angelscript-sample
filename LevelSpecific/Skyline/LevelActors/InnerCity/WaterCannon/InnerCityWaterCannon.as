namespace DevTogglesSkyline
{
	namespace Draw
	{
		const FHazeDevToggleBool WaterCannon;
	}
}

struct FSkylineWaterSpoutData
{
	float LifeTimer = 0.0;
	FVector CurrentLocation;
	FVector Velocity;
	bool bCollided = false;
}

struct FInnerCityWaterCannonEventBlockedData
{
	FVector Velocity;
	FHitResult Hit;
}

struct FInnerCityWaterCannonEventHitWaterData
{
	FVector Velocity;
	FVector ImpactLocation;
}

class UInnerCityWaterCannonEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartSpray()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopSpray()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMoveStartYaw()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMoveStopYaw()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMoveStartPitch()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMoveStopPitch()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnConstrainHit()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaterSegmentBlocked(FInnerCityWaterCannonEventBlockedData Data)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaterSegmentHitWater(FInnerCityWaterCannonEventHitWaterData Data)
	{
	}

};

class AInnerCityWaterCannon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent CannonRoot;

	UPROPERTY(DefaultComponent, Attach = CannonRoot)
	UFauxPhysicsAxisRotateComponent TurretYawRoot;
	default TurretYawRoot.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromActorControl;

	UPROPERTY(DefaultComponent, Attach = TurretYawRoot)
	UFauxPhysicsForceComponent YawForceComp;

	UPROPERTY(DefaultComponent, Attach = TurretYawRoot)
	UFauxPhysicsAxisRotateComponent TurretPitchRoot;
	default TurretPitchRoot.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromActorControl;

	UPROPERTY(DefaultComponent, Attach = TurretPitchRoot)
	UCapsuleComponent CapsuleComp;

	UPROPERTY(DefaultComponent, Attach = TurretPitchRoot)
	UFauxPhysicsForceComponent PitchForceComp;

	UPROPERTY(DefaultComponent, Attach = TurretPitchRoot)
	USceneComponent FireRoot;
	
	UPROPERTY(DefaultComponent, Attach = FireRoot)
	UNiagaraComponent WaterGunVFXComp;

	UPROPERTY(DefaultComponent, Attach = FireRoot)
	UNiagaraComponent WaterStreamVFXComp;

	UPROPERTY(DefaultComponent, Attach = TurretYawRoot)
	UThreeShotInteractionComponent InteractComp;
	default InteractComp.InteractionCapability = n"InnerCityWaterCannonCapability";

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(EditDefaultsOnly)
	UHazeLocomotionFeatureBase LocomotionFeature;

	UPROPERTY(DefaultComponent, Attach = TurretYawRoot)
	USceneComponent CameraRoot;
	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor CameraActor;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditInstanceOnly)
	AInnerCityWaterCannon OtherCannon;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt TutorialPrompt;
	default TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;

	UPROPERTY()
	float YawForce = 100.0;

	UPROPERTY()
	float PitchForce = 50.0;

	bool bKnockBackCoolDown = false;
	bool bIsShootingWater = false;

	bool bHasStoppedMovingYaw = true;
	bool bIsMovingPitch = true;
	
	bool bHasStoppedMovingPitch = true;
	bool bIsMovingYaw = true;
	
	TArray<FSkylineWaterSpoutData> WaterSpouts;
	const int ReservedSpouts = 32;
	
	UPROPERTY()
	float WaterVFXLifetime = 1.2;
	UPROPERTY()
	float WaterStartDistance = 10.0;
	UPROPERTY()
	float WaterStartVelocity = 1000.0;

	float ShootWaterSpoutTimespamp = 0.0;

	float SprayTime;
	float SprayTimer = 2.0;
	bool bIsInteracting = false;
	bool bMioHasInteracted = false;
	bool bZoeHasInteracted= false;

	FHitResult WaterCannonHit;
	AInnerCityWaterCannonWave WaveActor;

	AHazePlayerCharacter InteractingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStared");
		InteractComp.OnCancelPressed.AddUFunction(this,n"HandleInteractionStopped");
		//InteractComp.OnInteractionStopped.AddUFunction(this,n"HandleInteractionStopped");
		TurretYawRoot.OnMaxConstraintHit.AddUFunction(this, n"HandleConstrainHit");
		TurretYawRoot.OnMinConstraintHit.AddUFunction(this, n"HandleConstrainHit");
		CameraRoot.SetRelativeRotation(TurretPitchRoot.RelativeRotation * 0.5);
		CapsuleComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap");
		CapsuleComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DevTogglesSkyline::Draw::WaterCannon.MakeVisible();
		WaterSpouts.Reserve(ReservedSpouts);

		FName WaveActorName = FName(ActorNameOrLabel + "_WaveDecalActor");
		WaveActor = AInnerCityWaterCannonWave::Spawn(ActorLocation, FRotator(), WaveActorName);
		WaveActor.AddActorDisable(this);
	}

	UFUNCTION()
	private void HandleConstrainHit(float Strength)
	{
		UInnerCityWaterCannonEventHandler::Trigger_OnConstrainHit(this);
	}

	UFUNCTION()
	private void HandleInteractionStopped(AHazePlayerCharacter Player,
	                                      UThreeShotInteractionComponent Interaction)
	{
		bIsInteracting = false;
		Player.RemoveTutorialPromptByInstigator(this);
		Timer::SetTimer(this, n"DelayedInteractEnable", 1.0);
		InteractComp.Disable(this);
		
	}

	UFUNCTION()
	private void DelayedInteractEnable()
	{
		InteractComp.Enable(this);
	}

	UFUNCTION()
	private void HandleInteractionStared(UInteractionComponent InteractionComponent,
	                                     AHazePlayerCharacter Player)
	{
		InteractingPlayer = Player;
		bIsInteracting = true;

		if(InteractingPlayer==Game::Mio && !bMioHasInteracted)
		{
			Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, CannonRoot);
			bMioHasInteracted = true;
			OtherCannon.bMioHasInteracted = true;
		}

		if(InteractingPlayer==Game::Zoe && !bZoeHasInteracted)
		{
			Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, CannonRoot);
			bZoeHasInteracted = true;
			OtherCannon.bZoeHasInteracted = true;
		}
			
	}

	void HasStartedMovingPitch()
	{
		if(bIsMovingPitch)
			PrintToScreen("StartedMOVE PITCH", 2.0);

			UInnerCityWaterCannonEventHandler::Trigger_OnMoveStartPitch(this);

		bIsMovingPitch = false;
	}

	void HasStoppedMovingPitch()
	{
		PrintToScreen("Stopped PITCH", 2.0);
		bHasStoppedMovingPitch = true;
		UInnerCityWaterCannonEventHandler::Trigger_OnMoveStopPitch(this);
	}

	void HasStartedMovingYaw()
	{
		if(bIsMovingYaw)
		PrintToScreen("StartedMOVE yAW", 2.0);
			UInnerCityWaterCannonEventHandler::Trigger_OnMoveStartYaw(this);
			
		bIsMovingYaw = false;
	}

	void HasStoppedMovingYaw()
	{
		PrintToScreen("Stopped YaW", 2.0);
		bHasStoppedMovingYaw = true;
		UInnerCityWaterCannonEventHandler::Trigger_OnMoveStopYaw(this);
	}

	UFUNCTION()
	private void HandleOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		if(!bIsShootingWater)
			return;

		//Player.DamagePlayerHealth(0.1);
		float ImpulseStrength = Math::GetMappedRangeValueClamped(FVector2D(0.0, CapsuleComp.CapsuleHalfHeight * 2.0), FVector2D(4.0, 1.0), Player.ActorCenterLocation.Distance(ActorLocation));
		Player.AddMovementImpulse(CapsuleComp.GetUpVector() * 500.0 * ImpulseStrength);
		Player.AddMovementImpulse(CapsuleComp.GetForwardVector() * 300.0 * ImpulseStrength);
		CapsuleComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		
		Timer::SetTimer(this, n"KnockbackTimer", 0.5);
	}

	UFUNCTION()
	private void KnockbackTimer()
	{
		if (bIsShootingWater)
			CapsuleComp.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	
	}

	void Shoot()
	{
	
		InteractingPlayer.PlayForceFeedback(ForceFeedback, true, false,this,0.2);
		WaterGunVFXComp.Activate();
		UInnerCityWaterCannonEventHandler::Trigger_OnStartSpray(this);
		//WaterStreamVFXComp.Activate(true);
		InteractingPlayer.RemoveTutorialPromptByInstigator(this);
	}

	void StopShooting()
	{
		InteractingPlayer.StopForceFeedback(this);
		bIsShootingWater = false;
		WaterGunVFXComp.Deactivate();
		UInnerCityWaterCannonEventHandler::Trigger_OnStopSpray(this);
		//WaterStreamVFXComp.Deactivate();
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{


		if (DevTogglesSkyline::Draw::WaterCannon.IsEnabled())
		{
			PrintToScreen("WaterStreamIsShooting: " + bIsShootingWater);
			Debug::DrawDebugCoordinateSystem(ActorLocation, ActorRotation, 500);
			Debug::DrawDebugCapsule(CapsuleComp.WorldLocation, CapsuleComp.CapsuleHalfHeight * CapsuleComp.GetWorldScale().Size(), CapsuleComp.CapsuleRadius * CapsuleComp.GetWorldScale().Size(), CapsuleComp.WorldRotation, ColorDebug::White);
		}

		UpdateVFX_SFX(DeltaSeconds);
		if (bIsShootingWater && Time::GameTimeSeconds >= ShootWaterSpoutTimespamp)
		{
			const float Interval = WaterVFXLifetime / float(ReservedSpouts * 0.5);
			ShootWaterSpoutTimespamp = Time::GameTimeSeconds + Interval;
			SpawnWaterSpoutyInDirection(WaterGunVFXComp.UpVector);
		}
	}

	private void UpdateVFX_SFX(float DeltaSeconds)
	{
		
		// update timers, remove if overtime
		int Num = WaterSpouts.Num();
		for (int i = 0; i < Num; ++i)
		{
			WaterSpouts[i].LifeTimer += DeltaSeconds;
			if (WaterSpouts[i].LifeTimer >= WaterVFXLifetime || WaterSpouts[i].bCollided)
			{
				WaterSpouts.RemoveAt(i);
				--i;
				--Num;
			}
		}

		TArray<FVector> VFX_WaterGunLocations;
		VFX_WaterGunLocations.Reserve(WaterSpouts.Num());

		FVector LastLocation = FVector::ZeroVector;
		for (int i = 0; i < WaterSpouts.Num(); ++i)
		{
			FVector NewVelocity = WaterSpouts[i].Velocity - FVector::UpVector * 980.0 * DeltaSeconds;
			WaterSpouts[i].Velocity = NewVelocity;
			WaterSpouts[i].CurrentLocation = WaterSpouts[i].CurrentLocation + NewVelocity * DeltaSeconds;
			VFX_WaterGunLocations.Insert(WaterSpouts[i].CurrentLocation, 0);

			if (i > 0 && DevTogglesSkyline::Draw::WaterCannon.IsEnabled())
			{
				FVector Diff = WaterSpouts[i].CurrentLocation - LastLocation;
				FVector MiddlePoint = LastLocation + Diff * 0.5;
				FRotator SpoutRotation = FRotator::MakeFromZX(Diff.GetSafeNormal(), Diff); 
				Debug::DrawDebugCircle(MiddlePoint, 40.0, 8, ColorDebug::Cyan, 3.0, SpoutRotation.RightVector, SpoutRotation.ForwardVector);
			}

			LastLocation = WaterSpouts[i].CurrentLocation;
		}
	
		if(WaterGunVFXComp != nullptr)
		{
			//WaterGunVFXComp.SetNiagaraVariableBool("HitLava", bHitPlayer);
			NiagaraDataInterfaceArray::SetNiagaraArrayVector(WaterGunVFXComp, n"GP_Locations", VFX_WaterGunLocations);
		}

		// SFX
		{
			bool bHitWater = false;
			WaterCannonHit = FHitResult();
			if (WaterSpouts.Num() >= 2)
			{
				FVector WaterStartLocation = WaterSpouts[0].CurrentLocation;
				FVector WaterEndLocation = WaterSpouts[1].CurrentLocation;
				FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
				Trace.IgnoreActor(this);
				FVector TraceDelta = WaterEndLocation - WaterStartLocation;
				Trace.UseSphereShape(40);
				if (DevTogglesSkyline::Draw::WaterCannon.IsEnabled())
					Trace.DebugDrawOneFrame();
				FVector TraceEndLocation = WaterEndLocation + TraceDelta.GetSafeNormal() * 100;
				WaterCannonHit = Trace.QueryTraceSingle(WaterEndLocation, TraceEndLocation);
				bHitWater = !WaterCannonHit.bBlockingHit && TraceEndLocation.Z < ActorLocation.Z;
				if (WaterCannonHit.bBlockingHit)
				{
					WaterSpouts[0].bCollided = true;
					FInnerCityWaterCannonEventBlockedData Data;
					Data.Hit = WaterCannonHit;
					Data.Velocity = WaterSpouts[0].Velocity;
					UInnerCityWaterCannonEventHandler::Trigger_OnWaterSegmentBlocked(this, Data);
					if (DevTogglesSkyline::Draw::WaterCannon.IsEnabled())
						Debug::DrawDebugString(WaterCannonHit.ImpactPoint, "Hit: " + WaterCannonHit.GetComponent().Owner.ActorNameOrLabel, Scale = 2.0, Duration = 0.2);
					// WaterGunVFXComp.SetVariableVec3(n"GP_ImpactLocation", WaterCannonHit.ImpactPoint);
				}
				else if (bHitWater)
				{
					WaveActor.RemoveActorDisable(this);
					WaveActor.SetActorLocation(TraceEndLocation);

					WaterSpouts[0].bCollided = true;
					FInnerCityWaterCannonEventHitWaterData Data;
					Data.ImpactLocation = TraceEndLocation;
					Data.Velocity = WaterSpouts[0].Velocity;
					UInnerCityWaterCannonEventHandler::Trigger_OnWaterSegmentHitWater(this, Data);
					if (DevTogglesSkyline::Draw::WaterCannon.IsEnabled())
						Debug::DrawDebugString(TraceEndLocation, "Hit: water", Scale = 2.0, Color = ColorDebug::Blue, Duration = 0.2);

					// WaterGunVFXComp.SetVariableVec3(n"GP_ImpactLocation", TraceEndLocation);
				}
			}

			if (!bHitWater)
			{
				WaveActor.AddActorDisable(this);
				WaveActor.SetActorLocation(ActorLocation);
			}

		}
	}

	private void SpawnWaterSpoutyInDirection(FVector Direction)
	{
		FSkylineWaterSpoutData SpoutData;
		SpoutData.LifeTimer = 0.0;
		SpoutData.Velocity = Direction * WaterStartVelocity;
		SpoutData.CurrentLocation = WaterGunVFXComp.WorldLocation + Direction * WaterStartDistance;

		if(WaterGunVFXComp != nullptr)
		{
			const FVector VFXStartVelocity = SpoutData.Velocity;
			WaterGunVFXComp.SetVariableVec3(n"GP_Velocity", VFXStartVelocity);
			WaterGunVFXComp.SetVariableFloat(n"GP_LifeTime", WaterVFXLifetime);
		}

		WaterSpouts.Add(SpoutData);
		if (WaterSpouts.Num() > ReservedSpouts)
		{
			PrintToScreen("SpawnWaterSpouty: Should reserve water spouts with number " + WaterSpouts.Num(), 5.0);
		}
	}

	UFUNCTION()
	void IsShootingWater()
	{
		bIsShootingWater = true;
		CapsuleComp.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	}

	UFUNCTION()
	void IsNotShootingWater()
	{
		bIsShootingWater = false;
		CapsuleComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}
};