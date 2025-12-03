/**
 * 
 */
UCLASS(Abstract, HideCategories="Cooking Collision AssetUserData ComponentReplication Variable Activation")
class UWindJavelinPlayerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = "WindJavelin")
	TSubclassOf<AWindJavelin> WindJavelinClass;

	UPROPERTY(Category = "WindJavelin")
	protected UWindJavelinSettings DefaultSettings;

	UPROPERTY()
	UMaterialParameterCollection WindParams;

	AHazePlayerCharacter Player = nullptr;
	UPlayerAimingComponent AimComp = nullptr;
	UPlayerTargetablesComponent PlayerTargetableComp;

    protected float ChargeFactor_Internal = 0.0;
    float AimDuration = 0.0;

	bool bIsAiming = false;
	bool bIsThrowing = false;

	bool bSpawn = false;
	bool bThrow = false;

	bool bShowTutorial = false;

	AWindJavelin WindJavelin;
	AWindJavelin ThrownWindJavelin;

	UWindJavelinResponseComponent AimAtResponseComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		PlayerTargetableComp = UPlayerTargetablesComponent::Get(Owner);

		Player.ApplyDefaultSettings(DefaultSettings);
	}

	bool GetIsAiming() const
	{
		if(AimComp.IsAiming(this))
			return true;

		if(bIsAiming)
			return true;

		return false;
	}

	bool GetIsThrowing() const
	{
		return bIsThrowing;
	}

	bool GetIsUsingWindJavelin() const
	{
		return bIsAiming || bIsThrowing;
	}

    void ShowAutoAimWidgets()
	{
		PlayerTargetableComp.ShowWidgetsForTargetables(
			UWindJavelinAutoAimTargetComponent,
			Settings.AutoAimTargetWidget
		);
	}

    bool HasAutoAimTarget() const
	{
		const FAimingResult AimResult = AimComp.GetAimingTarget(this);
		return AimResult.AutoAimTarget != nullptr;
	}

    bool GetbFullyCharged() const property
    {
        return GetChargeFactor() > (1.0 - KINDA_SMALL_NUMBER);
    }

	void SetChargeFactor(float InChargeFactor, bool bWindJavelin)
	{
		ChargeFactor_Internal = Math::Clamp(InChargeFactor, 0.0, 1.0);

		float TargetFov = Settings.AimMaxFOV;
		const float FOV = Math::Lerp(0.0, TargetFov, Settings.AimFOVCurve.GetFloatValue(ChargeFactor_Internal));
		UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(FOV, this, 0.5);
	}

	UFUNCTION(BlueprintPure)
	float GetChargeFactor() const
	{
		return ChargeFactor_Internal;
	}

	FHitResult TraceForTarget() const
	{
		const FAimingResult AimResult = AimComp.GetAimingTarget(this);

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ETraceTypeQuery::Visibility);
		TraceSettings.UseLine();
		TraceSettings.IgnorePlayers();

		const FVector Start = AimResult.AimOrigin;
		const FVector End = Start + AimResult.AimDirection * WindJavelin::MaxThrowDistance;
		
		return TraceSettings.QueryTraceSingle(Start, End);
	}

	FWindJavelinTargetData CalculateTargetData() const
	{
        const float Speed = Settings.ThrowSpeed;
        const float Gravity = Settings.Gravity;
		const FVector Origin = WindJavelin.ActorLocation;

		const FHitResult Hit = TraceForTarget();

		FWindJavelinTargetData TargetData = FWindJavelinTargetData();

		if(Hit.bBlockingHit)
		{
			TargetData.Origin = Origin;
			TargetData.TargetLocation = Hit.Location;
		}
		else
		{
			TargetData.Origin = Origin;
			TargetData.TargetLocation = Hit.TraceEnd;
		}

		TargetData.Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(TargetData.Origin, TargetData.TargetLocation, Gravity, Speed);

		return TargetData;
	}

	UWindJavelinSettings GetSettings() const property
	{
		return UWindJavelinSettings::GetSettings(Player);
	}
}

struct FWindJavelinTargetData
{
	FVector Origin;
	FVector TargetLocation;
	FVector Velocity;

	FVector GetDirection() const
	{
		return (TargetLocation - Origin).GetSafeNormal();
	}
}