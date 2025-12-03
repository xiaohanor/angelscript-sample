
event void FOnPlayerAttachedToLadder(AHazePlayerCharacter Player, ALadder LadderActor, ELadderEnterEventStates EnterState);
event void FOnPlayerDetachedLadder(AHazePlayerCharacter Player, ALadder LadderActor, ELadderExitEventStates ExitState);

enum ELadderType
{
	Default,
	BottomSegmented,
	TopSegmented
}

UCLASS(Abstract)
class ALadder : AHazeActor
{
	access readonly = private, * (readonly);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	ULadderEnterZone EnterZone;
	default EnterZone.Shape = FHazeShapeSettings::MakeBox(FVector::ZeroVector);
	default EnterZone.bAlwaysShowShapeInEditor = false;

	UPROPERTY(DefaultComponent)
	ULadderEnterZone TopEnterZone;
	default TopEnterZone.Shape = FHazeShapeSettings::MakeBox(FVector::ZeroVector);
	default TopEnterZone.bAlwaysShowShapeInEditor = false;	
	default TopEnterZone.bIsTopEnterZone = true;

	UPROPERTY(DefaultComponent)
	UOneShotInteractionComponent Interact;
	default Interact.MovementSettings = FMoveToParams::NoMovement();

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Meshes")
	UStaticMesh BottomMesh;
	UPROPERTY(EditAnywhere, Category = "Settings|Meshes")
	UStaticMesh MiddleMesh;
	UPROPERTY(EditAnywhere, Category = "Settings|Meshes")
	UStaticMesh TopMesh;

	UPROPERTY(EditAnywhere, Category = "Settings|Meshes")
	TArray<FLadderDetailMeshes> DetailMeshes;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UHazeCameraSettingsDataAsset CameraSetting;

	//Multiplier for the base calculated culling distances for the ladder meshes
	UPROPERTY(EditInstanceOnly, Category = "Settings|Meshes")
	float MaxCullingDistMultiplier = 3.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int Segments = 6;
	int MinSegments = 4;

