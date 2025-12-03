
struct FGravityWhipImpactAudioData
{
	bool bUpdated = false;
	
	UPROPERTY()
	FVector TargetLocation;

	UPROPERTY()
	bool bBlockingHit = false;

	UPROPERTY()
	UPhysicalMaterialAudioAsset AudioAsset = nullptr;

	UPROPERTY()
	float WhipLengthNormalized = 0.0;
}

struct FGravityWhipGrabbedObjectAudioData
{
	UPROPERTY()
	UGravityWhipTargetComponent TargetComponent = nullptr;

	UPROPERTY()
	float RelativeVelocity = 0.0;

	UPROPERTY()
	float DirectionDelta = 0.0;

	FVector TrackedRelativeLocation;

	FGravityWhipGrabbedObjectAudioData(AHazePlayerCharacter Player, UGravityWhipTargetComponent InTargetComponent)
	{
		TargetComponent = InTargetComponent;	
		TrackedRelativeLocation = InTargetComponent.GetWorldLocation() - Player.GetActorLocation();
	}
}


UCLASS(Abstract)
class UGameplay_Gadget_Player_GravityWhip_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void TargetStartGrab(FGravityWhipGrabData GrabData){}

	UFUNCTION(BlueprintEvent)
	void TargetReleased(FGravityWhipReleaseData ReleaseData){}

	UFUNCTION(BlueprintEvent)
	void TargetPreThrown(FGravityWhipReleaseData ReleaseData){}

	UFUNCTION(BlueprintEvent)
	void TargetThrown(FGravityWhipReleaseData ReleaseData){}

	UFUNCTION(BlueprintEvent)
	void TargetGrabbed(FGravityWhipGrabData GrabData){}

	UFUNCTION(BlueprintEvent)
	void WhipGrabTurnedIntoHit(FGravityWhipGrabData GrabData){}

	/* END OF AUTO-GENERATED CODE */

	const float WHIP_GRAB_TARGET_MAX_RELATIVE_VELOCITY = 1000;
	const float MIN_WHIP_LENGTH_ACTIVE = 25;

	// Emitter located at the end of the whip
	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Impact")
	UHazeAudioEmitter WhipEndEmitter;

	// Emitter located at the end of the whip, used for grabbed objects
	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Grabbing")
	UHazeAudioEmitter WhipGrabEmitter;

	// Emitter tracked to closest Mio (other player) along whip while grabbing
	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Grabbing")
	UHazeAudioEmitter WhipBeamEmitter;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Impact")
	float MaxWhipLength = 0;

	UPROPERTY(BlueprintReadOnly)
	bool bIsOnGravityBike = false;

	UHazeSkeletalMeshComponentBase WhipMesh;

	UGravityWhipUserComponent WhipUserComp;
	UGravityBikeWhipComponent BikeWhipComp;
	UHazeCameraComponent CameraComp;
	UHazeMovementAudioComponent MoveAudioComp;

	FVector GetWhipEnd() const property
	{
		return WhipMesh.GetSocketLocation(n"Whip36");
	}

	FRotator GetWhipRotation() const property
	{			
		return WhipMesh.GetSocketRotation(n"Whip36");
	}

	private FHazeRuntimeSpline CachedWhipSpline;
	private FHazeRuntimeSpline GetWhipSpline() property
	{
		if(bWhipSplineUpdated)
			return CachedWhipSpline;

		const FVector WhipBase = WhipMesh.GetSocketLocation(n"WhipBase");
		const FVector WhipTangent1 = WhipMesh.GetSocketLocation(n"Whip7");
		const FVector WhipTangent2 = WhipMesh.GetSocketLocation(n"Whip13");
		const FVector WhipTangent3 = WhipMesh.GetSocketLocation(n"Whip30");
		const FVector WhipEndPoint = WhipEnd;

		TArray<FVector> SplinePoints;
		SplinePoints.Reserve(5);

		SplinePoints.Add(WhipBase);
		SplinePoints.Add(WhipTangent1);
		SplinePoints.Add(WhipTangent2);
		SplinePoints.Add(WhipTangent3);
		SplinePoints.Add(WhipEndPoint);

		CachedWhipSpline.SetPoints(SplinePoints);
		bWhipSplineUpdated = true;
		
		return CachedWhipSpline;
	}

	private UPhysicalMaterialAudioAsset GrabPhysMat = nullptr;
	private bool bHadWhipImpact = false;
	private bool bWhipSplineUpdated = false;

	private FGravityWhipImpactAudioData ImpactData;
	private TArray<FGravityWhipGrabbedObjectAudioData> TrackedGrabbedObjectDatas;

	private FRotator PreviousViewVelo;
	private FVector PreviousWhipEnd;
	private FVector PrevPlayerLocation;

	private float DirectionDelta = 0.0;
	private float GravitaionRelativeVelocityNormalized = 0.0;
	private AHazePlayerCharacter Player;

	const FName WHIP_GROUP_NAME = n"GravityWhip";

	// Tick while whip is actively being used
	UFUNCTION(BlueprintEvent)
	void TickWhipActive(float DeltaSeconds) {}

	UFUNCTION()
	void OnGrabTargets(FGravityBikeWhipGrabEventData InGrabData)
	{
		FGravityWhipGrabData GrabData;
		GrabData.GrabMode = EGravityWhipGrabMode::Sling;
		GrabData.HighlightPrimitive = nullptr;
		GrabData.AudioData = InGrabData.GrabTargets[0].AudioData;

		TargetStartGrab(GrabData);
	}

	UFUNCTION()
	void OnThrowTargets(FGravityBikeWhipThrowEventData InThrowData)
	{
		FGravityWhipReleaseData ReleaseData;
		ReleaseData.AudioData = InThrowData.ThrowDatas[0].GrabTargetComp.AudioData;

		TargetThrown(ReleaseData);
	}

	UFUNCTION()
	void OnStartThrowRebound(FGravityBikeWhipThrowEventData InThrowData)
	{
		FGravityWhipReleaseData ReleaseData;
		ReleaseData.AudioData = InThrowData.ThrowDatas[0].GrabTargetComp.AudioData;

		TargetPreThrown(ReleaseData);
	}

	UFUNCTION()
	void OnStartThrow(FGravityBikeWhipThrowEventData InThrowData)
	{
		FGravityWhipReleaseData ReleaseData;
		ReleaseData.AudioData = InThrowData.ThrowDatas[0].GrabTargetComp.AudioData;

		TargetPreThrown(ReleaseData);
	}
	

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(EmitterName == n"WhipEndEmitter" || EmitterName == n"WhipBeamEmitter" || EmitterName == n"WhipGrabEmitter")
		{
			bUseAttach = false;
			return false;
		}

		bUseAttach = true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		WhipMesh = UHazeSkeletalMeshComponentBase::Get(HazeOwner);
		Player = Game::GetZoe();
		WhipUserComp = UGravityWhipUserComponent::Get(Player);	

		MoveAudioComp = UHazeMovementAudioComponent::Get(HazeOwner);

		MaxWhipLength = GravityWhip::Grab::AirGrabDistance;

		EffectEvent::LinkActorToReceiveEffectEventsFrom(HazeOwner, Player);

		AGravityBikeWhip BikeWhip = Cast<AGravityBikeWhip>(HazeOwner);
		if(BikeWhip != nullptr)
		{
			bIsOnGravityBike = true;	
			BikeWhipComp = UGravityBikeWhipComponent::Get(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool GetScriptImplementedTriggerEffectEvents(
												 UHazeEffectEventHandlerComponent& EventHandlerComponent,
												 TMap<FName,TSubclassOf<UHazeEffectEventHandler>>& EventClassAndFunctionNames) const
	{
		if(!bIsOnGravityBike)
			return false;

		EventHandlerComponent = UHazeEffectEventHandlerComponent::Get(HazeOwner);

		EventClassAndFunctionNames.Add(n"OnGrabTargets", UGravityBikeWhipEventHandler);
		EventClassAndFunctionNames.Add(n"OnThrowTargets", UGravityBikeWhipEventHandler);
		EventClassAndFunctionNames.Add(n"OnStartThrow", UGravityBikeWhipEventHandler);
		EventClassAndFunctionNames.Add(n"OnStartThrowRebound", UGravityBikeWhipEventHandler);

		return true;		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		ImpactData.bUpdated = false;
		bWhipSplineUpdated = false;

		if(IsWhipActive())
		{
			// Move whip end emitter
			const FVector CurrentWhipEnd = WhipEnd;

			WhipEndEmitter.AudioComponent.SetWorldLocation(WhipEnd);	

			const FVector WhipTargetLocation = WhipUserComp.GrabCenterLocation;					
			WhipEndEmitter.AudioComponent.SetWorldRotation(WhipRotation);	
			
			// Get normal of impact, based on "forward" direction of whip beam compared on user position
			const FVector WhipGrabNormal = (HazeOwner.GetActorCenterLocation() - WhipTargetLocation).GetSafeNormal();
	
			auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);	
			GrabPhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromLocationChecked(WhipTargetLocation, WhipGrabNormal, Trace, bHadWhipImpact).AudioAsset);			

			if(IsGrabbingObjects())
			{	
				// Compute delta of camera movement
				DirectionDelta = Math::FInterpConstantTo(DirectionDelta, 0, DeltaSeconds, 3);

				FRotator ViewVelo = Player.GetViewAngularVelocity();
				if(Math::Sign(ViewVelo.Yaw) != Math::Sign(PreviousViewVelo.Yaw) && Math::Abs(ViewVelo.Yaw) > 0.1 && Math::Abs(PreviousViewVelo.Yaw) > 0)
				{	
					DirectionDelta = 1.0;	
				}	

				const FVector RelativeWhipEnd = CurrentWhipEnd - Player.GetActorLocation();
				const FVector PrevRelativeWhipEnd = PreviousWhipEnd - PrevPlayerLocation;

				const float GravitationDeltaDist = RelativeWhipEnd.Distance(PrevRelativeWhipEnd) / DeltaSeconds;
				GravitaionRelativeVelocityNormalized = Math::Min(1.0, GravitationDeltaDist / WHIP_GRAB_TARGET_MAX_RELATIVE_VELOCITY);	

				// Set location of Grab-emitter
				auto GrabAudioComp = WhipGrabEmitter.AudioComponent;
				GrabAudioComp.SetWorldLocation(WhipEnd);

				// const int NumOldGrabs = TrackedGrabbedObjectDatas.Num();			

				// // Remove old targets
				
				// for(int i = NumOldGrabs - 1; i >= 0; --i)
				// {
				// 	bool bIsValidTarget = false;
				// 	FGravityWhipGrabbedObjectAudioData TrackedGrabData = TrackedGrabbedObjectDatas[i];
					
				// 	for(auto& Target : CurrentGrabTargets)
				// 	{
				// 		if(Target == TrackedGrabData.TargetComponent)
				// 		{
				// 			bIsValidTarget = true;
				// 			break;
				// 		}
				// 	}

				// 	if(!bIsValidTarget)
				// 		TrackedGrabbedObjectDatas.RemoveAtSwap(i);
				// }				

				// // Update existing targets, or add new ones
				// for(auto& Target : CurrentGrabTargets)
				// {	
				// 	if(Target.AudioData.bAudioObject)
				// 	{
				// 		FGravityWhipGrabbedObjectAudioData TrackedGrabData;		
				// 		if(GetMatchingGrabData(Target, TrackedGrabData))
				// 		{	
				// 			const FVector CurrentLocation = Target.GetWorldLocation();
				// 			const FVector PrevLocation = TrackedGrabData.TrackedRelativeLocation;

				// 			const float Dist = CurrentLocation.Distance(PrevLocation) / DeltaSeconds;

				// 			TrackedGrabData.RelativeVelocity = Dist / WHIP_GRAB_TARGET_MAX_RELATIVE_VELOCITY;					
				// 		}	
				// 		else
				// 		{
				// 			TrackedGrabData = FGravityWhipGrabbedObjectAudioData(Player, Target);
				// 			TrackedGrabbedObjectDatas.Add(TrackedGrabData);
				// 		}

				// 		TrackedGrabData.DirectionDelta = DirectionDelta;
				// 	}				
				// }		

				PreviousViewVelo = ViewVelo;
				PreviousWhipEnd = CurrentWhipEnd;
			}	

			auto Spline = GetWhipSpline(); 
			const FVector ClosestMioPosOnWhipLine = Spline.GetClosestLocationToLocation(Player.OtherPlayer.GetActorLocation());
			
			WhipBeamEmitter.AudioComponent.SetWorldLocation(ClosestMioPosOnWhipLine);
			TickWhipActive(DeltaSeconds);	

			PrevPlayerLocation = Player.GetActorLocation();
		}		

	#if EDITOR
		LogState();
	#endif
	}

	void LogState()
	{
		auto TempLog = TEMPORAL_LOG(f"{HazeOwner.GetName()}/Audio");
		TempLog.Value("Tag", MoveAudioComp.GetActiveMovementTag(WHIP_GROUP_NAME));
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodetitle = "Is Whip Active"))
	bool IsWhipActive()
	{
		return WhipSpline.Length >= MIN_WHIP_LENGTH_ACTIVE;
	}

	// The data of the current frame of whipping
	UFUNCTION(BlueprintPure, Meta = (CompactNodetitle = "Impact Data"))
	void GetWhipImpactData(FGravityWhipImpactAudioData&out OutImpactData)
	{
		if(!ImpactData.bUpdated)
		{
			ImpactData.TargetLocation = WhipEnd;
			ImpactData.bBlockingHit = bHadWhipImpact;

			ImpactData.WhipLengthNormalized = Math::Min(1,  WhipSpline.Length / GravityWhip::Grab::AirGrabDistance);
			ImpactData.AudioAsset = GrabPhysMat;

			ImpactData.bUpdated = true;
		}	

		OutImpactData = ImpactData;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Gravitation Velocity Normalized"))
	float GetGravitationRelativeVelocityNormalized()
	{	
		return GravitaionRelativeVelocityNormalized;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodetitle = "Whip is Retracting"))
	bool IsRetracting()
	{
		auto Tag = MoveAudioComp.GetActiveMovementTag(WHIP_GROUP_NAME);
		return Tag == n"StartRetract" || Tag == n"FullyRetracted";
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodetitle = "Is Grabbing Objects"))
	bool IsGrabbingObjects()
	{
		if(!bIsOnGravityBike)
			return WhipUserComp.IsGrabbingAny();

		return BikeWhipComp.GrabbedTargets.Num() > 0;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodetitle = "Whip End Location"))
	FVector GetWhipEndLocation()
	{		
		return WhipUserComp.GrabCenterLocation;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodetitle = "Impact Emitter Environment Type"))
	EHazeAudioEnvironmentType GetImpactPrioritizedReverbZoneEnvironmentType()
	{
		auto ReverbComp = WhipEndEmitter.AudioComponent.ReverbComponent;
		if(ReverbComp.PrioritizedReverbZone != nullptr)
			return ReverbComp.PrioritizedReverbZone.EnvironmentType;

		return EHazeAudioEnvironmentType::Swtc_Environment_None;		
	}

	// bool GetCurrentGrabDatas(TArray<UGravityWhipTargetComponent>& OutGrabTargets)
	// {
	// 	if(!bIsOnGravityBike)
	// 	{
	// 		for(auto& GrabData : WhipUserComp.Grabs)
	// 		{
	// 			OutGrabTargets.Append(GrabData.TargetComponents);			
	// 		}
	// 	}
	// 	else
	// 	{
	// 		for(auto& GrabData : BikeWhipComp.GrabbedTargets)
	// 		{
	// 			OutGrabTargets.Append(GrabData.TargetComponents);	
	// 		}
	// 	}

	// 	return OutGrabTargets.Num() > 0;
	// }



	bool GetMatchingGrabData(const UGravityWhipTargetComponent& InTarget, FGravityWhipGrabbedObjectAudioData& OutGrabData)
	{
		bool bFoundMatchingData = false;

		for(int i = 0; i < TrackedGrabbedObjectDatas.Num(); ++i)
		{
			if(TrackedGrabbedObjectDatas[i].TargetComponent == InTarget)
			{
				OutGrabData = TrackedGrabbedObjectDatas[i];
				bFoundMatchingData = true;
				break;
			}	
		}	

		return bFoundMatchingData;
	}
}