class USkylineBikeTowerEnemyShipVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineBikeTowerEnemyShipVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto EnemyShip = Cast<ASkylineBikeTowerEnemyShip>(InComponent.Owner);

		auto Spline = UHazeSplineComponent::Get(EnemyShip.MovementSpline);
		if (Spline == nullptr)
			return;

		FLinearColor Color = FLinearColor::Green;

		float Size = 50.0;

		int Resolution = 100;
		int Samples = int(Spline.SplineLength / Resolution);

		TArray<FVector> Locations;

		for (int i = 0; i < Samples; i++)
			Locations.Add(Spline.GetWorldTransformAtSplineFraction(i / float(Samples)).TransformPositionNoScale(EnemyShip.Offset));

		for (int i = 0; i < Samples - 1; i++)
			DrawLine(Locations[i], Locations[i + 1], Color, Size);
	}
}

class USkylineBikeTowerEnemyShipVisualizerComponent : UActorComponent {}

event void FSkylineBikeTowerEnemyShipSignature();
event void FSkylineBikeTowerEnemyShipDamageSignature(AHazeActor Instigator);

UCLASS(Abstract)
class ASkylineBikeTowerEnemyShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USkylineHighwayFloatingComponent FloatingComp;
	default FloatingComp.bUseImpostorMeshesAtDistance = false;
	default FloatingComp.bDisableCollisionAtDistance = false;
	default FloatingComp.DistanceLocationMultiplier = 1.0;
	default FloatingComp.DistanceRotationMultiplier = 1.0;

	UPROPERTY(DefaultComponent, Attach = FloatingComp)
	USceneComponent MeshPivot;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	USceneComponent LeftMissilePivot;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	USceneComponent RightMissilePivot;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp, AttachSocket = "Hatch")
	UStaticMeshComponent HatchMeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp, AttachSocket = "LeftThruster")
	USkylineAttackShipThrusterComponent LeftThrusterSpawnerComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp, AttachSocket = "RightThruster")
	USkylineAttackShipThrusterComponent RightThrusterSpawnerComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp, AttachSocket = "Cannon")
	USkylineBossTankAutoCannonComponent AutoCannonComp;
	default AutoCannonComp.MinDistance = 100.0;
	default AutoCannonComp.MagSize = 30;
	default AutoCannonComp.ReloadTime = 1.5;
	default AutoCannonComp.FireInterval = 0.8;

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	UCapsuleComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = MeshPivot)
	UGravityBikeWeaponTargetableComponent TargetComp;

	UPROPERTY(DefaultComponent, Attach = TargetComp)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeWeaponProjectileResponseComponent BikeWeaponProjectileResponseComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;
	default HealthComp.MaxHealth = 20.0; // 10.0

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly_Imprecise;
	default SyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::Standard;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = false; // true
	default DisableComp.AutoDisableRange = 60000; // 60000

	UPROPERTY(DefaultComponent)
	USkylineBikeTowerEnemyShipVisualizerComponent VisualizerComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	FVector Velocity;

	UPROPERTY(EditAnywhere)
	bool bKillerShip = false;
	bool bKillerMissileReady = true;
	AGravityBikeFree KillerMissileTarget;
	float KillerMissileDelay = 2.0;

	UPROPERTY(EditAnywhere)
	AActor BikePath;
	UHazeSplineComponent BikePathSpline;

	UPROPERTY(EditAnywhere)
	FVector Offset = FVector::ZeroVector;

	UPROPERTY(EditAnywhere)
	float OffsetOnSpline = 0.0;

	UPROPERTY(EditAnywhere)
	float MovementSpeed = 9000.0;

	UPROPERTY(EditAnywhere)
	float LerpSpeed = 1.0;

	UPROPERTY(EditAnywhere)
	bool bUseMovementPrediction = true;

	UPROPERTY(EditAnywhere)
	float EntrySpeed = 5000.0;

	UPROPERTY(EditInstanceOnly)
	AActor EntrySpline;
	FSplinePosition EntrySplinePosition;

	UPROPERTY(EditInstanceOnly)
	float EntryBlendTime = 3.0;

	UPROPERTY(EditAnywhere)
	bool bDisableAfterEntry = false;

	FHazeAcceleratedFloat EntryBlend;
	default EntryBlend.Value = 1.0;

	UPROPERTY(EditInstanceOnly)
	AActor MovementSpline;
	UHazeSplineComponent Spline;
	FSplinePosition SplinePosition;
	FSplinePosition LerpedSplinePosition;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

	UPROPERTY(EditAnywhere)
	bool bTargetMio = true;

	UPROPERTY(EditAnywhere)
	bool bTargetZoe = true;

	UPROPERTY(EditAnywhere)
	bool bTriggerActivatesMovementAndTargeting = false;
	bool bIdle = false;

	UPROPERTY(EditAnywhere)
	bool bStartDisabled = false;

	UPROPERTY(EditAnywhere)
	bool bFreeMovement = false;

	float Drag = 1.4;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineBikeTowerEnemyShipMissile> MissileClass;

	UPROPERTY()
	FSkylineBikeTowerEnemyShipSignature OnDie;

	UPROPERTY()
	FSkylineBikeTowerEnemyShipDamageSignature OnDieFromInstigator;

	UPROPERTY()
	FSkylineBikeTowerEnemyShipSignature OnEntryComplete;

	TInstigated<bool> bFollowTargetHeight;

	TPerPlayer<bool> bHealthBarHidden;

	bool bOnEntrySpline = false;

	FTransform InitialTransform;

	FHazeAcceleratedFloat AccHeight;

	bool bLeftFire = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialTransform = ActorTransform;

		if (bKillerShip)
			TargetComp.SetUsableByPlayers(EHazeSelectPlayer::None);

		if(bTargetMio && !bTargetZoe)
		{
			SetActorControlSide(Game::Mio);
		}
		else if(!bTargetMio && bTargetZoe)
		{
			SetActorControlSide(Game::Zoe);
		}

		if (BikePath != nullptr)
		{
			BikePathSpline = UHazeSplineComponent::Get(BikePath);
			if (BikePathSpline == nullptr)
				bKillerShip = false;
		}

		if (EntrySpline != nullptr)
			SetEntrySpline(EntrySpline);
		else if (MovementSpline != nullptr)
			SetMovementSpline(MovementSpline);

		UBasicAIHealthBarSettings::SetHealthBarAttachComponentName(this, n"FloatingComp", this);
		UBasicAIHealthBarSettings::SetHealthBarOffset(this, FVector::UpVector * 800.0, this);

		BikeWeaponProjectileResponseComp.OnImpact.AddUFunction(this, n"HandleImpact");

		if (bTargetMio)
			AutoCannonComp.AddTarget(Game::Mio);

		if (bTargetZoe)
			AutoCannonComp.AddTarget(Game::Zoe);

		if (bTriggerActivatesMovementAndTargeting)
		{
			EntryBlend.SnapTo(0.0);
			bIdle = true;
		}

		if (Trigger != nullptr)
		{
			if (!bTriggerActivatesMovementAndTargeting)
				AddActorDisable(this);

			//DisableComp.AddActorDisableToActorAndLinkedActors(Trigger);
			Trigger.OnPlayerEnter.AddUFunction(this, n"HandleTriggerEnter");
		}
		else if (bStartDisabled)
		{
			AddActorDisable(this);
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(Editor::IsPlaying() && EndPlayReason == EEndPlayReason::Destroyed)
			devErrorAlways("Don't destroy TowerEnemyShips! They should be disabled instead!");
	}
