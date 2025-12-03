struct FHydraPortalPropAnimations
{
	UPROPERTY(Category = "HydraPortal")
	FHazePlaySequenceData EnterPhase;
	
	UPROPERTY(Category = "HydraPortal")
	FHazePlaySequenceData PhaseMH;
	
	UPROPERTY(Category = "HydraPortal")
	FHazePlaySequenceData ExitPhase;
}

UCLASS()
class ULocomotionFeatureHydraPortalProps : UDataAsset
{
	UPROPERTY(Meta = ShowOnlyInnerProperties)
	FHydraPortalPropAnimations AnimData;
}

UCLASS(Abstract)
class UFeatureAnimInstanceHydraPortalProps : UHazeAnimInstanceBase
{
	UPROPERTY()
	ULocomotionFeatureHydraPortalProps LeftGauntletFeature;
	UPROPERTY()
	ULocomotionFeatureHydraPortalProps RightGauntletFeature;
	UPROPERTY()
	ULocomotionFeatureHydraPortalProps HydraFeature;
	UPROPERTY()
	ULocomotionFeatureHydraPortalProps PortalFeature;

	UPROPERTY()
	FHydraPortalPropAnimations AnimData;

	UPROPERTY()
	bool bAttackFinished = false;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		// This is a hack, because the skeletal meshes are on the same actor
		if (OwningComponent.Name == n"LeftGauntletMesh")
			AnimData = LeftGauntletFeature.AnimData;
		else if (OwningComponent.Name == n"RightGauntletMesh")
			AnimData = RightGauntletFeature.AnimData;
		else if (OwningComponent.Name == n"PortalMesh")
			AnimData = PortalFeature.AnimData;
		else
			AnimData = HydraFeature.AnimData;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (GetWorld().IsGameWorld())
		{
			AMeltdownBossPhaseThreeRainAttack AttackActor = TListedActors<AMeltdownBossPhaseThreeRainAttack>().GetSingle();
			if (AttackActor != nullptr)
			{
				bAttackFinished = AttackActor.bAttackFinished;
			}
		}
	}
}
