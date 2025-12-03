/**
 * 
 */
 UCLASS(Abstract)
class ARopeArrow : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USphereComponent Sphere;
    default Sphere.SphereRadius = 16.0;
    default Sphere.bAffectDynamicIndirectLighting = false;
	default Sphere.bCanEverAffectNavigation = false;
	default Sphere.SetCollisionProfileName(n"NoCollision");
	default Sphere.SetGenerateOverlapEvents(false);
  	default Sphere.BodyInstance.bNotifyRigidBodyCollision = false;
  	default Sphere.BodyInstance.bUseCCD = false;
	default Sphere.CollisionEnabled = ECollisionEnabled::NoCollision;
	default Sphere.bCastDynamicShadow = false;
	default Sphere.AddTag(ComponentTags::HideOnCameraOverlap);

    UPROPERTY(DefaultComponent, BlueprintReadOnly, Attach = "Sphere")
    UStaticMeshComponent Mesh;
    default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

    #if EDITOR
    UPROPERTY(DefaultComponent)
    UTemporalLogTransformLoggerComponent TemporalLogTransform;
    #endif

    UPROPERTY(DefaultComponent, Attach = "Sphere")
    UCableComponent CableComp;

    UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;

    FRopeArrowHitData HitData;
    bool bIsLaunched = false;

	UProjectileProximityManagerComponent ProximityManager;

    float Gravity = 0.0;

    bool bActive = false;

    APoleClimbActor PoleClimb;
	APerchSpline PerchSpline;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SetActorControlSide(Player);

        Activate(true);
    }

    void Activate(bool bInitial = false)
    {
        if(bActive)
            return;

        bActive = true;

        if(!bInitial)
        {
            UnblockCapabilities(RopeArrow::RopeArrowTag, this);
            RemoveActorDisable(this);
        }

        if (ProximityManager != nullptr)
			ProximityManager.RegisterProjectile(this);

        // TriggerEffectEvent(n"RopeArrow.Activate"); // UNKNOWN EFFECT EVENT NAMESPACE
    }

    void Deactivate()
    {
        if(!bActive)
            return;

        bActive = false;

        BlockCapabilities(RopeArrow::RopeArrowTag, this);
        AddActorDisable(this);

        bIsLaunched = false;
        HitData = FRopeArrowHitData();

        if (ProximityManager != nullptr)
			ProximityManager.UnregisterProjectile(this);

        // TriggerEffectEvent(n"RopeArrow.Deactivate"); // UNKNOWN EFFECT EVENT NAMESPACE

        if(PoleClimb != nullptr)
        {
            PoleClimb.DestroyActor();
            PoleClimb = nullptr;
        }

        if(PerchSpline != nullptr)
        {
            PerchSpline.DestroyActor();
            PerchSpline = nullptr;
        }
    }

	void Launch(FVector InVelocity, float InGravity, UProjectileProximityManagerComponent InProximityManager)
	{
		ProximityManager = InProximityManager;

        Activate();

        Gravity = InGravity;
		SetActorVelocity(InVelocity);
        bIsLaunched = true;
	}

    void OnHitActor(const FHitResult& HitResult)
    {
        check(HasControl());

        if(HitResult.Actor == nullptr)
        {
            Deactivate();
            return;
        }

        HitData = FRopeArrowHitData(HitResult);
    }

    bool GetbHasHitData() const property
    {
        return HitData.Component != nullptr;
    }

    URopeArrowSettings GetSettings() const property
    {
        return URopeArrowSettings::GetSettings(Player);
    }

	FHazeTraceSettings GetTraceSettings() const
    {
		FHazeTraceSettings RopeTraceSettings = Trace::InitChannel(ETraceTypeQuery::Visibility, n"RopeArrow");
        RopeTraceSettings.UseSphereShape(Sphere.SphereRadius);

        if(IceBow::ShouldIgnoreOtherPlayer())
            RopeTraceSettings.IgnorePlayers();
        else
            RopeTraceSettings.IgnoreActor(Player);

		RopeTraceSettings.SetTraceComplex(false);
        return RopeTraceSettings;
    }
}