#endif

	UFUNCTION(DevFunction)
	void DevActivate()
	{
		bIdle = false;
		RemoveActorDisable(this);
	}

	UFUNCTION()
	private void HandleTriggerEnter(AHazePlayerCharacter Player)
	{
		if (Player.IsMio() != bTargetMio || Player.IsZoe() != bTargetZoe)
			return;

		bIdle = false;

		if (!bTriggerActivatesMovementAndTargeting)
			RemoveActorDisable(this);

		//DisableComp.RemoveActorDisableFromActorAndLinkedActors(Trigger);
	}

	void SetEntrySpline(AActor ActorWithSpline)
	{
		if (EntrySpline != nullptr)
		{
			EntryBlend.SnapTo(0.0);

			Spline = UHazeSplineComponent::Get(EntrySpline);
			if (Spline != nullptr)
			{
				EntrySplinePosition = Spline.GetSplinePositionAtSplineDistance(0.0);
				bOnEntrySpline = true;
			}
		}
	}

	void SetMovementSpline(AActor ActorWithSpline)
	{
		Spline = UHazeSplineComponent::Get(MovementSpline);
		if (Spline != nullptr)
		{
			SplinePosition = Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
			LerpedSplinePosition = SplinePosition;
			AccHeight.SnapTo(SplinePosition.WorldLocation.Z);
		}		
	}

	UFUNCTION()
	void ApplyFollowTargetHeight(FInstigator Instigator)
	{
		if (bFollowTargetHeight.IsDefaultValue())
		{
			AutoCannonComp.bTraceTargetVisibility = false;
			AutoCannonComp.TargetMovementPredictionMultiplier = 2.5;
			BP_OnShootOutModeBegin();
		}

		bFollowTargetHeight.Apply(true, Instigator);
	}

	UFUNCTION()
	void ClearFollowTargetHeight(FInstigator Instigator)
	{
		bFollowTargetHeight.Clear(Instigator);

		if (bFollowTargetHeight.IsDefaultValue())
		{
			AutoCannonComp.bTraceTargetVisibility = true;
			AutoCannonComp.TargetMovementPredictionMultiplier = 1.0;
			BP_OnShootOutModeEnd();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnShootOutModeBegin() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnShootOutModeEnd() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AutoCannonComp.UpdateTargeting(DeltaSeconds);

		if(HasControl())
			TickControl(DeltaSeconds);
		else
			TickRemote(DeltaSeconds);
	}

	private void TickControl(float DeltaTime)
	{
		check(HasControl());

		if (bOnEntrySpline)
		{
			if (!EntrySplinePosition.Move(EntrySpeed * DeltaTime))
			{
				Velocity = EntrySplinePosition.WorldForwardVector * EntrySpeed;

				bOnEntrySpline = false;

				OnEntryComplete.Broadcast();

				if (bDisableAfterEntry)
					AddActorDisable(this);

				if (MovementSpline != nullptr)
					SetMovementSpline(MovementSpline);				
			}

			ActorTransform = EntrySplinePosition.WorldTransformNoScale;

			InitialTransform = ActorTransform;

			return;
		}

		if (bIdle)
			return;

		if (AutoCannonComp.CanFire())
			AutoCannonComp.Fire();
		
		AGravityBikeFree ClosestTarget = nullptr;
		float ClosestDistanceSquared = AutoCannonComp.DetectionDistanceSquared;

		// Temp
		ClosestDistanceSquared = BIG_NUMBER;

		for (auto Target : AutoCannonComp.Targets)
		{
			FVector ToTarget = Target.ActorLocation - ActorLocation;
			if (ToTarget.SizeSquared() < ClosestDistanceSquared)
			{
				ClosestDistanceSquared = ToTarget.SizeSquared();
				ClosestTarget = UGravityBikeFreeDriverComponent::Get(Target).GetGravityBike();
			}
		}

		FTransform Transform = ActorTransform;

		if (ClosestTarget != nullptr)
		{
			FVector ToTarget = ClosestTarget.ActorLocation - ActorLocation;

			if (bKillerShip)
			{
				FTransform BikePathTransform = BikePathSpline.GetClosestSplineWorldTransformToWorldLocation(ClosestTarget.ActorLocation);

				if (!ClosestTarget.BikeDriver.IsPlayerDead() && ClosestTarget.ActorVelocity.SafeNormal.DotProduct(BikePathTransform.Rotation.ForwardVector.SafeNormal) < 0.0)
				{
					KillerMissileDelay -= DeltaTime;
//					Debug::DrawDebugLine(ActorLocation, ActorLocation + ToTarget, FLinearColor::Red, 20.0, 0.0);

					if (bKillerMissileReady && KillerMissileDelay <= 0.0)
					{
						KillerMissileTarget = ClosestTarget;
						LaunchKillerMissileAtTarget(KillerMissileTarget, 2.0);
					}
				}
				else
				{
					KillerMissileDelay = 2.0;
				}

//				PrintToScreen("KDelay: " + KillerMissileDelay, 0.0, FLinearColor::DPink);
			}

			FQuat TargetRotation = FQuat::MakeFromZX(FVector::UpVector, ToTarget);
			Transform.Rotation = Math::QInterpTo(ActorQuat, TargetRotation, DeltaTime, 2.0);
		
			if (Spline != nullptr)
			{
				auto TargetSplinePosition = Spline.GetClosestSplinePositionToWorldLocation(ClosestTarget.ActorLocation + ClosestTarget.ActorVelocity * 1.8);
			
				float DeltaMove = SplinePosition.DeltaToReachClosest(TargetSplinePosition);

				SplinePosition.Move(Math::Sign(DeltaMove) * MovementSpeed * DeltaTime);
			
				float LerpedDistance = Math::Lerp(LerpedSplinePosition.CurrentSplineDistance, SplinePosition.CurrentSplineDistance, LerpSpeed * DeltaTime);

				LerpedSplinePosition = Spline.GetSplinePositionAtSplineDistance(LerpedDistance);

//				auto OffsetSplinePosition = Spline.GetSplinePositionAtSplineDistance(LerpedDistance + Offset.X);
//				Offset = FVector(0.0, Offset.Y, Offset.Z);
				auto OffsetSplinePosition = Spline.GetSplinePositionAtSplineDistance(LerpedDistance + OffsetOnSpline);

				FTransform NewTransform = OffsetSplinePosition.WorldTransformNoScale;

				AccHeight.AccelerateTo((bFollowTargetHeight.Get() ? ClosestTarget.ActorLocation.Z : NewTransform.Location.Z), 6.0, DeltaTime);

				NewTransform.Location = FVector(NewTransform.Location.X, NewTransform.Location.Y, AccHeight.Value);

				Transform.Location = NewTransform.TransformPositionNoScale(Offset); 
			}

			if (bFreeMovement)
			{
				FVector FreeMovementTarget = ClosestTarget.ActorLocation + ClosestTarget.ActorTransform.TransformVectorNoScale(Offset);

				FVector TankBossLocation = TListedActors<ASkylineBossTank>().Single.ActorLocation;

				if (TankBossLocation.Dist2D(ActorLocation, FVector::UpVector) < 10000.0)
					FreeMovementTarget.Z = TankBossLocation.Z + 3500.0;

				FVector ToFreeMovementTarget = FreeMovementTarget - ActorLocation;

//				Debug::DrawDebugPoint(FreeMovementTarget, 100.0, FLinearColor::Red, 0.0);
				FVector Acceleration = ToFreeMovementTarget.SafeNormal * Math::Min(ToFreeMovementTarget.Size() * 4.0, (MovementSpeed * Drag))
									 - Velocity * Drag;

				Velocity += (Acceleration * DeltaTime).GetClampedToMaxSize(ToFreeMovementTarget.Size());

				Transform.Location = ActorLocation;
				Transform.AddToTranslation(Velocity * DeltaTime);
			}
		}

		InitialTransform.AddToTranslation(Velocity * DeltaTime);
		EntryBlend.AccelerateTo(1.0, EntryBlendTime, DeltaTime);
		ActorTransform = LerpTransform(InitialTransform, Transform, EntryBlend.Value);
	}

	private void TickRemote(float DeltaTime)
	{
		check(!HasControl());

		const FHazeSyncedActorPosition SyncedPosition = SyncedActorPositionComp.Position;
		SetActorLocationAndRotation(SyncedPosition.WorldLocation, SyncedPosition.WorldRotation);
		SetActorVelocity(SyncedPosition.WorldVelocity);
	}

	UFUNCTION()
	private void HandleImpact(FGravityBikeWeaponImpactData ImpactData)
	{
		if(HealthComp.IsDead())
			return;

		HealthComp.TakeDamage(ImpactData.Damage, EDamageType::Default, ImpactData.Instigator);

		if(HealthComp.IsDead())
			CrumbExplode(ImpactData.Instigator);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbExplode(AHazeActor Instigator)
	{
		if(IsActorDisabledBy(n"Destroyed"))
			return;
		
		if(!HealthComp.IsDead())
			HealthComp.Die();

		OnDie.Broadcast();
		OnDieFromInstigator.Broadcast(Instigator);

		USkylineBikeTowerEnemyShipEventHandler::Trigger_OnExplode(this);
		AddActorDisable(n"Destroyed");
	}

	UFUNCTION()
	void TeleportToTarget(AActor TargetActor)
	{
		EntryBlend.SnapTo(1.0);
		bIdle = false;
		bOnEntrySpline = false;

		RemoveActorDisable(this);

		if(!HasControl())
			return;

		SetActorLocationAndRotation(TargetActor.ActorLocation, TargetActor.ActorRotation);
		SyncedActorPositionComp.SnapRemote();

		if (MovementSpline != nullptr)
			SetMovementSpline(MovementSpline);
	}

	UFUNCTION()
	void TeleportToTransform(FTransform TargetTransform)
	{
		EntryBlend.SnapTo(1.0);
		bIdle = false;
		bOnEntrySpline = false;

		RemoveActorDisable(this);

		if(!HasControl())
			return;

		SetActorLocationAndRotation(TargetTransform.Location, TargetTransform.Rotation);
		SyncedActorPositionComp.SnapRemote();

		if (MovementSpline != nullptr)
			SetMovementSpline(MovementSpline);
	}

	UFUNCTION()
	void ActivateForPlayer(AHazePlayerCharacter Player)
	{
		FTransform TargetTransform;

		FVector ViewDirection = Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).SafeNormal;

		FVector Origin = TListedActors<ASkylineBossTank>().Single.ConstraintRadiusOrigin.ActorLocation;
		FVector Start = FVector(Player.ViewLocation.X, Player.ViewLocation.Y, Origin.Z);

		auto Points = Math::GetLineSegmentSphereIntersectionPoints(Start, Start + ViewDirection * 1000000.0, Origin, 35000.0);

		FVector Location = Points.MinIntersection;

//		Debug::DrawDebugPoint(Points.MinIntersection, 300.0, FLinearColor::Red, 5.0);

		TargetTransform.Location = Location - FVector::UpVector * 2000.0;
		TargetTransform.Rotation = (Player.ViewLocation - Location).ToOrientationQuat();

		Velocity += (FVector::UpVector * 5000.0) - (TargetTransform.Rotation.ForwardVector * 5000);

		TeleportToTransform(TargetTransform);
	}

	UFUNCTION()
	void ActivateClosestToLocationOnMovementSpline(AHazeActor Actor)
	{
		EntryBlend.SnapTo(1.0);
		bIdle = false;
		bOnEntrySpline = false;

		RemoveActorDisable(this);

		if(!HasControl())
			return;

		if (MovementSpline != nullptr)
		{
			Spline = UHazeSplineComponent::Get(MovementSpline);
			if (Spline != nullptr)
			{
				SplinePosition = Spline.GetClosestSplinePositionToWorldLocation(Actor.ActorLocation);
				LerpedSplinePosition = SplinePosition;
				AccHeight.SnapTo(SplinePosition.WorldLocation.Z + 15000.0);
			}	
		}

		SetActorLocationAndRotation(SplinePosition.WorldLocation, SplinePosition.WorldLocation.Rotation());
		SyncedActorPositionComp.SnapRemote();
	}

	bool HasFreeTarget()
	{
		TListedActors<ASkylineBikeTowerEnemyShip> EnemyShips;
		for (auto EnemyShip : EnemyShips)
		{
			if (EnemyShip.AutoCannonComp.HasTarget())
			{
				if (EnemyShip.AutoCannonComp.CurrentTarget == AutoCannonComp.CurrentTarget)
					return false;
			}
		}

		AutoCannonComp.UpdateTargeting(Time::GetActorDeltaSeconds(this));

		return true;
	}

	UFUNCTION()
	void LaunchKillerMissileAtTarget(AActor TargetActor, float TimeToImpact = 2.0)
	{
		bKillerMissileReady = false;

		auto MissileFirePivot = (bLeftFire ? LeftMissilePivot : RightMissilePivot);

		auto Missile = SpawnActor(MissileClass, bDeferredSpawn = true);

		auto InterfaceComp = USkylineInterfaceComponent::Get(TargetActor);
		if (InterfaceComp != nullptr)
			Missile.InterfaceComp.OnTriggerActivate.AddUFunction(InterfaceComp, n"HandleActivate");

		Missile.TargetComponent = TargetActor.RootComponent;
		Missile.TimeToImpact = TimeToImpact;
		Missile.SplineMissileComp.OnImpact.AddUFunction(this, n"HandleKillerMissileImpact");
		FTransform SpawnTransform;
		SpawnTransform.Location = MissileFirePivot.WorldLocation;
		SpawnTransform.Rotation = MissileFirePivot.ComponentQuat;
		FinishSpawningActor(Missile, SpawnTransform);

		BP_LaunchMissile(SpawnTransform.GetRelativeTransform(FloatingComp.WorldTransform));
	
		bLeftFire = !bLeftFire;
	}

	UFUNCTION()
	private void HandleKillerMissileImpact()
	{
		bKillerMissileReady = true;
		KillerMissileTarget.GetDriver().DamagePlayerHealth(0.5);
	}

	UFUNCTION()
	void LaunchMissileAtTarget(AActor TargetActor, float TimeToImpact = 2.0)
	{
		auto MissileFirePivot = (bLeftFire ? LeftMissilePivot : RightMissilePivot);

		auto Missile = SpawnActor(MissileClass, bDeferredSpawn = true);

		auto InterfaceComp = USkylineInterfaceComponent::Get(TargetActor);
		if (InterfaceComp != nullptr)
			Missile.InterfaceComp.OnTriggerActivate.AddUFunction(InterfaceComp, n"HandleActivate");

		Missile.TargetTransform = TargetActor.ActorTransform;
		Missile.TimeToImpact = TimeToImpact;
		FTransform SpawnTransform;
		SpawnTransform.Location = MissileFirePivot.WorldLocation;
		SpawnTransform.Rotation = MissileFirePivot.ComponentQuat;
		FinishSpawningActor(Missile, SpawnTransform);

		BP_LaunchMissile(SpawnTransform.GetRelativeTransform(FloatingComp.WorldTransform));
	
		bLeftFire = !bLeftFire;
	}

	UFUNCTION(BlueprintEvent)
	void BP_LaunchMissile(FTransform Transform) {}

	private FTransform LerpTransform(FTransform A, FTransform B, float Alpha) const
	{
		FVector Location = Math::Lerp(A.Location, B.Location, Alpha);
		FQuat Rotation = FQuat::Slerp(A.Rotation, B.Rotation, Alpha);
		FVector Scale3D = Math::Lerp(A.Scale3D, B.Scale3D, Alpha);
		return FTransform(Rotation, Location, Scale3D);
	}
};

