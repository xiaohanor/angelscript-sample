UCLASS(Abstract)
class AIslandShootableSpinningInteract : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UIslandRedBlueImpactResponseComponent ImpactResponseComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(EditAnywhere)
	float Drag = 0.8;

	UPROPERTY(EditAnywhere)
	FVector RotationAxis = FVector::UpVector;

	UPROPERTY(EditAnywhere)
	float ImpulseMultiplier = 100.0;

	float AngularVelocity = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		const float IntegratedDragFactor = Math::Exp(-Drag);
		AngularVelocity = AngularVelocity * Math::Pow(IntegratedDragFactor, DeltaTime);
		FRotator DeltaRotation = Math::RotatorFromAxisAndAngle(WorldRotationAxis, AngularVelocity * DeltaTime);
		ActorQuat = DeltaRotation.Quaternion() * ActorQuat;
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		FVector ProjectedVector = Data.BulletShootDirection.VectorPlaneProject(WorldRotationAxis);
		FVector ImpactToCenterDir = (ActorLocation - Data.ImpactLocation).VectorPlaneProject(WorldRotationAxis).GetSafeNormal();
		float ShootDirTowardsCenterness = ImpactToCenterDir.DotProduct(ProjectedVector.GetSafeNormal());
		float Impulse = ProjectedVector.Size() * (1.0 - ShootDirTowardsCenterness) * ImpulseMultiplier;

		FVector CenterToImpactDir = -ImpactToCenterDir;
		FVector RightDir = WorldRotationAxis.CrossProduct(CenterToImpactDir);

		float Sign = Math::Sign(RightDir.DotProduct(ProjectedVector));
		AngularVelocity += Impulse * Sign;

		UIslandShootableSpinningInteractEventHandler::Trigger_OnImpact(this);
	}

	FVector GetWorldRotationAxis() const property
	{
		return ActorTransform.TransformVectorNoScale(RotationAxis);
	}
}