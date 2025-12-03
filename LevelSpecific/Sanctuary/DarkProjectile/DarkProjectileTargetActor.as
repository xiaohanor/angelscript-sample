class ADarkProjectileTargetActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;
	default Mesh.bGenerateOverlapEvents = false;
	default Mesh.CollisionProfileName = n"EnemyCharacter";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UDarkProjectileTargetComponent TargetComponent;

	UPROPERTY(DefaultComponent)
	ULightBeamTargetComponent BeamTargetComponent;
	
	UPROPERTY(EditAnywhere, Category = "Dark")
	FVector Axis = FVector::RightVector;

	UPROPERTY(EditAnywhere, Category = "Dark")
	float Speed = 2.0;

	UPROPERTY(EditAnywhere, Category = "Dark")
	float Distance = 250.0;

	FHazeAcceleratedVector Offset;

	private FVector InitialLocation;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Axis = Axis.GetSafeNormal();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialLocation = ActorLocation;

		{
			auto ResponseComp = UDarkProjectileResponseComponent::GetOrCreate(this);
			ResponseComp.OnHit.AddUFunction(this, n"HandleDarkProjectileHit");
		}

		{
			auto ResponseComp = ULightProjectileResponseComponent::GetOrCreate(this);
			ResponseComp.OnHit.AddUFunction(this, n"HandleLightProjectileHit");
		}

		{
			auto ResponseComp = ULightBeamResponseComponent::GetOrCreate(this);
			ResponseComp.OnHitBegin.AddUFunction(this, n"HandleLightBeamHitBegin");
			ResponseComp.OnHitEnd.AddUFunction(this, n"HandleLightBeamHitEnd");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Math::IsNearlyZero(Speed) || 
			Math::IsNearlyZero(Distance))
			return;

		const FVector Movement = Axis * Math::Sin(Time::GameTimeSeconds * Speed) * Distance;
		Offset.SpringTo(FVector::ZeroVector, 100.0, 0.2, DeltaTime);
		ActorLocation = InitialLocation + Movement + Offset.Value;
	}

	UFUNCTION()
	private void HandleDarkProjectileHit(FDarkProjectileHitData HitData)
	{
		Offset.SnapTo(-HitData.Normal * 100.0);

		Debug::DrawDebugLine(
			HitData.Location,
			HitData.Location + HitData.Normal * 250.0,
			FLinearColor::Purple,
			Duration = 5.0
		);
	}

	UFUNCTION()
	private void HandleLightProjectileHit(FLightProjectileHitData HitData)
	{
		Offset.SnapTo(-HitData.Normal * 25.0);

		Debug::DrawDebugLine(
			HitData.Location,
			HitData.Location + HitData.Normal * 250.0,
			FLinearColor::Yellow,
			Duration = 5.0
		);
	}

	UFUNCTION()
	private void HandleLightBeamHitEnd(AHazePlayerCharacter Instigator)
	{
		Print("OnHitEnd", 1.0);
	}

	UFUNCTION()
	private void HandleLightBeamHitBegin(AHazePlayerCharacter Instigator)
	{
		Print("OnHitBegin", 1.0);
	}
}