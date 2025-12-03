UCLASS(Abstract)
class AVortexSandFishGlassShard : ASandHandBreakable
{
	UPROPERTY(DefaultComponent)
	USphereComponent SphereComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike LaunchTimeLike;
	default LaunchTimeLike.bCurveUseNormalizedTime = true;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem DestroyedVFX;

	AHazePlayerCharacter TargetPlayer;
	float FlyToHeight;

	private FVector StartLocation;
	private FVector EndLocation;
	private bool bFlying = false;
	private bool bHasCollided = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorRotation(FQuat::MakeFromX(FVector::UpVector));

		StartLocation = ActorLocation;
		EndLocation = StartLocation + FVector(0, 0, FlyToHeight);

		bFlying = false;

		LaunchTimeLike.BindUpdate(this, n"LaunchTimeLikeUpdate");
		LaunchTimeLike.BindFinished(this, n"LaunchTimeLikeFinished");

		LaunchTimeLike.PlayFromStart();

		ResponseComp.OnSandHandHitEvent.AddUFunction(this, n"OnSandHandHit");

		if(HasControl())
		{
			SphereComp.OnComponentBeginOverlap.AddUFunction(this, n"OnSphereOverlapped");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshComp.AddLocalRotation(FRotator(0, 600 * DeltaSeconds, 0));

		if(bFlying)
		{
			const FVector Location = Math::VInterpConstantTo(ActorLocation, TargetPlayer.ActorLocation, DeltaSeconds, 1800);
			const FQuat Rotation = FQuat::MakeFromX(TargetPlayer.ActorLocation - Location);
			SetActorLocationAndRotation(Location, Rotation);
		}
	}

	UFUNCTION()
	private void LaunchTimeLikeUpdate(float CurrentValue)
	{
		const FVector Location = Math::Lerp(StartLocation, EndLocation, CurrentValue);
		const FQuat Rotation = FQuat::FastLerp(FQuat::MakeFromX(FVector::UpVector), FQuat::MakeFromX(TargetPlayer.ActorLocation - Location), CurrentValue);
		SetActorLocationAndRotation(Location, Rotation);
	}

	UFUNCTION()
	private void LaunchTimeLikeFinished()
	{
		bFlying = true;
	}

	UFUNCTION()
	private void OnSandHandHit(FSandHandHitData HitData)
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(DestroyedVFX, ActorLocation);
		DestroyActor();
	}

	UFUNCTION()
	private void OnSphereOverlapped(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		check(HasControl());

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr)
		{
			CrumbOnPlayerHit();
			bHasCollided = true;
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnPlayerHit()
	{
		// FB TODO: This is how it worked in BP...
		DestroyActor();
	}
};