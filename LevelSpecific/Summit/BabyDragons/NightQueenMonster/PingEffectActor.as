


/**
 * We currently only allow 1 ping to be active at the same time. 
 * To make it easier to manage during prototyping we'll just use 
 * 1 ping actor per level and pass that around.
 * @TODO: Make manager for this instead
 */
UFUNCTION(BlueprintCallable)
APingEffectActor GetOrCreateInactivePingEffectActor(
	TSubclassOf<APingEffectActor> PingEffectActorClass,
	FVector Location,
	FRotator Rotation,
	TArray<AActor> IgnoreActors
)
{
	// check if we've spawned the ping actor.
	TListedActors<APingEffectActor> PingEffectActors;
	
	// something else is using it.
	if(PingEffectActors.Num() > 0)
		return nullptr;
		
	AActor SpawnedActor = SpawnActor(PingEffectActorClass.Get(), Location, Rotation, bDeferredSpawn = true);
	APingEffectActor SpawnedPing = Cast<APingEffectActor>(SpawnedActor);

	for(auto IterActor : IgnoreActors)
		SpawnedPing.PingEffectComponent.HiddenActors.AddUnique(IterActor);

	TListedActors<AGiant> Birds;
	for(auto IterActor : Birds)
		SpawnedPing.PingEffectComponent.HiddenActors.AddUnique(IterActor);

	if(SpawnedPing != nullptr)
		FinishSpawningActor(SpawnedPing);

	return SpawnedPing;
}

UCLASS(Abstract)
class APingEffectActor : AHazeActor
{
	// Whether we should restart the effect expansion once it reaches max radius
	UPROPERTY(EditAnywhere)
	bool bLooping = false;

	UPROPERTY(EditAnywhere)
	bool bActive = true;

	// X-axis = time, Y-axis =  radius. Controls how fast the sphere expands and its maximum radius.
	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve TimeAndRadiusCurve;
	default TimeAndRadiusCurve.AddDefaultKey(0.0, 0.01);
	default TimeAndRadiusCurve.AddDefaultKey(7.0, 1500.0);

    UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

    UPROPERTY(DefaultComponent)
	UPingEffectComponent PingEffectComponent;

    // UPROPERTY(DefaultComponent, Attach = PingEffectComponent)
    UPROPERTY(DefaultComponent)
	UStaticMeshComponent SphereMesh;

    // UPROPERTY(DefaultComponent, Attach = PingEffectComponent)
    UPROPERTY(DefaultComponent)
	UNiagaraComponent NiagaraComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	float CurrentRadius = 0.01;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	float CurrentTime = 0.0;

	UPROPERTY(BlueprintReadOnly, NotVisible)
    TPerPlayer<bool> PreviousOverlap;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	float MinRadius = 0.0;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	float MaxRadius = 0.0;

	/**
	 * The current sphere mesh == 100 unreal units. We want to normalize it down to 1 uu.
	 * @TODO: use a better sphere mesh. We'll have to update Mattias shaders as well when we do this and niagara.
	 */
	private float MeshSizeNormalizer = 0.01;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// MeshSizeNormalizer = 1.0 / SphereMesh.GetBoundsRadius();
		// InitParams();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshSizeNormalizer = 1.0 / SphereMesh.GetBoundsRadius();
		RestartRadar();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		// reset texture so that nigara doesn't blast us with particles while in the editor.
		bActive = false;
		// PingEffectComponent.Update(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float Dt)
	{
		if(!bActive)
			return;

		UpdateSphereScale(Dt);

		UpdatePlayerOverlaps();

		UpdateState();

		// Debug::DrawDebugLine(GetActorLocation(), Game::Mio.GetActorLocation());
		// Debug::DrawDebugLine(GetActorLocation(), Game::Zoe.GetActorLocation());
		// Debug::DrawDebugSphere(SphereMesh.GetWorldLocation(), CurrentRadius, 64, FLinearColor::Black, 20.0, 0.0);
	}

	void InitParams()
	{
		CurrentTime = 0.0;

		PreviousOverlap[0] = false;
		PreviousOverlap[1] = false;

		TimeAndRadiusCurve.GetValueRange(MinRadius, MaxRadius);

		NiagaraComp.SetNiagaraVariableObject("StaticMesh", SphereMesh.StaticMesh);
		NiagaraComp.SetNiagaraVariableFloat("MaxSphereRadius", MaxRadius);
	}

	UFUNCTION(BlueprintCallable)
	void RestartRadar()
	{
		if(IsActorDisabledBy(this))
			RemoveActorDisable(this);

		InitParams();
		PingEffectComponent.Ping();
		bActive = true;
	}

