class ASummitKnightAreaDenialZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "Autoaimtarget";
	default Billboard.RelativeScale3D = FVector(3.0);
#endif

	UPROPERTY(DefaultComponent)
	USummitKnightAreaDenialSphereComponent SphereComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegisterComp;
	default RegisterComp.bDelistWhileActorDisabled = false;

	UPROPERTY()
	TSubclassOf<ASummitKnightMetalObstacle> MetalObstacleClass;

	UPROPERTY()
	TSubclassOf<ASummitKnightCrystalObstacle> CrystalObstacleClass;

	ASummitKnightMetalObstacle MetalObstacle;
	ASummitKnightCrystalObstacle CrystalObstacle;

	float SortScore = 0.0;
	int opCmp(ASummitKnightAreaDenialZone Other) const
	{
		return (SortScore > Other.SortScore ? 1 : -1);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetupObstacles();
	}

	void SetupObstacles()
	{
		if (MetalObstacle == nullptr)
		{
			MetalObstacle = SpawnActor(MetalObstacleClass, ActorLocation, ActorRotation, NAME_None, true, Level);
			MetalObstacle.MakeNetworked(this, n"MetalObstacle");
			FinishSpawningActor(MetalObstacle);
		}
		if (CrystalObstacle == nullptr)
		{
			CrystalObstacle = SpawnActor(CrystalObstacleClass, ActorLocation, ActorRotation, NAME_None, true, Level);
			CrystalObstacle.MakeNetworked(this, n"CrystalObstacle");
			FinishSpawningActor(CrystalObstacle);
		}
	}

	bool HasActiveObstacle()
	{	
		if ((MetalObstacle != nullptr) && MetalObstacle.IsActive())
			return true;
		if ((CrystalObstacle != nullptr) && CrystalObstacle.IsActive())
			return true;
		return false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSmashObstacle()
	{
		if ((MetalObstacle != nullptr) && MetalObstacle.IsActive())
			MetalObstacle.Shatter();
		if ((CrystalObstacle != nullptr) && CrystalObstacle.IsActive())
			CrystalObstacle.Shatter();
	}
}

struct FAreaDenialZoneObstacleSpawnParameters
{
	float SpawnTime;
	float SpawnInterval;
	int MetalVariant = -1;
	int CrystalVariant = -1;
	TArray<ASummitKnightAreaDenialZone> Zones;

	void Reset(int NumExpectedObstacles)
	{
		Zones.Reset(NumExpectedObstacles);
		SpawnTime = BIG_NUMBER; 
		SpawnInterval = 0.0;
	}
}

class USummitKnightAreaDenialSphereComponent : USphereComponent
{
	default CollisionProfileName = n"NoCollision";
	default SphereRadius = 400.0;
	default ShapeColor = FLinearColor::Red.ToFColor(true);

	float GetScaledRadius() const property
	{
		return WorldScale.X * SphereRadius;
	}
}

#if EDITOR
class USummitKnightAreaDenialSphereComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitKnightAreaDenialSphereComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		USummitKnightAreaDenialSphereComponent AreaDenialComp = Cast<USummitKnightAreaDenialSphereComponent>(Component);
		if (Component == nullptr)
			return;

		TArray<USummitKnightAreaDenialSphereComponent> Comps;
		Comps.Add(AreaDenialComp);	
		AreaDenialComp.Owner.RootComponent.GetChildrenComponentsByClass(USummitKnightAreaDenialSphereComponent, true, Comps);
		for (USummitKnightAreaDenialSphereComponent Comp : Comps)
		{
			DrawCircle(Comp.WorldLocation, Comp.ScaledRadius, FLinearColor::Red, 20.0);
		}
	}
}
#endif

