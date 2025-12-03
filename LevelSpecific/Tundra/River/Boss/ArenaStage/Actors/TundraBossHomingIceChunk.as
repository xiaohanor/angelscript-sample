event void FOnIceChunkExploded(FVector ExplosionLocation);

class ATundraBossHomingIceChunk : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent SphereFX;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent DamageLocation;

	UPROPERTY(EditInstanceOnly)
	AHazeActor ZLocationReferece;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ExplosionVFX;

	UPROPERTY()
	FHazeTimeLike SpawnAnimationTimelike;
	default SpawnAnimationTimelike.Duration = 0.5;

	UPROPERTY()
	FOnIceChunkExploded OnIceChunkExploded;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer PlayerToFollow;

	UPROPERTY()
	TSubclassOf<UDamageEffect> FurBallDamageEffect;
	UPROPERTY()
	TSubclassOf<UDeathEffect> FurBallDeathEffect;
	UPROPERTY()
	UCurveVector SpawnCurve;

	FVector SpawnAnimationStartLoc;
	FVector SpawnAnimationEndLoc;

	float ChaseTime = 0;
	float ChaseTimeDuration = 5;

	float SpawnInterpolationTimer = 0;
	float SpawnInterpolationTimerDuration = 1;
	FVector SpawnForwardLocation;
	
	float MinSpeed = 550;
	float BigShapeMonkeyMinSpeed = 600;
	float BigShapeTreeMinSpeed = 550;
	float MaxSpeed = 1000;
	float SpeedAtSlowDown = 0;
	float SlowDownTimer = 0;
	float CurrentSpeed = 0;
	bool bSlowingDown = false;
	bool bIceChunkHidden = true;

	//Slighty smaller than the ball itself to make it penetrate the player's capsule a bit
	float HitSphereRadius = 85;

	AHazePlayerCharacter TargetPlayer;
	FVector StartingLocation;
	FVector LocationLastTick;
	FVector CurrentVelocity;

	bool bChunkIsExploding = false;

	bool bExploded = false;
	bool bExplodedOnRemote = false;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(PlayerToFollow == EHazePlayer::Mio)
		{
			SetActorControlSide(Game::Mio);
			TargetPlayer = Game::Mio;
		}
		else
		{
			SetActorControlSide(Game::Zoe);
			TargetPlayer = Game::Zoe;
		}

		SpawnAnimationTimelike.BindUpdate(this, n"SpawnAnimationTimelikeUpdate");
		SpawnAnimationTimelike.BindFinished(this, n"SpawnAnimationTimelikeFinished");
	}

	UFUNCTION()
	private void SpawnAnimationTimelikeUpdate(float CurrentValue)
	{
		SetActorLocation(Math::VLerp(SpawnAnimationStartLoc, SpawnAnimationEndLoc, SpawnCurve.GetVectorValue(CurrentValue)));
	}

	UFUNCTION()
	private void SpawnAnimationTimelikeFinished()
	{
		ActivateIceChunk();	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{		
		CurrentVelocity = (ActorLocation - LocationLastTick) / DeltaSeconds;
		LocationLastTick = ActorLocation;
		FVector Cross = FVector::UpVector.CrossProduct(CurrentVelocity.GetSafeNormal());
		Mesh.AddWorldRotation(Math::RotatorFromAxisAndAngle(Cross, CurrentVelocity.Size() * DeltaSeconds));

		CollisionCheck();

		if(bSlowingDown)
		{
		 	SlowDownTimer += DeltaSeconds;
			SlowDownTimer = Math::Saturate(SlowDownTimer);

			if(SlowDownTimer >= 1)
			{
				bSlowingDown = false;
				ChaseTime = 0;
				bChunkIsExploding = true;
				
				if(HasControl())
					CrumbExplode();
			}
		}

		if(bChunkIsExploding)
			return;

		ChaseTime += DeltaSeconds;
		if(ChaseTime >= ChaseTimeDuration && !bSlowingDown)
		{
			SpeedAtSlowDown = CurrentSpeed;
			bSlowingDown = true;
		}

		MoveChunk(DeltaSeconds);
	}

	private void MoveChunk(float DeltaSeconds)
	{
		AHazePlayerCharacter CurrentTarget;

		if(!TargetPlayer.IsPlayerDead() || TargetPlayer.OtherPlayer.IsPlayerDead())
		{
			CurrentTarget = TargetPlayer;
		}
		else
		{
			CurrentTarget = TargetPlayer.OtherPlayer;
		}

		FVector SpawnDir;
		FVector SpawnTargetLocation;
		
		CurrentSpeed = GetSpeed(CurrentTarget);

		// We're most likely chasing the same target with two chunks at this point. Slowing this down a bit so they're less likely to overlap.
		if(CurrentTarget != TargetPlayer)
			CurrentSpeed *= 0.75;
		
		// Doing this so that the ball doesn't snap towards the current target right after the spawn animation, but instead follows the spawn velocity for a short while.
		if(SpawnInterpolationTimer <= 1)
		{
			SpawnDir = (SpawnForwardLocation - ActorLocation).GetSafeNormal2D();
			SpawnTargetLocation = ActorLocation + SpawnDir * CurrentSpeed * DeltaSeconds;
			SpawnInterpolationTimer += DeltaSeconds;
		}

		FVector TargetLocation;
		FVector TargetDir = (CurrentTarget.ActorLocation - ActorLocation).GetSafeNormal2D();
		TargetLocation = ActorLocation + TargetDir * CurrentSpeed * DeltaSeconds;

		FVector NewLocation = Math::Lerp(SpawnTargetLocation, TargetLocation, Math::Saturate(SpawnInterpolationTimer/SpawnInterpolationTimerDuration));
		SetActorLocation(NewLocation);
	}

	private float GetSpeed(AHazePlayerCharacter Player)
	{
		float MinSpeedToUse = MinSpeed;

		if(bSlowingDown)
			return Math::Lerp(SpeedAtSlowDown, 0, SlowDownTimer);

		auto ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		
		if(ShapeShiftComp == nullptr)
			return 0;

		if(Player == Game::Mio && ShapeShiftComp.CurrentShapeType == ETundraShapeshiftShape::Big)
			MinSpeedToUse = BigShapeMonkeyMinSpeed;

		if(Player == Game::Zoe && ShapeShiftComp.CurrentShapeType == ETundraShapeshiftShape::Big)
			MinSpeedToUse = BigShapeTreeMinSpeed;		

		float Dist = (Player.ActorLocation - ActorLocation).Size2D();
		if(Dist > 100)
			return Math::GetMappedRangeValueClamped(FVector2D(1000, 150), FVector2D(MaxSpeed, MinSpeedToUse), Dist);
		else
			return Math::GetMappedRangeValueClamped(FVector2D(100, 50), FVector2D(MinSpeedToUse, 0.0), Dist);
	}

	// Called from AnimNotify - Starts the spawn animation. Fully activates the IceChunk when the animation is done. 
	void ActivateIceChunkFromIceKingAnimation(FVector SpawnLocation, FVector ForwardVector)
	{
		bIceChunkHidden = false;
		bExploded = false;
		bExplodedOnRemote = false;
		SetActorHiddenInGame(false);
		
		SpawnAnimationStartLoc = SpawnLocation;
		SpawnAnimationEndLoc = SpawnAnimationStartLoc + ForwardVector * 1500;
		SpawnAnimationEndLoc.Z = ZLocationReferece.ActorLocation.Z;
		StartingLocation = SpawnAnimationEndLoc;
		
		FTundraBossHomingIceChunkEffectParams Params;
		Params.Lifetime = ChaseTimeDuration;
		UTundraBossHomingIceChunk_EffectHandler::Trigger_OnIceChunkSpawned(this, Params);
		
		SetActorRotation(FRotator::MakeFromX(ForwardVector));
		SpawnAnimationTimelike.PlayFromStart();
	}

	UFUNCTION()
	private void ActivateIceChunk()
	{
		SpawnForwardLocation = ActorLocation + ActorForwardVector * 1000;
		SpawnInterpolationTimer = 0;
		SetActorTickEnabled(true);
			
		ChaseTime = 0;
		SlowDownTimer = 0;
		bSlowingDown = false;
		bChunkIsExploding = false;
	}

	void DeactivateIceChunk()
	{	
		bIceChunkHidden = true;
		SetActorTickEnabled(false);
		SetActorHiddenInGame(true);
		SetActorLocation(StartingLocation);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbExplode()
	{
		bExploded = true;
		OnIceChunkExploded.Broadcast(ActorLocation);
		
		bool bRemotePlayVFX = !HasControl() && !bExplodedOnRemote;
		if(HasControl() || bRemotePlayVFX)
		{			
			Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, ActorLocation);
			SetActorHiddenInGame(true);
			FTundraBossHomingIceChunkEffectParams Params;
			Params.ExplosionLocation = ActorLocation;
			UTundraBossHomingIceChunk_EffectHandler::Trigger_OnIceChunkExploded(this, Params);
		}

		DeactivateIceChunk();
	}

	// Only used if this ball is the remaining one when the ice explodes. Not a crumbfunction since the call already is crumbed.
	void ExplodeFromIceExplosion()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, ActorLocation);
		SetActorHiddenInGame(true);
		FTundraBossHomingIceChunkEffectParams Params;
		Params.ExplosionLocation = ActorLocation;
		UTundraBossHomingIceChunk_EffectHandler::Trigger_OnIceChunkExploded(this, Params);
		
		DeactivateIceChunk();
	}

	private void ExplodeLocal()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, ActorLocation);
		SetActorHiddenInGame(true);
		FTundraBossHomingIceChunkEffectParams Params;
		Params.ExplosionLocation = ActorLocation;
		UTundraBossHomingIceChunk_EffectHandler::Trigger_OnIceChunkExploded(this, Params);
		SetActorTickEnabled(false);
	}

	void ExplodeOnRemote()
	{
		// Called only on remote side
		ExplodeLocal();
		NetRemoteExploded();
	}

	UFUNCTION(NetFunction)
	void NetRemoteExploded()
	{
		if(HasControl() && !bExploded)
			CrumbExplode();
	}
	
	private void CollisionCheck()
	{		
		if(!HasControl())
		{
			for(auto Player : Game::Players)
			{
				if(!Player.HasControl())
				continue;

				FHazeShapeSettings CapsuleSettings = FHazeShapeSettings::MakeCapsule(Player.CapsuleComponent.CapsuleRadius, Player.CapsuleComponent.CapsuleHalfHeight);
				float DistToCapsule = CapsuleSettings.GetWorldDistanceToShape(Player.CapsuleComponent.WorldTransform, ActorLocation);

				if(DistToCapsule < HitSphereRadius)
				{					
					ApplyDamageAndKnockdown(Player);
					ExplodeOnRemote();
					bExplodedOnRemote = true;
				}
			}

			return;
		}

		for(auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;

			FHazeShapeSettings CapsuleSettings = FHazeShapeSettings::MakeCapsule(Player.CapsuleComponent.CapsuleRadius, Player.CapsuleComponent.CapsuleHalfHeight);
			float DistToCapsule = CapsuleSettings.GetWorldDistanceToShape(Player.CapsuleComponent.WorldTransform, ActorLocation);

			if(DistToCapsule < HitSphereRadius)
			{
				ApplyDamageAndKnockdown(Player);
				CrumbExplode();
			}
		}
	}

	private void ApplyDamageAndKnockdown(AHazePlayerCharacter Player)
	{
		FVector Dir = CurrentVelocity;
		
		if(Dir == FVector::ZeroVector)
			Dir = ActorForwardVector;

		FPlayerDeathDamageParams DeathParams;
		DeathParams.ImpactDirection = Dir.GetSafeNormal2D();
		DeathParams.ForceScale = 5;
		Player.DamagePlayerHealth(0.5, DeathParams, FurBallDamageEffect, FurBallDeathEffect);

		FKnockdown KnockDown;
		KnockDown.Move = (Dir.GetSafeNormal2D() * 2500);
		KnockDown.Duration = 2;
		Player.ApplyKnockdown(KnockDown);
	}
};