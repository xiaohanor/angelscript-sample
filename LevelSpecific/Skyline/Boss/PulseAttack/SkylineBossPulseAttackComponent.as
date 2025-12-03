UCLASS(Abstract)
class USkylineBossPulseAttackComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	private TSubclassOf<ASkylineBossPulseAttack> PulseClass;

	UPROPERTY(EditAnywhere)
	const float PulseChargeupTime = 3;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve HazeSphereOpacityCurve;

	private ASkylineBoss Boss;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Boss = Cast<ASkylineBoss>(Owner);
	}

	void CreatePulse()
	{
		auto Pulse1 = SpawnActor(PulseClass, Boss.CoreCollision.WorldLocation + FVector::UpVector * 300);
		if(Pulse1 != nullptr)
			Pulse1.SetActorRotation(Boss.CoreCollision.WorldRotation.ForwardVector.RotateAngleAxis(90, FVector::UpVector).Rotation());
		
		auto Pulse2 = SpawnActor(PulseClass, Boss.CoreCollision.WorldLocation + FVector::UpVector * 300);
		if(Pulse2 != nullptr)
			Pulse2.SetActorRotation(Boss.CoreCollision.WorldRotation.ForwardVector.RotateAngleAxis(-90, FVector::UpVector).Rotation());
	}
};