UCLASS(Abstract)
class ASketchbookBossProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CollissionMesh;
	default CollissionMesh.GenerateOverlapEvents = true;
	default CollissionMesh.bVisible = false;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem OnDestroyedEffect;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect KnockDownForceFeedback;

	const float Damage = 0.5;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UHazeAudioEvent ProjectileShootAudioEvent;
	
	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UHazeAudioEvent ProjectileHitAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UHazeAudioEvent ProjectileImpactAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	private UHazeAudioEmitter ProjectileEmitter;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		OnDestroyed.AddUFunction(this, n"OnProjectileDestroyed");

		FHazeAudioEmitterAttachmentParams EmitterParams;
		EmitterParams.Attachment = Mesh;
		EmitterParams.Instigator = this;
		EmitterParams.Owner = this;

		ProjectileEmitter = Audio::GetPooledEmitter(EmitterParams);

		ProjectileEmitter.PostEvent(ProjectileShootAudioEvent);
	}

	UFUNCTION()
	private void OnProjectileDestroyed(AActor DestroyedActor)
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(OnDestroyedEffect, ActorLocation, ActorRotation);
		Audio::ReturnPooledEmitter(this, ProjectileEmitter);
	}

	UFUNCTION()
	private void OnBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if(Player == nullptr)
			return;

		if(Player.IsPlayerDead())
			return;
		
		FVector KnockBack = Player.GetActorLocation() - GetActorLocation();
		KnockBack.Normalize();
		KnockBack *= 100;
		KnockBack.Z += 1;

		UPlayerKnockdownComponent::Get(Player).ClearOldKnockdowns(1);
		Player.ApplyKnockdown(KnockBack,1.5,n"Knockdown");
		Player.PlayForceFeedback(KnockDownForceFeedback, false, false, this);
		Player.DamagePlayerHealth(0.0, FPlayerDeathDamageParams(), DamageEffect);

		ProjectileEmitter.PostEvent(ProjectileHitAudioEvent);
		DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CollissionMesh.SetWorldLocation(FVector(0, ActorLocation.Y, ActorLocation.Z));
		
		if(ActorLocation.Z < SketchbookBoss::GetSketchbookBossFightManager().ArenaFloorZ)
		{
			if(SceneView::IsInView(SceneView::GetFullScreenPlayer(), ActorLocation))
				AudioComponent::PostFireForget(ProjectileImpactAudioEvent, FHazeAudioFireForgetEventParams());	
			DestroyActor();
		}		

		if(ProjectileEmitter != nullptr)
		{
			float X;
			float Y_;
			FVector2D Previous;
			Audio::GetScreenPositionRelativePanningValue(ProjectileEmitter.AudioComponent.WorldLocation, Previous, X, Y_);	
			ProjectileEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0.0);
		}
	}
	
};