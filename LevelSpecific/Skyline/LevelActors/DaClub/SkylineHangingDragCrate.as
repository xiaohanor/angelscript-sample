class ASkylineHangingDragCrate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent XAxisRotateComp;
	default XAxisRotateComp.Friction = 1.5;
	default XAxisRotateComp.ForceScalar = 0.2;
	default XAxisRotateComp.LocalRotationAxis = FVector::ForwardVector;
	default XAxisRotateComp.bConstrain = true;
	default XAxisRotateComp.ConstrainAngleMin = -60.0;
	default XAxisRotateComp.ConstrainAngleMax = 60.0;
	default XAxisRotateComp.ConstrainBounce = 0.0;
	default XAxisRotateComp.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = XAxisRotateComp)
	UFauxPhysicsAxisRotateComponent YAxisRotateComp;
	default YAxisRotateComp.Friction = 1.5;
	default YAxisRotateComp.ForceScalar = 0.2;
	default YAxisRotateComp.LocalRotationAxis = FVector::RightVector;
	default YAxisRotateComp.bConstrain = true;
	default YAxisRotateComp.ConstrainAngleMin = -60.0;
	default YAxisRotateComp.ConstrainAngleMax = 60.0;
	default YAxisRotateComp.ConstrainBounce = 0.0;
	default YAxisRotateComp.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	FTransform InitialTransform;

	UPROPERTY(DefaultComponent, Attach = YAxisRotateComp)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.Friction = 8.0;
	default TranslateComp.ForceScalar = 2.0;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.MinZ = -500.0;
	default TranslateComp.MaxZ = 200.0;
	default TranslateComp.ConstrainBounce = 0.5;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.Force = FVector::UpVector * -4000.0;
	default ForceComp.bWorldSpace = true;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UGravityWhipTargetComponent WhipTargetComp;

	UPROPERTY(DefaultComponent, Attach = WhipTargetComp)
	UTargetableOutlineComponent WhipOutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent BladeCombatTargetComp;

	UPROPERTY(DefaultComponent, Attach = BladeCombatTargetComp)
	UTargetableOutlineComponent BladeOutlineComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent BladeCollision;
	default BladeCollision.CapsuleHalfHeight = 150.0;
	default BladeCollision.CapsuleRadius = 20.0;
	default BladeCollision.bGenerateOverlapEvents = false;
	default BladeCollision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BladeCollision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;
	default WhipResponseComp.ImpulseMultiplier = 0.0;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent WhipFauxPhysicsComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeCombatResponseComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;

	bool bIsLoose = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialTransform = TranslateComp.RelativeTransform;
		TranslateComp.AddDisabler(this);

		BladeCombatResponseComp.OnHit.AddUFunction(this, n"HandleBladeHit");
		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleContstrainHit");
	}

	UFUNCTION()
	private void HandleContstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Min)
			TranslateComp.MaxZ = TranslateComp.MinZ; 
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{	
		TranslateComp.AttachToComponent(Root);
		TranslateComp.RelativeTransform = InitialTransform;
		TranslateComp.RemoveDisabler(this);
		BladeCombatTargetComp.Disable(this);
		BladeCollision.CollisionEnabled = ECollisionEnabled::NoCollision;

		BP_BladeHit();
	}

	UFUNCTION(BlueprintEvent)
	void BP_BladeHit()
	{

	}

};