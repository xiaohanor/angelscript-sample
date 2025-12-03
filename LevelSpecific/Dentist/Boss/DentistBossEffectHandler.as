// GRABBER
struct FDentistBossEffectHandlerOnGrabberGroundPoundedParams
{
	UPROPERTY()
	FVector GroundPoundLocation;
	UPROPERTY()
	float HealthAfterGroundPound;
}

struct FDentistBossEffectHandlerOnGrabberDestroyedParams
{
	UPROPERTY()
	FVector ExplosionLocation;

	UPROPERTY()
	FVector UpperArmLocation;

	UPROPERTY()
	FRotator ArmExplodeRotation;

	UPROPERTY()
	USceneComponent SparkAttachRoot;

	UPROPERTY()
	FName SparkAttachSocketName;
}


// DRILL
struct FDentistBossEffectHandlerOnDrillHitStartedParams
{
	UPROPERTY()
	USceneComponent PlayerRoot;

	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	FVector DrillHitRelativeLocation;
}

struct FDentistBossEffectHandlerOnDrillStoppedParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FDentistBossEffectHandlerOnDrillSplitToothParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FDentistBossEffectHandlerOnSwitchedDrillTelegraphParams
{
	UPROPERTY()
	AHazePlayerCharacter NewPlayer;
}

struct FDentistBossEffectHandlerOnDrillStartedSpinningArenaParams
{
	UPROPERTY()
	FVector DrillHitLocation;
}

struct FDentistBossEffectHandlerOnDrillStoppedSpinningArenaParams
{
	UPROPERTY()
	FVector DrillHitLocation;
}

struct FDentistBossEffectHandlerOnSelfDrillHitTeethParams
{
	UPROPERTY()
	USceneComponent HitRoot;
}

struct FDentistBossEffectHandlerOnSelfDrillStartedParams
{
	UPROPERTY()
	USceneComponent HitRoot;
}

struct FDentistBossEffectHandlerOnSelfDrillCompleteParams
{
	UPROPERTY()
	USceneComponent HitRoot;
}


// DENTURES
struct FDentistBossEffectHandlerOnDenturesGroundPoundedParams
{
	UPROPERTY()
	FVector HitLocation;

	UPROPERTY()
	FVector HitNormal;
}

struct FDentistBossEffectHandlerOnDenturesKilledByGroundPoundParams
{
	UPROPERTY()
	FVector WindupScrewLocation;

	UPROPERTY()
	FRotator WindupScrewRotation;
}

struct FDentistBossEffectHandlerOnDenturesDestroyedWithGrabberParams
{
	UPROPERTY()
	ADentistBossToolDentures Dentures;
}

struct FDentistBossEffectHandlerOnDenturesBeingRiddenByPlayerParams
{
	UPROPERTY()
	ADentistBossToolDentures Dentures;

	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FDentistBossEffectHandlerOnDenturesWindupScrewSpawnStartParams
{
	UPROPERTY()
	USceneComponent ScrewRoot;
}

struct FDentistBossEffectHandlerOnDenturesWindupScrewSpawnStoppedParams
{
	UPROPERTY()
	USceneComponent ScrewRoot;
}

struct FDentistBossEffectHandlerOnDenturesWindupScrewDespawnStartParams
{
	UPROPERTY()
	USceneComponent ScrewRoot;
}

struct FDentistBossEffectHandlerOnDenturesWindupScrewDespawnStoppedParams
{
	UPROPERTY()
	USceneComponent ScrewRoot;
}

struct FDentistBossEffectHandlerOnDenturesReleasedParams
{
	UPROPERTY()
	ADentistBossToolDentures Dentures;
}

struct FDentistBossEffectHandlerOnDenturesLandedParams
{
	UPROPERTY()
	ADentistBossToolDentures Dentures;
}

struct FDentistBossEffectHandlerOnDenturesBiteParams
{
	UPROPERTY()
	ADentistBossToolDentures Dentures;

	UPROPERTY()
	USceneComponent BiteRoot;
}

struct FDentistBossEffectHandlerOnDenturesFreeJumpParams
{
	UPROPERTY()
	ADentistBossToolDentures Dentures;
}

struct FDentistBossEffectHandlerOnDenturesRiddenJumpParams
{
	UPROPERTY()
	ADentistBossToolDentures Dentures;

	UPROPERTY()
	AHazePlayerCharacter RidingPlayer;
}

struct FDentistBossEffectHandlerOnDenturesFlipParams
{
	UPROPERTY()
	ADentistBossToolDentures Dentures;
}

struct FDentistBossEffectHandlerOnDenturesBitePushPlayerParams
{
	UPROPERTY()
	ADentistBossToolDentures Dentures;

