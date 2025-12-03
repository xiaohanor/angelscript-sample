event void FOnRubyKnightDoubleInteractTriggered();
event void FOnRubyKnightDoubleInteractCompleted();

class ARubyKnightDoubleInteract : AHazeActor
{
	UPROPERTY()
	FOnRubyKnightDoubleInteractTriggered OnDoubleInteractTriggered;
	UPROPERTY()
	FOnRubyKnightDoubleInteractCompleted OnDoubleInteractCompleted;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent TopVisualizeLocation;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent HittableCollision1;
	default HittableCollision1.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent HittableCollision2;
	default HittableCollision2.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = HittableCollision1)
	UTeenDragonTailAttackResponseComponent RollResponseComp1;
	default RollResponseComp1.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent, Attach = HittableCollision2)
	UTeenDragonTailAttackResponseComponent RollResponseComp2;
	default RollResponseComp2.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RubyKnightDoubleInteractRotateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"RubyKnightDoubleInteractReactCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"RubyKnightDoubleInteractSinkOnCompleteCapability");

	UPROPERTY(EditInstanceOnly)
	ASummitAcidActivatorActor AcidActivator;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve ReactCurve;
	default ReactCurve.AddDefaultKey(0.0, 0.0);
	default ReactCurve.AddDefaultKey(0.3, 1.0);
	default ReactCurve.AddDefaultKey(1.0, 0.0);

	UPROPERTY(EditAnywhere)
	float DownReactAmount = 100.0;
	UPROPERTY(EditAnywhere)
	float DownReactDuration = 1.0;
	FVector TargetOnReactLocation;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve CompleteCurve;
	default CompleteCurve.AddDefaultKey(0.0, 0.0);
	default CompleteCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	float DownOnCompleteAmount = 1420.0;
	UPROPERTY(EditAnywhere)
	float DownOnCompleteDuration = 4.0;
	FVector TargetOnCompleteLocation;

	UPROPERTY(EditAnywhere)
	float RotateAccelerationDuration = 2.5;

	FVector StartLocation;

	bool bIsReacting;
	bool bComplete;
	float RotateAmountPerHit = 45.0;
	FRotator TargetRotation;

	FVector TargetDirectionVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RollResponseComp1.OnHitByRoll.AddUFunction(this, n"RollHit");
		RollResponseComp2.OnHitByRoll.AddUFunction(this, n"RollHit");
		TargetRotation = ActorRotation;
		TargetDirectionVector = ActorRightVector;

		AcidActivator.OnAcidActorActivated.AddUFunction(this, n"OnAcidActorActivated");

		StartLocation = ActorLocation;
		TargetOnReactLocation = ActorLocation - FVector::UpVector * DownReactAmount;
		TargetOnCompleteLocation = ActorLocation - FVector::UpVector * DownOnCompleteAmount;
	}

	UFUNCTION()
	private void OnAcidActorActivated()
	{
		if (bIsReacting)
			return;

		if(bComplete)
			return;
		
		//Network check should happen here somewhere to verify if Acid activated or not on other side before completing
		bComplete = IsAllowedToComplete(); 

		if (!bComplete)
			bIsReacting = true;
		else
			OnDoubleInteractTriggered.Broadcast();
	}

	UFUNCTION()
	private void RollHit(FRollParams Params)
	{
		FVector HitDirection = (Params.HitLocation - Params.HitComponent.WorldLocation).GetSafeNormal();
		float RotateAmount = RotateAmountPerHit * GetRotateDirectionFromHit(Params.HitComponent, HitDirection);
		TargetRotation += FRotator(0, RotateAmount, 0);
	}

	int GetRotateDirectionFromHit(UPrimitiveComponent HitComponent, FVector HitDirection)
	{
		float Dot = HitComponent.ForwardVector.DotProduct(HitDirection);

		if (Dot > 0.5)
			return 1;

		if (Dot < -0.5)
			return -1;

		return 0;
	}

	bool IsAllowedToComplete()
	{
		float Dot = ActorForwardVector.DotProduct(TargetDirectionVector);
		return Dot > 1.0 - KINDA_SMALL_NUMBER || Dot < -1.0 + KINDA_SMALL_NUMBER;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugCircle(TopVisualizeLocation.WorldLocation - FVector::UpVector * DownOnCompleteAmount, 500.0, 20, FLinearColor::Green, 10.0, FVector(0,1,0));
	}
#endif
};