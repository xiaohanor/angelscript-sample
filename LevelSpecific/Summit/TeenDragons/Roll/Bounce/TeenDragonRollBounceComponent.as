class UTeenDragonRollBounceComponent : UActorComponent
{
	uint LastResolverBounceFrame = 0;
	bool bHasBouncedSinceLanding = false;
	FTeenDragonRollBounceData PreviousBounceData;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	bool HasResolverBouncedThisFrame() const
	{
		return LastResolverBounceFrame >= Time::FrameNumber;
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbSendOnBounceEvent(FVector GroundLocation, FVector GroundNormal, float LandingSpeed)
	{
		FTeenDragonRollOnBouncedParams Params;
		Params.GroundLocation = GroundLocation;
		Params.GroundNormal = GroundNormal;
		Params.LandingSpeed = LandingSpeed;
		UTeenDragonRollVFX::Trigger_OnBounced(PlayerOwner, Params);
	}
};