	UPROPERTY()
	AHazePlayerCharacter PushedPlayer;
}


// CHAIR
struct FDentistBossEffectHandlerOnChairDestroyedByDrillParams
{
	UPROPERTY()
	ADentistBossToolChair Chair;
}

struct FDentistBossEffectHandlerOnChairDestroyedByEscapingParams
{
	UPROPERTY()
	ADentistBossToolChair Chair;
}


// TOOTH BRUSH
struct FDentistBossEffectHandlerOnToothBrushStartedBrushingParams
{
	UPROPERTY()
	USceneComponent BrushEffectRoot;
}

struct FDentistBossEffectHandlerOnToothBrushHitToothPasteParams
{
	UPROPERTY()
	FVector ToothPasteLocation;
}

struct FDentistBossEffectHandlerOnToothBrushHitPlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

// TOOTH PASTE
struct FDentistBossEffectHandlerOnToothPasteShotParams
{
	UPROPERTY()
	USceneComponent ToothPasteMuzzle;
}

struct FDentistBossEffectHandlerOnToothPasteLandedParams
{
	UPROPERTY()
	FVector LandLocation;
}


// SCRAPER
struct FDentistBossEffectHandlerOnScraperHookedPlayerParams
{
	UPROPERTY()
	FVector HookTipLocation;

	UPROPERTY()
	FRotator HookTipRotation;

	UPROPERTY()
	AHazePlayerCharacter HookedPlayer;
}


// HAMMER
struct FDentistBossEffectHandlerOnHammerHitScraperParams
{
	UPROPERTY()
	FVector HookTipLocation;

	UPROPERTY()
	FRotator HookTipRotation;

	UPROPERTY()
	FVector HammerHitLocation;

	UPROPERTY()
	AHazePlayerCharacter HookedPlayer;
}

struct FDentistBossEffectHandlerOnHammerSplitPlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}


// CUP
struct FDentistBossEffectHandlerOnPlayerCaughtByCupParams
{
	UPROPERTY()
	AHazePlayerCharacter PlayerCaughtByCup;
}

struct FDentistBossEffectHandlerOnCupMovementStoppedParams
{
	UPROPERTY()
	AHazePlayerCharacter PlayerCaughtByCup;
}

struct FDentistBossEffectHandlerOnCupBecomeFlattenedParams
{
	UPROPERTY()
	ADentistBossToolCup Cup;

	UPROPERTY()
	bool bPlayerIsInCup = false;
}

struct FDentistBossEffectHandlerOnCupDisappearAfterBecomingFlattenedParams
{
	UPROPERTY()
	ADentistBossToolCup Cup;

	UPROPERTY()
	bool bPlayerIsInCup = false;
}

struct FDentistBossEffectHandlerOnCupPlacedOnCakeParams
{
	UPROPERTY()
	ADentistBossToolCup Cup;

	UPROPERTY()
	bool bPlayerIsInCup = false;
}

struct FDentistBossEffectHandlerOnCupSwitchPlaceParams
{
	UPROPERTY()
	EDentistBossToolCupSortType SortType;
	UPROPERTY()
	ADentistBossToolCup LeftmostCup;
	UPROPERTY()
	bool bPlayerIsInLeftmostCup = false;
	UPROPERTY()
	ADentistBossToolCup RightmostCup;
	UPROPERTY()
	bool bPlayerIsInRightmostCup = false;
}

struct FDentistBossEffectHandlerOnCupChosenByDashingPlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter DashingPlayer;

	UPROPERTY()
	ADentistBossToolCup Cup;

	UPROPERTY()
	bool bPlayerIsInCup = false;
}

// STATE
struct FDentistBossEffectHandlerOnSwitchedStateParams
{
	UPROPERTY()
	EDentistBossState NewState;
}

// WIGGLE
struct FDentistBossEffectHandlerOnPlayerWiggleStickMaxReachedParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	bool bWiggledLeft = false;
}

struct FDentistBossEffectHandlerOnPlayerWiggleStickParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

// SPLIT TOOTH
struct FDentistBossEffectHandlerOnPlayerToothSplitParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	ADentistSplitToothAI SplitToothAI;
}

struct FDentistBossEffectHandlerOnPlayerSwatAwayParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}


