class UEnforcerArmComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<AEnforcerArm> ArmClass;
	AEnforcerArm Arm;
	FVector SpawnPosition;
	
	private bool bInitialized = false;
	bool bStruggling = false;
	bool bReturn = false;
	private FVector OriginalClawPosition;
	private FVector OriginalDynamicArmScale;

	TArray<AHazeActor> AttackedActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Initialize();
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthComp.OnDie.AddUFunction(this, n"OnDie");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");		
	}

	UFUNCTION()
	private void OnReset()
	{
		Arm.RemoveActorDisable(this);
	}

	UFUNCTION()
	private void OnDie(AHazeActor RespawnableActor)
	{
		Arm.AddActorDisable(this);
	}

	void Initialize()
	{
		if(bInitialized)
			return;
		bInitialized = true;

		Arm = SpawnActor(ArmClass, bDeferredSpawn = true);
		Arm.MakeNetworked(this, n"Arm");
		Arm.Owner = Cast<AHazeActor>(Owner);
		FinishSpawningActor(Arm);
		Arm.AttachToActor(Owner, n"Neck");
		OriginalClawPosition = Arm.Claw.GetRelativeLocation();		
		OriginalDynamicArmScale = Arm.DynamicArm.RelativeScale3D;
		ResetPosition();
	}

	void StartAttack()
	{
		bReturn = false;
	}

	void EndAttack()
	{
		bReturn = true;
	}

	void StartStruggle()
	{
		bStruggling = true;
		bReturn = false;
	}

	void EndStruggle()
	{
		bStruggling = false;
		bReturn = true;
	}

	void SetArmWorldLocation(FVector WorldPosition)
	{
		Arm.Claw.SetWorldLocation(WorldPosition);
		AdjustExtensionArm();
	}

	void SetArmRelativeLocation(FVector LocalPosition)
	{
		Arm.Claw.SetRelativeLocation(LocalPosition);
		AdjustExtensionArm();
	}	

	void ResetPosition()
	{
		Arm.Claw.SetRelativeLocation(GetDefaultPosition());
		AdjustExtensionArm();
	}	

	FVector GetDefaultPosition()
	{
		return OriginalClawPosition;		
	}

	private void AdjustExtensionArm()
	{
		float DistanceScale = Arm.Claw.RelativeLocation.X / OriginalClawPosition.X;
		FVector NewScale = FVector(OriginalDynamicArmScale.X * DistanceScale, OriginalDynamicArmScale.Y, OriginalDynamicArmScale.Z);
		Arm.DynamicArm.SetRelativeScale3D(NewScale);
		Arm.DynamicArm.SetRelativeRotation((Arm.Claw.GetRelativeLocation() - Arm.DynamicArm.GetRelativeLocation()).Rotation());
	}

	void RemoveAttackedActor(AHazeActor Actor)
	{
		AttackedActors.Remove(Actor);
	}
}