class ASanctuaryCentipedeFallingLava : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LavaMeshComp;

	UPROPERTY(DefaultComponent, Attach = LavaMeshComp)
	UBoxComponent TriggerComp;
	default TriggerComp.BoxExtent = FVector(50.0);

	UPROPERTY(Category = Settings, EditInstanceOnly)
	float Interval = 5.0;

	UPROPERTY(Category = Settings, EditInstanceOnly)
	float StartDelay = 0.0;

	UPROPERTY(Category = Settings, EditInstanceOnly)
	float FallSpeed = 1000.0;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Timer::SetTimer(this, n"DropLava", Interval, true, StartDelay);
	}

	UFUNCTION()
	void DropLava()
	{
		LavaMeshComp.SetRelativeLocation(FVector::UpVector * Interval * FallSpeed * 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LavaMeshComp.AddWorldOffset(ActorUpVector * FallSpeed * DeltaSeconds * -1.0);
	}
};