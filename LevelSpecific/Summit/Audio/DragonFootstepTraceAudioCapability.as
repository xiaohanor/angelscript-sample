// USTRUCT()
// struct FDragonFootstepParams
// {
// 	UPROPERTY()
// 	EDragonFootType FootStepType = EDragonFootType::None;

// 	UPROPERTY()
// 	FName MovementState = n"";

// 	UPROPERTY()
// 	UPhysicalMaterialAudioAsset AudioPhysMat = nullptr;

// 	UPROPERTY()
// 	float SlopeTilt = 0.0;

// 	// Set in trace settings
// 	UPROPERTY()
// 	float MakeUpGain = 0.0;

// 	// Set in trace settings
// 	UPROPERTY()
// 	float Pitch = 0.0;

// }

// class UDragonFootstepTraceAudioCapability : UHazeCapability
// {
// 	default TickGroup = EHazeTickGroup::Audio;
// 	default DebugCategory = n"Audio";

// 	UMeshComponent Mesh;
// 	UHazeMovementComponent MoveComp;
// 	UPlayerTeenDragonComponent DragonComp;
// 	UDragonMovementAudioComponent DragonMoveComp;
// 	UDragonFootstepTraceComponent TraceComp;

// 	TMap<EDragonFootType, FVector> TrackedFootLocations;	
// 	FVector CachedDragonLocation;
// 	const FName MOVEMENT_GROUP_NAME = n"Dragon_Foot";

// 	AHazeActor Dragon;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		MoveComp = UHazeMovementComponent::Get(Owner);
// 		DragonComp = UPlayerTeenDragonComponent::Get(Owner);
// 		DragonMoveComp = UDragonMovementAudioComponent::Get(Owner);
// 		TraceComp = UDragonFootstepTraceComponent::Get(Owner);

// 		if(DragonMoveComp.Form == EDragonForm::Baby)
// 		{
// 			Mesh = UMeshComponent::Get(Owner);
// 		}
// 		else if(DragonMoveComp.Form == EDragonForm::Teen)
// 		{
// 			Mesh = DragonComp.GetDragonMesh();
// 			Dragon = Cast<AHazeActor>(Mesh.GetOwner());
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const
// 	{
// 		if(DragonMoveComp.IsMovementBlocked(EMovementAudioFlags::Footsteps))
// 			return false;

// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		if(DragonMoveComp.IsMovementBlocked(EMovementAudioFlags::Footsteps))
// 			return true;

// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated()
// 	{
// 		for(int i = 0; i < int(EDragonFootType::MAX); ++i)
// 		{
// 			InitializeFootData(TraceComp.GetTraceData(EDragonFootType(i)));
// 		}

// 		if(DragonMoveComp.TraceSettings != nullptr)
// 			Owner.ApplySettings(DragonMoveComp.TraceSettings, this);

// 		CachedDragonLocation = Owner.GetActorCenterLocation();
// 	}

// 	void InitializeFootData(FDragonFootstepTraceData& InFootData)
// 	{
// 		InFootData.PlantTriggerTimeStamp = InFootData.Settings.TriggerCooldown;

// 		InFootData.Trace.bGrounded = false;
// 		InFootData.Trace.bPerformed = false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		// const FName MovementTag = DragonMoveComp.GetActiveMovementTag(MOVEMENT_GROUP_NAME);
// 		// if(MovementTag == NAME_None)
// 		// 	return;

// 		for(int i = 0; i < int(EDragonFootType::MAX); ++i)
// 		{
// 			FDragonFootstepTraceData& TraceData = TraceComp.GetTraceData(EDragonFootType(i));

// 			// if(!CanPerformFootstep(TraceData))
// 			// 	continue;

// 			// Reset performed-flag
// 			TraceData.Trace.bPerformed = false;

// 			TraceData.Start = GetTraceFrameStartPos(TraceData);

// 			// if(!ValidateFootFrameVelo(TraceData))
// 			// 	continue;

// 			const float TraceLength = GetScaledTraceLength(TraceData);

// 			TraceData.End = GetTraceFrameEndPos(TraceData, TraceLength);
// 			continue;

// 			if(TraceComp.PerformFootTrace_Sphere(TraceData, TraceData.Settings.SphereTraceRadius, bDebug = IsDebugActive()))
// 			{
// 				FDragonFootstepParams FootParams;
// 				//FootParams.MovementState = MovementTag;
// 				const bool bIsPlant = TraceData.Trace.bGrounded;

// 				UPhysicalMaterial PhysMat = nullptr;
// 				if(bIsPlant)
// 				{
// 					FHazeTraceSettings TraceSettings = TraceComp.InitTraceSettings();
// 					PhysMat = AudioTrace::GetPhysMaterialFromHit(TraceData.Hit, TraceSettings);	
// 					TraceData.LastPhysMat = PhysMat;
// 				}
// 				else
// 				{
// 					PhysMat = TraceData.LastPhysMat;
// 					if(PhysMat == nullptr)
// 						return;
// 				}

// 				FootParams.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset);
// 				FootParams.FootStepType = TraceData.Hit.bBlockingHit ? TraceData.Foot : EDragonFootType::Release;

