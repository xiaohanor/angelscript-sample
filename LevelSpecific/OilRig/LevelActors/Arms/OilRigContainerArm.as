UCLASS(Abstract)
class AOilRigContainerArm : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Top;

	UPROPERTY(DefaultComponent, Attach = Top)
	UStaticMeshComponent Mid;

	UPROPERTY(DefaultComponent, Attach = Mid)
	UStaticMeshComponent Bottom;

	UPROPERTY(DefaultComponent, Attach = Bottom)
	UStaticMeshComponent Swivel;

	UPROPERTY(DefaultComponent, Attach = Swivel)
	UStaticMeshComponent ArmTop;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Head;

	UPROPERTY(DefaultComponent, Attach = Head)
	UStaticMeshComponent ArmBottom;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FVector DirLeftRight = (ArmTop.WorldLocation - ArmBottom.WorldLocation).GetSafeNormal();
		FRotator LeftRot = DirLeftRight.Rotation();
		ArmTop.SetWorldRotation(LeftRot);

		Swivel.SetWorldRotation(FRotator(0.0, LeftRot.Yaw + 90.0, 0.0));

		FVector DirRightLeft = (ArmBottom.WorldLocation - ArmTop.WorldLocation).GetSafeNormal();
		FRotator RightRot = DirRightLeft.Rotation();
		RightRot.Pitch *= -1.0;
		RightRot.Roll = 180.0;
		RightRot.Yaw += 180.0;
		ArmBottom.SetWorldRotation(RightRot);
	}

	UFUNCTION()
	void SetMovingState(bool bMoving)
	{
		SetActorTickEnabled(bMoving);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector DirLeftRight = (ArmTop.WorldLocation - ArmBottom.WorldLocation).GetSafeNormal();
		FRotator LeftRot = DirLeftRight.Rotation();
		ArmTop.SetWorldRotation(LeftRot);

		Swivel.SetWorldRotation(FRotator(0.0, LeftRot.Yaw + 90.0, 0.0));

		FVector DirRightLeft = (ArmBottom.WorldLocation - ArmTop.WorldLocation).GetSafeNormal();
		FRotator RightRot = DirRightLeft.Rotation();
		RightRot.Pitch *= -1.0;
		RightRot.Roll = 180.0;
		RightRot.Yaw += 180.0;
		ArmBottom.SetWorldRotation(RightRot);
	}
}