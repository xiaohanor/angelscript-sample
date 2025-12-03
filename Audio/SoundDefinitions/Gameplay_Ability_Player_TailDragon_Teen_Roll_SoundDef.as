struct FDragonRollingSurfaceEvents
{
	UPROPERTY()
	UHazeAudioEvent RollingEvent;

	UPROPERTY()
	UHazeAudioEvent JumpEvent;

	UPROPERTY()
	UHazeAudioEvent LandEvent;
}


UCLASS(Abstract)
class UGameplay_Ability_Player_TailDragon_Teen_Roll_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnJump(){}

	UFUNCTION(BlueprintEvent)
	void RollImpact(FRollParams ImpactParams){}

	/* END OF AUTO-GENERATED CODE */

	const FHazeAudioID PanningRTPCId = FHazeAudioID("Rtpc_SpeakerPanning_LR");
	const FName DragonRollingGroupName = n"Dragon_Grounded_Roll";

	AHazePlayerCharacter DragonRiderPlayer;
	UHazeMovementComponent MoveComp;
	UPlayerTeenDragonComponent DragonComp;
	UTeenDragonRollBounceComponent BounceComp;
	UDragonFootstepTraceComponent TraceComp;

	UPROPERTY(BlueprintReadOnly)
	UDragonMovementAudioComponent AudioMoveComp;

	UPROPERTY(BlueprintReadWrite)
	FHazeAudioPostEventInstance RollingBodyEventInstance;

	UPROPERTY(BlueprintReadWrite)
	FHazeAudioPostEventInstance RollingSurfaceEventInstance;

	UPROPERTY(EditDefaultsOnly)
	TMap<EHazeAudioPhysicalMaterialHardnessType, FDragonRollingSurfaceEvents> SurfaceRollingEvents;

	UPROPERTY(BlueprintReadOnly)
	float RollingSpeed = 0.0;

	UPROPERTY(BlueprintReadWrite)
	bool bIsRolling = false;

	UPROPERTY()
	float ImpactCooldown = 0.3;

	UFUNCTION(BlueprintEvent)
	void StartRollingMaterial(UHazeAudioEvent RollingEvent) {}

	UFUNCTION(BlueprintEvent) 
	void StopRollingMaterial() {}

	UFUNCTION(BlueprintEvent)
	void OnLand(float ImpactSpeed, float SlopeAngle) {}

	UFUNCTION(BlueprintEvent)
	void ForceStopLoops() {}

	private UPhysicalMaterialAudioAsset LastPhysMat = nullptr;

	private bool bWasGrounded = true;
	private bool bShouldQueryJumpApex = false;
	private bool bHasStartedFalling = false;
	private float ImpactTimer = 0.0;

	private FVector LastAirborneLocation;
	private FVector LastActorLocation;
	private FVector JumpApexLocation;

	private UTeenDragonRollSettings RollSettings;

	UFUNCTION(BlueprintEvent)
	void OnEnterCoins() {};

	UFUNCTION(BlueprintEvent)
	void OnExitCoins() {};

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DragonRiderPlayer = Game::GetZoe();
		MoveComp = UHazeMovementComponent::Get(DragonRiderPlayer);
		AudioMoveComp = UDragonMovementAudioComponent::Get(HazeOwner);
		DragonComp = UPlayerTeenDragonComponent::Get(DragonRiderPlayer);
		BounceComp = UTeenDragonRollBounceComponent::Get(DragonRiderPlayer);
		TraceComp = UDragonFootstepTraceComponent::Get(DragonRiderPlayer);

		RollSettings = UTeenDragonRollSettings::GetSettings(DragonRiderPlayer);
	
		const float PlayerPanningValue =  DragonRiderPlayer.IsMio() ? -1.0 : 1.0;
		DefaultEmitter.SetRTPC(PanningRTPCId, PlayerPanningValue, 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ProxyEmitterSoundDef::LinkToActor(this, Game::GetZoe());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(bIsRolling)
		{
			RollingSpeed = GetRollingSpeed();
			QueryContactMaterial();

			const bool bIsGrounded = MoveComp.IsOnAnyGround() || BounceComp.HasResolverBouncedThisFrame();
			QueryOnGrounded(bIsGrounded, DeltaSeconds);
			bWasGrounded = bIsGrounded;

			
			if(!bIsGrounded)
				LastAirborneLocation = DragonComp.DragonMesh.GetCenterOfMass();	
		}
		else
		{
			LastPhysMat = nullptr;
		}

		// // Don't like having to check for this, but for some reason animation ABP:s can go out of sync and cause stuck loops if we don't handle it...
		// if(bIsRolling 
		// && !AudioMoveComp.IsGroupActive(DragonRollingGroupName)
		// && (RollingSurfaceEventInstance.IsPlaying() && !RollingSurfaceEventInstance.bIsBeingStopped))
		// {
		// 	ForceStopLoops();
		// }	

		LastActorLocation = DragonRiderPlayer.GetActorCenterLocation();	
	}


