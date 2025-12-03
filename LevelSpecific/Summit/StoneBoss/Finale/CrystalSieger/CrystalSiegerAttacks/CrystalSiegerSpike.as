event void FOnCrystalSiegeSpikeCompletedAttack(ACrystalSiegerSpike CompletedSpike);

class ACrystalSiegerSpike : AHazeActor
{
	UPROPERTY()
	FOnCrystalSiegeSpikeCompletedAttack OnCrystalSiegeSpikeCompletedAttack;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
	default Visual.SpriteName = "SkullAndBones";
	default Visual.SetWorldScale3D(FVector(1.5));
#endif	

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetHiddenInGame(true);
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent Telegraph;
	default Telegraph.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent Impact;
	default Impact.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FallApart;
	default FallApart.SetAutoActivate(false);

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	float AttackTime = 1.5;
	float AttackDuration = 1.5;

	private bool bCompletedAttack = false;
	private bool bIsAttacking;

	FVector Offset = FVector(0,0,-500);
	FVector StartScale;
	FVector TargetScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Telegraph.Activate();
		bIsAttacking = true;
		MeshComp.RelativeLocation = Offset;
		TargetScale = MeshComp.RelativeScale3D;
		StartScale = MeshComp.RelativeScale3D * 0.3;
		MeshComp.RelativeScale3D = StartScale;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsAttacking)
		{
			MeshComp.RelativeLocation = Math::VInterpConstantTo(MeshComp.RelativeLocation, Offset, DeltaSeconds, Offset.Size() * 0.5);
			MeshComp.RelativeScale3D = Math::VInterpConstantTo(MeshComp.RelativeScale3D, FVector(0.05), DeltaSeconds, 0.5);
			return;
		}

		if (AttackTime > 0.0)
		{
			AttackTime -= DeltaSeconds;
		}
		else if (!bCompletedAttack)
		{
			bCompletedAttack = true;

			MeshComp.SetHiddenInGame(false);
			Impact.Activate();
			Telegraph.Deactivate();

			for (AHazePlayerCharacter Player : Game::Players)
				Player.PlayCameraShake(CameraShake, this);	
		}

		if (bCompletedAttack)
		{

			if (AttackDuration > 0.0)
			{
				MeshComp.RelativeLocation = Math::VInterpConstantTo(MeshComp.RelativeLocation, FVector(0), DeltaSeconds, Offset.Size() * 4);
				MeshComp.RelativeScale3D = Math::VInterpConstantTo(MeshComp.RelativeScale3D, TargetScale, DeltaSeconds, TargetScale.Size() * 2);
				AttackDuration -= DeltaSeconds;
			}
			else
			{
				// MeshComp.SetHiddenInGame(true);
				FallApart.Activate();
				bIsAttacking = false;
				OnCrystalSiegeSpikeCompletedAttack.Broadcast(this);
			}
		}
	}

	void ActivateSpike(FVector Location, FRotator Rotation, float NewAttackTime = 1.5, float NewAttacKDuration = 2.0)
	{
		ActorLocation = Location;
		ActorRotation = Rotation;
		AttackTime = NewAttackTime;
		AttackDuration = NewAttacKDuration;
		bCompletedAttack = false;
		bIsAttacking = true;
		MeshComp.SetHiddenInGame(true);
		Telegraph.Activate();
		MeshComp.RelativeLocation = Offset;
		MeshComp.RelativeScale3D = StartScale;
	}
};