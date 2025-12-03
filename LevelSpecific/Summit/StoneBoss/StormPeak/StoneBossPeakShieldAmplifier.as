event void FOnShieldAmplifierDestroyed(AStoneBossPeakShieldAmplifier Amplifier);

class AStoneBossPeakShieldAmplifier : AHazeActor
{
	FOnShieldAmplifierDestroyed OnShieldAmplifierDestroyed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereCollision;
	default SphereCollision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default SphereCollision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponse;

	UPROPERTY(DefaultComponent)
	UAdultDragonTailSmashModeResponseComponent ResponseComp;

	int MaxHits = 10;
	int Hits;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponse.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		ResponseComp.OnHitBySmashMode.AddUFunction(this, n"OnHitBySmashMode");
		
		if (HasControl())
			CrumbDestroyShieldAmplifier();
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		Hits--;
		HitCheck();
	}

	UFUNCTION()
	private void OnHitBySmashMode(FTailSmashModeHitParams Params)
	{
		Hits--;
		HitCheck();
	}

	void HitCheck()
	{
		if (!HasControl())
			return;

		if (Hits <= 0)
		{
			CrumbDestroyShieldAmplifier();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivateShieldAmplifier()
	{
		Hits = MaxHits;
		SphereCollision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);	
		SetActorHiddenInGame(false);
	}

	UFUNCTION(CrumbFunction)
	void CrumbDestroyShieldAmplifier()
	{
		SphereCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);	
		SetActorHiddenInGame(true);
		OnShieldAmplifierDestroyed.Broadcast(this);
	}
};