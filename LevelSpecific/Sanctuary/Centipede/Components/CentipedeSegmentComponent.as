class UCentipedeSegmentComponent : USphereComponent
{
	default SphereRadius = Centipede::SegmentRadius;

	FVector PreviousLocation;

	FVector PreviousAnimationLocation;

	float LegAnimationTime;

	// Literal head of the centipede
	bool bIsHead = false;

	// Belongs to the end that looks like an individual body
	bool bIsHeadBody = false;

	// This bone joins immovable bones with the movable body
	bool bIsMasterJoint = false;

	private UCentipedeLavaIntoleranceComponent LavaIntoleranceComponent;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem BurningVFXSystem;
	private UNiagaraComponent BurningVFX;

	// Used as ID for spawning burning feedback
	int SegmentIndex = -1;

	// Used during simulation from CentipedeBodyMovementCapability
	bool bIsSimulating = false;
	FVector SimulateLocation;
	FQuat SimulateRotation;

	access ReadOnlyAccess = private, * (readonly);
	access : ReadOnlyAccess bool bIsBurning = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LavaIntoleranceComponent = UCentipedeLavaIntoleranceComponent::Get(Owner);
		BurningVFX = UNiagaraComponent::Create(Owner);
		BurningVFX.Deactivate();
		BurningVFX.AttachToComponent(this);
		BurningVFX.Asset = BurningVFXSystem;
	}

	bool IsLavaInvulnerable()
	{
		return LavaIntoleranceComponent.bIsRespawning;
	}

	void DebugDraw(FLinearColor Color, float Duration)
	{
#if TEST
		Debug::DrawDebugSphere(WorldLocation, SphereRadius * 1.5, 12, Color, 3, Duration);
#endif
	}

	void StartBurn()
	{
		bIsBurning = true;
		BurningVFX.Activate();
	}

	void StopBurn()
	{
		bIsBurning = false;
		BurningVFX.Deactivate();
	}
}