class ATundraBossFallingIceBlockStairs : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default Mesh.WorldScale3D = FVector(7,7,7);

	UPROPERTY()
	UNiagaraSystem ImpactVFX;
	UPROPERTY()
	UNiagaraSystem CrackVFX;

	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	TSubclassOf<UCameraShakeBase> ImpactCameraShakeClass;
	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	float Scale = 1.0;
	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	bool bPlayInWorld = true;
	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	float InnerRadius = 850.0;
	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	float OuterRadius = 3000.0;

	UPROPERTY(EditInstanceOnly)
	float DropDelay = 0;

	float FallDistance = 10000;

	FHazeTimeLike DropIceBlockTimelike;
	default DropIceBlockTimelike.Duration = 0.5;

	default ActorHiddenInGame = true;
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DropIceBlockTimelike.BindUpdate(this, n"DropIceBlockTimelikeUpdate");
		DropIceBlockTimelike.BindFinished(this, n"DropIceBlockTimelikeFinished");
	}

	UFUNCTION()
	void StartDroppingIceBlock()
	{
		if(DropDelay <= 0)
		{
			StartDroppingIceBlockDelayed();
			
		}
		else
		{
			Timer::SetTimer(this, n"StartDroppingIceBlockDelayed", DropDelay);
		}
	}

	UFUNCTION()
	private void StartDroppingIceBlockDelayed()
	{
		SetActorHiddenInGame(false);
		DropIceBlockTimelike.PlayFromStart();
		UTundraBossFallingIceBlockEffectEventHandler::Trigger_OnStartFalling(this);
	}

	UFUNCTION()
	private void DropIceBlockTimelikeUpdate(float CurrentValue)
	{
		float Height = Math::Lerp(FallDistance, 0, CurrentValue);
		MeshRoot.SetRelativeLocation(FVector(0, 0, Height));
	}

	UFUNCTION()
	private void DropIceBlockTimelikeFinished()
	{
		OnIceBlockImpact();
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ImpactVFX, ActorLocation, ActorRotation);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(CrackVFX, ActorLocation, ActorRotation);
		UTundraBossFallingIceBlockEffectEventHandler::Trigger_OnHitGround(this);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(ImpactCameraShakeClass, this, MeshRoot.WorldLocation, InnerRadius, OuterRadius, 1.0, Scale);
	}

	UFUNCTION(BlueprintEvent)
	void OnIceBlockImpact(){}
};

class ATundraBossFallingIceBlockStairsTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxTrigger;

	UPROPERTY(EditInstanceOnly)
	TArray<ATundraBossFallingIceBlockStairs> IceBlocks;

	bool bHasBeenTriggered = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnTrigger");
	}

	UFUNCTION()
	private void OnTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{
		if(bHasBeenTriggered)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;
		if(!Player.HasControl())
			return;

		TriggerIceBlocks();
		bHasBeenTriggered = true;
	}

	void TriggerIceBlocks()
	{
		for(auto Block : IceBlocks)
			Block.StartDroppingIceBlock();
	}
}