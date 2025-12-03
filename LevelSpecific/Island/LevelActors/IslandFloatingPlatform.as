class AIslandFloatingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent MovingRoot;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent FauxPhysicsPlayerWeightComp;

	UPROPERTY(DefaultComponent, Attach = "MovingRoot")
	UFauxPhysicsTranslateComponent FauxPhysicsTranslateComp;

	UPROPERTY(DefaultComponent, Attach = "FauxPhysicsTranslateComp")
	UStaticMeshComponent FloatingPlatform;
	//default FloatingPlatform.RemoveTag(n"Walkable");

	UPROPERTY()
	UMaterialInterface LightWarningMaterial;

	UPROPERTY()
	UMaterialInterface LightDefaultMaterial;

	UPROPERTY()
	TArray<int> MaterialSlots;
	int SlotCount = 0;
	int MaxSlotCount;

	UPROPERTY()
	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnimation.Curve.AddDefaultKey(1.0, 0.0);

	float YawOffset = 0;
	float MaxYawOffset = 5;

	UPROPERTY(EditInstanceOnly)
	float AdditionalGrapplePointRange = 1500;

	UPROPERTY(EditInstanceOnly)
	bool bAllowGrappleToPoint = true;

	UPROPERTY(DefaultComponent, Attach = "FloatingPlatform")
	UPerchPointComponent PerchPoint;

	UPROPERTY(EditInstanceOnly)
	bool bPerchStartActive = true;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(EditInstanceOnly)
	bool bAmbientMovement = true;
	float AmbientMovementCounter = 0;
	
	UPROPERTY(EditInstanceOnly)
	float AmbientMovementAmplitude = 20;

	UPROPERTY(EditInstanceOnly)
	float AmbientMovementDuration = 5;

	float AmbientMovementOffset = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		PerchPoint.bAllowGrappleToPoint = bAllowGrappleToPoint;
		PerchPoint.AdditionalGrappleRange = AdditionalGrapplePointRange;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveAnimation.BindUpdate(this, n"TL_WarningAnimation");

		if(bAmbientMovement)
		{
			SetActorTickEnabled(true);
			AmbientMovementCounter = Math::RandRange(0.0, AmbientMovementDuration);
		}

		if(!bPerchStartActive)
			PerchPoint.Disable(this);

		MaxSlotCount = MaterialSlots.Num();
	}

	UFUNCTION()
	void SetCountdownProgress(float Progress)
	{
		int NumberOfRedLights = Math::CeilToInt((Progress * MaxSlotCount));

		for(int i = 0; i<MaxSlotCount;i++)
		{
			if(i<NumberOfRedLights)
			{
				FloatingPlatform.SetMaterial(MaterialSlots[i], LightWarningMaterial);
			}

			else
			{
				FloatingPlatform.SetMaterial(MaterialSlots[i], LightDefaultMaterial);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AmbientMovementCounter += DeltaSeconds;
		if(AmbientMovementCounter > AmbientMovementDuration)
		{
			AmbientMovementCounter -= AmbientMovementDuration;
		}

		MovingRoot.SetRelativeLocation(FVector(0,0,Math::Sin((AmbientMovementCounter/AmbientMovementDuration)*PI*2)*AmbientMovementAmplitude));
	}

	UFUNCTION()
	void SetPerchPointActive(bool bNewActive)
	{
		if(!bNewActive)
		{
			PerchPoint.Disable(this);
			SetActorEnableCollision(false);
		}

		else
		{
			PerchPoint.Enable(this);
			SetActorEnableCollision(true);
		}
	}

	UFUNCTION()
	void TriggerWarningAnimation(float Duration)
	{
		MoveAnimation.SetPlayRate(1/Duration);
		MoveAnimation.PlayFromStart();
	}

	UFUNCTION()
	void TL_WarningAnimation(float CurveValue)
	{
		YawOffset = CurveValue*MaxYawOffset;
		MovingRoot.SetRelativeRotation(FRotator(0, YawOffset, 0));
	}
}