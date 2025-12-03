struct FPlayerLookAtTriggerState
{
	float LookAtTime = 0.0;
	bool bInVolume = false;
	bool bHasTriggered = false;
	float CoolDown = 0.0;
}

enum EPlayerLookAtTriggerReplication
{
	Local, 		// Trigger independently on both remote and control side. Any sync will have to be done externally. 
	Crumb, 		// Trigger only on control side, using crumb to trigger on remote side. This will match normal player movement/view best.
	NetFunction,// Trigger on control side, using netfunction to trigger on remote side. Use when you want sync but as fast replication as possible.
}

event void FPlayerLookAtEvent(AHazePlayerCharacter Player);

class UPlayerLookAtTriggerComponent : USceneComponent
{
	// If true, we will not check for players looking at us until enabled.
	UPROPERTY(EditAnywhere, Category = "LookAt")
	bool bStartDisabled = false;

	// Player needs to be within this range to count as triggering. Note that we use player focus location, not view location!
	UPROPERTY(EditAnywhere, Category = "LookAt")
	float Range = 5000.0;

	// If set, player needs to be within given volume (which also needs to triggers overlaps with player).
	UPROPERTY(EditAnywhere, Category = "LookAt")
	AVolume TriggerVolume = nullptr;

	// OnBeginLookAt will be broadcast when player has been looking near us for this many seconds
	UPROPERTY(EditAnywhere, Category = "LookAt")
	float LookDuration = 0.25;

	// To count as triggering we need to be within this fraction of center of players view. 
	// 0 is directly in the center, 1 is to the edges of screen.
	UPROPERTY(EditAnywhere, Category = "LookAt")
	float ViewCenterFraction = 0.5;

	// Which players can trigger this?
	UPROPERTY(EditAnywhere, Category = "LookAt")
	EHazeSelectPlayer Players = EHazeSelectPlayer::Both;

	// If set, we will only trigger if a player is using all of these capability Tags
	UPROPERTY(EditAnywhere, Category = "LookAt")
	TArray<FName> CapabilityTags;

	// Class which, if set, places further custom conditions on when to trigger
	UPROPERTY(EditAnywhere, Category = "LookAt")
	TSubclassOf<UHazePlayerCondition> PlayerConditionClass = nullptr;

	// How is triggering handled in network? Don't change in runtime unless you know what you're doing!
	UPROPERTY(EditAnywhere, Category = "Network")
	EPlayerLookAtTriggerReplication ReplicationType = EPlayerLookAtTriggerReplication::Crumb; 

	// Broadcast when player has met all the look at criteria 
	UPROPERTY(EditAnywhere, Category = "LookAt")
	FPlayerLookAtEvent OnBeginLookAt;

	// Broadcast when player was previously looking at this but now fails one of the criteria
	UPROPERTY(EditAnywhere, Category = "LookAt")
	FPlayerLookAtEvent OnEndLookAt;

	private TPerPlayer<FPlayerLookAtTriggerState> PlayerStates;
	private bool bDisabled = false;
	private UHazePlayerCondition PlayerCondition = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (PlayerConditionClass.IsValid())
			PlayerCondition = NewObject(Owner, PlayerConditionClass);

		if (TriggerVolume != nullptr)
		{
			// Only tick where there are users within volume
			SetComponentTickEnabled(false);
			TriggerVolume.OnActorBeginOverlap.AddUFunction(this, n"OnVolumeBeginOverlap");
			TriggerVolume.OnActorEndOverlap.AddUFunction(this, n"OnVolumeEndOverlap");
		}