UFUNCTION()
void DestroyAllBikeTowerEnemyShips()
{
	TListedActors<ASkylineBikeTowerEnemyShip> ListedEnemyShips;
	
	TArray<ASkylineBikeTowerEnemyShip> EnemyShips = ListedEnemyShips.CopyAndInvalidate();
	
	for (int i = EnemyShips.Num() - 1; i >= 0; i--)
    {
		EnemyShips[i].AddActorDisable(n"Destroyed");
    }
}

UFUNCTION()
void SetBikeTowerEnemyShipsHealthBarVisibilityForPlayer(AHazePlayerCharacter Player, bool bHidden)
{
	TListedActors<ASkylineBikeTowerEnemyShip> ListedEnemyShips;
	
	TArray<ASkylineBikeTowerEnemyShip> EnemyShips = ListedEnemyShips.CopyAndInvalidate();
	
	EHazeSelectPlayer PlayerVisibility = EHazeSelectPlayer::Both;

	for (int i = EnemyShips.Num() - 1; i >= 0; i--)
    {
		EnemyShips[i].bHealthBarHidden[Player] = bHidden;

		if (EnemyShips[i].bHealthBarHidden[Game::Mio] && !EnemyShips[i].bHealthBarHidden[Game::Zoe])
			PlayerVisibility = EHazeSelectPlayer::Zoe;

		if (!EnemyShips[i].bHealthBarHidden[Game::Mio] && EnemyShips[i].bHealthBarHidden[Game::Zoe])
			PlayerVisibility = EHazeSelectPlayer::Mio;

		if (EnemyShips[i].bHealthBarHidden[Game::Mio] && EnemyShips[i].bHealthBarHidden[Game::Zoe])
			PlayerVisibility = EHazeSelectPlayer::None;

		if (!EnemyShips[i].bHealthBarHidden[Game::Mio] && !EnemyShips[i].bHealthBarHidden[Game::Zoe])
			PlayerVisibility = EHazeSelectPlayer::Both;

		EnemyShips[i].HealthBarComp.SetPlayerVisibility(PlayerVisibility);		
    }
}