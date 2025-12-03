struct FTrainDroneScanParams
{
	UPROPERTY()
	AHazeActor TrainCart;

	FTrainDroneScanParams(AHazeActor _TrainCart)
	{
		TrainCart = _TrainCart;
	}
}

struct FTrainDroneAttackParams
{
	UPROPERTY()
	UBasicAIProjectileLauncherComponent Weapon;

	UPROPERTY()
	AHazeActor TrainCart;

	UPROPERTY()
	FVector TargetLocalLoc;

	FTrainDroneAttackParams(UBasicAIProjectileLauncherComponent _Weapon, AHazeActor _TrainCart, FVector _TargetLocalLoc)
	{
		Weapon = _Weapon;
		TrainCart = _TrainCart;
		TargetLocalLoc = _TargetLocalLoc;
	}
}

struct FTrainDroneDeathParams
{
	UPROPERTY()
	AActor ParentActor;

	FTrainDroneDeathParams(AActor _ParentActor)
	{
		ParentActor = _ParentActor;
	}
}

UCLASS(Abstract)
class UCoastTrainDroneEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartScanning(FTrainDroneScanParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStopScanning() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraph(FTrainDroneAttackParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStopTelegraphing() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnAttack(FTrainDroneAttackParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath(FTrainDroneDeathParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDamage() {}

	UStaticMeshComponent Scanner;
	UCoastTrainDroneSettings Settings;
	float ScannerLength = 2500.0;
	private float ScannerWidth;

	UFUNCTION()
	void InitScanner(UStaticMesh Mesh, UMaterialInterface Material)
	{
		Settings = UCoastTrainDroneSettings::GetSettings(Owner);
		ScannerWidth = Settings.ScanCartDetectionWidth * 2.5;
		if (Scanner == nullptr)
			Scanner = UStaticMeshComponent::Create(Owner);
		Scanner.StaticMesh = Mesh;
		Scanner.SetMaterial(0, Material);
		Scanner.WorldScale3D = FVector(0.1, ScannerWidth * 0.02, ScannerLength * 0.01);
		Scanner.RelativeLocation = FVector(0.0, 0.0, -ScannerLength);
		Scanner.CollisionProfileName = n"NoCollision";
		Scanner.bGenerateOverlapEvents = false;
		Scanner.SetComponentTickEnabled(false);
		Scanner.AddComponentVisualsBlocker(this);
		Scanner.DetachFromParent(true);
	}

	UFUNCTION()
	void UpdateScanner(AHazeActor TrainCart)
	{
		if (TrainCart == nullptr)
			return;

		FVector CartCenterLoc = Math::ProjectPositionOnInfiniteLine(TrainCart.ActorLocation, TrainCart.ActorForwardVector, Owner.ActorLocation);
		FVector ToCartDir = (CartCenterLoc - Owner.ActorLocation).GetSafeNormal();
		Scanner.WorldLocation = Owner.ActorLocation + ToCartDir * ScannerLength;
		Scanner.WorldRotation = FRotator::MakeFromZX(-ToCartDir, TrainCart.ActorForwardVector);

		// Fluctuate a bit
		FVector Scale = Scanner.WorldScale;
		Scale.Y = ScannerWidth * 0.02 + ScannerWidth * 0.1 * 0.02 * Math::Sin(Time::GameTimeSeconds * 5.57); 
		Scanner.WorldScale3D = Scale;

	}

	UFUNCTION()
	void ShowScanner()
	{
		Scanner.RemoveComponentVisualsBlocker(this);
	}

	UFUNCTION()
	void HideScanner()
	{
		Scanner.AddComponentVisualsBlocker(this);
	}
}
