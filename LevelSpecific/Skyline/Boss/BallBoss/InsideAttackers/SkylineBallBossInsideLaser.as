class ASkylineBallBossInsideLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UBoxComponent LaserCollision1;
	default LaserCollision1.bGenerateOverlapEvents = false;
	default LaserCollision1.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UBoxComponent LaserCollision2;
	default LaserCollision2.bGenerateOverlapEvents = false;
	default LaserCollision2.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UBoxComponent LaserCollision3;
	default LaserCollision3.bGenerateOverlapEvents = false;
	default LaserCollision3.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 30.0;

	UPROPERTY(EditAnywhere)
	float DamageCooldown = 0.5;
	float DamageTimeStamp;

	float ActualRotationSpeed = 0.0;

	bool bRotating = false;

	ASkylineBallBoss BallBoss;

	UPlayerMovementComponent MioMoveComp;

	bool bLaserActive = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BallBoss = Cast<ASkylineBallBoss>(AttachmentRootActor);
		BallBoss.OnPhaseChanged.AddUFunction(this, n"HandlePhaseChanged");

		MioMoveComp = UPlayerMovementComponent::Get(Game::Mio);
	}

	UFUNCTION()
	private void HandlePhaseChanged(ESkylineBallBossPhase NewPhase)
	{
		if (NewPhase == ESkylineBallBossPhase::TopMioIn)
			Activate();

		if (NewPhase == ESkylineBallBossPhase::TopMioInKillWeakpoint)
			Deactivate();

		if (NewPhase == ESkylineBallBossPhase::TopSmallBoss)
			DisableActor();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RotationRoot.AddRelativeRotation(FRotator(0.0, ActualRotationSpeed * DeltaSeconds, 0.0));
		
		if (bLaserActive && HasMioWalkedOverShockwave() && DamageTimeStamp + DamageCooldown < Time::GameTimeSeconds)
		{
			DamageTimeStamp = Time::GameTimeSeconds;
			Game::Mio.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(Game::Mio.ActorUpVector), BallBoss.LaserSoftDamageEffect, BallBoss.LaserSoftDeathEffect);
		}

		if (bLaserActive && !bRotating && IsMioWalkingOnBallBoss())
		{
			StartRotating();
		}
	}

	bool HasMioWalkedOverShockwave() const
	{
		// If our ground is not the ball boss, we can't have walked over the shockwave
		if(!IsMioWalkingOnBallBoss())
			return false;

		// If our ground impact is within the collision, we are currently walking on the shockwave
		if(Math::IsPointInBoxWithTransform(MioMoveComp.GroundContact.Location, LaserCollision1.WorldTransform, LaserCollision1.BoxExtent))
			return true;

		if(Math::IsPointInBoxWithTransform(MioMoveComp.GroundContact.Location, LaserCollision2.WorldTransform, LaserCollision2.BoxExtent))
			return true;

		if(Math::IsPointInBoxWithTransform(MioMoveComp.GroundContact.Location, LaserCollision3.WorldTransform, LaserCollision3.BoxExtent))
			return true;

		return false;
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

	UFUNCTION()
	private void Activate()
	{
		bLaserActive = true;
		BP_Activate();
		//QueueComp.Duration(2.0, this, n"AccelerateUpadate");
	}

	private void StartRotating()
	{
		bRotating = true;
		QueueComp.Duration(2.0, this, n"AccelerateUpadate");
	}

	UFUNCTION()
	private void Deactivate()
	{
		bLaserActive = false;
		BP_Deactivate();
		QueueComp.ReverseDuration(1.0, this, n"AccelerateUpadate");
	}

	UFUNCTION()
	private void DisableActor()
	{
		AddActorDisable(this);
	}

	UFUNCTION()
	private void AccelerateUpadate(float Alpha)
	{
		ActualRotationSpeed = RotationSpeed * Alpha;
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activate(){}

	UFUNCTION(BlueprintEvent)
	private void BP_Deactivate(){}
};