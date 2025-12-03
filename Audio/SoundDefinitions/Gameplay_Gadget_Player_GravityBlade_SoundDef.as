
UCLASS(Abstract)
class UGameplay_Gadget_Player_GravityBlade_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnHitEnemy(FGravityBladeHitData HitData){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditDefaultsOnly)
	TArray<FHazeProxyEmitterUserAuxTargetData> GravityBladeAuxUserSends;

	UGravityBladeGrappleUserComponent GrappleUserComp;

	UPROPERTY(BlueprintReadOnly)
	bool bIsOnGravityBike = false;

	bool bHasBoundEvents = false;

	private UGravityBladeGrappleUserComponent GetGrappleComp() property
	{
		if(GrappleUserComp == nullptr)
			GrappleUserComp = UGravityBladeGrappleUserComponent::Get(PlayerOwner);

		return GrappleUserComp;
	}
	

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SetPlayerOwner(Game::GetMio());

		GrappleUserComp = UGravityBladeGrappleUserComponent::Get(PlayerOwner);

		auto PlayerMoveAudioComp = UHazeMovementAudioComponent::Get(PlayerOwner);
		auto GravityBladeMoveAudioComp = UHazeMovementAudioComponent::Get(HazeOwner);

		PlayerMoveAudioComp.LinkMovementRequests(GravityBladeMoveAudioComp);

		auto GravityBikeBlade = Cast<AGravityBikeBlade>(HazeOwner);
		
		if(GravityBikeBlade != nullptr)
			bIsOnGravityBike = true;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasBoundEvents = true;
	}

	UFUNCTION(BlueprintPure)
	float GetGrappleCameraTransitionTime()
	{
		float32 _ = 0.0;
		float32 TimeMax = 0.0;

		GrappleUserComp.GrappleCameraBlend.RotationCurve.GetTimeRange(_, TimeMax);
		return TimeMax;
	}

	UFUNCTION(BlueprintOverride)
	bool GetScriptImplementedTriggerEffectEvents(
												 UHazeEffectEventHandlerComponent& EventHandlerComponent,
												 TMap<FName,TSubclassOf<UHazeEffectEventHandler>>& EventClassAndFunctionNames) const
	{
		if(bHasBoundEvents)
			return false;

		auto GravityBlade = Cast<AGravityBladeActor>(HazeOwner);		

		if(GravityBlade != nullptr)
		{
			EventHandlerComponent = UHazeEffectEventHandlerComponent::Get(GravityBlade);

			EventClassAndFunctionNames.Add(n"StartThrow", UGravityBladeGrappleEventHandler);
			EventClassAndFunctionNames.Add(n"EndThrow", UGravityBladeGrappleEventHandler);
			EventClassAndFunctionNames.Add(n"StartGravityShiftTransition", UGravityBladeGrappleEventHandler);
			EventClassAndFunctionNames.Add(n"EndGravityShiftTransition", UGravityBladeGrappleEventHandler);

			return true;		
		}
		else
		{
			auto BikeBlade = Cast<AGravityBikeBlade>(HazeOwner);
			if(BikeBlade != nullptr)
			{
				EventHandlerComponent = UHazeEffectEventHandlerComponent::Get(BikeBlade);

				EventClassAndFunctionNames.Add(n"OnThrowStarted", UGravityBikeBladeEventHandler);
				EventClassAndFunctionNames.Add(n"OnThrowStopped", UGravityBikeBladeEventHandler);
				EventClassAndFunctionNames.Add(n"OnGravityChangeStarted", UGravityBikeBladeEventHandler);
				//EventClassAndFunctionNames.Add(n"OnGravityChangeStopped", UGravityBikeBladeEventHandler);

				return true;
			}

		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnLinkedToProxy(const FName& ProxyTag, TArray<FHazeProxyEmitterUserAuxTargetData>& OutUserAuxTargetDatas)
	{
		OutUserAuxTargetDatas = GravityBladeAuxUserSends;
	}

	UFUNCTION(BlueprintPure)
	void GetTimeToGravityShiftTarget(float&out TimeSeconds, int&out OvershootMilliseconds)
	{
		if(!bIsOnGravityBike && (!GrappleComp.ActiveGrappleData.IsValid() || !GrappleComp.ActiveGrappleData.CanShiftGravity()))
			return;

		const float GRAVITY_SHIFT_END_APEX_TIME = 1.0;

		if(!bIsOnGravityBike)
		{
			const float Alpha = GrappleUserComp.AnimationData.GrappleStateAlpha;
			TimeSeconds = Math::Lerp(GrappleComp.GrapplePullDuration, 0.0, Alpha);			
		}
		else
		{
			auto BikeBladeComponent = UGravityBikeBladePlayerComponent::Get(PlayerOwner);
			const float Alpha = BikeBladeComponent.GravityChangeAlpha;
			TimeSeconds = Math::Lerp(BikeBladeComponent.GravityChangeDuration, 0.0, Alpha);	

			// // Try to predict fast end to Bike transitions, move back TimeSeconds slightly...
			// TimeSeconds -= 0.15; 
		}
		
		if(TimeSeconds < GRAVITY_SHIFT_END_APEX_TIME)
			OvershootMilliseconds = Math::FloorToInt((GRAVITY_SHIFT_END_APEX_TIME - TimeSeconds) * 1000);
		else
			OvershootMilliseconds = -1;
	}

	UFUNCTION(BlueprintPure)
	bool HasGravityShiftTimeDrifted(const float CurrTime, const float LastTime, const float DeltaTime)
	{
		const float TimeDelta = LastTime - CurrTime;
		return (TimeDelta - DeltaTime) > 0.10;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is In Sidescroller"))
	bool IsSidescroller()
	{
		return UPlayerMovementPerspectiveModeComponent::Get(PlayerOwner).PerspectiveMode == EPlayerMovementPerspectiveMode::SideScroller;
	}

	UFUNCTION(BlueprintEvent)
	void StartThrow(FGravityBladeThrowData ThrowData) {}

	UFUNCTION()
	void OnThrowStarted(FGravityBikeBladeThrowEventData InThrowData)
	{
		FGravityBladeThrowData ThrowData;
		ThrowData.Location = InThrowData.TargetLocation;
		ThrowData.Normal = InThrowData.TargetNormal;
		ThrowData.ThrowDuration = InThrowData.ThrowDuration;

		StartThrow(ThrowData);
	}

	UFUNCTION(BlueprintEvent)
	void EndThrow(FGravityBladeThrowData ThrowData) {}

	UFUNCTION()
	void OnThrowStopped(FGravityBikeBladeThrowEventData InThrowData)
	{
		FGravityBladeThrowData ThrowData;
		ThrowData.Location = InThrowData.TargetLocation;
		
		EndThrow(ThrowData);
	}

	UFUNCTION(BlueprintEvent)
	void StartGravityShiftTransition(FGravityBladeGravityTransitionData TransitionData) {}

	UFUNCTION()
	void OnGravityChangeStarted()
	{
		auto BikeBladeComponent = UGravityBikeBladePlayerComponent::Get(PlayerOwner);

		FGravityBladeGravityTransitionData GravityData;
		GravityData.bWillAffectCamera = true;

		auto MovementSpline = FHazeRuntimeSpline();
		MovementSpline.AddPoint(PlayerOwner.ActorTransform.Location);
		MovementSpline.AddPoint(GrappleComp.ActiveGrappleData.WorldLocation);

		const float NewLength = MovementSpline.Length;
		GravityData.PullDuration = BikeBladeComponent.GravityChangeDuration;

		GravityData.bTransitionToOriginalGravity = (GrappleComp.ActiveAlignSurface.SurfaceNormal == FVector::UpVector);
		
		StartGravityShiftTransition(GravityData);
	}

	UFUNCTION(BlueprintEvent)
	void EndGravityShiftTransition() {}	
}