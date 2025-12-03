class ASummitSoundCrystal : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CrystalsRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlatformLocation;

	UPROPERTY(DefaultComponent, Attach = PlatformLocation)
	UStaticMeshComponent AcidResponseMesh;
    
	UPROPERTY(DefaultComponent, Attach = AcidResponseMesh)
	UAcidResponseComponent AcidResponseComp;

	ATeenDragon PlayerChar;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent ImpulseCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent CrystalExplodeFX;
	default CrystalExplodeFX.SetAutoActivate(false);

	UPROPERTY(EditAnywhere)
    bool bStartActive;

	UPROPERTY(EditAnywhere)
	float TimeUntilDrop = 5;
	float UntilDropTimer;
		
	UPROPERTY(EditAnywhere)
    bool bFallingPlatform;

	UPROPERTY(EditAnywhere)
    bool bAutoCrack;

	UPROPERTY(EditAnywhere)
	float TimeUntilCrack = 3;
	float UntilCrackTimer;
	UPROPERTY(BlueprintReadWrite)
	bool bBeginCrack;

	UPROPERTY(EditAnywhere, meta = (ClampMin="1", ClampMax="3"))
    int CrystalType = 1;

	UPROPERTY(EditAnywhere)
    float AcidDamage = 1.5;

	UPROPERTY()
	UMaterialInterface TypeOneMaterial;

	UPROPERTY()
	UMaterialInterface TypeTwoMaterial;

	UPROPERTY()
	UMaterialInterface TypeThreeMaterial;

    float AcidHP;

	bool bIsActive;

	UPROPERTY(BlueprintReadWrite)
    bool bIsStopped;

	UPROPERTY(BlueprintReadWrite)
	bool bIsPlaying;

	UPROPERTY(EditAnywhere)
	float BobHeight = 10;

	UPROPERTY(EditAnywhere)
	float BobSpeed = 10;

	UPROPERTY(EditAnywhere)
	float BobOffset = 25;

	UPROPERTY(EditAnywhere)
	float ImpulseForward;

	UPROPERTY(EditAnywhere)
	float ImpulseUp;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 2.0;
	default MoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnimation.Curve.AddDefaultKey(2.0, 1.0);

	UPROPERTY(EditAnywhere)
	FHazeTimeLike CrackAnimation;	
	default CrackAnimation.Duration = 3;
	default CrackAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default CrackAnimation.Curve.AddDefaultKey(3.0, 1.0);

	bool bAcidHits;
	bool bAllowAcidHits;

	UPROPERTY(DefaultComponent, Attach = PlatformLocation)
	UBoxComponent Collision; 
	default Collision.bGenerateOverlapEvents = false;
	default Collision.CollisionProfileName = n"TriggerOnlyPlayer";

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		UntilDropTimer = TimeUntilDrop;
		UntilCrackTimer = TimeUntilCrack;

		Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		ImpulseCollision.OnComponentBeginOverlap.AddUFunction(this, n"ImpulseCollider");

		if (bStartActive)
			Activate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsActive)
			return;

		if (!bIsStopped) {

			if (MoveAnimation.GetValue() == 1.0) {
				UntilDropTimer = UntilDropTimer - DeltaSeconds;
				if(UntilDropTimer <= 0) {
					Reverse();
					UntilDropTimer = TimeUntilDrop;
				}
			}

			CrystalsRoot.SetRelativeLocation(FVector::UpVector * Math::Sin((Time::GameTimeSeconds * BobSpeed + BobOffset)) * BobHeight);

			if(MoveAnimation.IsPlaying() && MoveAnimation.GetValue() != 1.0)
				CrystalsRoot.AddRelativeRotation(FRotator(1,2,0));

			if (MoveAnimation.GetValue() == 1.0) {
				bAcidHits = true;
			} else {
				bAcidHits = false;
			}

		}

		if (bIsStopped && bBeginCrack) {
			UntilCrackTimer = UntilCrackTimer - DeltaSeconds;
			if(UntilCrackTimer <= 0) {
				Restart();
				UntilCrackTimer = TimeUntilCrack;
				bBeginCrack = false;
			}
		}

		if (bIsStopped && bAutoCrack) {
			CrackPlatform();
		}

		if (MoveAnimation.GetValue() == 0.0 && !bBeginCrack) {
			CrystalsRoot.AddRelativeRotation(FRotator(0,1,0));
		} else {
			CrystalsRoot.SetRelativeRotation(FRotator(0,0,0));
		}
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Param)
	{
        if (bIsStopped)
            return;

		if (bAcidHits) {
			AcidHP = AcidHP + AcidDamage;
		}

		if (AcidHP >= 100) {
			bIsStopped = true;
			MoveAnimation.Stop();
			BP_Stopped();
		}

	}
	
	UFUNCTION()
	void OnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
	{

		if (bFallingPlatform) {
			if(!bIsStopped)
				return;

			CrystalExplode();

			if (!bBeginCrack) {
				if(OtherActor == Game::Mio || OtherActor == Game::Zoe) {
					CrackPlatform();
				}
			}
		}

	}

	UFUNCTION()
	private void ImpulseCollider(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                             UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                             const FHitResult&in SweepResult)
	{
		Reverse();
		ATeenDragon EnterDragon = Cast<ATeenDragon>(OtherActor);

		if (EnterDragon != nullptr)
			PlayerChar = EnterDragon;
	}

	UFUNCTION()
	void CrystalExplode()
	{
		CrystalExplodeFX.Activate();

		if (PlayerChar == nullptr)
			return;

		PlayerChar.SetActorVelocity(FVector::ZeroVector);
		FVector Impulse;
		Impulse += PlayerChar.ActorForwardVector * ImpulseForward;
		Impulse += PlayerChar.ActorUpVector * ImpulseUp;
		PlayerChar.AddMovementImpulse(Impulse); 
	}

	UFUNCTION()
	void Activate() {
		bIsActive = true;
		BP_Activate();
	}

	UFUNCTION()
	void Deactivate() {
		bIsActive = false;
	}

	UFUNCTION()
	void Play() {
		MoveAnimation.SetPlayRate(1.0);
		BP_Play();
	}

	UFUNCTION()
	void ForceStop() {
		bIsStopped = true;
		MoveAnimation.Stop();
		BP_Stopped();
	}


	UFUNCTION()
	void Reverse() {
		MoveAnimation.SetPlayRate(2.0);
		// Reset values
		AcidHP = 0;
		UntilCrackTimer = TimeUntilCrack;
		UntilDropTimer = TimeUntilDrop;
		BP_DisableAcid();
		BP_Reverse();

	}

	UFUNCTION()
	void Restart() {
		bIsStopped = false;
		bBeginCrack = false;
		CrackAnimation.Reverse();
		Reverse();
		BP_Restart();
	}

	UFUNCTION()
	void CrackPlatform() {
		bBeginCrack = true;
		BP_EnableAcid();
		BP_StartCracking();
	}


	UFUNCTION(BlueprintEvent)
	void BP_Activate() {}

	UFUNCTION(BlueprintEvent)
	void BP_Reverse() {}

	UFUNCTION(BlueprintEvent)
	void BP_Play() {}

	UFUNCTION(BlueprintEvent)
	void BP_Stopped() {}

	UFUNCTION(BlueprintEvent)
	void BP_Restart() {}

	UFUNCTION(BlueprintEvent)
	void BP_StartCracking() {}

	UFUNCTION(BlueprintEvent)
	void BP_EnableAcid() {}

	UFUNCTION(BlueprintEvent)
	void BP_DisableAcid() {}

}
