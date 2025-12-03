class ACavernRock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ImpactEffect;
	default ImpactEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Target;

	UPROPERTY(DefaultComponent, Attach = Target)
	USceneComponent TargetMeshRoot;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 7000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, Target.RelativeLocation, DeltaSeconds, MoveSpeed);
		MeshRoot.RelativeRotation = Math::QInterpConstantTo(MeshRoot.RelativeRotation.Quaternion(), Target.RelativeRotation.Quaternion(), DeltaSeconds, 0.5).Rotator();

		if ((MeshRoot.RelativeLocation - Target.RelativeLocation).Size() < 1.0)
		{
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	void ActivateCavernRock()
	{
		SetActorTickEnabled(true);
		ImpactEffect.Activate();
	}
}