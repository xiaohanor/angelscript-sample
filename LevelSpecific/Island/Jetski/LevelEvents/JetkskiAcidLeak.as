class AJetskiAcidLeak : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ActivationEffect;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent LeakEffect;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DeathCollision;
	default DeathCollision.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY()
	TSubclassOf<UDeathEffect> AcidLeakDeathEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeathCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		if(!Player.HasControl())
			return;

		Player.KillPlayer(FPlayerDeathDamageParams(), AcidLeakDeathEffect);

		UJetskiAcidLeakEventHandler::Trigger_OnKillPlayer(this);
	}

	UFUNCTION()
	void ActivateLeak()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ActivationEffect, ActorLocation);
		LeakEffect.Activate();

		UJetskiAcidLeakEventHandler::Trigger_StartLeaking(this);

		DeathCollision.CollisionEnabled = ECollisionEnabled::QueryOnly;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(CameraShakeClass, this, ActorLocation, 15000.0, 15000.0);
		
	}
};

UCLASS(Abstract)
class UJetskiAcidLeakEventHandler : UHazeEffectEventHandler
{
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartLeaking()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKillPlayer()
	{
	}

};