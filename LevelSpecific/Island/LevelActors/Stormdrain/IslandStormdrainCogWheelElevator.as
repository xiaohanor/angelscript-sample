class AIslandStormdrainCogWheelElevator : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent MovementRoot;

	UPROPERTY(DefaultComponent, Attach = "MovementRoot")
	UStaticMeshComponent Elevator;
	
	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent RailingRight;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent RailingLeft;

	UPROPERTY(DefaultComponent, Attach = "MovementRoot")
	USceneComponent RightCogWheelRoot;

	UPROPERTY(DefaultComponent, Attach = "MovementRoot")
	USceneComponent LeftCogWheelRoot;

	UPROPERTY(DefaultComponent, Attach = "RightCogWheelRoot")
	UStaticMeshComponent RightCogWheel;

	UPROPERTY(DefaultComponent, Attach = "LeftCogWheelRoot")
	UStaticMeshComponent LeftCogWheel;

	UPROPERTY(DefaultComponent, Attach = "RightCogWheel")
	UIslandRedBlueImpactResponseComponent RightCogWheelShootComp;
	default RightCogWheelShootComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent, Attach = "RightCogWheel")
	UIslandRedBlueTargetableComponent RightCogWheelTarget;

	UPROPERTY(DefaultComponent, Attach = "LeftCogWheel")
	UIslandRedBlueImpactResponseComponent LeftCogWheelShootComp;
	default LeftCogWheelShootComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent, Attach = "LeftCogWheel")
	UIslandRedBlueTargetableComponent LeftCogWheelTarget;

	UPROPERTY()
	UMaterialInterface MioMaterial;

	UPROPERTY()
	UMaterialInterface ZoeMaterial;

	UPROPERTY()
	UMaterialInterface HitMaterial;

	float ResetMioMaterialTimer = 0;
	float ResetZoeMaterialTimer = 0;
	float MaxResetMaterialTimer = 0.05;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	FRotator RightCogWheelDefaultRotation;
	FRotator LeftCogWheelDefaultRotation;

	float RightCogWheelImpactTimer = 0;
	float LeftCogWheelImpactTimer = 0;
	float MaxImpactTimer = 0.5;

	float CurrentHeight = 0;
	float TargetHeight = 0;
	float MoveSpeed = 300;
	float MinHeight = -1500;
	float MaxRotation = -300;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		RightCogWheelDefaultRotation = RightCogWheelRoot.GetRelativeRotation();
		LeftCogWheelDefaultRotation = LeftCogWheelRoot.GetRelativeRotation();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LeftCogWheelShootComp.OnImpactEvent.AddUFunction(this, n"LeftCogWheelImpact");
		RightCogWheelShootComp.OnImpactEvent.AddUFunction(this, n"RightCogWheelImpact");
		RightCogWheelTarget.DisableForPlayer(Game::GetMio(), this);
		LeftCogWheelTarget.DisableForPlayer(Game::GetZoe(), this);
	}

	UFUNCTION()
	void RightCogWheelImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if(Data.Player == Game::GetZoe())
		{
			RightCogWheelImpactTimer = MaxImpactTimer;
			SetActorTickEnabled(true);
			RightCogWheel.SetMaterial(0, HitMaterial);
			ResetZoeMaterialTimer = MaxResetMaterialTimer;
		}
	}

	UFUNCTION()
	void LeftCogWheelImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if(Data.Player == Game::GetMio())
		{
			LeftCogWheelImpactTimer = MaxImpactTimer;
			SetActorTickEnabled(true);
			LeftCogWheel.SetMaterial(0, HitMaterial);
			ResetMioMaterialTimer = MaxResetMaterialTimer;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(LeftCogWheelImpactTimer > 0 && RightCogWheelImpactTimer > 0)
		{
			TargetHeight -= MoveSpeed*DeltaSeconds;
			TargetHeight = Math::Max(MinHeight, TargetHeight);
		}

		else if(LeftCogWheelImpactTimer <= 0 && RightCogWheelImpactTimer <= 0)
		{
			TargetHeight += MoveSpeed*DeltaSeconds;
			TargetHeight = Math::Min(0, TargetHeight);
		}

		RightCogWheelImpactTimer -= DeltaSeconds;
		LeftCogWheelImpactTimer -= DeltaSeconds;

		CurrentHeight = Math::FInterpTo(CurrentHeight, TargetHeight, DeltaSeconds, 0.7);
		MovementRoot.SetRelativeLocation(FVector(0,0,CurrentHeight));

		RightCogWheelRoot.SetRelativeRotation(RightCogWheelDefaultRotation + FRotator(GetPitchFromHeight(), 0, 0));
		LeftCogWheelRoot.SetRelativeRotation(LeftCogWheelDefaultRotation + FRotator(GetPitchFromHeight(), 0, 0));

		if(ResetMioMaterialTimer > 0)
		{
			ResetMioMaterialTimer -= DeltaSeconds;
			if(ResetMioMaterialTimer <= 0)
			{
				LeftCogWheel.SetMaterial(0, MioMaterial);
			}
		}

		if(ResetZoeMaterialTimer > 0)
		{
			ResetZoeMaterialTimer -= DeltaSeconds;
			if(ResetZoeMaterialTimer <= 0)
			{
				RightCogWheel.SetMaterial(0, ZoeMaterial);
			}
		}
	}
	
	float GetPitchFromHeight()
	{
		return Math::GetMappedRangeValueUnclamped(FVector2D(0,MinHeight),FVector2D(0, MaxRotation),CurrentHeight);
	}

}