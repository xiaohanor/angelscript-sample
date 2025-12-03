asset CongaLineMonkeySheet of UHazeCapabilitySheet
{
	AddCapability(n"CongaLineMonkeyCompoundCapability");
	AddCapability(n"CongaLineMonkeyDisperseCapability");
	AddCapability(n"CongaLineMonkeyDanceCapability");
	AddCapability(n"CongaLineMonkeyIdleCapability");
	AddCapability(n"CongaLineMonkeyStartFollowingCapability");
};

// class UCongaLineMonkeyTargetableComponent : UTargetableComponent
// {
// 	default TargetableCategory = ActionNames::Interaction;
// 	UCongaLineDancerComponent DancerComp;

// 	UFUNCTION(BlueprintOverride)
// 	void BeginPlay()
// 	{
// 		Super::BeginPlay();
// 		DancerComp = Cast<ACongaLineMonkey>(Owner).DancerComp;
// 	}

// 	bool CheckTargetable(FTargetableQuery& Query) const override
// 	{
// 		if(Cast<ACongaLineMonkey>(Owner).DancerComp.CurrentState != ECongaLineDancerState::Idle)
// 			return false;

// 		auto StrikePoseComp = UCongaLineStrikePoseComponent::Get(Query.Player);
// 		if(StrikePoseComp != nullptr)
// 		{
// 			if(!StrikePoseComp.CanPose())
// 				return false;
// 		}

// 		Targetable::ApplyVisibleRange(Query,  CongaLine::StartEnteringCongaLineRange);
// 		Targetable::ApplyTargetableRange(Query, CongaLine::StartEnteringCongaLineRange);
// 		return true;
// 	}
// }


enum EMonkeyColorCode
{
	Mio,
	Zoe
}

UCLASS(Abstract)
class ACongaLineMonkey : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCharacterSkeletalMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(CongaLineMonkeySheet);

	UPROPERTY(DefaultComponent)
	UCongaLineDancerComponent DancerComp;
	
	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly;
	default SyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::Standard;

	UPROPERTY(EditDefaultsOnly)
	USkeletalMesh MioMonkey;

	UPROPERTY(EditDefaultsOnly)
	USkeletalMesh ZoeMonkey;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;

	UPROPERTY(EditAnywhere)
	EMonkeyColorCode ColorCode;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UHazeAudioEvent PlayerInRangeEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	FHazeAudioFireForgetEventParams EventParams;

	private bool bLeaderPlayerWasInRange = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		devCheck(CongaLine::GetManager() != nullptr, "Using a CongaLine monkey, but there is no CongaLineManager in the level!");
		CongaLine::GetManager().AddMonkey(this);
		CongaLine::GetManager().OnCongaStartedEvent.AddUFunction(this, n"SetupLeader");

		if(ColorCode == EMonkeyColorCode::Mio)
		{
			MeshComp.SetSkeletalMeshAsset(MioMonkey);
			SetActorControlSide(Game::Mio);
		}
		else
		{
			MeshComp.SetSkeletalMeshAsset(ZoeMonkey);
			SetActorControlSide(Game::Zoe);
		}

		SetActorHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bIsWithinReactionRange = IsWithinReactionRange();

		// Play reaction audio when leader is coming into range
		if(bIsWithinReactionRange
		&& !bLeaderPlayerWasInRange
		&& !DancerComp.IsInCongaLine())
		{
			FVector2D _;
			float PanningValue = 0.0;
			float _Y;
			Audio::GetScreenPositionRelativePanningValue(ActorLocation, _, PanningValue, _Y);

			EventParams.RTPCs.Add(FHazeAudioRTPCParam(FHazeAudioID("Rtpc_SpeakerPanning_LR"), PanningValue));
			AudioComponent::PostFireForget(PlayerInRangeEvent, EventParams);			
		}

		bLeaderPlayerWasInRange = bIsWithinReactionRange;
	}

	UFUNCTION()
	private void SetupLeader()
	{
		if(ColorCode == EMonkeyColorCode::Mio)
			DancerComp.CurrentLeader = UCongaLinePlayerComponent::Get(Game::Mio);
		else
			DancerComp.CurrentLeader = UCongaLinePlayerComponent::Get(Game::Zoe);
	}

	AHazePlayerCharacter GetClosestPlayerWithinReactionRange()
	{
		float ClosestDist = CongaLine::MonkeyStartReactingRange;
		AHazePlayerCharacter ClosestPlayer = nullptr;

		if(ActorLocation.Distance(Game::GetMio().ActorLocation) < ClosestDist)
		{
			ClosestDist = ActorLocation.Distance(Game::GetMio().ActorLocation);
			ClosestPlayer = Game::GetMio();
		}
		if(ActorLocation.Distance(Game::GetZoe().ActorLocation) < ClosestDist)
		{
			ClosestPlayer = Game::GetZoe();
		}

		return ClosestPlayer;
	}

	
	AHazePlayerCharacter GetClosestPlayerWithinPickupRange()
	{
		float ClosestDist = CongaLine::EnterCongaLineRange;
		AHazePlayerCharacter ClosestPlayer = nullptr;

		if(ActorLocation.Distance(Game::GetMio().ActorLocation) < ClosestDist)
		{
			ClosestDist = ActorLocation.Distance(Game::GetMio().ActorLocation);
			ClosestPlayer = Game::GetMio();
		}
		if(ActorLocation.Distance(Game::GetZoe().ActorLocation) < ClosestDist)
		{
			ClosestPlayer = Game::GetZoe();
		}

		return ClosestPlayer;
	}

	bool IsWithinReactionRange() const
	{
		if(!CongaLine::IsCongaLineActive())
			return false;
		
		return ActorLocation.Distance(DancerComp.CurrentLeader.Owner.ActorLocation) < CongaLine::MonkeyStartReactingRange;
	}

	bool IsWithinEnterRange() const
	{
		if(!CongaLine::IsCongaLineActive())
			return false;
		
		return ActorLocation.Distance(DancerComp.CurrentLeader.Owner.ActorLocation) < CongaLine::EnterCongaLineRange;
	}

	UFUNCTION()
	void SetVisibility(bool bEnabled)
	{
		MeshComp.SetVisibility(bEnabled);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		FLinearColor DebugCol = ColorCode == EMonkeyColorCode::Mio ? ColorDebug::Purple : ColorDebug::Green;
		
		Debug::DrawDebugPoint(ActorLocation + FVector::UpVector * 50, 50, DebugCol);
	}
#endif
};