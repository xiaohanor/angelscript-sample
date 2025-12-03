struct FSkylineTripodMechLegAudioData
{
	const ESkylineBossLeg Leg = ESkylineBossLeg::Left;
	const UHazeAudioEmitter LegEmitter;
	const UHazeAudioEmitter FootEmitter;
	const UHazeAudioEmitter FootDamageEmitter;
	const UHazeSkeletalMeshComponentBase BossMesh;

	private FHazeRuntimeSpline LegSpline;
	private float LegDistanceVelo;

	const float MAX_LEG_VELO_DISTANCE_RANGE = 100.0;

	FSkylineTripodMechLegAudioData(const ESkylineBossLeg InLeg, UHazeAudioEmitter InLegEmitter, 
								UHazeAudioEmitter InFootEmitter, UHazeAudioEmitter InFootDamageEmitter,
								UHazeSkeletalMeshComponentBase InBossMesh)
	{
		Leg = InLeg;
		LegEmitter = InLegEmitter;
		FootEmitter = InFootEmitter;
		FootDamageEmitter = InFootDamageEmitter;
		BossMesh = InBossMesh;
	}

	void SetLegEmitterPositions()
	{
		// First cache leg velo from last spline
		const float PrevDistance = LegSpline.Length;

		LegSpline = GetLegSplinePoints();

		TArray<FAkSoundPosition> LegSplinePositions;
		
		auto Players = Game::GetPlayers();
		for(int i = 0; i < 2; ++i)
		{
			auto Player = Players[i];

			FAkSoundPosition ClosestPlayerSoundPos();
			ClosestPlayerSoundPos.SetPosition(LegSpline.GetClosestLocationToLocation(Player.ActorLocation));

			LegSplinePositions.Add(ClosestPlayerSoundPos);	
		}

		LegEmitter.AudioComponent.SetMultipleSoundPositions(LegSplinePositions);
		LegDistanceVelo = Math::Abs(LegSpline.GetLength() - PrevDistance);
	}

	float GetLegVelo() const
	{
		return Math::Min(1, LegDistanceVelo / MAX_LEG_VELO_DISTANCE_RANGE);
	}

	private FHazeRuntimeSpline GetLegSplinePoints()
	{		
		FName StartBoneName = NAME_None;	

		switch(Leg)
		{
			case(ESkylineBossLeg::Left): StartBoneName = n"LeftFrontLeg29"; break;
			case(ESkylineBossLeg::Right): StartBoneName = n"RightFrontLeg29"; break;
			case(ESkylineBossLeg::Center): StartBoneName = n"BackLeg29"; break;
			default: break;
		}
		
		TArray<FVector> LegPoints;
		LegPoints.SetNum(SkylineBoss::NUM_LEG_BONE_INDEXES - 1);

		FName ItBoneName = StartBoneName;	

		for(int BoneIndex = 1; BoneIndex < SkylineBoss::NUM_LEG_BONE_INDEXES; ++BoneIndex)	
		{
			FVector BoneItLocation = BossMesh.GetSocketLocation(ItBoneName);
			LegPoints[BoneIndex - 1] = BoneItLocation;

			ItBoneName = BossMesh.GetParentBone(ItBoneName);		
		}
	
		LegSpline.SetPoints(LegPoints);
		return LegSpline;
	}
}

