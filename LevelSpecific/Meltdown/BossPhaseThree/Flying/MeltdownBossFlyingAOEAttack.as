event void FOnFireComplete();

class AMeltdownBossFlyingAOEAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase WalkerHead;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent DamageCollision;

	FRotator StartRot = FRotator(40,0,0);
	FRotator EndRot = FRotator(-40,0,0);

	UPROPERTY()
	bool bCanDamage;

	UPROPERTY()
	FOnFireComplete FireComplete;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintCallable)
	void Launch()
	{
		RemoveActorDisable(this);
		StartSequence();
	}

	UFUNCTION(BlueprintEvent)
	void StartSequence()
	{}

	UFUNCTION(BlueprintCallable)
	void SequenceDone()
	{
		FireComplete.Broadcast();
		AddActorDisable(this);
	}

};