enum ESketchbookArrowState
{
	Despawned,
	Launched,
	Attached,
};

/**
 * 
 */
 UCLASS(Abstract)
class ASketchbookArrow : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

    UPROPERTY(DefaultComponent, Attach = MeshRoot)
    UStaticMeshComponent Mesh;
    default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	USceneComponent TrailAttachComp;

    #if EDITOR
    UPROPERTY(DefaultComponent)
    UTemporalLogTransformLoggerComponent TemporalLogTransform;
    #endif

    UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(EditAnywhere)
	float MoveSpeedMultiplier = 1.5;

    FSketchbookArrowHitData HitData;

    float ChargeFactor = 0.0;

	USketchbookBowPlayerComponent BowComp;

    float Gravity = 0.0;

	private ESketchbookArrowState ArrowState = ESketchbookArrowState::Despawned;
	private float AttachTime;
	private float BoingTime;

	FTraversalTrajectory Trajectory;

	float LaunchDuration = 0;

	UFUNCTION(BlueprintEvent)
	void BP_Launch(AHazePlayerCharacter InPlayer, FVector InVelocity, float InGravity, USketchbookBowPlayerComponent InBowComp) {};

	UFUNCTION(BlueprintEvent)
	void BP_Unspawn() {};

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SetActorControlSide(Player);

		SetArrowState(ESketchbookArrowState::Despawned);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
		switch(ArrowState)
		{
			case ESketchbookArrowState::Despawned:
				break;

			case ESketchbookArrowState::Launched:
				TickLaunched(DeltaTime);
				break;

			case ESketchbookArrowState::Attached:
				TickAttached(DeltaTime);
				break;
		}

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		TemporalLog
			.Point("Actor Location", ActorLocation, 10.0, FLinearColor::Blue)
			.Value("Charge Factor", ChargeFactor)
		;
