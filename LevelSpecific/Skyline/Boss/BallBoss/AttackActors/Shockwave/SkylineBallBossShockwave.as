enum ESkylineBossShockwaveGroundState
{
	NotGrounded,
	GroundedInFront,
	GroundedBehind,
}

class ASkylineBallBossShockwave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ShockwaveRoot;

	UPROPERTY(DefaultComponent, Attach = ShockwaveRoot)
	UHazeDecalComponent DecalComp;

	UPROPERTY(DefaultComponent, Attach = ShockwaveRoot)
	UStaticMeshComponent ShockwaveMeshComp;

	UPROPERTY()
	UNiagaraSystem ActivateVFXSystem;
	
	UPROPERTY()
	float ShockwaveDuration = 5.0;

	UPROPERTY()
	float Damage = 0.4;

	UPROPERTY()
	float DamageCooldown = 0.5;

	float BallBossRadius = 980.0;

	float MaxXYScale = 9.5;

	ASkylineBallBoss BallBoss;

	bool bDangerous = false;

	UPROPERTY()
	FHazeTimeLike ShockwaveZTimelike;
	default ShockwaveZTimelike.UseSmoothCurveZeroToOne();

	private UPlayerMovementComponent MioMoveComp;
	private ESkylineBossShockwaveGroundState MioGroundStateLastFrame;

	float LastTimeHitMio;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShockwaveZTimelike.Duration = ShockwaveDuration;
		ShockwaveZTimelike.BindUpdate(this, n"ShockwaveZTimelikeUpdate");
		ShockwaveZTimelike.BindFinished(this, n"ShockwaveZTimelikeFinished");
		ShockwaveZTimelike.SetNewTime(0.5);
		Activate();

		MioMoveComp = UPlayerMovementComponent::Get(Game::Mio);
		MioGroundStateLastFrame = GetMioGroundState();

		MaxXYScale = 9.5 * (BallBossRadius / 980.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bDangerous)
		{
			if(HasMioWalkedOverShockwave() && ShockwaveZTimelike.Position > 0.01)
			{
				if (LastTimeHitMio + DamageCooldown < Time::GameTimeSeconds)
				{
					FVector DeathDir = (Game::Mio.ActorLocation - ActorLocation).GetSafeNormal();
					Game::Mio.DamagePlayerHealth(0.4, FPlayerDeathDamageParams(DeathDir), BallBoss.LaserSoftDamageEffect, BallBoss.LaserSoftDeathEffect);
					LastTimeHitMio = Time::GameTimeSeconds;
				}
			}
		}

		MioGroundStateLastFrame = GetMioGroundState();
	}

	UFUNCTION()
	void Activate()
	{
		DecalComp.SetHiddenInGame(false);
		ShockwaveZTimelike.Play();
		if (ActivateVFXSystem != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(ActivateVFXSystem, ActorLocation);
		bDangerous = true;
	}

	UFUNCTION()
	private void ShockwaveZTimelikeUpdate(float CurrentValue)
	{
		ShockwaveRoot.SetRelativeLocation(FVector::ForwardVector * -BallBossRadius * 2 * CurrentValue);
		//Debug::DrawDebugBox(DecalComp.WorldLocation, DecalComp.DecalSize, DecalComp.WorldRotation);

		float Alpha = Math::Sin(ShockwaveZTimelike.GetPosition() * PI);
		float XYScale = Math::Lerp(0.0, MaxXYScale, Alpha);
		XYScale = Math::Max(XYScale, SMALL_NUMBER);
		ShockwaveMeshComp.SetRelativeScale3D(FVector(XYScale, XYScale, XYScale));
	}

	UFUNCTION()
	private void ShockwaveZTimelikeFinished()
	{
		Deactivate();
	}

	UFUNCTION()
	private void Deactivate()
	{
		DestroyActor();
	}

	bool IsMioWalkingOnBallBoss() const
	{
		if(!MioMoveComp.HasGroundContact())
			return false;

		if(MioMoveComp.GroundContact.Actor != BallBoss)
			return false;

		if(MioMoveComp.GroundContact.Component.HasTag(n"Safe"))
			return false;

		return true;
	}

	ESkylineBossShockwaveGroundState GetMioGroundState() const
	{
		if(!IsMioWalkingOnBallBoss())
			return ESkylineBossShockwaveGroundState::NotGrounded;

		// Check if our ground impact location is in the forward or backward direction from the decal
		const FVector Delta = MioMoveComp.GroundContact.Location - DecalComp.WorldLocation;
		const bool bIsInFront = Delta.DotProduct(DecalComp.WorldRotation.ForwardVector) > 0;

		if(bIsInFront)
			return ESkylineBossShockwaveGroundState::GroundedInFront;
		else
			return ESkylineBossShockwaveGroundState::GroundedBehind;
	}

	bool HasMioWalkedOverShockwave() const
	{
		// If our ground is not the ball boss, we can't have walked over the shockwave
		if(!IsMioWalkingOnBallBoss())
			return false;

		// If our ground impact is within the decal, we are currently walking on the shockwave
		if(Math::IsPointInBoxWithTransform(MioMoveComp.GroundContact.Location, DecalComp.WorldTransform, DecalComp.DecalSize))
			return true;

		// If we were grounded last frame...
		if(MioGroundStateLastFrame != ESkylineBossShockwaveGroundState::NotGrounded)
		{
			const ESkylineBossShockwaveGroundState MioGroundStateThisFrame = GetMioGroundState();

			// ...and we were behind and now in front, or vice versa, then we have walked across the shockwave
			if(MioGroundStateLastFrame != MioGroundStateThisFrame)
			{
				return true;
			}
		}

		return false;
	}
};