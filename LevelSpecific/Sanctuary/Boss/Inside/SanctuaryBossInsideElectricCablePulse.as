class ASanctuaryBossInsideElectricCablePulse : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY()
	float StartSpeed = 20000.0;

	UPROPERTY()
	float TargetSpeed = 5000.0;

	UPROPERTY()
	float SpinSpeed = 0.1;
	float AddedRotationDegrees = 0.0;

	UPROPERTY()
	float Radius = 200.0;

	UPROPERTY()
	FHazeAcceleratedFloat Speed;

	UPROPERTY(EditInstanceOnly)
	float ScaleMultiplier = 1.0;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossInsideElectricCable Cable;

	TPerPlayer<UPlayerMovementComponent> MoveComp;

	float DistanceAlongSpline = 0.0;

	bool bAvailable = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ElectricitySpawnEffect();
		USanctuaryBossInsideElectricCablePulseEventHandler::Trigger_OnPulse(this);
		Speed.SnapTo(StartSpeed);

		for (auto Player : Game::Players)
		{
			MoveComp[Player] = UPlayerMovementComponent::Get(Player);
		}
	}

	UFUNCTION(BlueprintEvent)
	void ElectricitySpawnEffect(){}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Speed.AccelerateTo(TargetSpeed, 3.0, DeltaSeconds);
		DistanceAlongSpline -= DeltaSeconds * Speed.Value;

		AddedRotationDegrees = DistanceAlongSpline * SpinSpeed;

		FQuat SplineRotation = Cable.SplineComp.GetWorldRotationAtSplineDistance(DistanceAlongSpline);
		FVector ForwardVector = SplineRotation.ForwardVector;
		FQuat AddedQuat = FQuat(ForwardVector, Math::DegreesToRadians(AddedRotationDegrees));
		FQuat ModifiedQuat = FQuat::ApplyDelta(SplineRotation, AddedQuat);

		FVector Location = Cable.SplineComp.GetWorldLocationAtSplineDistance(DistanceAlongSpline);

		SetActorLocationAndRotation(Location, ModifiedQuat);

		SetActorScale3D(FVector::OneVector * ScaleMultiplier * (Speed.Value / 5000.0));


		for (auto Player : Game::Players)
		{
			if (Player.GetDistanceTo(this) < Radius && MoveComp[Player].HasGroundContact())
			{
				Player.DamagePlayerHealth(0.5);
				Player.AddMovementImpulse(FVector::UpVector * 500.0);
			}
		}

		if (DistanceAlongSpline <= 0.0)
		{
			DestroyActor();
		}
	}
};

UCLASS(Abstract)
class USanctuaryBossInsideElectricCablePulseEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPulse() { }

};