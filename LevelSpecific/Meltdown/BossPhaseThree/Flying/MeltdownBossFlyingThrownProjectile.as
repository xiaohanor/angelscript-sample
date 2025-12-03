event void FOnThrowDone();

class AMeltdownBossFlyingThrownProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent ThrownMesh;

	UPROPERTY(DefaultComponent, Attach = ThrownMesh)
	UHazeCapsuleCollisionComponent Collision;

	UPROPERTY(EditAnywhere)
	AMeltdownBossFlyingPhaseManager PhaseManager;

	UPROPERTY()
	float Speed = 2550.0;
	UPROPERTY()
	float TurnRate = 1.0;
	UPROPERTY()
	float Lifetime = 5.0;

	UPROPERTY()
	float NextThrow = 2.5;

	UPROPERTY()
	FOnThrowDone ThrowDone;

	FVector StartLocation;


	private AHazePlayerCharacter TargetPlayer;
	private bool bLaunched = false;
	private float Timer = 0.0;
	private FVector OriginalLaunchDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Collision.OnComponentBeginOverlap.AddUFunction(this,n"OnCollisionOverlap");
		AddActorDisable(this);

		StartLocation = ActorLocation;
	}

	UFUNCTION()
	private void OnCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;
		
		Player.DamagePlayerHealth(0.5);
	}

	UFUNCTION(BlueprintEvent)
	void Impact()
	{
	}

	UFUNCTION(DevFunction)
	void Launch(AHazePlayerCharacter Target)
	{
		if(PhaseManager.bPhaseOneDone == true)
		{
			AddActorDisable(this);
			return;
		}

		RemoveActorDisable(this);

		bLaunched = true;
		TargetPlayer = Target;
		Timer = 0.0;

		OriginalLaunchDirection = (Target.ActorLocation - ActorLocation).GetSafeNormal();
		ActorRotation = FRotator::MakeFromX(OriginalLaunchDirection);
		ThrowAnim();
	}

	UFUNCTION(BlueprintEvent)
	void ThrowAnim()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bLaunched)
			return;

		FVector TargetVector = (TargetPlayer.ActorLocation - ActorLocation).GetSafeNormal();
		if (TargetVector.DotProduct(OriginalLaunchDirection) > 0)
		{
			ActorRotation = Math::RInterpConstantShortestPathTo(
				ActorRotation,
				FRotator::MakeFromX(TargetVector),
				DeltaSeconds,
				TurnRate,
			);
			
		}

		if(PhaseManager.bPhaseOneDone == true)
			AddActorDisable(this);

		ActorLocation += ActorForwardVector * Speed * DeltaSeconds;

		MeshRoot.AddLocalRotation(FRotator(0,50,50) * DeltaSeconds);
		
		Timer += DeltaSeconds;
		if (Timer > Lifetime)
		{
				AddActorDisable(this);
				ActorLocation = StartLocation;
				bLaunched = false;
		}
	
		 Timer += DeltaSeconds;
		 if (Timer > NextThrow)
		 	ThrowDone.Broadcast();
		
	}
};