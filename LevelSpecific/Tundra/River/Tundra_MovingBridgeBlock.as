event void FMovingBridgeBlockEvent();

UCLASS(Abstract)
class ATundra_MovingBridgeBlock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent FauxRotateComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UFauxPhysicsWeightComponent FauxWeightComp;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent ForceLocation;

	UPROPERTY(DefaultComponent)
	UInheritVelocityComponent InheritVelocityComp;

	UPROPERTY(EditAnywhere)
	float ForceAmount = 1500;

	UPROPERTY(EditInstanceOnly)
	AActor LifeGivingActor;

	UPROPERTY(EditInstanceOnly)
	AActor FocusActor;

	UPROPERTY(EditInstanceOnly)
	AStaticMeshActor DestructionActor;

	UStaticMeshComponent DestructionMesh;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ImpactFF;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike TL_Destruction;
	default TL_Destruction.Duration = 5;
	default TL_Destruction.UseLinearCurveZeroToOne();

	UPROPERTY()
	UTundraLifeReceivingComponent LifeComp;

	bool bCanPush = true;
	bool bHasHitMax = false;
	bool bHasHitMin = false;
	float DestructionDelay = 2.5;
	float DestructionTimer = -1;
	bool bDestructionStarted = false;

	UPROPERTY()
	FMovingBridgeBlockEvent HitLedgeEvent;

	UPROPERTY()
	FMovingBridgeBlockEvent DestructionEvent;

	UMaterialInstanceDynamic DestructionMID1;
	UMaterialInstanceDynamic DestructionMID2;
	UMaterialInstanceDynamic DestructionMID3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LifeComp = UTundraLifeReceivingComponent::Get(LifeGivingActor);
		FauxRotateComp.OnMaxConstraintHit.AddUFunction(this, n"OnMaxConstraintHit");
		FauxRotateComp.OnMinConstraintHit.AddUFunction(this, n"OnMinConstraintHit");
		FauxRotateComp.ApplyImpulse(ForceLocation.RelativeLocation, ForceLocation.ForwardVector * 100);
		FocusActor.AttachToComponent(RotationRoot, AttachmentRule = EAttachmentRule::KeepWorld);

		if(DestructionActor != nullptr)
		{
			DestructionMesh = DestructionActor.StaticMeshComponent;
		}

		DestructionMID1 = Material::CreateDynamicMaterialInstance(this, DestructionMesh.GetMaterial(0));
		DestructionMID2 = Material::CreateDynamicMaterialInstance(this, DestructionMesh.GetMaterial(1));
		DestructionMID3 = Material::CreateDynamicMaterialInstance(this, DestructionMesh.GetMaterial(2));
		DestructionMesh.SetMaterial(0, DestructionMID1);
		DestructionMesh.SetMaterial(1, DestructionMID2);
		DestructionMesh.SetMaterial(2, DestructionMID3);

		TL_Destruction.BindUpdate(this, n"TL_Destruction_Upate");
	}

	UFUNCTION()
	private void OnMinConstraintHit(float Strength)
	{

		bCanPush = true;
		ImpactShake(Strength);
		HitLedgeEvent.Broadcast();

		// if(!bHasHitMin)
		// {
		// 	bHasHitMin = true;
		// 	DestructionTimer = DestructionDelay;
		// 	bDestructionStarted = true;
		// }
		// Print("Hit min constraint " + Strength, 3);
	}

	UFUNCTION()
	private void TL_Destruction_Upate(float CurrentValue)
	{
		DestructionMID1.SetScalarParameterValue(n"VAT_DisplayTime", CurrentValue);
		DestructionMID2.SetScalarParameterValue(n"VAT_DisplayTime", CurrentValue);
		DestructionMID3.SetScalarParameterValue(n"VAT_DisplayTime", CurrentValue);
	}

	UFUNCTION()
	private void OnMaxConstraintHit(float Strength)
	{
		bCanPush = true;

		if(!bHasHitMax)
		{
			bHasHitMax = true;
			return;
		}

		ImpactShake(Strength);
		// Print("Hit max constraint " + Strength, 3);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PushBlock();

		if(bCanPush)
		{
			if(Math::IsWithin(FauxRotateComp.GetCurrentAlphaBetweenConstraints(), 0.45, 0.55))
			{
				bCanPush = false;
				// Print("Crossed middle", 3);
			}
		}

		// if(DestructionTimer > 0)
		// {
		// 	DestructionTimer -= DeltaSeconds;
		// }
		// else if(DestructionTimer <= 0 && !bDestructionStarted)
		// {
		// 	DestructionMesh.SetHiddenInGame(false);
		// 	TL_Destruction.PlayFromStart();
		// }
	}

	UFUNCTION(BlueprintCallable)
	void StartDestruction()
	{
		// DestructionMesh.SetHiddenInGame(false);
		TL_Destruction.PlayFromStart();
		DestructionEvent.Broadcast();
	}

	void PushBlock()
	{
		if(!bCanPush)
			return;

		if(LifeComp != nullptr && LifeComp.IsCurrentlyLifeGiving())
		{
			FVector Force = ForceLocation.ForwardVector * ForceAmount * LifeComp.GetHorizontalAlpha();
			FauxRotateComp.ApplyForce(ForceLocation.RelativeLocation, FVector(Force.X, 0, 0));
			// Print(""+Force.X);
		}
	}

	void ImpactShake(float Strength)
	{
		if(Strength < 0.2)
			return;

		Game::GetMio().PlayWorldCameraShake(CameraShake, this, ForceLocation.WorldLocation, InnerRadius = 4000, OuterRadius = 10000, Scale = Strength);
		Game::GetZoe().PlayWorldCameraShake(CameraShake, this, ForceLocation.WorldLocation, InnerRadius = 4000, OuterRadius = 10000, Scale = Strength);

		Game::GetZoe().PlayForceFeedback(ImpactFF, false, false, this, Strength * 1.5);
		if(Game::GetMio().GetDistanceTo(FocusActor) < 3500)
		{
			Game::GetMio().PlayForceFeedback(ImpactFF, false, false, this, Strength * 1.5);
		}
		
	}
};