UCLASS(Abstract)
class UGameplay_Character_Boss_Skyline_TripodMech_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void LegDamaged(FSkylineBossLegEventData LegEventData){}

	UFUNCTION(BlueprintEvent)
	void FootPlaced(FSkylineBossFootEventData FootEventData){}

	UFUNCTION(BlueprintEvent)
	void FootLifted(FSkylineBossFootEventData FootEventData){}

	UFUNCTION(BlueprintEvent)
	void FootPlacingStart(FSkylineBossFootEventData FootEventData){}

	UFUNCTION(BlueprintEvent)
	void BeamStop(){}

	UFUNCTION(BlueprintEvent)
	void BeamStart(){}

	UFUNCTION(BlueprintEvent)
	void PendingDown(){}

	UFUNCTION(BlueprintEvent)
	void CoreDestroyed(){}

	UFUNCTION(BlueprintEvent)
	void CoreDamaged(FSkylineBossCoreDamagedEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void CloseHatch(){}

	UFUNCTION(BlueprintEvent)
	void OpenHatch(){}

	UFUNCTION(BlueprintEvent)
	void BeginFall(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly, NotVisible)
	ASkylineBoss Boss;

	UPROPERTY(BlueprintReadOnly, EditInstanceOnly,  Category = "Emitters", Meta = (DisplayName = "Emitter - Head"))
	UHazeAudioEmitter HeadEmitter;

	UPROPERTY(BlueprintReadOnly, EditInstanceOnly,  Category = "Emitters", Meta = (DisplayName = "Emitter - Left Foot"))
	UHazeAudioEmitter LeftFootEmitter;

	UPROPERTY(BlueprintReadOnly, EditInstanceOnly,  Category = "Emitters", Meta = (DisplayName = "Emitter - Left Foot Damage"))
	UHazeAudioEmitter LeftFootDamageEmitter;

	UPROPERTY(BlueprintReadOnly, EditInstanceOnly, Category = "Emitters", Meta = (DisplayName = "Emitter - Right Foot"))
	UHazeAudioEmitter RightFootEmitter;

	UPROPERTY(BlueprintReadOnly, EditInstanceOnly, Category = "Emitters", Meta = (DisplayName = "Emitter - Right Foot Damage"))
	UHazeAudioEmitter RightFootDamageEmitter;

	UPROPERTY(BlueprintReadOnly, EditInstanceOnly, Category = "Emitters", Meta = (DisplayName = "Emitter - Center Foot"))
	UHazeAudioEmitter CenterFootEmitter;

	UPROPERTY(BlueprintReadOnly, EditInstanceOnly, Category = "Emitters", Meta = (DisplayName = "Emitter - Center Foot Damage"))
	UHazeAudioEmitter CenterFootDamageEmitter;

	UPROPERTY(BlueprintReadOnly,  Category = "Emitters", Meta = (DisplayName = "Emitter - Left Leg"))
	UHazeAudioEmitter LeftLegEmitter;

	UPROPERTY(BlueprintReadOnly, Category = "Emitters", Meta = (DisplayName = "Emitter - Right Leg"))
	UHazeAudioEmitter RightLegEmitter;

	UPROPERTY(BlueprintReadOnly, Category = "Emitters", Meta = (DisplayName = "Emitter - Center Leg"))
	UHazeAudioEmitter CenterLegEmitter;

	UPROPERTY(BlueprintReadOnly, Category = "Emitters", Meta = (DisplayName = "Emitter - Impact"))
	UHazeAudioEmitter ImpactEmitter;

	UPROPERTY(NotVisible)
	bool bBeamIsActive = false;

	private TArray<FSkylineTripodMechLegAudioData> LegDatas;

	private USkylineBossFocusBeamComponent PrimaryFocusBeamComponent;

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(EmitterName == n"ImpactEmitter")
		{
			bUseAttach = false;
			return false;
		}
		else
		{
			ComponentName = n"Mesh";
			TargetActor = HazeOwner;
			
			if(EmitterName == n"LeftLegEmitter") BoneName = n"LeftFrontLeg29";
			else if(EmitterName == n"RightLegEmitter") BoneName = n"RightFrontLeg29";
			else if(EmitterName == n"CenterLegEmitter") BoneName = n"BackLeg29";

			bUseAttach = true;
			return true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Boss = Cast<ASkylineBoss>(HazeOwner);
		InitializeLegDatas();
	
		PrimaryFocusBeamComponent = Boss.GetComponentByClass(USkylineBossFocusBeamComponent);
	}

	private void InitializeLegDatas()
	{
		LegDatas.SetNum(3);	

		LegDatas[ESkylineBossLeg::Left] = FSkylineTripodMechLegAudioData(ESkylineBossLeg::Left, InLegEmitter = LeftLegEmitter, InFootEmitter = LeftFootEmitter, InFootDamageEmitter = LeftFootDamageEmitter, InBossMesh = Boss.Mesh);
		LegDatas[ESkylineBossLeg::Right] = FSkylineTripodMechLegAudioData(ESkylineBossLeg::Right, InLegEmitter = RightLegEmitter, InFootEmitter = RightFootEmitter, InFootDamageEmitter = RightFootDamageEmitter, InBossMesh = Boss.Mesh);
		LegDatas[ESkylineBossLeg::Center] = FSkylineTripodMechLegAudioData(ESkylineBossLeg::Center, InLegEmitter = CenterLegEmitter, InFootEmitter = CenterFootEmitter, InFootDamageEmitter = CenterFootDamageEmitter, InBossMesh = Boss.Mesh);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(int LegIndex = 0; LegIndex < 3; ++LegIndex)
		{
			auto& LegData = LegDatas[LegIndex];
			LegData.SetLegEmitterPositions();		
		}

		if(bBeamIsActive)
		{
			ImpactEmitter.AudioComponent.SetWorldLocation(PrimaryFocusBeamComponent.CurrentImpactLocation);
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnFootEmitterPlaying(const UHazeAudioEmitter FootEmitter) {}

	UFUNCTION()
	void BroadcastFootEmittersPlaying()
	{
		for (int i=0; i < 3; ++i)
		{
			if (LegDatas[i].FootEmitter.IsPlaying())
			{
				OnFootEmitterPlaying(LegDatas[i].FootEmitter);
			}
		}
	}

	UFUNCTION(BlueprintPure)
	void GetFootEmitter(ESkylineBossLeg LegIndex, const UHazeAudioEmitter&out FootEmitter)
	{
		FootEmitter = LegDatas[LegIndex].FootEmitter;
	}

	UFUNCTION(BlueprintPure)
	void GetFootDamageEmitter(ESkylineBossLeg LegIndex, const UHazeAudioEmitter&out FootDamageEmitter)
	{
		FootDamageEmitter = LegDatas[LegIndex].FootDamageEmitter;
	}

	UFUNCTION(BlueprintPure)
	void GetLegEmitter(ESkylineBossLeg LegIndex, const UHazeAudioEmitter&out LegEmitter)
	{
		LegEmitter = LegDatas[LegIndex].LegEmitter;
	}

	UFUNCTION(BlueprintPure)
	float GetLegVelo(const ESkylineBossLeg LegIndex)
	{
		return LegDatas[LegIndex].GetLegVelo();
	}
}