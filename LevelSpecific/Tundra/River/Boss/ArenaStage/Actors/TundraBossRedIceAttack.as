class ATundraBossRedIceAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;
	default MeshRoot.RelativeLocation = FVector(0, 0, -500);
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UTelegraphDecalComponent TelegraphDecal;
	default TelegraphDecal.bAutoShow = false;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh01;
	default Mesh01.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USphereComponent SphereCollision;
	default SphereCollision.bVisible = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UForceFeedbackComponent FFComp;

	UPROPERTY()
	FHazeTimeLike MoveIceUpTimelike;
	default MoveIceUpTimelike.Duration = 1;

	UPROPERTY()
	TSubclassOf<UDamageEffect> RedIceDamageEffect;
	UPROPERTY()
	TSubclassOf<UDeathEffect> RedIceDeathEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveIceUpTimelike.BindUpdate(this, n"MoveIceUpTimelikeUpdate");
		MoveIceUpTimelike.BindFinished(this, n"MoveIceUpTimelikeFinished");
		MoveIceUpTimelike.PlayRate = 1 / 0.1;

		MeshRoot.SetHiddenInGame(true, true);
	}

	UFUNCTION()
	void MoveIceUp()
	{
		MoveIceUpTimelike.PlayFromStart();
		MeshRoot.SetHiddenInGame(false, true);
		BP_OnRedIceStarted();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnRedIceStarted()
	{

	}	

	UFUNCTION()
	private void MoveIceUpTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.RelativeLocation = Math::Lerp(FVector(0, 0, -500), FVector::ZeroVector, CurrentValue);
	}

	UFUNCTION()
	private void MoveIceUpTimelikeFinished()
	{
		CollisionCheck(SphereCollision.SphereRadius);
		UTundraBossRedIceAttackEffectHandler::Trigger_OnStartRedIceAttack(this);
		TelegraphDecal.HideTelegraph();
		FFComp.Play();
		BP_ExplodeCamShake();
	}

	UFUNCTION()
	private void MoveIceDownTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.RelativeLocation = Math::Lerp(FVector::ZeroVector, FVector(0, 0, -500), CurrentValue);
	}

	UFUNCTION()
	private void MoveIceDownTimelikeFinished()
	{
		MeshRoot.SetHiddenInGame(true, true);
	}

	void CollisionCheck(float SphereRadius)
	{
		for(auto Player : Game::Players)
		{
			FHazeShapeSettings CapsuleSettings = FHazeShapeSettings::MakeCapsule(Player.CapsuleComponent.CapsuleRadius, Player.CapsuleComponent.CapsuleHalfHeight);
			float DistToCapsule = CapsuleSettings.GetWorldDistanceToShape(Player.CapsuleComponent.WorldTransform, ActorLocation);

			if(DistToCapsule < SphereRadius)
			{
				FVector Dir = (Player.ActorLocation - ActorLocation).GetSafeNormal();
				FPlayerDeathDamageParams DeathParams;
				DeathParams.ImpactDirection = Dir;
				DeathParams.ForceScale = 5;
				Player.DamagePlayerHealth(0.5, DeathParams, RedIceDamageEffect, RedIceDeathEffect);

#if TEST
				if(Player.GetGodMode() == EGodMode::God)
					return;
#endif

				FKnockdown KnockDown;
				KnockDown.Move = Dir * 500;
				KnockDown.Duration = 1.0;
				KnockDown.Cooldown = 2;
				Player.ApplyKnockdown(KnockDown);
			}
		}
	}

	void StartRedIceAttack(FVector SpawnLocation)
	{
		SetActorLocation(SpawnLocation);
		UTundraBossRedIceAttackEffectHandler::Trigger_OnStartRedIceForeshadow(this);

		TelegraphDecal.ShowTelegraph();
		Timer::SetTimer(this, n"MoveIceUp", 2);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ExplodeCamShake(){}
};

UCLASS(Abstract)
class UTundraBossRedIceAttackEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartRedIceAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartRedIceForeshadow() {}
}