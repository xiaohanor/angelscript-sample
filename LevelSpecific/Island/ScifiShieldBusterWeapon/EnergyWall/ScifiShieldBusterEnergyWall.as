
/** Add 'ScifiShieldBusterImpactWallTargetableComponent' and place them where you want to be able to cut holes in the wall */
class AScifiShieldBusterEnergyWall : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent WallMesh;

	UPROPERTY(DefaultComponent)
	UScifiShieldBusterImpactResponseComponent ImpactResponse;

	UPROPERTY(DefaultComponent)
	UBoxComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.CollisionProfileName = n"BlockAll";
	
	UPROPERTY(EditAnywhere)
	UScifiShieldBusterEnergyWallCutterSettings CustomSettings;

	UPROPERTY(EditConst)
	TArray<UScifiShieldBusterEnergyWallTargetableComponent> Targets;

	UPROPERTY(EditConst)
	TArray<FInstigator> CutterFunctionalityBlockers;

	UPROPERTY(EditConst)
	AScifiShieldBusterInternalWallCutter CurrentWallCutter;


	//	WallMesh.SetScalarParameterValueOnMaterials(n"Bubble0Radius1", Hole0Radius1);
	//	WallMesh.SetScalarParameterValueOnMaterials(n"Bubble0Radius2", Hole0Radius2);
	//	WallMesh.SetVectorParameterValueOnMaterials(n"Bubble0Loc", Hole0Location);

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TArray<UActorComponent> FoundComponents;
		GetAllComponents(UScifiShieldBusterEnergyWallTargetableComponent, FoundComponents);

		Targets.Reset();

		for(auto ActorComp : FoundComponents)
		{
			Targets.Add(Cast<UScifiShieldBusterEnergyWallTargetableComponent>(ActorComp));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		#if EDITOR
		if(!ensure(Targets.Num() > 0, "" + GetName() + " has no 'ScifiShieldBusterEnergyWallTargetableComponent'"))
		{
			FVector Extends = GetActorBoxExtents(true);
			float DebugRadius = Shape::GetEncapsulatingSphereRadius(FCollisionShape::MakeBox(Extends));
			Debug::DrawDebugSphere(GetActorLocation(), DebugRadius, LineColor = FLinearColor::Red, Duration = 10);
		}
		#endif
	}

	// Stops this wall from being cutable
	UFUNCTION()
	void AddWallCutterBlocker(FInstigator Instigator)
	{
		CutterFunctionalityBlockers.AddUnique(Instigator);
	}

	// Enables this wall from being cutable, when all blockers has been removed
	UFUNCTION()
	void RemoveWallCutterBlocker(FInstigator Instigator)
	{
		CutterFunctionalityBlockers.RemoveSingleSwap(Instigator);
	}

	bool CanCut() const
	{
		return CutterFunctionalityBlockers.Num() == 0;
	}

	UScifiShieldBusterEnergyWallCutterSettings GetCutterSettings() property
	{
		if(CustomSettings == nullptr)
			return Cast<UScifiShieldBusterEnergyWallCutterSettings>(UScifiShieldBusterEnergyWallCutterSettings.DefaultObject);
		else
			return CustomSettings;
	}
}

/** Add to 'ScifiShieldBusterImpactWall' and place them where you want to be able to cut holes in the wall */
class UScifiShieldBusterEnergyWallTargetableComponent : UScifiShieldBusterTargetableComponent
{
	UPROPERTY(EditAnywhere)
	FVector CutOffset = FVector::ZeroVector;

	AScifiShieldBusterEnergyWall WallOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		WallOwner = Cast<AScifiShieldBusterEnergyWall>(Owner);
	}

	FVector GetCutLocation() const
	{
		return GetWorldLocation() + CutOffset;
	}
}


/** Settings controlling the wall */
class UScifiShieldBusterEnergyWallCutterSettings : UDataAsset
{
	/** If we have an impact, how big the hole should at least be, 
	 * so we can make the first hole bigger than the grow amount.
	 * only used if bigger than 'ImpactSizeGenerationAmount'
	*/ 
	UPROPERTY(Category = "Impacts")
	float ImpactMinSize = 0;

	// How much the hole will grow with each impact
	UPROPERTY(Category = "Impacts")
	float ImpactSizeGenerationAmount = 300;

	// How big the hole can become
	UPROPERTY(Category = "Impacts")
	float MaxSize = 300;

	// How fast the hole shrinks
	UPROPERTY(Category = "Degeneration", meta = (ClampMin = "0"))
	float DegenerationSpeed = 100;

	// The smallest size of the whole that we can pass trough
	UPROPERTY(Category = "Player")
	float MinPassThroughSize = 100.0;

	// How long the capsule is that that disable the collision against the wall for the player
	UPROPERTY(Category = "Player")
	float MovementCollisionIgnoreSize = 600.0;

	// A multiplier changing how fast the hole shrinks in relation to how long ago it was hit
	UPROPERTY(Category = "Degeneration")
	FRuntimeFloatCurve DegenerationSpeedMultiplier;
	default DegenerationSpeedMultiplier.AddDefaultKey(0.0, 0.0);
	default DegenerationSpeedMultiplier.AddDefaultKey(1.0, 0.0);
	default DegenerationSpeedMultiplier.AddDefaultKey(2.0, 1.0);
}

/** Internal class for cutting wholes in the walls */
class AScifiShieldBusterInternalWallCutter : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UScifiShieldBusterInteralWallCutterComponent MovementZone;

	float LastImpactTime = 0;
	float CurrentSize = 0;

	AScifiShieldBusterEnergyWall CurrentAttachedWall;
	UScifiShieldBusterEnergyWallTargetableComponent CurrentAttachedWallTargetComponent;
}

/** Internal class for cutting wholes in the walls used by the wallcutter */
class UScifiShieldBusterInteralWallCutterComponent : UHazeMovablePlayerTriggerComponent
{	
	AScifiShieldBusterInternalWallCutter Cutter;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cutter = Cast<AScifiShieldBusterInternalWallCutter>(Owner);
	}

	// [LUCAS]: Not supported anymore, but shield buster is cut anyway
	/*UFUNCTION(BlueprintOverride)
	FHazeTraceShape GetRuntimeUpdateShape(bool bForActivation) const
	{
		const UScifiShieldBusterEnergyWallCutterSettings Settings = Cutter.CurrentAttachedWall.GetCutterSettings();
		const float MinPassThroughSize = Settings.MinPassThroughSize;

		// Safety distance so player player dont travel through to small holes
		if(Cutter.CurrentSize >= MinPassThroughSize)
			return FHazeTraceShape::MakeCapsule(Cutter.CurrentSize, Settings.MovementCollisionIgnoreSize, FQuat::MakeFromXZ(FVector::UpVector, Cutter.ActorForwardVector));
		else
			return FHazeTraceShape();
	}*/

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter OtherActor)
	{
		if(Cutter.CurrentAttachedWall != nullptr)
		{
			auto MoveComp = UHazeMovementComponent::Get(OtherActor);
			MoveComp.AddMovementIgnoresActor(this, Cutter.CurrentAttachedWall);
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter OtherActor)
	{
		auto MoveComp = UHazeMovementComponent::Get(OtherActor);
		MoveComp.RemoveMovementIgnoresActor(this);
	}

	AScifiShieldBusterEnergyWall GetEnergyWall() const
	{
		return Cutter.CurrentAttachedWall;
	}
}