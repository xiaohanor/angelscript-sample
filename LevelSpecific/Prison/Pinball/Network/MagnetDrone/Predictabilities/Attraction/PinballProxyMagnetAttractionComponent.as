UCLASS(NotBlueprintable, NotPlaceable)
class UPinballProxyMagnetAttractionComponent : UPinballMagnetDroneProxyComponent
{
	default ControlComponentClass = UMagnetDroneAttractionComponent;

	/**
	 * Copied Data
	 */
	UMagnetDroneAttractionSettings Settings;
	TArray<UMagnetDroneAttractionMode> AttractionModes;

	/**
	 * Synced data
	 * Initially the same as Control, but will be modified during the prediction
	 */
	FMagnetDroneTargetData AttractionTarget;
	EMagnetDroneStartAttractionInstigator AttractionTargetInstigator;
	float AttractionAlpha;
	float StartAttractTime = 0;

	/**
	 * Local Data
	 */
	UPinballProxyMovementComponent MoveComp;
	// A kind of hacky way for the resolver to tell us we might be stuck
	bool bIsAttracting = false;
	uint AttractionMightBeStuckFrame = 0;
	FHitResult AttractionStartContact;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		MoveComp = UPinballProxyMovementComponent::Get(Proxy);

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballProxyMagnetAttraction");
#endif
	}

	void InitComponentState(const UActorComponent ControlComp) override
	{
		Super::InitComponentState(ControlComp);

#if !RELEASE
		FTemporalLog InitialLog = Proxy.GetInitialLog().Page(Name.ToString());
#endif

		auto ControlAttractionComp = Cast<UMagnetDroneAttractionComponent>(ControlComp);
		Settings = ControlAttractionComp.Settings;
		AttractionModes = ControlAttractionComp.AttractionModes;

		const FPinballPredictionSyncedAttractionData& AttractionData = Proxy.InitialSyncedData.AttractionData;
		AttractionTarget = AttractionData.AttractionTarget;
		AttractionTargetInstigator = AttractionData.AttractionTargetInstigator;
		AttractionAlpha = AttractionData.AttractionAlpha;
		StartAttractTime = AttractionData.StartAttractTime;
	}

	UMagnetDroneAttractionMode GetAttractionMode(TSubclassOf<UMagnetDroneAttractionMode> AttractionModeClass) const
	{
		for(auto AttractionMode : AttractionModes)
		{
			if(AttractionMode.Class == AttractionModeClass)
				return AttractionMode;
		}

		check(false);
		return nullptr;
	}

	bool HasAttractionTarget() const 
	{
		return AttractionTarget.IsValidTarget();
	}

	const FMagnetDroneTargetData& GetAttractionTarget() const
	{
		check(HasAttractionTarget());
		return AttractionTarget;
	}

	EMagnetDroneStartAttractionInstigator GetAttractionTargetInstigator() const
	{
		return AttractionTargetInstigator;
	}

	const FHitResult& GetAttractionStartContact() const
	{
		check(IsAttracting());
		return AttractionStartContact;
	}

	void SetAttractionAlpha(float InAttractionAlpha)
	{
		// use time to predict when we reach the target
		AttractionAlpha = InAttractionAlpha;
	}

	float GetAttractionAlpha() const
	{
		return AttractionAlpha;
	}

	bool IsAttracting() const
	{
		if(!AttractionTarget.IsValidTarget())
			return false;

		return bIsAttracting;
	}

	bool HasFinishedAttracting() const
	{
		return AttractionAlpha > 1.0 - KINDA_SMALL_NUMBER;
	}

	bool GetAttractionMightBeStuckThisFrame() const
	{
		return AttractionMightBeStuckFrame >= Time::FrameNumber - 1;
	}

#if !RELEASE
	void LogComponentState(FTemporalLog SubframeLog) const override
	{
		Super::LogComponentState(SubframeLog);
	}
#endif
};