enum EIslandShootablePlatformDirection
{
	Up,
	Down,
	Left,
	Right
}

class AIslandSidescrollerShootablePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent StaticMesh;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent StaticMeshFront;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent StaticMeshBottom;

	UPROPERTY(DefaultComponent, Attach = StaticMesh)
	UIslandRedBlueTargetableComponent TargetableComp;
	default TargetableComp.OptionalShape = FHazeShapeSettings::MakeBox(FVector(40, 40, 40));

	UPROPERTY(DefaultComponent, Attach = StaticMesh)
	UIslandRedBlueImpactCounterResponseComponent ImpactCounterResponseComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandSidescrollerShootablePlatformDummyComponent DummyComp;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UMaterialInterface RedMaterial;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UMaterialInterface BlueMaterial;

	UPROPERTY(EditAnywhere, Category = "Setup")
	EIslandRedBlueWeaponType Color = EIslandRedBlueWeaponType::Red;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UNiagaraSystem RedHitEffect;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UNiagaraSystem BlueHitEffect;

	UPROPERTY(EditAnywhere, Category = "Setup")
	AActor PlatformToCopySettingsFrom;

	UPROPERTY(EditAnywhere, Category = "Settings")
	EIslandShootablePlatformDirection Direction = EIslandShootablePlatformDirection::Up; 

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (ClampMin = 0))
	float MaxMoveAmount = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SpringStrength = 0.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ImpulsePerShot = 50.0;

	UPROPERTY(EditAnywhere, Category = "Flash")
	float ShotEmissiveMax = 5.0;

	UPROPERTY(EditAnywhere, Category = "Flash")
	float ShotFlashDuration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bMoveBack = true;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = bMoveBack, EditConditionHides))
	float MoveBackSpeed = 100.0;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = bMoveBack, EditConditionHides))
	float MoveBackDelay = 1.5;

	float InitialEmissiveIntensity;
	float TimeLastShot;

	UMaterialInstanceDynamic Material;

	bool bIsFlashing = false;
	float StartTime;

	bool bDoMoveBackEvent;
	bool bIsMoving;

	bool bHasMoved;

	UPROPERTY(EditAnywhere, Category = "Settings")
	ADynamicWaterEffectDecal DynamicWaterEffectDecal;

	int MaterialIndex = 1;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(PlatformToCopySettingsFrom != nullptr)
		{
			StaticMesh.WorldScale3D = PlatformToCopySettingsFrom.ActorScale3D;
			SetActorLocation(PlatformToCopySettingsFrom.ActorLocation);
		}

		if(Color == EIslandRedBlueWeaponType::Red)
		{
			StaticMesh.SetMaterial(MaterialIndex, RedMaterial);
			StaticMeshFront.SetMaterial(MaterialIndex, RedMaterial);
			StaticMeshBottom.SetMaterial(MaterialIndex, RedMaterial);
			TargetableComp.UsableByPlayers = EHazeSelectPlayer::Mio;
		}
		else if(Color == EIslandRedBlueWeaponType::Blue)
		{
			StaticMesh.SetMaterial(MaterialIndex, BlueMaterial);
			StaticMeshFront.SetMaterial(MaterialIndex, BlueMaterial);
			StaticMeshBottom.SetMaterial(MaterialIndex, BlueMaterial);
			TargetableComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
		}

		TranslateComp.MinY = 0.0;
		TranslateComp.MaxY = 0.0;
		switch(Direction)
		{
			case EIslandShootablePlatformDirection::Up:
			{
				TranslateComp.MinZ = 0.0;
				TranslateComp.MaxZ = MaxMoveAmount;

				TranslateComp.MinX = 0.0;
				TranslateComp.MaxX = 0.0;
				break;
			}
			case EIslandShootablePlatformDirection::Down:
			{
				TranslateComp.MinZ = -MaxMoveAmount;
				TranslateComp.MaxZ = 0.0;

				TranslateComp.MinX = 0.0;
				TranslateComp.MaxX = 0.0;
				break;
			}
			case EIslandShootablePlatformDirection::Left:
			{
				TranslateComp.MinX = -MaxMoveAmount;
				TranslateComp.MaxX = 0.0;

				TranslateComp.MinZ = 0.0;
				TranslateComp.MaxZ = 0.0;
				break;
			}
			case EIslandShootablePlatformDirection::Right:
			{
				TranslateComp.MinX = 0.0;
				TranslateComp.MaxX = MaxMoveAmount;

				TranslateComp.MinZ = 0.0;
				TranslateComp.MaxZ = 0.0;
				break;
			}
			default:
			{
				// ¯\_(ツ)_/¯
				break;
			}
		}

		TranslateComp.SpringStrength = SpringStrength;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartTime = Time::GameTimeSeconds;

		if(Color == EIslandRedBlueWeaponType::Red)
			ImpactCounterResponseComp.BlockImpactForColor(EIslandRedBlueWeaponType::Blue, this);
		else if(Color == EIslandRedBlueWeaponType::Blue)
			ImpactCounterResponseComp.BlockImpactForColor(EIslandRedBlueWeaponType::Red, this);

		Material = StaticMesh.CreateDynamicMaterialInstance(MaterialIndex);
		InitialEmissiveIntensity = Material.GetScalarParameterValue(n"EmissiveIntensity");

		Material = StaticMeshFront.CreateDynamicMaterialInstance(MaterialIndex);
	
		ImpactCounterResponseComp.OnImpactEvent.AddUFunction(this, n"OnBeenShot");

		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstrainHit");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsFlashing)
			HandleFlashing();
		
		if(bMoveBack
		&& Time::GetGameTimeSince(TimeLastShot) > MoveBackDelay)
		{
			FVector MoveBackDelta = -VectorDirection * MoveBackSpeed * DeltaSeconds;
			FauxPhysics::ApplyFauxMovementToParents(TranslateComp, MoveBackDelta);
			if (Time::GetGameTimeSince(TimeLastShot) < 2)
			{
				MovingBack();
			}
			else {
				bDoMoveBackEvent = false;
			}

			if (bHasMoved)
			{
				if (TranslateComp.GetCurrentAlphaBetweenConstraints().Z <= 0)
				{
					FullyDown();
				}
			}
			
		}
		float what = TranslateComp.GetCurrentAlphaBetweenConstraints().Z;
		//Print(""+what);

		if(DynamicWaterEffectDecal != nullptr)
			DynamicWaterEffectDecal.DynamicWaterEffectDecalComponent.Strength = Math::Abs(TranslateComp.GetVelocity().Z*0.005);
		
	}

	private void HandleFlashing()
	{
		const float TimeSinceShot = Time::GetGameTimeSince(TimeLastShot);
		if(TimeSinceShot >= ShotFlashDuration)
		{
			bIsFlashing = false;
			Material.SetScalarParameterValue(n"EmissiveIntensity", InitialEmissiveIntensity);
		}
		else
		{
			const float AdditionalEmissiveIntensity = Math::Sin((TimeSinceShot * PI) / ShotFlashDuration) * ShotEmissiveMax;
			Material.SetScalarParameterValue(n"EmissiveIntensity", InitialEmissiveIntensity + AdditionalEmissiveIntensity);
		}
	}

	FVector GetVectorDirection() const property
	{
		if(Direction == EIslandShootablePlatformDirection::Up)
			return StaticMesh.UpVector;
		else if(Direction == EIslandShootablePlatformDirection::Down)
			return -StaticMesh.UpVector;
		else if(Direction == EIslandShootablePlatformDirection::Left)
			return -StaticMesh.ForwardVector;
		else
			return StaticMesh.ForwardVector;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnBeenShot(FIslandRedBlueImpactResponseParams Data)
	{
		FVector ImpulseDir = VectorDirection;
		
		FVector Impulse = ImpulseDir * (ImpulsePerShot * Data.ImpactDamageMultiplier);
		FauxPhysics::ApplyFauxImpulseToActor(this, Impulse);

		if(!bIsFlashing)
			TimeLastShot = Time::GameTimeSeconds;
		bIsFlashing = true;

		UNiagaraSystem SystemToSpawn = Color == EIslandRedBlueWeaponType::Red ? RedHitEffect : BlueHitEffect;
		Niagara::SpawnOneShotNiagaraSystemAtLocation(SystemToSpawn, Data.ImpactLocation);

		bHasMoved = true;

		UIslandSidescrollerShootablePlatformEventHandler::Trigger_PlatformMovingUp(this);
		UIslandSidescrollerShootablePlatformEventHandler::Trigger_HitPlatform(this);
		// PrintToScreen("Moving up", 0.1);
	}

	UFUNCTION()
	private void HandleConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (TranslateComp.GetCurrentAlphaBetweenConstraints().Z > 0.5)
			UIslandSidescrollerShootablePlatformEventHandler::Trigger_FullyUp(this);
		else
			return;
		// PrintToScreen("Reached top", 10);
	}

	void MovingBack()
	{
		if (bDoMoveBackEvent)
			return;

		UIslandSidescrollerShootablePlatformEventHandler::Trigger_PlatformMovingDown(this);
		// PrintToScreen("Moving Down", 10);
		bDoMoveBackEvent = true;
	}

	void FullyDown()
	{
		bHasMoved = false;
		// PrintToScreen("Fully down", 10);
		UIslandSidescrollerShootablePlatformEventHandler::Trigger_FullyDown(this);
	}
};

#if EDITOR
class UIslandSidescrollerShootablePlatformDummyComponent : UActorComponent {};

class UIslandSidescrollerShootablePlatformComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandSidescrollerShootablePlatformDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UIslandSidescrollerShootablePlatformDummyComponent>(Component);
		if(Comp == nullptr)
		 	return;
		auto Platform = Cast<AIslandSidescrollerShootablePlatform>(Component.Owner);
		if(Platform == nullptr)
			return;
		FBox BoundingBox = Platform.GetActorLocalBoundingBox(true, false);
		FVector Center = Platform.ActorTransform.TransformPosition(BoundingBox.Center);
		FVector MoveAmount = (Platform.VectorDirection * Platform.MaxMoveAmount) * Platform.ActorScale3D;
		FVector MaxLocation = Center + MoveAmount;
		FVector Extent = BoundingBox.Extent * Platform.ActorScale3D;
		DrawWireBox(MaxLocation, Extent
			, Platform.StaticMesh.ComponentQuat, FLinearColor::Purple, 5);
		DrawWorldString("Max Location", MaxLocation + Extent, FLinearColor::Purple, 1.5, 2000, false);
	}
}

#endif