class AGravityBikeFreeBillBoard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent,Attach = Pivot)
	UStaticMeshComponent MainBillboard;

	UPROPERTY(DefaultComponent, Attach = MainBillboard)
	UStaticMeshComponent LegLeft;

	UPROPERTY(DefaultComponent, Attach = LegLeft)
	UAutoAimTargetComponent AimCompLeft;

	UPROPERTY(DefaultComponent, Attach = MainBillboard)
	UStaticMeshComponent LegRight;

	UPROPERTY(DefaultComponent, Attach = LegRight)
	UAutoAimTargetComponent AimCompRight;

	UPROPERTY(DefaultComponent)
	UGravityBikeWeaponProjectileResponseComponent WeaponComp;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike TimeLike;

	UPROPERTY(EditDefaultsOnly, Category =" Settings")
	UNiagaraSystem HitEffect;
	
	FVector Impulse;
	float BillboardLegs;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WeaponComp.OnImpact.AddUFunction(this, n"OnBikeBulletsHit");
		TimeLike.BindUpdate(this, n"AnimationUpdate");
		
	
	}


	UFUNCTION()
	private void AnimationUpdate(float CurrentValue)
	{
		Pivot.RelativeRotation = FRotator( CurrentValue * 90, 0.0,  0.0);
	}

	UFUNCTION()
	private void OnBikeBulletsHit(FGravityBikeWeaponImpactData ImpactData)
	{	
		UPrimitiveComponent CompHit = ImpactData.HitComponent;
		Niagara::SpawnOneShotNiagaraSystemAtLocation(HitEffect, CompHit.RelativeLocation, CompHit.RelativeRotation);
		CompHit.DestroyComponent(this);
		BillboardLegs++;
		

		if(BillboardLegs==2)
		{
		
			//TimeLike.Play();
				MainBillboard.SetSimulatePhysics(true);
		MainBillboard.AddImpulse(-FVector::UpVector * 55000000.0);
			
		}
	}

};