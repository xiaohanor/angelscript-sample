enum ESanctuaryHydraPlayerAnimationReaction
{
	None,
	FirstAppearance,
}

class USlidingDiscPlayerComponent : UActorComponent
{
	bool bIsSliding = false;

	UPROPERTY()
	bool bIsLanding = false;

	UPROPERTY()
	float LandedImpactStrength = 0.0;

	UPROPERTY()
	float HorizontalLandedImpactStrength = 0.0;

	UPROPERTY()
	float VerticalAirVelocity = 0.0;

	UPROPERTY()
	ESanctuaryHydraPlayerAnimationReaction HydraPlayerReaction;

	UHazeCrumbSyncedFloatComponent Lean;

	FVector2D Input;

	bool bInWaterSwitchSegment = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Lean = UHazeCrumbSyncedFloatComponent::Create(Owner, n"SyncedLean");
	}
}