		if (bStartDisabled)
			DisableTrigger();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		EndAllLookAts();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		float MinPlayerDistSqr = BIG_NUMBER;
		EHazeSelectPlayer Beginners = EHazeSelectPlayer::None;
		EHazeSelectPlayer Enders = EHazeSelectPlayer::None;
		for (int iPlayer = 0; iPlayer < 2; iPlayer++)
		{
			AHazePlayerCharacter Player = Game::GetPlayer(EHazePlayer(iPlayer));
			if (Player == nullptr) // (LV): Component can tick in editor because they added a bp actor into a sequencer :sweeney_cool:
				continue;
			if (!CanTriggerLocally(Player))
			{
				// Only alter state if allowed
				continue;
			}

			if ((TriggerVolume != nullptr) && !PlayerStates[iPlayer].bInVolume)
			{
				// Outside trigger
				DontLookAt(iPlayer, Enders);
				continue;
			}

			if (!Player.IsSelectedBy(Players))
			{
				// Not allowed to trigger this
				DontLookAt(iPlayer, Enders);
				continue;
			}

			// Only players who have made it this far are interesting for calculating min distance
			float DistSqr = (WorldLocation - Player.FocusLocation).SizeSquared();
			if (DistSqr < MinPlayerDistSqr)
				MinPlayerDistSqr = DistSqr;

			float Dist = Math::Sqrt(DistSqr);

			if (DistSqr > Math::Square(Range))
			{
				// Outside range
				DontLookAt(iPlayer, Enders);
				continue;
			}

			// Note that all of the view stuff will use other player's view if other player has fullscreen, which is what we want.
			if ((Player.ViewFOV <= 90.0) &&	(Player.ViewRotation.Vector().DotProduct(WorldLocation - Player.ViewLocation) < 0.0))
			{
				// Early out for most stuff behind camera
				DontLookAt(iPlayer, Enders);
				continue;
			}

			if (!IsUsingCapabilityTags(Player))
			{
				// Player is not using all capability tags
				DontLookAt(iPlayer, Enders);
				continue;
			}

			if ((PlayerCondition != nullptr) && !PlayerCondition.MeetCondition(Player))
			{
				// Player does not meet with custom conditions
				DontLookAt(iPlayer, Enders);
				continue;				
			}

			FVector2D ViewPos;
			if (!SceneView::ProjectWorldToViewpointRelativePosition(Player, WorldLocation, ViewPos))
			{
				// Not on screen
				DontLookAt(iPlayer, Enders);
				continue;
			}

			ViewPos = (ViewPos - FVector2D(0.5, 0.5)) * 2.0; // 0..1 -> -1..1
			if (ViewPos.SizeSquared() > Math::Square(ViewCenterFraction))
			{
				// Outside screen fraction
				DontLookAt(iPlayer, Enders);
				continue;
			}			

			// All conditions met!
			LookAt(iPlayer, Beginners);
		}

		// Set tick interval based on distance
		float MinTickInterval = Math::Min(0.5, LookDuration * 0.5);
		float RangeSqr = Math::Square(Range);
		if (MinPlayerDistSqr < RangeSqr)
		{
			SetComponentTickInterval(MinTickInterval);
		}
		else
		{
			float TickInterval = Math::GetMappedRangeValueClamped(FVector2D(RangeSqr, Math::Square(Range + Math::Max(Range, 5000.0))), FVector2D(MinTickInterval, 2.0), MinPlayerDistSqr);
			SetComponentTickInterval(TickInterval);
		}

