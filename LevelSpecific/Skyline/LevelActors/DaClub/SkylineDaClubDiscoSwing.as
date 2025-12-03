class ASkylineDaClubDiscoSwing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent ConeRotateComp;
	default ConeRotateComp.Friction = 0.1;
	default ConeRotateComp.LocalConeDirection = -FVector::UpVector;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.Force = -FVector::UpVector * 3000.0;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UFauxPhysicsForceComponent ForceCompExtra;
	default ForceCompExtra.Force = -FVector::UpVector * 2000.0;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UGravityWhipTargetComponent WhipTargetComp;
	default WhipTargetComp.MaximumDistance = 2000.0;
	default WhipTargetComp.MaximumAngle = 60.0;

	UPROPERTY(DefaultComponent, Attach = WhipTargetComp)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;
	default WhipResponseComp.GrabMode = EGravityWhipGrabMode::Drag;
	default WhipResponseComp.ForceMultiplier = 1.0;
//	default WhipResponseComp.OffsetDistance = 1000.0;
	default WhipResponseComp.ImpulseMultiplier = 0.0;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent WhipFauxPhysicsComp;

	UPROPERTY(EditAnywhere)
	float Length = 2500.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ConeRotateComp.RelativeLocation = FVector::UpVector * Length;
		Pivot.RelativeLocation = -FVector::UpVector * Length;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ConeRotateComp.TorqueBounds = Length;
		WhipResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		WhipResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		ForceComp.AddDisabler(UserComponent);
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		ForceComp.RemoveDisabler(UserComponent);
	}
};