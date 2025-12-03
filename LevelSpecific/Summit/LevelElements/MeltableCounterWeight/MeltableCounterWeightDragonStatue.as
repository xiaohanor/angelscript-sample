class AMeltableCounterWeightDragonStatue : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = ForceComp)
	UStaticMeshComponent DragonStatueMesh;

	UPROPERTY(DefaultComponent, Attach = ForceComp)
	UFauxPhysicsAxisRotateComponent LeftWingAttachment;
	default LeftWingAttachment.bConstrain = true;
	default LeftWingAttachment.ConstrainAngleMin = -90.0;

	UPROPERTY(DefaultComponent, Attach = LeftWingAttachment)
	UStaticMeshComponent LeftWingMesh;

	UPROPERTY(DefaultComponent, Attach = ForceComp)
	UFauxPhysicsAxisRotateComponent RightWingAttachment;
	default RightWingAttachment.bConstrain = true;
	default RightWingAttachment.ConstrainAngleMin = 90.0;

	UPROPERTY(DefaultComponent, Attach = RightWingAttachment)
	UStaticMeshComponent RightWingMesh;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 60000.0;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;
	default PlayerWeightComp.PlayerForce = 225.0;
	default PlayerWeightComp.PlayerImpulseScale = 0.03;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AMeltableCounterWeight CounterWeight;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MoveMax = 4000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MoveForce = 3000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector MoveDirection = FVector(0, 0, 1.0);

	UPROPERTY(EditAnywhere ,Category = "Settings")
	float WingRotationSpeed = 2.0;

	bool bHasHitEnd = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(CounterWeight != nullptr)
			CounterWeight.OnWeightStartsFalling.AddUFunction(this, n"OnWeightStartsFalling");

		TranslateComp.OnConstraintHit.AddUFunction(this, n"TranslateCompConstrainHit");
		ForceComp.AddDisabler(this);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FVector MaxLocation = MoveDirection * MoveMax;

		TranslateComp.MaxZ = MaxLocation.Z;
		TranslateComp.MaxY = MaxLocation.Y;
		TranslateComp.MaxX = MaxLocation.X;
		ForceComp.Force = ActorTransform.TransformVector(MoveDirection * (MoveForce * Math::Sign(MoveMax)));
	}

	UFUNCTION(NotBlueprintCallable)
	private void TranslateCompConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		bHasHitEnd = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bHasHitEnd)
		{
			FVector LeftWingForceOrigin = LeftWingAttachment.WorldLocation + LeftWingAttachment.RightVector * 500;
			LeftWingAttachment.ApplyForce(LeftWingForceOrigin, LeftWingAttachment.ForwardVector * 500);
			FVector RightWingForceOrigin = RightWingAttachment.WorldLocation + RightWingAttachment.RightVector * 500;
			RightWingAttachment.ApplyForce(RightWingForceOrigin, -RightWingAttachment.ForwardVector * 500);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnWeightStartsFalling(AMeltableCounterWeight CurrentCounterWeight)
	{
		ForceComp.RemoveDisabler(this);
	}
};