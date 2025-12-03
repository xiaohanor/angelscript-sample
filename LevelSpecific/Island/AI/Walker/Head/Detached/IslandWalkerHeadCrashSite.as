class AIslandWalkerHeadCrashSite : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent Area;
	default Area.CollisionProfileName = n"NoCollision";
	default Area.GenerateOverlapEvents = false;
	default Area.SphereRadius = 800.0;
	default Area.ShapeColor = FColor::Yellow;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegisterComp;
	default RegisterComp.bDelistWhileActorDisabled = false;

	UPROPERTY(EditInstanceOnly)
	bool bUsedWhenAcidPoolFlooded = false;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SpriteName = "Traversal";
	default EditorIcon.RelativeLocation = FVector(0.0, 0.0, 200.0);
#endif

	float SafeRadius;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SafeRadius = Math::Max(1.0, Area.SphereRadius - 300.0);
	}

	FVector GetCenter() const property
	{
		return Area.WorldLocation;
	}

	bool HasNearbyPlayer(float RadiusOffset = 0.0) const
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.ActorLocation.IsWithinDist2D(Center, Area.SphereRadius + RadiusOffset))
				return true;
		}
		return false;
	}

	FVector GetCrashLocation(FVector IdealLoc) const
	{
		FVector Location = IdealLoc;
		Location.Z = Area.WorldLocation.Z;
		if (Location.IsWithinDist2D(Area.WorldLocation, SafeRadius))
			return Location;
		return Area.WorldLocation + (Location - Area.WorldLocation).GetSafeNormal2D() * SafeRadius;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bUsedWhenAcidPoolFlooded)
		{
			EditorIcon.SpriteName = "Traversal_Transit";
			Area.ShapeColor = FColor::Green;
		}
		else
		{
			EditorIcon.SpriteName = "Traversal";
			Area.ShapeColor = FColor::Yellow;
		}
	}
#endif
};