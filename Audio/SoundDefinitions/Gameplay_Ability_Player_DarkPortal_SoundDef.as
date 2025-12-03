
UCLASS(Abstract)
class UGameplay_Ability_Player_DarkPortal_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void GrabActivated(){}

	UFUNCTION(BlueprintEvent)
	void GrabDeactivated(){}

	UFUNCTION(BlueprintEvent)
	void StartGrabbingObject(FDarkPortalGrabEventData GrabData){}

	UFUNCTION(BlueprintEvent)
	void StopGrabbingObject(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotVisible)
	UHazeAudioEmitter ArmsMultiEmitter;	

	UDarkPortalTargetComponent GrabComponent;
	FVector CachedGrabComponentLocation;
	float CachedGrabObjectSpeed = 0;
	const float MAX_GRAB_OBJECT_SPEED = 1500;

	const float MAX_REACH_LENGTH_RANGE_SQUARED = 19500000;

	TArray<FAkSoundPosition> ArmSoundPositions;	
	TArray<FVector> PreviousArmSoundPositions;
	default PreviousArmSoundPositions.SetNum(2);

	UPROPERTY(BlueprintReadOnly)
	float HeartbeatInterval = 2.0;

	ADarkPortalActor DarkPortal;
	
	bool GetbHasSpawnedArms() const property
	{
		return DarkPortal.IsGrabbingActive();
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DarkPortal = Cast<ADarkPortalActor>(HazeOwner);
		ArmSoundPositions.SetNum(2);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return DarkPortal.State == EDarkPortalState::Settle;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return DarkPortal.State != EDarkPortalState::Settle;
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(EmitterName == n"ArmsMultiEmitter")
		{
			bUseAttach = false;
			return false;
		}

		return true;
	}

	UFUNCTION(BlueprintEvent)
	void TickGrabbing(float DeltaSeconds) {}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Reset tracked arm positions
		PreviousArmSoundPositions[0] = DarkPortal.OriginLocation;
		PreviousArmSoundPositions[1] = DarkPortal.OriginLocation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(bHasSpawnedArms)
		{
			for(auto Player : Game::GetPlayers())
			{
				FVector ClosestPlayerPos;
				float ClosestPlayerSplineDistSqrd = MAX_flt;

				for(auto& Arm : DarkPortal.SpawnedArms)
				{
					auto Spline = Arm.CurrentPortalCurve.ToSpline();
					auto PlayerSplinePos = Spline.GetClosestLocationToLocation(Player.ActorLocation);
					auto PlayerSplineDistSqrd = PlayerSplinePos.DistSquared(Player.ActorLocation);

					if(PlayerSplineDistSqrd < ClosestPlayerSplineDistSqrd)
					{
						ClosestPlayerSplineDistSqrd = PlayerSplineDistSqrd;
						ClosestPlayerPos = PlayerSplinePos;
					}
				}

				auto PreviousPos = PreviousArmSoundPositions[Player.Player];
				if(!PreviousPos.IsZero())
				{
					ClosestPlayerPos = Math::VInterpConstantTo(PreviousPos, ClosestPlayerPos, DeltaSeconds, 500.0);
				}

				ArmSoundPositions[Player.Player].SetPosition(ClosestPlayerPos);
				PreviousArmSoundPositions[Player.Player] = ClosestPlayerPos;
			}

			ArmsMultiEmitter.AudioComponent.SetMultipleSoundPositions(ArmSoundPositions);
		}
		else
		{
			PreviousArmSoundPositions[0] = DarkPortal.OriginLocation;
			PreviousArmSoundPositions[1] = DarkPortal.OriginLocation;
		}

		if(GrabComponent != nullptr)
		{
			auto CurrentGrabComponentLocation = GrabComponent.WorldLocation;
			auto Velo = CurrentGrabComponentLocation - CachedGrabComponentLocation;
			CachedGrabObjectSpeed = Velo.Size() / DeltaSeconds;

			CachedGrabComponentLocation = CurrentGrabComponentLocation;	

			TickGrabbing(DeltaSeconds);
 		}
	}

	UFUNCTION(BlueprintCallable)
	void SetGrabTarget(UDarkPortalTargetComponent TargetComponent)
	{
		CachedGrabObjectSpeed = 0.0;
		GrabComponent = TargetComponent;
		
		if(GrabComponent != nullptr)
			CachedGrabComponentLocation = GrabComponent.WorldLocation;
	} 

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Grab Object Speed"))
	float GetGrabObjectSpeedNormalized()
	{
		return Math::Min(1, CachedGrabObjectSpeed / 1500);
	}
	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Reach Length"))
	float GetReachLengthNormalized()
	{
		if(!bHasSpawnedArms)
			return 0;

		float MaxDistSquared = 0.0;

		for(auto& Arm : DarkPortal.SpawnedArms)
		{			
			float ArmDistSqrd = Arm.CurrentPortalCurve.End.DistSquared(DarkPortal.OriginLocation);
			MaxDistSquared = Math::Max(MaxDistSquared, ArmDistSqrd);
		}

		return Math::Min(1, MaxDistSquared / MAX_REACH_LENGTH_RANGE_SQUARED);
	}

}