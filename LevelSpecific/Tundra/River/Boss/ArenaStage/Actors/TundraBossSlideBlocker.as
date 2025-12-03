class ATundraBossSlideBlocker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent DestroyVFX;
	default DestroyVFX.bAutoActivate = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		DestroyBlocker(Player);
	}

	void DestroyBlocker(AHazePlayerCharacter Player)
	{
		BoxComp.CollisionEnabled = ECollisionEnabled::NoCollision;
		Mesh.SetHiddenInGame(true);
		Player.DamagePlayerHealth(0.1);
		DestroyVFX.Activate();
		BP_FFOnImpact(Player);
	}

	UFUNCTION(BlueprintEvent)
	void BP_FFOnImpact(AHazePlayerCharacter Player){}
};