#endif
    }

	private void SetArrowState(ESketchbookArrowState InArrowState)
	{
		if(ArrowState == InArrowState)
			return;

		switch(InArrowState)
		{
			case ESketchbookArrowState::Despawned:
			{
				AddActorDisable(this);
				DetachFromActor();
				BP_Unspawn();
				BowComp.SpawnPoolComponent.UnSpawn(this);
				break;
			}

			case ESketchbookArrowState::Launched:
				if(IsActorDisabledBy(this))
					RemoveActorDisable(this);
				break;

			case ESketchbookArrowState::Attached:
				if(IsActorDisabledBy(this))
					RemoveActorDisable(this);
				break;
		}

		ArrowState = InArrowState;
	}

	ESketchbookArrowState GetArrowState() const
	{
		return ArrowState;
	}

	void Launch(AHazePlayerCharacter InPlayer, FVector InVelocity, float InGravity, USketchbookBowPlayerComponent InBowComp)
	{
		RemoveActorDisable(this);

		LaunchDuration = 0;

		Player = InPlayer;
        Gravity = InGravity;
		SetActorVelocity(InVelocity);

		Trajectory.LaunchLocation = ActorLocation;
		Trajectory.LaunchVelocity = ActorVelocity;
		Trajectory.Gravity = FVector::DownVector * Gravity;

		BowComp = InBowComp;

		FHitResult InitialHit = InitialSweep();
        if(InitialHit.bStartPenetrating)
        {
            // What to do now?
			SetArrowState(ESketchbookArrowState::Despawned);
            return;
        }

        if(InitialHit.bBlockingHit)
        {
            SetActorLocation(InitialHit.Location);
            
            if(HasControl())
                OnHitActor(InitialHit);
        }

		SetArrowState(ESketchbookArrowState::Launched);
		BP_Launch(InPlayer, InVelocity, InGravity, InBowComp);

		Mesh.SetCustomDepthStencilValue(InPlayer.Mesh.CustomDepthStencilValue);
	}

	FHitResult InitialSweep() const
    {
		FHazeTraceSettings Settings = GetTraceSettings();

        const FVector Start = Player.ViewLocation;
        const FVector End = ActorLocation;

        const FHitResult Hit = Settings.QueryTraceSingle(
			Start,
			End
		);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
        TemporalLog.HitResults("InitialSweep", Hit, Settings.Shape);
#endif

        return Hit;
    }

	void TickLaunched(float DeltaTime)
	{
		// Using trajectory for movement to get perfectly accurate aiming
		const FVector StartLocation = Trajectory.GetLocation(LaunchDuration);

		LaunchDuration += DeltaTime * MoveSpeedMultiplier;
		
		const FVector EndLocation = Trajectory.GetLocation(LaunchDuration);

        FHitResult Hit = Sweep(StartLocation, EndLocation);

        if(Hit.bBlockingHit)
        {
            SetActorLocation(Hit.Location);
        }
        else
        {
			const FVector Velocity = Trajectory.GetVelocity(LaunchDuration);
			const FQuat NewRotation = FQuat::MakeFromXZ(Velocity, ActorUpVector);
            SetActorLocationAndRotation(EndLocation, NewRotation);
			SetActorVelocity(Velocity);
        }

        if(HasControl())
        {
            if(Hit.bBlockingHit)
                OnHitActor(Hit);
        }
	}

	FHitResult Sweep(FVector StartLocation, FVector EndLocation) const
    {
        FHazeTraceSettings Settings = GetTraceSettings();

        const FHitResult Hit = Settings.QueryTraceSingle(
			StartLocation,
			EndLocation
		);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
        TemporalLog.HitResults("Sweep", Hit, Settings.Shape);
#endif

        return Hit;
    }

    void OnHitActor(const FHitResult& HitResult)
    {
        check(HasControl());

        HitData = FSketchbookArrowHitData(HitResult);

        const float HitImpulseScale = USketchbookArrowSettings::GetSettings(Player).HitImpulseScale;

        float ResponseCompImpulseScale = 0.0;

        TArray<USketchbookArrowResponseComponent> ResponseComponents;
        HitData.Component.Owner.GetComponentsByClass(ResponseComponents);

        if(ResponseComponents.Num() > 0)
        {
            for(int i = ResponseComponents.Num() - 1; i >= 0; i--)
            {
				ResponseCompImpulseScale += ResponseComponents[i].ArrowImpulseScale;
            }

            // Average all the hit response components impulse scales
            if(ResponseComponents.Num() > 0)
                ResponseCompImpulseScale /= ResponseComponents.Num();
        }
        else
        {
            ResponseCompImpulseScale = 1.0;
        }

        float Impulse = ChargeFactor * ResponseCompImpulseScale * HitImpulseScale;
        FSketchbookArrowHitEventData EventData(this);
        CrumbOnHitActor(ResponseComponents, EventData, Impulse);
    }

    UFUNCTION(CrumbFunction)
    private void CrumbOnHitActor(TArray<USketchbookArrowResponseComponent> HitResponseComponents, FSketchbookArrowHitEventData& EventData, float HitImpulse)
    {
		if(ArrowState == ESketchbookArrowState::Attached)
			return;
		
		EventData.bHasControl = HasControl();

        for(auto HitResponseComponent : HitResponseComponents)
		{
			if(HitResponseComponent == nullptr)
				continue;

            HitResponseComponent.OnHitByArrow.Broadcast(EventData, ActorLocation);
		}

        USketchbookArrowEventHandler::Trigger_Hit(this, EventData);
		
		if(EventData.Component != nullptr)
		{
        	if(HitImpulse > KINDA_SMALL_NUMBER)
            	FauxPhysics::ApplyFauxImpulseToParentsAt(EventData.Component, EventData.GetImpactPoint(), GetActorVelocity() * HitImpulse);

			SetActorLocation(EventData.GetImpactPoint());
			AttachToComponent(EventData.Component, EventData.BoneName, AttachmentRule = EAttachmentRule::KeepWorld);
		}

		SetArrowState(ESketchbookArrowState::Attached);
		AttachTime = Time::GameTimeSeconds;
		BoingTime = 0;
    }

	private void TickAttached(float DeltaTime)
	{
		if(!IsValid(AttachParentActor) || AttachParentActor.IsActorDisabled())
		{
			SetArrowState(ESketchbookArrowState::Despawned);
			return;
		}

		auto HitPrimitive = Cast<UPrimitiveComponent>(RootComponent.AttachParent);
		const bool bAttachmentIsInvalid = HitPrimitive != nullptr && HitPrimitive.IsHiddenInGame() && !HitPrimitive.HasTag(n"SketchbookArrowAttach");
		if(bAttachmentIsInvalid)
		{
			SetArrowState(ESketchbookArrowState::Despawned);
			return;
		}

		const float AttachedDuration = Time::GetGameTimeSince(AttachTime);
		if(AttachedDuration > 3)
		{
			SetArrowState(ESketchbookArrowState::Despawned);
			return;
		}

		const float BoingAlpha = 1.0 - Math::Saturate(AttachedDuration / 0.5);
		const float BoingFrequency = 80.0;
		const float BoingAmplitude = 0.3 * Math::Pow(BoingAlpha, 2);

		BoingTime += DeltaTime * BoingFrequency;

		const float Angle = Math::Sin(BoingTime) * BoingAmplitude;
		FQuat Rotation = FQuat(FVector::RightVector, Angle);
		MeshRoot.SetRelativeRotation(Rotation);
	}

	UFUNCTION()
	private void DestroyAfterDelay()
	{
		SetArrowState(ESketchbookArrowState::Despawned);
	}

    bool HasHitData() const
    {
        return HitData.Component != nullptr;
    }

    FHazeTraceSettings GetTraceSettings() const
    {
		FHazeTraceSettings Settings = Trace::InitChannel(ETraceTypeQuery::Visibility, n"SketchbookArrow");
        Settings.UseLine();
		Settings.IgnorePlayers();
		Settings.SetTraceComplex(false);
        return Settings;
    }
}