class AIslandOverseerReturnGrenade : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerReturnGrenadeFireCapability");

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshOffsetComp;

	UPROPERTY(DefaultComponent, Attach=MeshOffsetComp)
	UCapsuleComponent Collider;

	UPROPERTY(DefaultComponent, Attach=MeshOffsetComp)
	UHazeSkeletalMeshComponentBase RedMesh;

	UPROPERTY(DefaultComponent, Attach=MeshOffsetComp)
	UHazeSkeletalMeshComponentBase BlueMesh;

	UPROPERTY(DefaultComponent, Attach=MeshOffsetComp)
	UIslandRedBlueTargetableComponent TargetableComp;

	UPROPERTY(DefaultComponent)
	USceneComponent FireBase;

	UPROPERTY(DefaultComponent, Attach=FireBase)
	USceneComponent FireBar;

	UPROPERTY(DefaultComponent, Attach=FireBase)
	UNiagaraComponent FireTelegraphFx;
	default FireTelegraphFx.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 19.82;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent, Attach=MeshOffsetComp)
	UIslandRedBlueImpactResponseComponent ImpactResponseComp;

	UPROPERTY(DefaultComponent)
	USceneComponent DisabledEffectContainer;

	UPROPERTY(DefaultComponent, Attach=DisabledEffectContainer)
	UNiagaraComponent DisabledEffect;

	UPROPERTY(DefaultComponent)
	UIslandOverseerRedBlueDamageComponent OverseerRedBlueDamageComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem VFXAsset_FireSpline;

	UPROPERTY()
	UOutlineDataAsset RedOutlineDataAsset;

	UPROPERTY()
	UOutlineDataAsset BlueOutlineDataAsset;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;
	
	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UIslandOverseerReturnGrenadePlayerComponent PlayerComp;
	float LandedTime;
	bool bOperational;
	AHazeActor Launcher;
	bool bReturned;
	bool bBlue;
	float Health = 1;
	float MaxHealth = 1;
	float RedBlueDamagePerSecond = 1;
	int LocationIndex;

	float ReturnAlpha;
	float ReturnSpeed = 1.2;
	FHazeAcceleratedFloat AccReturnSpeed;
	FVector ReturnLocation;
	FVector ReturnDirection;
	FVector2D ReturnScreenLocation;
	FVector ReturnMidLocation;
	FVector ReturnStartLocation;
	AHazeActor ReturnTarget;
	AHazePlayerCharacter ReturningPlayer;
	TArray<AHazePlayerCharacter> HitTargets;

	float StoppedDuration = 6;
	float StoppedTime;

	FVector TargetLocation;
	float TookDamageTime;
	float TookDamageDuration = 0.03;
	float TookDamageOffset = 20;
	FVector TookDamageLocation;
	FHazeAcceleratedVector AccTookDamageLocation;
	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedVector AccLocation;

	float FlashDuration = 0.05;
	float FlashTime;

	UPROPERTY()
	float DamageBarDistance = 1000;
	UPROPERTY()
	float DamageBarStartOffset = 100;
	UPROPERTY()
	float DamageBarSpacing = 55;
	UPROPERTY()
	float DamageBarScaling = 0.45;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		ImpactResponseComp.OnImpactEvent.AddUFunction(this, n"OnRedBlueImpact");
		OverseerRedBlueDamageComp.OnDamage.AddUFunction(this, n"Damage");
		
		InteractionComp.Disable(this);
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");

		for(AHazePlayerCharacter Player : Game::Players)
		{
			Outline::ApplyOutline(RedMesh, Player, RedOutlineDataAsset, this, EInstigatePriority::Normal);
			Outline::ApplyOutline(BlueMesh, Player, BlueOutlineDataAsset, this, EInstigatePriority::Normal);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			Outline::ClearOutline(RedMesh, Player, this);
			Outline::ClearOutline(BlueMesh, Player, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			Outline::ApplyOutline(RedMesh, Player, RedOutlineDataAsset, this, EInstigatePriority::Normal);
			Outline::ApplyOutline(BlueMesh, Player, BlueOutlineDataAsset, this, EInstigatePriority::Normal);
		}
	}

	void SetColor(bool bColorBlue)
	{
		bBlue = bColorBlue;
		BlueMesh.SetVisibility(bBlue, false);
		RedMesh.SetVisibility(!bBlue, false);
	}

	UFUNCTION()
	private void Damage(float Damage, AHazeActor Instigator)
	{
		if(!CanDamage(Instigator))
			return;

		Health -= Damage * RedBlueDamagePerSecond;
		if(Health <= 0)
		{
			if(HasControl())
				CrumbStopOperation();
		}
	}

	UFUNCTION()
	private void OnRedBlueImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if(!CanDamage(Data.Player))
			return;

		UIslandOverseerReturnGrenadeEventHandler::Trigger_OnDamaged(this, FIslandOverseerReturnGrenadeOnDamagedEventData(bBlue));
		TookDamageTime = Time::GameTimeSeconds;
		TookDamageLocation = (ActorLocation - Data.Player.ActorLocation).GetSafeNormal() * TookDamageOffset;

		if(Time::GetGameTimeSince(FlashTime) > FlashDuration + 0.04)
		{
			DamageFlash::DamageFlashActor(this, FlashDuration, FLinearColor(50, 0, 0, 1));
			FlashTime = Time::GameTimeSeconds;
			// FlashDuration = Math::RandRange(0.05, 0.1);
		}
	}

	private bool CanDamage(AHazeActor Player)
	{
		if(Health <= 0)
			return false;
		if(bBlue && Player == Game::Mio)
			return false;
		if(!bBlue && Player == Game::Zoe)
			return false;
		return true;
	}

	private void StartOperation()
	{
		SetColor(bBlue);
		InteractionComp.Disable(this);
		bOperational = true;
		Health = 1;
		UIslandOverseerReturnGrenadeEventHandler::Trigger_OnRecover(this, FIslandOverseerReturnGrenadeOnRecoverEventData(bBlue));
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStopOperation()
	{
		UIslandOverseerReturnGrenadeEventHandler::Trigger_OnBreak(this, FIslandOverseerReturnGrenadeOnBreakEventData(bBlue, StoppedDuration));
		InteractionComp.Enable(this);
		bOperational = false;
		StoppedTime = Time::GameTimeSeconds;
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		ReturningPlayer = Player;
		AddActorCollisionBlock(this);
		PlayerComp = UIslandOverseerReturnGrenadePlayerComponent::GetOrCreate(Player);

		FVector Direction = Player.ActorLocation - ActorLocation;
		if(Player.ViewRotation.RightVector.DotProduct(Direction) > 0)
			PlayerComp.bReturnLeft = true;
		else
			PlayerComp.bReturnRight = true;

		AccLocation.SnapTo(ActorLocation);
		AccRotation.SnapTo(ActorRotation);
		
		UIslandOverseerReturnGrenadeEventHandler::Trigger_OnInteractionStarted(this);
		Player.PlayForceFeedback(ForceFeedback::Default_Very_Light, this);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStartReturn()
	{
		FVector Origin;
		FVector Direction;
		SceneView::DeprojectScreenToWorld_Absolute(ReturnScreenLocation, Origin, Direction);
		ReturnLocation = Origin + Direction * 250;

		// Do this before changing the launcher
		ReturnStartLocation = ActorLocation;
		ReturnDirection = (ReturnLocation - ActorLocation).GetSafeNormal();
		ReturnMidLocation = ((ReturnStartLocation + ReturnLocation) / 2) + ReturnDirection.Rotation().RightVector * 500;
		ReturnTarget = ProjectileComp.Launcher;
		ProjectileComp.Launcher = ReturningPlayer;
		ProjectileComp.bIsLaunched = false;
		ProjectileComp.Launch(ReturnDirection * 1800, ActorRotation);
		AccRotation.SnapTo(ActorRotation);
		bReturned = true;
		ReturnAlpha = 0;
		AccReturnSpeed.SnapTo(0);
		LandedTime = 0;
		UIslandOverseerReturnGrenadeEventHandler::Trigger_OnReturn(this);
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bOperational = false;
		LandedTime = 0;
		AddActorCollisionBlock(this);
		bReturned = false;		
		ProjectileComp.TraceType = ETraceTypeQuery::WeaponTraceEnemy;
		ProjectileComp.Launcher = Launcher;
		ProjectileComp.bIsLaunched = false;
		InteractionComp.Disable(this);
		Health = MaxHealth;
	}

	UFUNCTION()
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		UIslandOverseerReturnGrenadeEventHandler::Trigger_OnLaunch(this, FIslandOverseerReturnGrenadeOnLaunchEventData(Projectile.Owner.ActorLocation));
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!bReturned && PlayerComp != nullptr && PlayerComp.bThrow)
		{
			if(ReturningPlayer.HasControl())
				CrumbStartReturn();
		}

		if (!ProjectileComp.bIsLaunched)
			return;

		if(TookDamageTime > 0 && Time::GetGameTimeSince(TookDamageTime) < TookDamageDuration)
			AccTookDamageLocation.AccelerateTo(TookDamageLocation, TookDamageDuration, DeltaTime);
		else
			AccTookDamageLocation.AccelerateTo(FVector::ZeroVector, TookDamageDuration, DeltaTime);
		MeshOffsetComp.RelativeLocation = AccTookDamageLocation.Value;

		if(StoppedTime > SMALL_NUMBER && Time::GetGameTimeSince(StoppedTime) > StoppedDuration)
		{
			StartOperation();
			StoppedTime = 0;
		}

		// Local movement, should be deterministic(ish)
		if(bReturned)
		{
			AccReturnSpeed.AccelerateTo(ReturnSpeed, 0.5, DeltaTime);
			ReturnAlpha += AccReturnSpeed.Value * DeltaTime;
			ActorLocation = BezierCurve::GetLocation_1CP_ConstantSpeed(ReturnStartLocation, ReturnMidLocation, ReturnLocation, ReturnAlpha);

			FRotator TargetRotation = BezierCurve::GetDirection_1CP_ConstantSpeed(ReturnStartLocation, ReturnMidLocation, ReturnLocation, ReturnAlpha).Rotation();
			AccRotation.AccelerateTo(TargetRotation, 0.5, DeltaTime);
			SetActorRotation(AccRotation.Value);

			if(ReturnAlpha >= 1)
			{
				FHitResult ReturnHit = FHitResult();
				ReturnHit.Actor = ReturnTarget;
				DoHit(ReturnHit);
			}
			return;
		}
		else if(PlayerComp != nullptr && (PlayerComp.bReturnLeft || PlayerComp.bReturnRight))
		{
			AccLocation.AccelerateTo(ReturningPlayer.Mesh.GetSocketLocation(n"RightAttach"), 0.2, DeltaTime);
			SetActorLocation(AccLocation.Value);
		}
		if(LandedTime > 0)
		{
			AccRotation.SpringTo(FRotator::ZeroRotator, 150, 0.25, DeltaTime);
			SetActorRotation(AccRotation.Value);

			if(Health > 0 && !bOperational && Time::GetGameTimeSince(LandedTime) > 0.75)
			{
				bOperational = true;
				RemoveActorCollisionBlock(this);
			}

			return;
		}
		else
		{
			FHitResult Hit;
			SetActorLocation(GetUpdatedMovementLocation(DeltaTime, Hit));
			SetActorRotation(ProjectileComp.Velocity.RotateAngleAxis(90, ProjectileComp.Velocity.Rotation().RightVector).Rotation());
			if (Hit.bBlockingHit)
				DoHit(Hit);
		}
	}

	private void DoHit(FHitResult Hit)
	{
		OnImpact(Hit);
		Impact(Hit);
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
		if(Player != nullptr)
		{
			if(!HitTargets.Contains(Player))
			{
				Player.KillPlayer();
				HitTargets.Add(Player);
			}
			return;
		}

		if(bReturned)
			Explode();
		else
			UIslandOverseerReturnGrenadeEventHandler::Trigger_OnHit(this, FIslandOverseerReturnGrenadeOnHitEventData(Hit));
		Land();
	}

	private void Impact(FHitResult Hit)
	{
		FBasicAiProjectileOnImpactData Data;
		Data.HitResult = Hit;
		UBasicAIProjectileEffectHandler::Trigger_OnImpact(ProjectileComp.HazeOwner, Data);
		BasicAIProjectile::DealDamage(Hit, ProjectileComp.Damage, ProjectileComp.DamageType, ProjectileComp.Launcher);
	}

	void Explode()
	{
		UIslandOverseerReturnGrenadeEventHandler::Trigger_OnExplode(this);
		ProjectileComp.Expire();
	}

	void Land()
	{
		LandedTime = Time::GameTimeSeconds;
		AccRotation.SnapTo(ProjectileComp.Velocity.RotateAngleAxis(90, ProjectileComp.Velocity.Rotation().RightVector).Rotation());
		UIslandOverseerReturnGrenadeEventHandler::Trigger_OnLandImpact(this);
	}

	// Helper function for simple trace projectiles
	private FVector GetUpdatedMovementLocation(float DeltaTime, FHitResult& OutHit, bool bIgnoreCollision = false, float SubStepDuration = BIG_NUMBER)
	{
		FVector OwnLoc = ProjectileComp.Owner.ActorLocation;
		
		FVector Delta = FVector::ZeroVector;

		// TODO: Use frame independent gravity and friction instead (Loc.Z -= Gravity * Math::Square(DeltaTime) * 0.5 and pow/exp) and test properly
		// Perform substepping movement
		float RemainingTime = DeltaTime;
		for(; RemainingTime > SubStepDuration; RemainingTime -= SubStepDuration)
		{
			ProjectileComp.Velocity -= ProjectileComp.UpVector * ProjectileComp.Gravity * SubStepDuration;
			ProjectileComp.Velocity -= ProjectileComp.Velocity * ProjectileComp.Friction * SubStepDuration;
			Delta += ProjectileComp.Velocity * SubStepDuration;
		}

		// Move the remaining fraction of a substep
		ProjectileComp.Velocity -= ProjectileComp.UpVector * ProjectileComp.Gravity * RemainingTime;
		ProjectileComp.Velocity -= ProjectileComp.Velocity * ProjectileComp.Friction * RemainingTime;
		Delta += ProjectileComp.Velocity * RemainingTime;

		if (Delta.IsNearlyZero())
			return OwnLoc;

		if (!bIgnoreCollision)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ProjectileComp.TraceType);
			Trace.UseCapsuleShape(Collider);
			Trace.IgnoreActors(ProjectileComp.AdditionalIgnoreActors);
			if(bReturned)
				Trace.IgnoreActors(Game::Players);

			if (Launcher != nullptr)
			{	
				Trace.IgnoreActor(Launcher, ProjectileComp.bIgnoreDescendants);

				if (ProjectileComp.bIgnoreLauncherAttachParents)
				{
					AActor AttachParent = Launcher.AttachParentActor;
					while (AttachParent != nullptr)
					{
						Trace.IgnoreActor(AttachParent);
						AttachParent = AttachParent.AttachParentActor;
					}				
				}
			}
			OutHit = Trace.QueryTraceSingle(OwnLoc, OwnLoc + Delta);

			if (OutHit.bBlockingHit && !OutHit.Actor.IsA(AHazePlayerCharacter))
				return OutHit.ImpactPoint;
		}

		return OwnLoc + Delta;
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	// Projectile impacted on local side, any gameplay need to be networked if started here
	UFUNCTION(BlueprintEvent)
	void OnLocalImpact(FHitResult Hit) {}
}