// 				switch(TraceData.Foot)
// 				{
// 					case(EDragonFootType::FrontLeft) : UDragonMovementAudioEventHandler::Trigger_OnFootstepTrace_FrontLeft(Dragon, FootParams); break;
// 					case(EDragonFootType::FrontRight) : UDragonMovementAudioEventHandler::Trigger_OnFootstepTrace_FrontRight(Dragon, FootParams); break;
// 					case(EDragonFootType::BackLeft) : UDragonMovementAudioEventHandler::Trigger_OnFootstepTrace_BackLeft(Dragon, FootParams); break;
// 					case(EDragonFootType::BackRight) : UDragonMovementAudioEventHandler::Trigger_OnFootstepTrace_BackRight(Dragon, FootParams); break;
// 				}
				
// 				//Debug::DrawDebugPoint(TraceData.Hit.Location, 10, FLinearColor(0.89, 0.07, 0.62), 3.0, bRenderInForground = false);	

// 				// TODO: Implement shared cooldown with bIsAllFeet?
// 				QueryCooldowns(TraceData, false);
// 			}			
// 		}

// 		for(int i = 0; i < int(EDragonFootType::MAX); ++i)
// 		{
// 			FDragonFootstepTraceData& TraceData = TraceComp.GetTraceData(EDragonFootType(i));
// 			TrackedFootLocations.FindOrAdd(TraceData.Foot, TraceData.Start);
// 		}

// 		CachedDragonLocation = Owner.GetActorLocation();
// 	}

// 	private bool CanPerformFootstep(FDragonFootstepTraceData& TraceData)
// 	{
// 		return Time::GetRealTimeSince(TraceData.PlantTriggerTimeStamp) >= TraceData.Settings.TriggerCooldown;		
// 	}

// 	private void QueryCooldowns(FDragonFootstepTraceData& TraceData, const bool bIsAllFeet)
// 	{		
// 		if(TraceData.Trace.bGrounded)
// 		{
// 			TraceData.PlantTriggerTimeStamp = Time::GetRealTimeSeconds();
// 			FDragonFootstepTraceData& OtherFoot = GetOtherSideFoot(TraceData);
// 			OtherFoot.PlantTriggerTimeStamp = TraceData.PlantTriggerTimeStamp;

// 			// if(bIsBothFeet)
// 			// {
// 			// 	GetOtherFoot(TraceData).PlantTriggerTimeStamp = TraceData.PlantTriggerTimeStamp;
// 			// }

// 			TArray<FDragonFootstepTraceData> OtherDatas;
// 			GetOtherFeet(TraceData, OtherDatas);

// 			for(auto& Data : OtherDatas)
// 			{
// 				Data.PlantTriggerTimeStamp = TraceData.PlantTriggerTimeStamp;
// 			}
// 		}
// 		else
// 		{
// 			TraceData.ReleaseTriggerTimeStamp = Time::GetRealTimeSeconds();
// 			FDragonFootstepTraceData& OtherFoot = GetOtherSideFoot(TraceData);
// 			OtherFoot.ReleaseTriggerTimeStamp = TraceData.ReleaseTriggerTimeStamp;
// 			// if(bIsBothFeet)
// 			// {
// 			// 	GetOtherFoot(TraceData).ReleaseTriggerTimeStamp = TraceData.ReleaseTriggerTimeStamp;
// 			// }

// 			TArray<FDragonFootstepTraceData> OtherDatas;
// 			GetOtherFeet(TraceData, OtherDatas);

// 			for(auto& Data : OtherDatas)
// 			{
// 				Data.ReleaseTriggerTimeStamp = TraceData.ReleaseTriggerTimeStamp;
// 			}
// 		}		
// 	}

// 	private void GetOtherFeet(const FDragonFootstepTraceData& InTraceData, TArray<FDragonFootstepTraceData>& OutTraceDatas)
// 	{
// 		for(int i = 0; i < int(EDragonFootType::MAX); ++i)
// 		{
// 			if(i == int(InTraceData.Foot))
// 				continue;

// 			OutTraceDatas.Add(TraceComp.GetTraceData(EDragonFootType(i)));
// 		}		
// 	}

// 	private FDragonFootstepTraceData& GetOtherSideFoot(const FDragonFootstepTraceData& InTraceData)
// 	{
// 		switch(InTraceData.Foot)
// 		{
// 			case(EDragonFootType::FrontLeft): return TraceComp.GetTraceData(EDragonFootType::FrontRight);
// 			case(EDragonFootType::FrontRight): return TraceComp.GetTraceData(EDragonFootType::FrontLeft);
// 			case(EDragonFootType::BackLeft): return TraceComp.GetTraceData(EDragonFootType::BackRight);
// 			case(EDragonFootType::BackRight): return TraceComp.GetTraceData(EDragonFootType::BackLeft);
// 		}

// 		devError("Couldn't return matching trace data for Dragon footstep audio!");
// 		return TraceComp.GetTraceData(EDragonFootType::FrontLeft);
// 	}
// }