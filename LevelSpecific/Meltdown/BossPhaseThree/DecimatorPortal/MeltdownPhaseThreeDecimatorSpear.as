UCLASS(Abstract)
class AMeltdownPhaseThreeDecimatorSpear : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UTelegraphDecalComponent TelegraphDecal;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> SpearShake;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect SpearFeedback; 

	AHazePlayerCharacter TargetPlayer;

	const float DamageRadius = 150.0;
	const float BlockingRadius = 250.0;
	const float TargetHeight = 2000.0;
	float StartHeight;

	bool bBlocksAttacks = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartHeight = Mesh.RelativeLocation.Z;
	}
	
	void Launch()
	{
		UMeltdownPhaseThreeDecimatorSpearEffectHandler::Trigger_OnTelegraph(this);

		ActionQueue.Idle(0.75);
		ActionQueue.Event(this, n"StartRising");
		ActionQueue.Duration(0.6, this, n"Rise");
		ActionQueue.Event(this, n"FinishAttack");
		ActionQueue.Idle(1.0);
		ActionQueue.Event(this, n"Destroy");
	}

	UFUNCTION()
	private void StartRising()
	{
		UMeltdownPhaseThreeDecimatorSpearEffectHandler::Trigger_OnLaunch(this);

		TelegraphDecal.HideTelegraph();
		bBlocksAttacks = false;

		FVector DamageOrigin = ActorLocation;
		// Debug::DrawDebugSphere(DamageOrigin, DamageRadius, LineColor = FLinearColor::Red);

		bool bHitPlayer = false;
		for (auto Player : Game::Players)
		{
			if (Player.CapsuleComponent.IntersectsSphere(DamageOrigin, DamageRadius))
			{
				FVector KnockDirection = (Player.ActorLocation - DamageOrigin).GetSafeNormal2D();
				Player.AddKnockbackImpulse(KnockDirection, 900.0, 1200.0);
				Player.DamagePlayerHealth(0.5);

				bHitPlayer = true;
			}
		}
		
		if (bHitPlayer)
			UMeltdownPhaseThreeDecimatorSpearEffectHandler::Trigger_OnHitPlayer(this);
	}

	UFUNCTION()
	private void Rise(float Alpha)
	{
		float HeightAlpha = Math::EaseIn(0.0, 1.0, Alpha, 2.0);
		float Height = Math::Lerp(StartHeight, TargetHeight, HeightAlpha);
		Mesh.SetRelativeLocation(FVector(0, 0, Height));

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if(ActorLocation.Dist2D(Player.ActorLocation) < 200)
			{
				Player.PlayCameraShake(SpearShake,this);
				Player.PlayForceFeedback(SpearFeedback,false,false,this);
			}
		}
	}

	UFUNCTION()
	private void FinishAttack()
	{
		Mesh.SetHiddenInGame(true);
	}

	UFUNCTION()
	private void Destroy()
	{
		DestroyActor();
	}
};

UCLASS(Abstract)
class UMeltdownPhaseThreeDecimatorSpearEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraph() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitPlayer() {}

}
