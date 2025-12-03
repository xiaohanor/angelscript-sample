UCLASS(Abstract)
class ASketchbookBossDuckProjectile : ASketchbookBossProjectile
{
	UPROPERTY(EditDefaultsOnly)
	const float EggFallSpeed = 850;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		AddActorWorldOffset(FVector::DownVector * EggFallSpeed * DeltaSeconds);
	}
};