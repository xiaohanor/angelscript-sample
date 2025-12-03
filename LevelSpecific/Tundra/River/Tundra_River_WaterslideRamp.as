class ATundra_River_WaterslideRamp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UStaticMeshComponent Mesh2Comp;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UNiagaraComponent WaterSpoutComp;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UHazeCapsuleCollisionComponent WaterCapsuleTrigger;
	default WaterCapsuleTrigger.CapsuleRadius = 150;
	default WaterCapsuleTrigger.CapsuleHalfHeight = 300;
	default WaterCapsuleTrigger.RelativeLocation = FVector(2500, 80, 500);

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UArrowComponent LaunchDirectionArrow;
	default LaunchDirectionArrow.RelativeLocation = FVector(0, 0, 150);
	default LaunchDirectionArrow.RelativeRotation = FRotator(60, 0, 0);
	default LaunchDirectionArrow.ArrowSize = 4;

	UPROPERTY(EditInstanceOnly, Category = "Ramp Settings")
	AActor LifeGivingActor;

	UPROPERTY(EditAnywhere, Category = "Ramp Settings")
	float LaunchForce = 2000;

	UPROPERTY(EditAnywhere, Category = "Ramp Settings")
	bool bShouldZeroVelocity = true;

	UTundraLifeReceivingComponent LifeComp;

	bool bActivated = false;


	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LifeComp = UTundraLifeReceivingComponent::Get(LifeGivingActor);
		ImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnWaterSpoutImpacted");
		//RotateRamp();
		
		ActivateRamp(); // TODO: Remove when blockage is implemented
	}

	UFUNCTION()
	private void OnWaterSpoutImpacted(AHazePlayerCharacter Player)
	{
		AHazePlayerCharacter PlayerRef = Cast<AHazePlayerCharacter>(Player);
		if(Player.IsMio())
		{
			LaunchPlayer(Player);
		}
	}

	UFUNCTION()
	private void LaunchPlayer(AHazePlayerCharacter Player)
	{
		if(!bActivated)
			return;

		UTundra_River_WaterslideLaunch_PlayerComponent LaunchPlayerComp = UTundra_River_WaterslideLaunch_PlayerComponent::Get(Player);
		LaunchPlayerComp.OnNewLaunchTriggered();
		
		if(bShouldZeroVelocity)
		{
			Player.SetActorHorizontalAndVerticalVelocity(FVector::ZeroVector, FVector::ZeroVector);
		}
		
		Player.AddMovementImpulse(LaunchDirectionArrow.ForwardVector * LaunchForce);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(LifeComp != nullptr && LifeComp.IsCurrentlyLifeGiving())
		{
			if(Math::Abs(LifeComp.VerticalAlpha) >= 0.9 && !bActivated)
			{
				ActivateRamp();
			}
			//if(bActivated)
			//{
				RotateRamp();
			//}
		}
	}

	UFUNCTION(BlueprintCallable)
	void RotateRamp()
	{
		RotationRoot.RelativeRotation = FRotator(Math::GetMappedRangeValueClamped(FVector2D(-1, 1),FVector2D(0, 40), LifeComp.VerticalAlpha), 0, 0);

		FRotator SpoutRot = WaterSpoutComp.RelativeRotation;
		float DesiredRotation = RotationRoot.RelativeRotation.Pitch;
		//WaterSpoutComp.RelativeRotation = FRotator(DesiredRotation * 0.15, SpoutRot.Yaw, SpoutRot.Roll);
	}

	UFUNCTION(BlueprintCallable)
	void ActivateRamp()
	{
		bActivated = true;
		WaterSpoutComp.Activate();
	}
};