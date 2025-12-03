UCLASS(Abstract)
class UTreeGuardianBaseEffectEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotVisible, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	ATundraPlayerTreeGuardianActor TreeGuardianActor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TreeGuardianActor = Cast<ATundraPlayerTreeGuardianActor>(Owner);
		Player = TreeGuardianActor.Player;
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
	}

	// Called with an anim notify when tree guardian takes a step
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstep(FTundraPlayerTreeGuardianOnFootstepParams Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepAudio_Plant_Left(FTundraPlayerTreeGuardianAudioFootstepParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepAudio_Plant_Right(FTundraPlayerTreeGuardianAudioFootstepParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepAudio_Release(FTundraPlayerTreeGuardianAudioFootstepParams Params) {}

    // Called when we transform into the tree guardian
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTransformedInto(FTundraPlayerTreeGuardianTransformParams Params) { }

 	// Called when we transform back into human form
 	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTransformedOutOf(FTundraPlayerTreeGuardianTransformParams Params) { }

	// Called right when the tree guardian will start moving towards grapple point (roots should grow inwards as we move to the point)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRangedGrappleStartedEnter(FTundraPlayerTreeGuardianRangedGrappleEnterEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRangedGrappleInit(FTundraPlayerTreeGuardianRangedGrappleEnterEffectParams Params) {}

	// Called when the roots should start growing from the tree guardian's hands towards the target
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartGrowingOutRangedInteractionRoots(FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams Params) { }

	// Called when roots hit a surface (will get called for grapples and life gives)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRootsHitSurface(FTundraPlayerTreeGuardianRangedHitSurfaceEffectParams Params) { }

	// Called when the tree guardian has started life giving (as soon as it can actually interact with the life receiving component)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLifeGivingStarted(FTundraPlayerTreeGuardianLifeGivingEffectParams Params) { }

	// Called when the roots should start growing back into the tree guardian's hands from being attached at the target
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartGrowingInRangedInteractionRoots(FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams Params) { }

	// Called when the tree guardian exits life giving
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLifeGivingStopped(FTundraPlayerTreeGuardianLifeGivingEffectParams Params) { }

	// Called with an anim notify when tree guardian actually puts his hand into the earth and starts life giving
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnNonRangedLifeGivingHandsTouchEarth() { }

	// Called when the tree guardian started entering life giving (as soon as the player presses RT)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLifeGivingEntering(FTundraPlayerTreeGuardianLifeGivingEffectParams Params) { }

	// Called when the tree guardian has reached the grapple point
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRangedGrappleReachedPoint() { }

	// Called when an ongoing grapple is interuppted by a death or shapeshift etc.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRangedGrappleBlocked() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRangedShootStartPullingProjectile(FTundraPlayerTreeGuardianRangedShootParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRangedShootShootProjectile(FTundraPlayerTreeGuardianRangedShootParams Params) {}

	UFUNCTION(BlueprintPure)
	FVector GetLifeGivingEndLocation() property
	{
		return TreeGuardianComp.CurrentRangedLifeGivingRootEndLocation;
	}

	UFUNCTION(BlueprintPure)
	float GetLifeGivingVerticalAlpha() property
	{
		return TreeGuardianComp.LifeGiveAnimData.LifeGivingVerticalAlpha;
	}

	UFUNCTION(BlueprintPure)
	float GetLifeGivingHorizontalAlpha() property
	{
		return TreeGuardianComp.LifeGiveAnimData.LifeGivingVerticalAlpha;
	}

}

struct FTundraPlayerTreeGuardianRangedShootParams
{
	UPROPERTY()
	AHazeActor Projectile;
}

struct FTundraPlayerTreeGuardianTransformParams
{
	UPROPERTY()
	float MorphTime;
}

struct FTundraPlayerTreeGuardianOnFootstepParams
{
	FTundraPlayerTreeGuardianOnFootstepParams(bool In_bIsLeft)
	{
		bIsLeft = In_bIsLeft;
	}

	UPROPERTY()
	bool bIsLeft;
}

struct FTundraPlayerTreeGuardianAudioFootstepParams
{
	UPROPERTY()
	UPhysicalMaterialAudioAsset AudioPhysMat = nullptr;

	UPROPERTY()
	float Pitch = 0.0;

	UPROPERTY()
	float SlopeTilt = 0.0;	
}

struct FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams
{
	UPROPERTY()
	ETundraTreeGuardianRangedInteractionType InteractionType;

	UPROPERTY()
	USceneComponent RootsOriginPoint;

	UPROPERTY()
	USceneComponent RootsTargetPoint;

	UPROPERTY()
	float GrowTime;

	UPROPERTY()
	float TravelTime;
}

struct FTundraPlayerTreeGuardianRangedInteractionHitGrowOutEffectParams
{
	/* This is the origin point and in the beginning also the end point, get the current end point with GetCurrentRangedHitRootEndLocation (in the effect handler) */
	UPROPERTY()
	USceneComponent RootsOriginPoint;

	UPROPERTY()
	float GrowSpeed;

	UPROPERTY()
	FVector GrowVelocity;
}

struct FTundraPlayerTreeGuardianRangedInteractionHitGrowInEffectParams
{
	/* This is the origin point where the roots started growing out from, get the current end point with GetCurrentRangedHitRootEndLocation (in the effect handler) */
	UPROPERTY()
	USceneComponent RootsOriginPoint;

	UPROPERTY()
	float GrowInDuration;
}

struct FTundraPlayerTreeGuardianRangedGrappleEnterEffectParams
{
	UPROPERTY()
	USceneComponent RootsOriginPoint;

	UPROPERTY()
	USceneComponent RootsTargetPoint;

	UPROPERTY()
	float GrappleDuration;
}

struct FTundraPlayerTreeGuardianRangedHitSurfaceEffectParams
{
	UPROPERTY()
	ETundraTreeGuardianRangedInteractionType InteractionType;

	UPROPERTY()
	FHitResult HitResult;
}

enum ETundraPlayerTreeGuardianLifeGivingType
{
	NonRanged,
	Ranged
}

struct FTundraPlayerTreeGuardianLifeGivingEffectParams
{
	UPROPERTY()
	UTundraLifeReceivingComponent LifeReceivingComponent;

	UPROPERTY()
	ETundraPlayerTreeGuardianLifeGivingType LifeGivingType;
}
