UCLASS(Abstract)
class AMotherKiteCluster : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ClusterRoot;

	UPROPERTY(DefaultComponent, Attach = ClusterRoot)
	USphereComponent CollectTrigger;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike DisperseTimeLike;

	bool bCollected = false;
	FVector DisperseStartLocation;

	UNiagaraComponent KiteSystem;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CollectTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");

		KiteSystem = UNiagaraComponent::Get(this);

		DisperseTimeLike.BindUpdate(this, n"UpdateDisperse");
		DisperseTimeLike.BindFinished(this, n"FinishDisperse");
	}

	UFUNCTION()
	private void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (!HasControl())
			return;

		if (bCollected)
			return;

		AMotherKite MotherKite = Cast<AMotherKite>(OtherActor);
		if (MotherKite != nullptr)
		{
			bCollected = true;
			MotherKite.CollectCluster(this);
		}
	}

	void Disperse()
	{
		DisperseStartLocation = ActorLocation;
		DisperseTimeLike.PlayFromStart();

		KiteSystem.SetFloatParameter(n"NoiseFrequency", 1.0);
		KiteSystem.SetFloatParameter(n"NoiseStrength", 6000.0);
		KiteSystem.SetFloatParameter(n"SpringStrength", 0.5);

		BP_Disperse();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Disperse() {}

	UFUNCTION()
	private void UpdateDisperse(float CurValue)
	{
		FVector Loc = Math::Lerp(DisperseStartLocation, DisperseStartLocation + (FVector::UpVector * 4000.0), CurValue);
		SetActorLocation(Loc);
	}

	UFUNCTION()
	private void FinishDisperse()
	{
		AddActorDisable(this);
	}
}