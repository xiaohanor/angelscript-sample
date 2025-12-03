UCLASS(Abstract)
class ATazerBotZappableCanister : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CanisterRoot;

	UPROPERTY(DefaultComponent, Attach = CanisterRoot)
	UCapsuleComponent OverlapComp;

	bool bBotConnected = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OverlapComp.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlap");
	}

	UFUNCTION()
	private void BeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		ATazerBot Bot = Cast<ATazerBot>(OtherActor);
		if (Bot == nullptr)
			return;

		if (OtherComp != Bot.PlayerTipCollider)
			return;

		if (bBotConnected)
			return;

		bBotConnected = true;

		BP_BotConnected();
	}

	UFUNCTION(BlueprintEvent)
	void BP_BotConnected() {}

	UFUNCTION()
	void Explode()
	{
		BP_Explode();

		PlayerHealth::KillPlayersInRadius(ActorLocation, 350.0);

		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bBotConnected)
		{
			float Roll = Math::Sin(Time::GameTimeSeconds * 40.0) * 0.5;
			CanisterRoot.SetRelativeRotation(FRotator(0.0, 0.0, Roll));
		}
	}
}