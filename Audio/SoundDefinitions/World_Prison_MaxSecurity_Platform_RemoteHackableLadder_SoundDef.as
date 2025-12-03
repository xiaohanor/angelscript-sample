
UCLASS(Abstract)
class UWorld_Prison_MaxSecurity_Platform_RemoteHackableLadder_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnPiecesDisconnect(FRemoteHackableBridgePieceEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void OnPiecesStartConnection(FRemoteHackableBridgePieceEventData EventData){}

	/* END OF AUTO-GENERATED CODE */

	ARemoteHackableDividedLadder HackableLadder;
	URemoteHackingResponseComponent HackingResponseComp;
	UPlayerMovementComponent PlayerMoveComp;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter FrontBridgePieceEmitter;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter BackBridgePieceEmitter;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		HackableLadder = Cast<ARemoteHackableDividedLadder>(HazeOwner);
		HackingResponseComp = URemoteHackingResponseComponent::Get(HackableLadder);
		PlayerMoveComp = UPlayerMovementComponent::Get(Game::GetMio());

		DefaultEmitter.AudioComponent.AttachToComponent(HackableLadder.HackableRoot);
		FrontBridgePieceEmitter.AudioComponent.AttachToComponent(HackableLadder.HackableRoot);
		BackBridgePieceEmitter.AudioComponent.AttachToComponent(HackableLadder.HackableRoot);

		FrontBridgePieceEmitter.AudioComponent.SetRelativeLocation(FVector(0.0, 0.0, 175));
		BackBridgePieceEmitter.AudioComponent.SetRelativeLocation(FVector(0.0, 0.0, -175));
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
		return Math::GetMappedRangeValueClamped(FVector2D(-800, HackableLadder.MaxHackableOffset), FVector2D(0.0, 1.0), HackableLadder.SyncedHackableOffset.Value);
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