		// Trigger events last, to minimize risk of side effects
		TriggerBeginLookAts(Beginners);
		TriggerEndLookAts(Enders);

#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
		{
			FLinearColor Color = (PlayerStates[0].bHasTriggered || PlayerStates[1].bHasTriggered) ? FLinearColor::Green : FLinearColor::Red;
			Debug::DrawDebugSphere(WorldLocation, 100.0, 4, Color, 0.0, 10.0);
		}
#endif		
	}

	bool IsUsingCapabilityTags(AHazePlayerCharacter Player)
	{
		for (auto CapabilityTag : CapabilityTags)
		{
			if (!Player.IsAnyCapabilityActive(CapabilityTag))
				return false;
		}
	
		return true;
	}

	private void DontLookAt(int iPlayer, EHazeSelectPlayer& NewStopLookingAt)
	{
		if (PlayerStates[iPlayer].bHasTriggered)
		{
		 	NewStopLookingAt = Player::SelectAdd(NewStopLookingAt, EHazePlayer(iPlayer));

			// Cooldown before being able to trigger lookat again to avoid very frequent netmessages
			PlayerStates[iPlayer].CoolDown = Time::RealTimeSeconds + 0.2; 
		}
		PlayerStates[iPlayer].bHasTriggered = false;
		PlayerStates[iPlayer].LookAtTime = 0.0;
	}

	private void LookAt(int iPlayer, EHazeSelectPlayer& NewLookingAt)
	{
		if (PlayerStates[iPlayer].LookAtTime == 0)
			PlayerStates[iPlayer].LookAtTime = Time::RealTimeSeconds;
		if (!PlayerStates[iPlayer].bHasTriggered && 
			(Time::GetRealTimeSince(PlayerStates[iPlayer].LookAtTime) >= LookDuration) && 
			(Time::RealTimeSeconds > PlayerStates[iPlayer].CoolDown))
		{
			PlayerStates[iPlayer].bHasTriggered = true;
			NewLookingAt = Player::SelectAdd(NewLookingAt, EHazePlayer(iPlayer));
		}
	}

	bool CanTriggerLocally(AHazePlayerCharacter Player)
	{
		if (ReplicationType == EPlayerLookAtTriggerReplication::Local)
			return true;

		if (Player.HasControl())
			return true;

		return false;
	}

	void TriggerBeginLookAts(EHazeSelectPlayer Beginners)
	{
		if (Beginners == EHazeSelectPlayer::None)
			return;

		// If we allow local triggering, this might be both. Otherwise there will be only one.
		TArray<AHazePlayerCharacter> TriggeringPlayers = Game::GetPlayersSelectedBy(Beginners);
		for (AHazePlayerCharacter Player : TriggeringPlayers)
		{
			if (ReplicationType == EPlayerLookAtTriggerReplication::Crumb)
				CrumbBeginLookAt(Player);
			else if (ReplicationType == EPlayerLookAtTriggerReplication::Local)
				OnBeginLookAt.Broadcast(Player);
			else if (ReplicationType == EPlayerLookAtTriggerReplication::NetFunction)
				NetBeginLookAt(Player);
		}
	}

	void TriggerEndLookAts(EHazeSelectPlayer Enders)
	{
		if (Enders == EHazeSelectPlayer::None)
			return;

		// If we allow local triggering, this might be both. Otherwise there will be only one.
		TArray<AHazePlayerCharacter> TriggeringPlayers = Game::GetPlayersSelectedBy(Enders);
		for (AHazePlayerCharacter Player : TriggeringPlayers)
		{
			if (ReplicationType == EPlayerLookAtTriggerReplication::Crumb)
				CrumbEndLookAt(Player);
			else if (ReplicationType == EPlayerLookAtTriggerReplication::Local)
				OnEndLookAt.Broadcast(Player);
			else if (ReplicationType == EPlayerLookAtTriggerReplication::NetFunction)
				NetEndLookAt(Player);
		}
	}

	UFUNCTION(NetFunction)
	private void NetBeginLookAt(AHazePlayerCharacter Player)
	{
		OnBeginLookAt.Broadcast(Player);
		PlayerStates[Player].bHasTriggered = true; // Keep remote updated
	}

	UFUNCTION(NetFunction)
	private void NetEndLookAt(AHazePlayerCharacter Player)
	{
		OnEndLookAt.Broadcast(Player);
		PlayerStates[Player].bHasTriggered = false; // Keep remote updated
	}

	UFUNCTION(CrumbFunction)
	private void CrumbBeginLookAt(AHazePlayerCharacter Player)
	{
		if (!ensure(Player != nullptr))
			return;
		OnBeginLookAt.Broadcast(Player);
		PlayerStates[Player].bHasTriggered = true; // Keep remote updated
	}

	UFUNCTION(CrumbFunction)
	private void CrumbEndLookAt(AHazePlayerCharacter Player)
	{
		if (!ensure(Player != nullptr))
			return;
		OnEndLookAt.Broadcast(Player);
		PlayerStates[Player].bHasTriggered = false; // Keep remote updated
	}

	UFUNCTION(NotBlueprintCallable)
	void OnVolumeBeginOverlap(AActor OverlappingActor, AActor OtherActor)
	{
		if (OverlappingActor != TriggerVolume)
			return;
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		PlayerStates[Player].bInVolume = true;	
		SetComponentTickEnabled(true);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnVolumeEndOverlap(AActor OverlappingActor, AActor OtherActor)
	{
		if (OverlappingActor != TriggerVolume)
			return;
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		PlayerStates[Player].bInVolume = false;	
		if (!PlayerStates[Player.OtherPlayer].bInVolume)
			SetComponentTickEnabled(false);

		// End look at for player
		EHazeSelectPlayer Enders = EHazeSelectPlayer::None;
		DontLookAt(int(Player.Player), Enders);
		TriggerEndLookAts(Enders);
	}

	UFUNCTION()
	void DisableTrigger()
	{
		if (bDisabled)
			return;

		bDisabled = true;
		SetComponentTickEnabled(false);
		EndAllLookAts();
	}

	UFUNCTION()
	void EnableTrigger()
	{
		if (!bDisabled)
			return;

		bDisabled = false;
		SetComponentTickEnabled(true);
	}

	void EndAllLookAts()
	{
		EHazeSelectPlayer Enders = EHazeSelectPlayer::None;
		for (int iPlayer = 0; iPlayer < 2; iPlayer++)
		{
			AHazePlayerCharacter Player = Game::GetPlayer(EHazePlayer(iPlayer));
			if (CanTriggerLocally(Player) && PlayerStates[iPlayer].bHasTriggered)
				DontLookAt(iPlayer, Enders);
		}
		TriggerEndLookAts(Enders);
	}
}