	/* Whether to disable the Ladder by default when it enters play. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Settings", Meta = (InlineEditConditionToggle))
	bool bStartDisabled = false;

	/* Instigator to disable with if the Ladder enters play disabled. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Settings", Meta = (EditCondition = "bStartDisabled"))
	FName StartDisabledInstigator = n"StartDisabled";

	TInstigated<bool> Disablers;
	default Disablers.SetDefaultValue(false);

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Settings")
	access:readonly
	EHazeSelectPlayer UsableByPlayers;
	default UsableByPlayers = EHazeSelectPlayer::Both;

	//Stop the player from being able to exit the top of the ladder
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bBlockClimbingOutTop = false;

	//Stop the player from being able to exit at bottom
	UPROPERTY(EditInstanceOnly, Category = "Settings")
	bool bBlockBottomExit = false;

	//  If enabled you permanently remove the ability to enter the ladder from the top
	UPROPERTY(EditInstanceOnly, Category = "Settings")
	bool bDisableEnterFromTop = false;

	// If true we enter from top via entering trigger zone rather then interacting
	UPROPERTY(EditInstanceOnly, Category = "Settings")
	bool bEnterTopViaZone = true;

	FVector BottomRung_RelativePosition = FVector(-30.0, 0.0, 50.0);
	float RungSpacing = 50.0;

	UPROPERTY()
	UStaticMeshComponent TopMeshComp;

	UPROPERTY()
	FOnPlayerAttachedToLadder PlayerAttachedToLadderEvent;
	UPROPERTY()
	FOnPlayerDetachedLadder PlayerExitedLadderEvent;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "false"))
	bool bHasDecidedMobility = false;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	ELadderType LadderType;

	UPROPERTY(EditInstanceOnly, Category = "Settings", Meta = (EditCondition = "LadderType != ELadderType::Default", EditConditionHides))
	bool bAllowTransfer = false;

	UPROPERTY(EditInstanceOnly, Category = "Settings", Meta = (EditCondition = "LadderType != ELadderType::Default", EditConditionHides))
	ALadder LinkedLadder;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorPlacedInEditor()
	{
		RootComp.Mobility = EComponentMobility::Static;
		bHasDecidedMobility = true;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Interact.UsableByPlayers = UsableByPlayers;

		// Make the ladder static if it's not attached to anything
		if (!bHasDecidedMobility)
		{
			if (RootComp.AttachParent == nullptr)
				RootComp.Mobility = EComponentMobility::Static;
			bHasDecidedMobility = true;
		}

		if(LadderType == ELadderType::Default)
			LinkedLadder = nullptr;

		//Make sure we have min amount of pieces
		if (Segments < MinSegments)
			Segments = MinSegments;

		//Set size and location for activation shape
		EnterZone.Shape = FHazeShapeSettings::MakeBox(FVector(50.0, 40.0, 25 * Segments));
		EnterZone.RelativeLocation = FVector(-40.0, 0.0, 25 * (Segments + 1));

		TopEnterZone.Shape = FHazeShapeSettings::MakeBox(FVector(40.0 , 40.0, 75.0));
		TopEnterZone.RelativeLocation = FVector(40, 0, 50 * (Segments + 1) + 75);

		//Place interact comp in correct location
		Interact.RelativeLocation = FVector(80.0, 0.0, 50.0 * (Segments + 1));
		Interact.RelativeRotation = FRotator(0, 180.0, 0.0);

		//Based on the value calculated by Editor::GetDefaultCullingDistance for Bottom piece mesh
		//Some ladders wont generate a bottom piece but still want similar culling distance so hard code it here instead
		float BaseCullDistance = 3750;

		//Add bottom piece
		UStaticMeshComponent BottomPiece = UStaticMeshComponent::Create(this, n"LadderMeshBottom");
		BottomPiece.SetStaticMesh(BottomMesh);
		BottomPiece.CollisionEnabled = ECollisionEnabled::QueryOnly;
		BottomPiece.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
		BottomPiece.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
		BottomPiece.SetRelativeLocation(FVector(0.0, 0.0, 0.0));

		BottomPiece.LDMaxDrawDistance = BaseCullDistance * MaxCullingDistMultiplier;

		if (RootComp.Mobility == EComponentMobility::Static)
			BottomPiece.Mobility = EComponentMobility::Static;

		//Add middle pieces and enter points
		for (int i = 0 ; i < Segments ; i++)
		{
			FString PieceName = "LadderPiece" + (i + 1);
			UStaticMeshComponent LadderPiece = UStaticMeshComponent::Create(this, FName(PieceName));
			LadderPiece.SetStaticMesh(MiddleMesh);
			LadderPiece.CollisionEnabled = ECollisionEnabled::QueryOnly;
			LadderPiece.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
			LadderPiece.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
			LadderPiece.SetRelativeLocation(FVector(0.0, 0.0, 50.0 * (i + 1)));

			LadderPiece.LDMaxDrawDistance = BaseCullDistance * MaxCullingDistMultiplier;

			if (RootComp.Mobility == EComponentMobility::Static)
				LadderPiece.Mobility = EComponentMobility::Static;
		}

		//Add top piece
		UStaticMeshComponent TopPiece = UStaticMeshComponent::Create(this, n"LadderMeshTop");
		TopPiece.SetStaticMesh(TopMesh);
		TopPiece.CollisionEnabled = ECollisionEnabled::QueryOnly;
		TopPiece.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
		TopPiece.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
		TopPiece.LDMaxDrawDistance = BaseCullDistance * MaxCullingDistMultiplier;

		TopPiece.SetRelativeLocation(FVector(0.0, 0.0, 50.0 * (Segments + 1)));

		if (RootComp.Mobility == EComponentMobility::Static)
			TopPiece.Mobility = EComponentMobility::Static;

		//Add Detail Meshes
		if (DetailMeshes.Num() == 0)
			return;
		
		for (int i = 0; i < DetailMeshes.Num(); i++)
		{
			if(DetailMeshes[i].Segments == 0 || DetailMeshes[i].Mesh == nullptr)
				return;
			
			int PaddingInterval = DetailMeshes[i].PaddingInterval;
			int InitialSegmentOffset = 0;
			int MeshNumber = 0;

			for(int n = 0; n < DetailMeshes[i].Segments + (DetailMeshes[i].PaddingInterval * DetailMeshes[i].Segments) + DetailMeshes[i].BottomPieceOffset; n++)
			{
				//Skip x amount of segment steps from bottom
				if(InitialSegmentOffset < DetailMeshes[i].BottomPieceOffset)
				{
					InitialSegmentOffset++;
					continue;
				}

				//Skip x amount of segment steps in intervals between meshes
				if(PaddingInterval < DetailMeshes[i].PaddingInterval)
				{
					PaddingInterval++;
					continue;
				}

				FString PieceName = "DetailPiece" + (i + 1) + " - " + (MeshNumber + 1);
				UStaticMeshComponent DetailPiece = UStaticMeshComponent::Create(this, FName(PieceName));

				DetailPiece.SetStaticMesh(DetailMeshes[i].Mesh);
				DetailPiece.CollisionEnabled = ECollisionEnabled::NoCollision;
				DetailPiece.SetRelativeLocation(FVector(DetailMeshes[i].RelativeOffset.X, DetailMeshes[i].RelativeOffset.Y, DetailMeshes[i].RelativeOffset.Z + (DetailMeshes[i].bOverrideDefaultSegmentHeight? DetailMeshes[i].NewSegmentHeight : 50.0) * (n + 1)));

				//Update drawdistance to match the rest of the ladder pieces
				DetailPiece.LDMaxDrawDistance = BaseCullDistance * MaxCullingDistMultiplier;

				if (RootComp.Mobility == EComponentMobility::Static)
					DetailPiece.Mobility = EComponentMobility::Static;

				PaddingInterval = 0;	
				MeshNumber++;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Interact.OnInteractionStarted.AddUFunction(this, n"StartedInteract");
		if(bStartDisabled)
		{
			Disable(StartDisabledInstigator);
		}

		if(bDisableEnterFromTop)
		{
			Interact.Disable(n"DisabledByUser");
			TopEnterZone.DisableTrigger(n"DisabledByUser");
		}
		else
		{
			if(bEnterTopViaZone)
			{
				Interact.Disable(n"UsingEnterZone");
			}
			else
			{
				TopEnterZone.DisableTrigger(n"UsingInteract");
			}
		}
	}

	UFUNCTION()
	void StartedInteract(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		auto LadderComp = UPlayerLadderComponent::Get(Player);

		if(!TestRungForValidCollision(GetTopRung(), Player))
			return;

		if(LadderComp == nullptr)
			return;

		LadderComp.Data.EnterFromTopLadder = this;
		LadderComp.Data.EnterFromTopTriggeredFrame = Time::GetFrameNumber();
	}

	int GetRungCount() const property
	{
		return Segments - 1;
	}

	FLadderRung GetBottomRung() const
	{
		if (RungCount == 0)
			return FLadderRung();

		FLadderRung Rung;
		Rung.RungIndex = 0; 
		return Rung;
	}

	FLadderRung GetTopRung() const
	{
		if (RungCount == 0)
			return FLadderRung();

		FLadderRung Rung;
		Rung.RungIndex = RungCount - 1; 
		return Rung;
	}

	FVector GetRungWorldLocation(FLadderRung Rung) const
	{
		return ActorTransform.TransformPosition(
			BottomRung_RelativePosition + FVector(0, 0, RungSpacing * Rung.RungIndex)
		);
	}

	FVector GetRungRelativeLocation(FLadderRung Rung) const
	{
		return BottomRung_RelativePosition + FVector(0, 0, RungSpacing * Rung.RungIndex);
	}

	FLadderRung GetClosestRungToWorldLocation(FVector WorldLocation) const
	{
		float ClosestDistance = MAX_flt;
		int ClosestIndex = -1;

		FTransform LadderTransform = GetActorTransform();

		for (int i = 0; i < RungCount; ++i)
		{
			FVector RungLocation = LadderTransform.TransformPosition(
				BottomRung_RelativePosition + FVector(0, 0, RungSpacing * i)
			);

			FVector Delta = RungLocation - WorldLocation;
			float HeightDelta = ActorUpVector.DotProduct(Delta);

			float Distance = Math::Abs(HeightDelta);
			if (Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestIndex = i;
			}
		}

		FLadderRung Rung;
		Rung.RungIndex = ClosestIndex; 
		return Rung;
	}

	FLadderRung GetClosestRungBelowWorldLocation(FVector WorldLocation) const
	{
		float ClosestDistance = MAX_flt;
		int ClosestIndex = -1;

		FTransform LadderTransform = GetActorTransform();

		for (int i = 0; i < RungCount; ++i)
		{
			FVector RungLocation = LadderTransform.TransformPosition(
				BottomRung_RelativePosition + FVector(0, 0, RungSpacing * i)
			);

			FVector Delta = RungLocation - WorldLocation;
			float HeightDelta = ActorUpVector.DotProduct(Delta);
			if (HeightDelta > -1.0)
				continue;

			float Distance = Math::Abs(HeightDelta);
			if (Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestIndex = i;
			}
		}

		FLadderRung Rung;
		Rung.RungIndex = ClosestIndex; 
		return Rung;
	}

	FLadderRung GetClosestRungAboveWorldLocation(FVector WorldLocation) const
	{
		float ClosestDistance = MAX_flt;
		int ClosestIndex = -1;

		FTransform LadderTransform = GetActorTransform();

		for (int i = 0; i < RungCount; ++i)
		{
			FVector RungLocation = LadderTransform.TransformPosition(
				BottomRung_RelativePosition + FVector(0, 0, RungSpacing * i)
			);

			FVector Delta = RungLocation - WorldLocation;
			float HeightDelta = ActorUpVector.DotProduct(Delta);
			if (HeightDelta < 1.0)
				continue;

			float Distance = Math::Abs(HeightDelta);
			if (Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestIndex = i;
			}
		}

		FLadderRung Rung;
		Rung.RungIndex = ClosestIndex; 
		return Rung;
	}

	FLadderRung GetRungBelow(FLadderRung Rung) const
	{
		if (Rung.RungIndex <= 0)
			return FLadderRung();

		FLadderRung RungBelow;
		RungBelow.RungIndex = Rung.RungIndex - 1; 
		return RungBelow;
	}

	FLadderRung GetRungAbove(FLadderRung Rung) const
	{
		if (Rung.RungIndex >= RungCount - 1)
			return FLadderRung();

		FLadderRung RungBelow;
		RungBelow.RungIndex = Rung.RungIndex + 1; 
		return RungBelow;
	}

	bool TestRungForValidCollision(FLadderRung Rung, AHazePlayerCharacter Player, bool bDebug = false) const
	{
		FHazeTraceSettings CollisionTraceSettings = Trace::InitFromPlayer(Player);

		if(bDebug)
			CollisionTraceSettings.DebugDraw(1);

		CollisionTraceSettings.UseSphereShape(Player.GetScaledCapsuleRadius());
		CollisionTraceSettings.UseShapeWorldOffset(FVector::ZeroVector);

		if(Rung.RungIndex == GetClosestRungToWorldLocation(Player.ActorLocation).RungIndex)
		{
			//We are just Checking collision for entering on a specific rung
			FVector TraceStart = GetRungWorldLocation(GetClosestRungToWorldLocation(Player.ActorLocation)) + (ActorUpVector * (Player.GetScaledCapsuleRadius()));
			FVector TraceEnd = TraceStart + (ActorUpVector * (Player.GetScaledCapsuleHalfHeight() + (Player.GetScaledCapsuleRadius() / 2)));			
		
			FHitResult CollisionTestHit = CollisionTraceSettings.QueryTraceSingle(TraceStart, TraceEnd);

			if(CollisionTestHit.bStartPenetrating)
				return false;

			if(CollisionTestHit.bBlockingHit)
				return false;
		}
		else
		{
			//We are checking collision between our current and our target location
			FVector TraceStart;
			FVector TraceEnd;

			if((GetRungWorldLocation(Rung) - Player.ActorLocation).DotProduct(ActorUpVector) > 0)
			{
				//Trace from our current capsule plant to projected capsule top at target rung
				TraceStart = GetRungWorldLocation(GetClosestRungToWorldLocation(Player.ActorLocation)) + (ActorUpVector * (Player.GetScaledCapsuleRadius()));
				TraceEnd = GetRungWorldLocation(Rung) + (ActorUpVector * ((Player.ScaledCapsuleHalfHeight * 1.25) + Player.GetScaledCapsuleRadius()));
			}
			else
			{
				//Trace from our capsule top position down to our projected foot plant at target rung
				TraceStart = Player.ActorLocation + (ActorUpVector * (Player.GetScaledCapsuleHalfHeight() * 2  - Player.GetScaledCapsuleRadius()));
				TraceEnd = GetRungWorldLocation(Rung) + (ActorUpVector * Player.GetScaledCapsuleRadius());
			}

			FHitResult CollisionTestHit = CollisionTraceSettings.QueryTraceSingle(TraceStart, TraceEnd);

			if(CollisionTestHit.bStartPenetrating)
				return false;

			if(CollisionTestHit.bBlockingHit)
				return false;
		}

		return true;
	}

	UFUNCTION(Category = "Ladder")
	void EnableAfterStartDisabled()
	{
		if(bStartDisabled)
			Enable(StartDisabledInstigator);
	}

	UFUNCTION(Category = "Ladder")
	void Enable(FInstigator Disabler)
	{
		Disablers.Clear(Disabler);
		UpdateEnabledState();
	}

	UFUNCTION(Category = "Ladder")
	void Disable(FInstigator Disabler)
	{
		Disablers.Apply(true, Disabler);
		UpdateEnabledState();
	}

	UFUNCTION(Category = "Ladder")
	bool IsDisabled() const
	{
		return Disablers.Get();
	}

	void UpdateEnabledState()
	{
		if(Disablers.IsDefaultValue())
		{
			EnterZone.EnableTrigger(this);
			Interact.Enable(this);
		}
		else
		{
			EnterZone.DisableTrigger(this);
			Interact.Disable(this);
		}
	}

	//Will set UsableByPlayers on Ladder and Interact
	UFUNCTION()
	void SetLadderUsableByPlayers(EHazeSelectPlayer Players)
	{
		UsableByPlayers = Players;
		Interact.SetUsableByPlayers(Players);
	}
}

class ULadderEnterZone : UHazeMovablePlayerTriggerComponent
{
	default Shape = FHazeShapeSettings::MakeSphere(100.0);

	bool bIsTopEnterZone = false;

	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter Player)
	{
		auto LadderComp = UPlayerLadderComponent::Get(Player);
		if(LadderComp == nullptr)
			return;

		ALadder Ladder = Cast<ALadder>(Owner);

		if(bIsTopEnterZone)
			LadderComp.Data.QueryTopEnterLadders.RemoveSwap(Ladder);
		else
		{
			for (int i = 0; i < LadderComp.Data.QueryLadderData.Num(); i++)
			{
				if(LadderComp.Data.QueryLadderData[i].Ladder == Ladder)
				{
					LadderComp.Data.QueryLadderData.RemoveAtSwap(i);
					return;
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		auto LadderComp = UPlayerLadderComponent::Get(Player);
		if(LadderComp == nullptr)
			return;

		ALadder Ladder = Cast<ALadder>(Owner);

		if(Ladder.IsDisabled())
			return;

		if (!Player.IsSelectedBy(Ladder.UsableByPlayers))
			return;
		
		if(bIsTopEnterZone)
			LadderComp.Data.QueryTopEnterLadders.AddUnique(Ladder);
		else
		{
			for (int i = 0; i < LadderComp.Data.QueryLadderData.Num(); i++)
			{
				if(LadderComp.Data.QueryLadderData[i].Ladder == Ladder)
				{
					return;
				}
			}

			FQueryLadderData LadderData;
			LadderData.Ladder = Ladder;

			LadderComp.Data.QueryLadderData.AddUnique(LadderData);
		}
	}
}

struct FLadderDetailMeshes
{	
	UPROPERTY(EditAnywhere, Category = "Settings")
	UStaticMesh Mesh;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int Segments = 0;

	//Skip this many segments between pieces
	UPROPERTY(EditAnywhere, Category = "Settings", meta = (ClampMin = "0.0", UIMin = "0.0"))
	int PaddingInterval = 0;

	//How many segments should we skip for bottom piece
	UPROPERTY(EditAnywhere, Category = "Settings", meta = (ClampMin = "0.0", UIMin = "0.0"))
	int BottomPieceOffset = 0;

	//Offset for each mesh
	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector RelativeOffset;

	//If you want to define your own Step Height (interval delta for segments)
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bOverrideDefaultSegmentHeight = false;

	UPROPERTY(EditAnywhere, Category = "Settings", meta = (EditCondition = "bOverrideDefaultSegmentHeight", EditConditionHides, ClampMin = "0.0", UIMin = "0.0"))
	float NewSegmentHeight = 50.0;
}

enum ELadderEnterEventStates
{
	EnterFromBottom,
	EnterFromTop,
	MidAir,
	WallRun
}

enum ELadderExitEventStates
{
	ExitOnBottom,
	ExitOnTop,
	Cancel,
	JumpOut
}

struct FLadderRung
{
	UPROPERTY()
	int RungIndex = -1;

	bool IsValid() const
	{
		return RungIndex != -1;
	}

	void Clear()
	{
		RungIndex = -1;
	}

	bool opEquals(FLadderRung Other) const
	{
		return RungIndex == Other.RungIndex;
	}
}