	void UpdateSphereScale(const float Dt)
	{
		CurrentTime += Dt;
		CurrentRadius = TimeAndRadiusCurve.GetFloatValue(CurrentTime);
		const float NewScaleMagnitude = CurrentRadius * MeshSizeNormalizer;
		SphereMesh.SetWorldScale3D(FVector(NewScaleMagnitude));
		PingEffectComponent.Update(NewScaleMagnitude);
	}

	void UpdatePlayerOverlaps()
	{
		UpdatePlayerOverlap(Game::Mio);
		UpdatePlayerOverlap(Game::Zoe);
	}

	void UpdatePlayerOverlap(AHazePlayerCharacter Player)
	{
		// handle overlaps
		if(IsPlayerOverlapping(Player))
		{
			if(!PreviousOverlap[Player])
			{
				const bool bHitByRadar = !IsPlayerBehindCover(Player);
				PlayerBeginOverlap(Player, bHitByRadar);
				PreviousOverlap[Player] = true;
			}
		}
		else
		{
			if(PreviousOverlap[Player])
			{
				const bool bHitByRadar = !IsPlayerBehindCover(Player);
				PlayerEndOverlap(Player, bHitByRadar);
				PreviousOverlap[Player] = false;
			}
		}
	}

	// Handle deactivation & looping & player detectetion, etc.
	void UpdateState()
	{
		if(CurrentRadius >= MaxRadius)
		{
			if(bLooping)
			{
				RestartRadar();
			}
			else
			{
				DeactivateRadar();
			}
		}
	}

	UFUNCTION(BlueprintCallable)
	void DeactivateRadar()
	{
		bActive = false;
		AddActorDisable(this);
	}

	bool IsPlayerOverlapping(AHazePlayerCharacter Player) const
	{
		FVector Origin = FVector::ZeroVector;
		FVector Extent = FVector::ZeroVector;
		Player.GetActorBounds(true, Origin, Extent, false);

		// the player bounds is a capusle so we're only interested in the x or y component.
		const float PlayerRadius = Extent.X;

		float DistanceToPlayer = (Player.GetActorLocation() - SphereMesh.GetWorldLocation()).Size();
		DistanceToPlayer = Math::Max(0.0, DistanceToPlayer - PlayerRadius);

		const bool bOverlapping = DistanceToPlayer < CurrentRadius;
		
		// Debug::DrawDebugBox(Origin, Extent, Player.GetActorRotation());
		// PrintToScreen("Distance to " + Player.GetName() + " : " + DistanceToPlayer);

		return bOverlapping;
	}

    UFUNCTION(BlueprintEvent)
    void PlayerBeginOverlap(AHazePlayerCharacter OverlappedPlayer, bool bHitByRadar)
    {
		// PrintToScreenScaled("BeginOverlap | " + OverlappedPlayer.GetName() + " | " + " hit by radar: " + bHitByRadar, 2.0);
    }

    UFUNCTION(BlueprintEvent)
    void PlayerEndOverlap(AHazePlayerCharacter OverlappedPlayer, bool bHitByRadar)
    {
		// PrintToScreenScaled("EndOverlap | " + OverlappedPlayer.GetName() + " | " + " hit by radar: " + bHitByRadar, 2.0, FLinearColor::Yellow);
    }

	bool IsPlayerBehindCover(AHazePlayerCharacter InPlayer) const
	{
		// const bool bHitByRadar = PingEffectComponent.GetAlphaAtLocation(Player.GetActorCenterLocation()) == 0.0;
		// return bHitByRadar;

		// TEMP solution with trace: 

		FVector Extent;
		FVector Center;
		InPlayer.GetActorBounds(true, Center, Extent);

		FHazeTraceSettings TraceProfile = Trace::InitChannel(ETraceTypeQuery::Visibility);

		TraceProfile.IgnoreActor(Game::Mio);
		TraceProfile.IgnoreActor(Game::Zoe);
		TraceProfile.IgnoreActor(this);

		for(auto IterActor : PingEffectComponent.HiddenActors)
			TraceProfile.IgnoreActor(IterActor);

		TraceProfile.SetTraceComplex(false);
		TraceProfile.UseSphereShape(Extent.GetAbsMax()*0.5);

		// TraceProfile.DebugDraw(5.0);

		FHitResult Hit = TraceProfile.QueryTraceSingle(
			InPlayer.GetActorCenterLocation(),
			SphereMesh.GetWorldLocation()
		);

		return Hit.bBlockingHit;
	}


}