//	UFUNCTION(BlueprintPure)
	private float GetRollingSpeed()
	{
		// This is how rolling speed is currently calculated for anim in
		// FeatureAnimInstanceTailTeenRoll, make sure we keep the math in sync
		return Math::Min(1.0, DragonRiderPlayer.ActorVelocity.Size() / (RollSettings.MaximumRollSpeed * 0.8));
	}

	private void QueryContactMaterial()
	{
		FHazeTraceSettings TraceSettings = FHazeTraceSettings();
		TraceSettings.TraceWithPlayerProfile(DragonRiderPlayer);

		auto RollingHitResult = MoveComp.GroundContact.ConvertToHitResult();
		UPhysicalMaterialAudioAsset ContactPhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromHit(RollingHitResult, TraceSettings).AudioAsset);
		
		if(LastPhysMat != ContactPhysMat)
		{
			if(MoveComp.IsOnAnyGround())
			{
				FDragonRollingSurfaceEvents SurfaceEvents;
				if(SurfaceRollingEvents.Find(ContactPhysMat.HardnessType, SurfaceEvents))
					StartRollingMaterial(SurfaceEvents.RollingEvent);
			}				
		}

		if(MoveComp.IsOnAnyGround())
		{
			LastPhysMat = ContactPhysMat;
		}
		else if(LastPhysMat != nullptr)
		{
			LastPhysMat = nullptr;
			StopRollingMaterial();
		}
	}
	private void QueryOnGrounded(const bool bInIsGrounded, const float DeltaSeconds)
	{
		if(bWasGrounded && bInIsGrounded)
			return;

		const FVector Velo = DragonRiderPlayer.GetActorCenterLocation() - LastActorLocation;

		if(bWasGrounded && !bInIsGrounded)
		{
			LastAirborneLocation = DragonRiderPlayer.GetActorCenterLocation();
			bShouldQueryJumpApex = true;
			bHasStartedFalling = false;
		}
		else if(!bWasGrounded && bInIsGrounded)
		{
			if(Time::GetGameTimeSince(ImpactTimer) > ImpactCooldown)
			{
				// if(!bHasStartedFalling)
				// 	JumpApexLocation = DragonRiderPlayer.GetActorCenterLocation();

				const float VerticalDelta = (JumpApexLocation.Z - DragonRiderPlayer.GetActorCenterLocation().Z);	

				if(VerticalDelta > SMALL_NUMBER)
				{
					// Compensate for downhill velocity! SlopeAngle increases towards 1 if we go downhill, used to subtract output gain as compared to hitting flat ground
					const float ImpactSpeed = Math::Clamp(Math::Saturate(VerticalDelta / 350.0), 0.0, 1.0);					
					const FVector Normal = MoveComp.GetGroundContact().ImpactNormal;
					const float SlopeDot = Velo.GetSafeNormal().DotProduct(Normal);

					float SlopeAngle = Math::GetMappedRangeValueClamped(FVector2D(-0.1, -0.3), FVector2D(1.0, 0.0), SlopeDot);		

					// If we fell for a long time slope the downwards velocity calculated in slope angle should have no effect
					if(VerticalDelta > 1000.0)
						SlopeAngle = 0.0;		

					OnLand(ImpactSpeed, SlopeAngle);

					ImpactTimer = Time::GetGameTimeSeconds();
				}
			}
		}

		if(bShouldQueryJumpApex)
		{
			const float Dot = Velo.GetSafeNormal().DotProduct(FVector::UpVector);
			bHasStartedFalling = Dot < 0;
			if(bHasStartedFalling)
			{
				bShouldQueryJumpApex = false;
				JumpApexLocation = DragonRiderPlayer.GetActorCenterLocation();
			}
		}		
	}

	UFUNCTION(BlueprintPure)
	float IsInAirValue(bool bInverted)
	{
		float InAirValue = MoveComp.IsOnAnyGround() ? 0.0 : 1.0;

		if(bInverted)
		{
			if(InAirValue == 0.0)
				InAirValue = 1.0;
			else if(InAirValue == 1.0)
				InAirValue = 0.0;
		}	

		return InAirValue;
	}

	UFUNCTION(BlueprintPure)
	UHazeAudioEvent GetSurfaceJumpEvent()
	{	
		if(LastPhysMat == nullptr)
			return nullptr;

		FDragonRollingSurfaceEvents SurfaceEvents;
		SurfaceRollingEvents.Find(LastPhysMat.HardnessType, SurfaceEvents);
		return SurfaceEvents.JumpEvent;
	}

	UFUNCTION(BlueprintPure)
	UHazeAudioEvent GetSurfaceLandEvent()
	{
		UPhysicalMaterialAudioAsset LandPhysMat = LastPhysMat;
		if(LandPhysMat == nullptr)
		{
			LandPhysMat = TraceForLandImpact();
		}		

		FDragonRollingSurfaceEvents SurfaceEvents;
		SurfaceRollingEvents.Find(LandPhysMat.HardnessType, SurfaceEvents);
		return SurfaceEvents.LandEvent;
	}

	private UPhysicalMaterialAudioAsset TraceForLandImpact()
	{
		FHazeTraceSettings TraceSettings = FHazeTraceSettings();
		TraceSettings.TraceWithPlayerProfile(DragonRiderPlayer);
		TraceSettings.SetReturnPhysMaterial(true);

		const FVector Start = DragonComp.DragonMesh.GetCenterOfMass();
		const FVector End = Start + FVector::UpVector * 500;

		FHitResult Hit = TraceSettings.QueryTraceSingle(Start, End);
		return Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromHit(Hit, TraceSettings).AudioAsset);
	}

}