UCLASS(Abstract)
class APrisonBossHorizontalSlashActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SlashRoot;

	float Size = 0.0;

	float MoveSpeed = 1800.0;
	float Offset = 0.0;

	bool bLaunched = false;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spawned();
	}

	void Spawned()
	{
		bLaunched = true;
		UPrisonBossHorizontalSlashEffectEventHandler::Trigger_Spawn(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bLaunched)
			return;

		Offset += MoveSpeed * DeltaTime;
		SlashRoot.SetRelativeLocation(FVector(Offset, 0.0, 0.0));

		if (Offset >= 6000.0)
			Dissipate();
	}

	void Dissipate()
	{
		UPrisonBossHorizontalSlashEffectEventHandler::Trigger_Dissipate(this);
		DestroyActor();
	}
}