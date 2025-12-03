
UCLASS(Abstract)
class UWorld_Prison_MaxSecurity_Platform_RemoteHackableBridge_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnPiecesDisconnect(FRemoteHackableBridgePieceEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void OnPiecesStartConnection(FRemoteHackableBridgePieceEventData EventData){}

	/* END OF AUTO-GENERATED CODE */

	ARemoteHackableBridge HackableBridge;
	URemoteHackingResponseComponent HackingResponseComp;
	UPlayerMovementComponent PlayerMoveComp;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter FrontBridgePieceEmitter;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter BackBridgePieceEmitter;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		HackableBridge = Cast<ARemoteHackableBridge>(HazeOwner);
		HackingResponseComp = URemoteHackingResponseComponent::Get(HackableBridge);
		PlayerMoveComp = UPlayerMovementComponent::Get(Game::GetMio());

		FrontBridgePieceEmitter.AudioComponent.AttachToComponent(HackableBridge.HackableRoot);
		BackBridgePieceEmitter.AudioComponent.AttachToComponent(HackableBridge.HackableRoot);

		FrontBridgePieceEmitter.AudioComponent.SetRelativeLocation(FVector(HackableBridge.BRIDGE_PIECE_CONNECTION_TRACKING_DISTANCE, 0.0, 0.0));
		BackBridgePieceEmitter.AudioComponent.SetRelativeLocation(FVector(-HackableBridge.BRIDGE_PIECE_CONNECTION_TRACKING_DISTANCE, 0.0, 0.0));
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(EmitterName == n"FrontBridgePieceEmitter")
		{
			bUseAttach = false;
			return false;
		}
		else if(EmitterName == n"BackBridgePieceEmitter")
		{
			bUseAttach = false;
			return false;
		}

		return true;
	}

	UFUNCTION(BlueprintPure)
	float GetStickInput()
	{
		return PlayerMoveComp.SyncedLocalSpaceMovementInputForAnimationOnly.Size();
	}

	UFUNCTION(BlueprintPure)
	float GetProgressionAlpha()
	{
		return Math::GetMappedRangeValueClamped(FVector2D(HackableBridge.MinOffset, HackableBridge.MaxOffset), FVector2D(0.0, 1.0), HackableBridge.SyncedOffset.Value);
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return HackingResponseComp.IsHacked();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !HackingResponseComp.IsHacked();
	}

}