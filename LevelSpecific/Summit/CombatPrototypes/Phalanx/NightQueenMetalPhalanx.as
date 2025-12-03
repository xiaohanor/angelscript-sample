class ANightQueenMetalPhalanx : ANightQueenMetal
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ShieldRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpearRoot;

	UPROPERTY(DefaultComponent, Attach = SpearRoot)
	USummitKillAreaSphereComponent KillVolume;

	UPROPERTY()
	FVector SpearStartLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SpearStartLoc = ShieldRoot.RelativeLocation;

		float StartTime = Math::RandRange(0.0, 1.5);
		Timer::SetTimer(this, n"BP_StartPhalanx", StartTime);
	}
	
	UFUNCTION(BlueprintEvent)
	void BP_StartPhalanx() {}
}