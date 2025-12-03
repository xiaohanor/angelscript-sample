class ARotatingDragonStatue : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftWingRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightWingRoot;

	UPROPERTY(Category = "Setup")
	FRuntimeFloatCurve WingCurve;
	default WingCurve.AddDefaultKey(0.0, 0.0);
	default WingCurve.AddDefaultKey(0.025, 1.0);
	default WingCurve.AddDefaultKey(0.975, 1.0);
	default WingCurve.AddDefaultKey(1, 0.0);

	UPROPERTY(Category = "Setup")
	FRuntimeFloatCurve RotationCurve;
	default RotationCurve.AddDefaultKey(0.0, 0.0);
	default RotationCurve.AddDefaultKey(0.3, 0.35);
	default RotationCurve.AddDefaultKey(0.7, 0.65);
	default RotationCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Setup")
	float Duration = 11.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float StatueRotationAmount = -180.0;
	
	UPROPERTY(EditAnywhere, Category = "Setup")
	float WingRotationAmount = 90.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ASummitHittableBell TargetBell;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RotatingDragonStatueCapability");

	bool bRotationActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetBell.TailAttackComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		SetNewRotation();
	}

	void SetNewRotation()
	{
		bRotationActive = true;
	}
};