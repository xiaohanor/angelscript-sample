class ASkylineBallBossSmallBossShieldSegment : AWhipSlingableObject
{
	UPROPERTY(DefaultComponent, Attach = Collision)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	USkylineSmallBossTractorBeamComponent TractorBeamVFXComp;

	UPROPERTY()
	UNiagaraSystem ShieldDestroyedVFX;

	ASkylineBallBossSmallBoss SmallBoss;

	float TractorBeamAppearDelay = 1.0;

	default bDestroyOnImpact = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		TractorBeamVFXComp.SetupTractorBeamMaterial(MeshComp);
		Timer::SetTimer(this, n"ActivateTractorBeam", TractorBeamAppearDelay);
		OnWhipSlingableObjectImpact.AddUFunction(this, n"OnImpact");
	}	

	void DetachShieldSegment()
	{
		//MeshComp.SetCollisionObjectType(ECollisionChannel::ECC_PhysicsBody);
		MeshComp.SetSimulatePhysics(true);
		MeshComp.AddImpulse(FVector::UpVector * 20000.0);
		GravityWhipTargetComponent.Disable(this);
		if (HasControl())
			Timer::SetTimer(this, n"DelayedExplode", 2.0);
	}

	UFUNCTION()
	void ActivateTractorBeam()
	{
		TractorBeamVFXComp.Start();
	}

	void DeactivateTractorBeam()
	{
		TractorBeamVFXComp.TractorBeamLetGo();
	}

	UFUNCTION()
	private void DelayedExplode()
	{
		if (HasControl())
			CrumbExplodeShieldSegment();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbExplodeShieldSegment()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ShieldDestroyedVFX, MeshComp.WorldLocation);
		AddActorDisable(this);
	}

	UFUNCTION()
	void OnImpact(TArray<FHitResult> HitResults, FVector Velocity)
	{
		for (auto HitResult : HitResults)
		{
			auto HitShield = Cast<ASkylineBallBossSmallBossShieldSegment>(HitResult.Actor);

			if (HitShield != nullptr)
			{
				HitShield.DetachShieldSegment();
				SmallBoss.ShieldSegmentRemoved(this);
				continue;
			}
		}

		Timer::SetTimer(this, n"DestroySoon", 0.01);
	}

	UFUNCTION()
	private void DestroySoon()
	{
		DestroyActor();
	}
};