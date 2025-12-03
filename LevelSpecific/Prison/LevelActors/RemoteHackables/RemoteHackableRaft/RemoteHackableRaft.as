event void FRemoteHackingEventForVO(AHazePlayerCharacter Player);

UCLASS(Abstract)
class ARemoteHackableRaft : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RaftRoot;

	UPROPERTY(DefaultComponent, Attach = RaftRoot)
	UFauxPhysicsConeRotateComponent PlatformRotationRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = PlatformRotationRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent)
	URemoteHackingResponseComponent HackableComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bAllowUsingBoxCollisionShape = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbSyncedComponent;
	default CrumbSyncedComponent.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default CrumbSyncedComponent.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Player;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableRaftCapability");

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5500.0;

	UPROPERTY()
	FRemoteHackingEvent OnHacked;

	UPROPERTY()
	FRemoteHackingEventForVO OnPlayerLanded;

	UPROPERTY()
	FRemoteHackingEventForVO OnPlayerLeft;

	UPROPERTY(EditDefaultsOnly, Category = "Raft")
	UStaticMesh ThrusterMesh;

	UPROPERTY(EditDefaultsOnly, Category = "Raft")
	int ThrusterAmount = 8;

	UPROPERTY(EditDefaultsOnly, Category = "Raft")
	UNiagaraSystem ThrusterSystem;

	UPROPERTY(EditDefaultsOnly, Category = "Raft")
	UMaterialInterface ThrusterMeshMaterial;

	UPROPERTY(EditInstanceOnly, Category = "Raft")
	TArray<ASplineActor> SplinesToCollideWith;

	TArray<UNiagaraComponent> ThrusterComps;

	TMap<UNiagaraComponent, bool> ThrusterMap;

	bool bEffectOn = false;

	float PowerSourceRotationRate = 0.0;

	float MoveSpeed = 900.0;

	TArray<AHazePlayerCharacter> PlayersOnRaft;

	USweepingMovementData Movement;
	FVector PlayerInput;
	FVector DefaultLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		DefaultLoc = ActorLocation;
		Movement = MoveComp.SetupSweepingMovementData();

		HackableComp.OnHackingStarted.AddUFunction(this, n"Hacked");

		if(!SplinesToCollideWith.IsEmpty())
			MoveComp.ApplySplineCollision(SplinesToCollideWith, this);

		ThrusterMap.Empty();

		for (int i = 0, Count = ThrusterAmount; i < Count; ++i)
		{
			FRotator Rot;
			Rot.Yaw = (360.0/ThrusterAmount * i) + (45.0/2);
			Rot.Pitch = 110.0;

			UNiagaraComponent EffectComp = UNiagaraComponent::Create(this);
			EffectComp.AttachToComponent(PlatformRotationRoot);
			EffectComp.SetAsset(ThrusterSystem);
			EffectComp.SetRelativeRotation(Rot);
			EffectComp.SetRelativeLocation(EffectComp.UpVector * 300.0);
			EffectComp.SetRelativeLocation(FVector(EffectComp.RelativeLocation.X, EffectComp.RelativeLocation.Y, -70.0));
			EffectComp.SetAutoActivate(false);
			EffectComp.DeactivateImmediately();
			ThrusterMap.Add(EffectComp, false);
		}

		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");
		ImpactComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"PlayerLeft");
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		if (PlayersOnRaft.Contains(Player))
			return;

		PlayersOnRaft.Add(Player);

		PlatformRotationRoot.ApplyImpulse(Player.ActorLocation, -FVector::UpVector * 100.0);
		
		OnPlayerLanded.Broadcast(Player);
	}

	UFUNCTION()
	private void PlayerLeft(AHazePlayerCharacter Player)
	{
		if (PlayersOnRaft.Contains(Player))
			PlayersOnRaft.Remove(Player);

		OnPlayerLeft.Broadcast(Player);
	}

	UFUNCTION()
	private void Hacked()
	{
		OnHacked.Broadcast();
	}

	void UpdatePlayerInput(FVector Input)
	{
		PlayerInput = Input;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector Velocity = Math::VInterpTo(MoveComp.Velocity, PlayerInput * MoveSpeed, DeltaTime, 1.8);
				FVector DeltaMove = Velocity * DeltaTime;

				FVector TargetLoc = ActorLocation + DeltaMove;
				TargetLoc.Z = DefaultLoc.Z;
				Movement.AddDeltaFromMoveToPositionWithCustomHorizontalAndVerticalVelocity(TargetLoc, DeltaMove / DeltaTime, FVector::ZeroVector);
			}
			else
			{
				FHazeSyncedActorPosition LatestPosition;
				float LatestCrumbTime = 0.0;
				CrumbSyncedComponent.GetLatestAvailableData(LatestPosition, LatestCrumbTime);

				FVector LatestVelocity = LatestPosition.WorldVelocity;
				LatestVelocity.Z = 0;

				auto CrumbPosition = CrumbSyncedComponent.GetPosition();

				// Predict ahead by how far in the predicted past our latest data is
				// NOTE: We predict *more* into the future, because the FInterpTo later on is going to cause delay!
				float PredictTime = (Time::OtherSideCrumbTrailSendTimePrediction - LatestCrumbTime) + 0.3;

				FVector PredictedLocation = LatestPosition.WorldLocation + LatestVelocity * PredictTime;

				if(!CrumbPosition.WorldLocation.Equals(PredictedLocation))
				{
					FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(MoveComp);

					// Always sweep from the crumb synced position, this ensures we always sync up eventually, even if we keep getting hits
					FHitResult Hit = TraceSettings.QueryTraceSingle(CrumbPosition.WorldLocation, PredictedLocation);

					if(Hit.IsValidBlockingHit())
					{
						PredictedLocation = Hit.Location;
					}
				}

				PredictedLocation = Math::VInterpTo(ActorLocation, PredictedLocation, DeltaTime, 2);

				FVector PredictedVelocity = (PredictedLocation - ActorLocation) / DeltaTime;

				Movement.ApplyManualSyncedLocationAndRotation(
					PredictedLocation,
					PredictedVelocity,
					CrumbPosition.WorldRotation,
				);
			}

			MoveComp.ApplyMove(Movement);
		}

		for (AHazePlayerCharacter Player : PlayersOnRaft)
		{
			PlatformRotationRoot.ApplyForce(Player.ActorLocation, -FVector::UpVector * 50.0);
		}

		FVector TiltForceOrigin = PlatformRotationRoot.WorldLocation + FVector(0.0, 0.0, 50.0);
		float SpeedAlpha = Math::Lerp(0.0, 1.0, MoveComp.HorizontalVelocity.Size()/MoveSpeed);
		TiltForceOrigin += -MoveComp.HorizontalVelocity.GetSafeNormal() * 200.0 * SpeedAlpha;
		PlatformRotationRoot.ApplyForce(TiltForceOrigin, -FVector::UpVector * 150.0);

		for (auto Element : ThrusterMap)
		{
			FVector FlattenedThrusterDir = Element.Key.UpVector.ConstrainToPlane(FVector::UpVector);
			float Dot = FlattenedThrusterDir.DotProduct(MoveComp.Velocity.GetSafeNormal());

			if (MoveComp.Velocity.Size() <= 50.0)
			{
				if (Element.Value)
				{
					Element.Key.Deactivate();
					Element.Value = false;
				}
			}

			else if (Element.Value && Dot >= -0.5)
			{
				Element.Key.Deactivate();
				Element.Value = false;
			}
			else if (!Element.Value && Dot <= -0.5)
			{
				Element.Key.Activate(true);
				Element.Value = true;
			}
		}
	}
}