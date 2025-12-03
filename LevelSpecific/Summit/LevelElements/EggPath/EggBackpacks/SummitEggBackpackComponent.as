event void FSummitEggEvent(AHazePlayerCharacter PlayerPickingUpEgg, ASummitEggHolder HolderEggWasPlacedAt);

class USummitEggBackpackComponent : UActorComponent
{
	UPROPERTY(Category = "Setup")
	TSubclassOf<ASummitEggBackpack> BackpackClass;
	UPROPERTY(Category = "Setup")
	FName AttachmentSocketName = n"Backpack";

	UPROPERTY(Category = "Settings")
	UForceFeedbackEffect EggPlacedInBackpackRumble;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams PlayerPlacingAnim;
	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams BackpackPlacingAnim;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams FastPlayerPlacingAnim;
	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams FastBackpackPlacingAnim;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams PlayerMhAnim;
	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams BackpackMhAnim;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams PlayerPickupAnim;
	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams BackpackPickupAnim;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams FastPlayerPickupAnim;
	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams FastBackpackPickupAnim;

	UPROPERTY(Category = "Animations")
	FHazePlaySlotAnimationParams BackpackUnplacedAnim;

	AHazePlayerCharacter Player;
	ASummitEggBackpack Backpack;

	UPlayerMovementComponent MoveComp;

	TOptional<ASummitEggHolder> CurrentEggHolder;

	bool bIsHoldingEgg = false;
	bool bPickupRequested = false;
	bool bPlacementRequested = false;
	bool bExternalPickupRequested = false;
	bool bResetRequested = false;
	bool bPlayerAnimUnblockRequested = false;

	void BlockPlayer()
	{
		Player.ResetMovement();

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
	}

	void UnblockPlayer()
	{	
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);

		OverrideGround();
	}

	void DetachEgg(ASummitEggHolder EggPlacementHolder)
	{
		Backpack.EggMesh.DetachFromComponent();
		Backpack.EggMesh.AttachToComponent(EggPlacementHolder.EggPlacementLocation, n"NONE", EAttachmentRule::SnapToTarget);
	}

	void AttachEgg()
	{
		Backpack.EggMesh.DetachFromComponent();
		Backpack.EggMesh.AttachToComponent(Backpack.BackpackMesh, n"Egg", EAttachmentRule::SnapToTarget);
		Backpack.EggMesh.WorldScale3D = Backpack.BackpackMesh.WorldScale;
	}

	UFUNCTION(NetFunction)
	void NetActivateHolder(ASummitEggHolder EggPlacementHolder)
	{
		EggPlacementHolder.IsHoldingEgg[Player] = true;
		EggPlacementHolder.OnEggPlaced.Broadcast();
	}

	UFUNCTION(NetFunction)
	void NetDeactivateHolder(ASummitEggHolder EggPlacementHolder)
	{
		EggPlacementHolder.IsHoldingEgg[Player] = false;
		EggPlacementHolder.OnEggRemoved.Broadcast();
	}

	void OverrideGround()
	{
		if(MoveComp == nullptr)
			MoveComp = UPlayerMovementComponent::Get(Player);

		const float TraceDownLength = 50.0;

		FHazeTraceSettings Trace;
		Trace.TraceWithPlayer(Player);
		FVector Start = Player.ActorLocation;
		FVector End = Start + (FVector::DownVector * TraceDownLength);
		auto Hit = Trace.QueryTraceSingle(Start, End);

		if(Hit.bBlockingHit)
		{
			MoveComp.OverrideGroundContact(Hit, FInstigator(this, n"OverrideGround"));
		}
	}
};