UCLASS(Abstract)
class UDentistBossEffectHandler : UHazeEffectEventHandler
{
	// GRABBER
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrabberGroundPounded(FDentistBossEffectHandlerOnGrabberGroundPoundedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrabberDestroyed(FDentistBossEffectHandlerOnGrabberDestroyedParams Params) {}


	// DRILL
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDrillHitStarted(FDentistBossEffectHandlerOnDrillHitStartedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDrillSplitTooth(FDentistBossEffectHandlerOnDrillSplitToothParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDrillHitStopped(FDentistBossEffectHandlerOnDrillStoppedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwitchedDrillTelegraph(FDentistBossEffectHandlerOnSwitchedDrillTelegraphParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDrillStartedSpinningArena(FDentistBossEffectHandlerOnDrillStartedSpinningArenaParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDrillStoppedSpinningArena(FDentistBossEffectHandlerOnDrillStoppedSpinningArenaParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSelfDrillStarted(FDentistBossEffectHandlerOnSelfDrillStartedParams Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSelfDrillHitTeeth(FDentistBossEffectHandlerOnSelfDrillHitTeethParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSelfDrillComplete(FDentistBossEffectHandlerOnSelfDrillCompleteParams Params) {}


	// DENTURES
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesAboutToBeReleased() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesReleased(FDentistBossEffectHandlerOnDenturesReleasedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesLanded(FDentistBossEffectHandlerOnDenturesLandedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesGroundPounded(FDentistBossEffectHandlerOnDenturesGroundPoundedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesKilledByGroundPound(FDentistBossEffectHandlerOnDenturesKilledByGroundPoundParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesDestroyedWithGrabber(FDentistBossEffectHandlerOnDenturesDestroyedWithGrabberParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesBeingRiddenByPlayer(FDentistBossEffectHandlerOnDenturesBeingRiddenByPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesStartedBitingGrabber() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesScrewStartSpawning(FDentistBossEffectHandlerOnDenturesWindupScrewSpawnStartParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesScrewStoppedSpawning(FDentistBossEffectHandlerOnDenturesWindupScrewSpawnStoppedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesScrewStartedDespawning(FDentistBossEffectHandlerOnDenturesWindupScrewDespawnStartParams Params) {} // todo(ylva)

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesScrewStoppedDespawning(FDentistBossEffectHandlerOnDenturesWindupScrewDespawnStoppedParams Params) {} // todo(ylva)

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesBite(FDentistBossEffectHandlerOnDenturesBiteParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesFreeJumpStart(FDentistBossEffectHandlerOnDenturesFreeJumpParams Params) {} 

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesFreeJumpLand(FDentistBossEffectHandlerOnDenturesFreeJumpParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesFreeJumpedOffCake(FDentistBossEffectHandlerOnDenturesFreeJumpParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesRiddenJumpStart(FDentistBossEffectHandlerOnDenturesRiddenJumpParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesRiddenJumpLand(FDentistBossEffectHandlerOnDenturesRiddenJumpParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesFlipJumpStart(FDentistBossEffectHandlerOnDenturesFlipParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesFlipOver(FDentistBossEffectHandlerOnDenturesFlipParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesFlipBack(FDentistBossEffectHandlerOnDenturesFlipParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDenturesPushBitePlayer(FDentistBossEffectHandlerOnDenturesBitePushPlayerParams Params) {} 

	// CHAIR
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChairDestroyedByDrill(FDentistBossEffectHandlerOnChairDestroyedByDrillParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChairDestroyedByEscaping(FDentistBossEffectHandlerOnChairDestroyedByEscapingParams Params) {}


	// TOOTH BRUSH
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnToothBrushStartedBrushing(FDentistBossEffectHandlerOnToothBrushStartedBrushingParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnToothBrushStoppedBrushing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnToothBrushHitToothPaste(FDentistBossEffectHandlerOnToothBrushHitToothPasteParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnToothBrushHitPlayer(FDentistBossEffectHandlerOnToothBrushHitPlayerParams Params) {}

	// TOOTH PASTE
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnToothPasteShot(FDentistBossEffectHandlerOnToothPasteShotParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnToothPasteLanded(FDentistBossEffectHandlerOnToothPasteLandedParams Params) {}


	// SCRAPER
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnScraperHookedPlayer(FDentistBossEffectHandlerOnScraperHookedPlayerParams Params) {}


	// HAMMER
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHammerHitScraper(FDentistBossEffectHandlerOnHammerHitScraperParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHammerSplitPlayer(FDentistBossEffectHandlerOnHammerSplitPlayerParams Params) {}


	// CUP
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerCaughtInCup(FDentistBossEffectHandlerOnPlayerCaughtByCupParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCupPlacedOnCake(FDentistBossEffectHandlerOnCupPlacedOnCakeParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCupSwitchedPlaceStart(FDentistBossEffectHandlerOnCupSwitchPlaceParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCupSwitchedPlaceStop(FDentistBossEffectHandlerOnCupSwitchPlaceParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCupMovementStoppedParams(FDentistBossEffectHandlerOnCupMovementStoppedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCupBecomeFlattenedParams(FDentistBossEffectHandlerOnCupBecomeFlattenedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCupDisappearAfterBecomingFlattenedParams(FDentistBossEffectHandlerOnCupDisappearAfterBecomingFlattenedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCupChosenByDashingPlayer(FDentistBossEffectHandlerOnCupChosenByDashingPlayerParams Params) {}


	// STATE
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwitchedState(FDentistBossEffectHandlerOnSwitchedStateParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDentistChaseStarted() {}

	// WIGGLE
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerWiggleStickStarted(FDentistBossEffectHandlerOnPlayerWiggleStickParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerWiggleStickMaxReached(FDentistBossEffectHandlerOnPlayerWiggleStickMaxReachedParams Params) {}
	
	// SPLIT TOOTH
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerToothSplit(FDentistBossEffectHandlerOnPlayerToothSplitParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerToothReunited(FDentistBossEffectHandlerOnPlayerToothSplitParams Params) {}

	// SWAT
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerSwatAway(FDentistBossEffectHandlerOnPlayerSwatAwayParams Params) {}
};