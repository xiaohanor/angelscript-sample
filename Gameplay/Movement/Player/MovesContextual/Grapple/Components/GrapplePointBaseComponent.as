
event void FOnPlayerInitiatedGrappleToPointEventSignature(AHazePlayerCharacter Player, UGrapplePointBaseComponent TargetedGrapplePoint);
event void FOnGrappleHookReachedGrapplePointEventSignature(AHazePlayerCharacter Player, UGrapplePointBaseComponent ReachedGrapplePoint);
event void FOnPlayerFinishedGrapplingToPointEventSignature(AHazePlayerCharacter Player, UGrapplePointBaseComponent ActivatedGrapplePoint);
event void FOnPlayerInterruptedGrapplingToPointEventSignature(AHazePlayerCharacter Player, UGrapplePointBaseComponent InterruptedGrapplePoint);

UCLASS(Abstract, Meta = (EditorSpriteTexture = "/Game/Gameplay/Movement/ContextualMoves/ContextualMovesEditorTexture/GrapplePointIconBillboardGradient.GrapplePointIconBillboardGradient", EditorSpriteOffset = "X=0 Y=0 Z=65"))
class UGrapplePointBaseComponent : UContextualMovesTargetableComponent
{
	access EditAndReadOnly = private, * (editdefaults, readonly);

	default TargetableCategory = n"ContextualMoves";
	default UsableByPlayers = EHazeSelectPlayer::Both;
	default bVisualizeComponent = true;

	//Edit this to override the PoI position for the grapplePoint (Zero out to use default based on entry angle).
	UPROPERTY(EditAnywhere, Category = "Visuals", Meta = (MakeEditWidget = true))
	FVector PointOfInterestOffset;

	UPROPERTY(EditAnywhere, Category = "Visuals")
	FVector RopeAttachOffset;
	UPROPERTY(EditInstanceOnly, Category = "Visuals")
	FQuat GrappleRotation;

	UPROPERTY(Category = Settings, EditAnywhere, meta = (ClampMin="0.0"))
	float ActivationCooldown = 0.5;

	UPROPERTY(EditAnywhere)
	FSoundDefReference GrappleSoundDef;

	//What impact effect should trigger when the grapple attaches
	UPROPERTY(EditAnywhere ,Category = "Settings")
	EGrappleImpactType ImpactEffectType;

	access:EditAndReadOnly
	EGrapplePointVariations GrappleType = EGrapplePointVariations::GrapplePoint;

	UPROPERTY()
	FOnPlayerInitiatedGrappleToPointEventSignature OnPlayerInitiatedGrappleToPointEvent;

	UPROPERTY()
	FOnGrappleHookReachedGrapplePointEventSignature OnGrappleHookReachedGrapplePointEvent;

	UPROPERTY()
	FOnPlayerFinishedGrapplingToPointEventSignature OnPlayerFinishedGrapplingToPointEvent;

	UPROPERTY()
	FOnPlayerInterruptedGrapplingToPointEventSignature OnPlayerInterruptedGrapplingToPointEvent;
	
	TPerPlayer<bool> bIsPlayerGrapplingToPoint;
	TPerPlayer<float> CooldownOverAtGameTime;

	//Exclude this point from being targeted by player
	void ActivateGrapplePointForPlayer(AHazePlayerCharacter Player)
	{
		bIsPlayerGrapplingToPoint[Player] = true;
	}

	//Clear this point to allow it to be targeted by player once again
	void ClearPointForPlayer(AHazePlayerCharacter Player)
	{
		bIsPlayerGrapplingToPoint[Player] = false;
		CooldownOverAtGameTime[Player] = Time::GameTimeSeconds + ActivationCooldown;
	}
	
	bool CanTriggerGrappleEnter(AHazePlayerCharacter Player) const
	{
		return true;
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (!VerifyBaseTargetableConditions(Query))
			return false;

		if (!VerifyBaseGrappleConditions(Query))
			return false;
		
		Targetable::ApplyVisibleRange(Query, ActivationRange + AdditionalVisibleRange);
		Targetable::ScoreLookAtAim(Query);
		Targetable::ApplyTargetableRangeWithBuffer(Query, ActivationRange, ActivationBufferRange);
		Targetable::ApplyVisualProgressFromRange(Query, ActivationRange + AdditionalVisibleRange, ActivationRange, ActivationBufferRange);
		Targetable::RequireCapabilityTagNotBlocked(Query, PlayerMovementTags::Grapple);

		if (bTestCollision)
		{
			// Avoid tracing if we are already lower score than the current primary target
			if (!Query.IsCurrentScoreViableForPrimary())
				return false;
			return Targetable::RequireNotOccludedFromCamera(Query, bIgnoreOwnerCollision = bIgnorePointOwner);
		}

		return true;
	}

	bool VerifyBaseGrappleConditions(FTargetableQuery& Query) const
	{
		if(Query.Player.IsCapabilityTagBlocked(PlayerGrappleTags::GrapplePointQuery))
		{
			Query.Result.Score = 0;
			return false;
		}

		// Remove the one you are already on
		if (bIsPlayerGrapplingToPoint[Query.Player])
			return false;

		if (CooldownOverAtGameTime[Query.Player] > Time::GameTimeSeconds)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if(GrappleSoundDef.SoundDef.IsValid())
		{
			GrappleSoundDef.SpawnSoundDefAttached(Cast<AHazeActor>(GetOwner()));
		}
	}
}

enum EGrapplePointVariations
{
	GrapplePoint,
	LaunchPoint,
	SlidePoint,
	PerchPoint,
	WallrunPoint,
	WallScramblePoint,
	BashPoint,
	KiteTown_ZipPoint,
	KiteTown_SlingshotPoint,
	GrappleToPolePoint
}