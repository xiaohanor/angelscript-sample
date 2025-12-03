class USummitTailGeckoClimbJumpRampComponent : UActorComponent
{
	// The min height above the platform which is allowed to jump to
	UPROPERTY(EditAnywhere)
	float AttachMinHeightAbovePlatform = 500;

	// The max height above the platform which is allowed to jump to
	UPROPERTY(EditAnywhere)
	float AttachMaxHeightAbovePlatform = 1000;

	UPROPERTY(EditAnywhere)
	float AttachJumpSpeed = 2350;

	UPROPERTY(EditAnywhere)
	float WallMaxDistance = 4000;

	UPROPERTY(EditAnywhere)
	bool bOverrideDefaultJumpCurve = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bOverrideDefaultJumpCurve"))
	FRuntimeFloatCurve JumpSpeedCurve;
};