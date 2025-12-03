UENUM()
enum ETundraMonkeyMovementType
{
	Idle = 0,
	Walk = 1,
	Run = 2
}

// struct FTundraMonkeySurfaceEvents
// {
// 	UPROPERTY()
// 	TMap<EHazeAudioPhysicalMaterialHardnessType, FTundraMonkeyFootstepDatas> FootstepDatas;
// }

struct FTundraMonkeyFootstepDatas
{
	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent FootWalkEvent;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent HandWalkEvent;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent FootRunEvent;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent HandRunEvent;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent ReleaseEvent;
	
	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent JumpEvent;
	
	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent LandEvent;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent RollEvent;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent GroundSlamEvent;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent PoleClimbGrabEvent;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent PoleClimbSlideEvent;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent PoleClimbEnterEvent;
}

struct FTundraMonkeyFootstepReleaseDatas
{
	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent LeftFootEvent;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent RightFootEvent;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent LeftHandEvent;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioEvent RightHandEvent;
}

UCLASS(Abstract)
class UGameplay_Character_Creature_Player_Tundra_SnowMonkey_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnGroundedGroundSlam(FTundraPlayerSnowMonkeyGroundSlamEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnGroundSlamActivated(){}

	UFUNCTION(BlueprintEvent)
	void OnTransformedOutOf(FTundraPlayerSnowMonkeyTransformParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnTransformedInto(FTundraPlayerSnowMonkeyTransformParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Plant(FTundraMonkeyFootstepParams FootParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Jump(FTundraMonkeyJumpLandParams JumpParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Land(FTundraMonkeyJumpLandParams LandParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Roll(FTundraMonkeyJumpLandParams RollParams){}

	UFUNCTION(BlueprintEvent)
	void OnGroundSlamLanded(FTundraPlayerSnowMonkeyGroundSlamEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnHangClimb_Grab(){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Release(FTundraMonkeyFootstepParams FootParams){}

	UFUNCTION(BlueprintEvent)
	void OnPoleClimb_Grab(){}

	UFUNCTION(BlueprintEvent)
	void OnHangClimb_Stop(){}

	UFUNCTION(BlueprintEvent)
	void OnHangClimb_Start(){}

	UFUNCTION(BlueprintEvent)
	void OnPunchInteractMultiPunch(FTundraPlayerSnowMonkeyPunchInteractEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnPunchInteractSinglePunch(FTundraPlayerSnowMonkeyPunchInteractEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnPunchInteractMultiPunchTriggered(){}

	UFUNCTION(BlueprintEvent)
	void OnPunchInteractSinglePunchTriggered(){}

	UFUNCTION(BlueprintEvent)
	void OnGroundSlamStartedFalling(){}

	UFUNCTION(BlueprintEvent)
	void OnBossPunchSlowMotionExit(FTundraPlayerSnowMonkeyBossPunchSlowMotionEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnBossPunchSlowMotionEnter(FTundraPlayerSnowMonkeyBossPunchSlowMotionEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnGroundSlamLandedFarFromView(FTundraPlayerSnowMonkeyGroundSlamEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnGroundedGroundSlamFarFromView(FTundraPlayerSnowMonkeyGroundSlamEffectParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintEvent)
	void OnGroundSlamFistsUp() {};

	UFUNCTION(BlueprintEvent)
	void OnGroundSlamFistsDown() {};

	UFUNCTION(BlueprintEvent)
	void OnSlidingStart(bool bIsIceSlide) {};

	UFUNCTION(BlueprintEvent)
	void OnSlidingStop() {};

	UFUNCTION(BlueprintEvent)
	void OnPoleClimbEnter() {};

	const float AIRBORNE_GROUNDPOUND_MAX_DISTANCE = 650.0;	
	const float HANG_CLIMB_MAX_SPEED = 1250.0;
	const float MAX_HAND_VELO = 2500;
	const float MAX_POLE_SLIDE_SPEED = 2000;

	FVector CachedLeftHandLocation;
	FVector CachedRightHandLocation;

	float CachedRelativeLeftHandVeloSpeed;
	float CachedRelativeRightHandVeloSpeed;	

	FVector LastMonkeyLocation;

	UPROPERTY(BlueprintReadOnly)	
	AHazePlayerCharacter Player;

	UTundraMonkeyMovementAudioComponent MonkeyMoveComp;
	USkeletalMeshComponent MonkeySkelMesh;
	UHazeMovementComponent MoveComp;
	UPlayerSlideComponent SlideComp;
	UPlayerPoleClimbComponent PoleClimbComp;
	UTundraPlayerShapeshiftingComponent ShapeShiftComp;

	UPROPERTY(EditDefaultsOnly, Category = "Footstep Events")
	TMap<EHazeAudioPhysicalMaterialHardnessType, FTundraMonkeyFootstepDatas> FootstepEvents;

	UPROPERTY(EditDefaultsOnly, Category = "Footstep Events")
	TMap<ETundraMonkeyMovementType, FTundraMonkeyFootstepReleaseDatas> FootstepReleaseEvents;

	UPROPERTY(EditDefaultsOnly, Category = "Footstep Events", Meta = (GetOptions = "GetMaterialTypeNames"))
	TMap<FName, UHazeAudioEvent> SurfaceAddEvents;	

	UPROPERTY(EditDefaultsOnly, Category = "Ground Slam", Meta = (GetOptions = "GetMaterialTypeNames"))
	TMap<FName, UHazeAudioEvent> GroundSlamDebrisEvents;	

	// UPROPERTY(EditDefaultsOnly, Category = "Ground Slam")
	// TMap<EHazeAudioPhysicalMaterialHardnessType, UHazeAudioEvent> GroundSlamEvents;

	private bool bWasSliding = false;

	private float FallingSpeed;	
	float GetFallingSpeed()
	{
		return Math::Abs(FallingSpeed);
	}

	#if EDITOR
	UFUNCTION()
	TArray<FString> GetMaterialTypeNames() const
	{
		TArray<FString> MaterialTypeNames;

		TArray<FAssetData> PhysMatDatas;
		AssetRegistry::GetAssetsByClass(FTopLevelAssetPath(UPhysicalMaterialAudioAsset), PhysMatDatas);

		for(auto AssetData : PhysMatDatas)
		{
			FString _;
			FString MaterialName;

			AssetData.AssetName.ToString().Split("_", _, MaterialName);
			MaterialTypeNames.AddUnique(MaterialName);			
		}
	

		return MaterialTypeNames;
	}
	#endif

	bool GetbIsInMonkeyForm() const property
	{
		return ShapeShiftComp.IsBigShape();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return bIsInMonkeyForm;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !bIsInMonkeyForm;
	}

	UFUNCTION(BlueprintOverride)
		void ParentSetup()
	{
		Player = Game::GetMio();
		MonkeyMoveComp = UTundraMonkeyMovementAudioComponent::Get(Game::GetMio());

		MonkeySkelMesh = USkeletalMeshComponent::Get(HazeOwner);

		MoveComp = UHazeMovementComponent::Get(Player);
		SlideComp = UPlayerSlideComponent::Get(Player);
		PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);

		ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto MovementAudioComp = UHazeMovementAudioComponent::Get(Player);

		MovementAudio::RequestBlock(this, MovementAudioComp, EMovementAudioFlags::Breathing);
		MovementAudio::RequestBlock(this, MovementAudioComp, EMovementAudioFlags::Efforts);
		MovementAudio::RequestBlock(this, MovementAudioComp, EMovementAudioFlags::Falling);

		ProxyEmitterSoundDef::LinkToActor(this, Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto MovementAudioComp = UHazeMovementAudioComponent::Get(Player);

		MovementAudio::RequestUnBlock(this, MovementAudioComp, EMovementAudioFlags::Breathing);
		MovementAudio::RequestUnBlock(this, MovementAudioComp, EMovementAudioFlags::Efforts);
		MovementAudio::RequestUnBlock(this, MovementAudioComp, EMovementAudioFlags::Falling);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(MoveComp.IsInAir())
			FallingSpeed = MoveComp.GetVerticalSpeed();		

		QuerySliding();

		const FVector MonkeyLocation = HazeOwner.GetActorLocation();
		const FVector MonkeyVelo = MonkeyLocation - LastMonkeyLocation;

		const FVector LeftHandLocation = MonkeySkelMesh.GetSocketLocation(MovementAudio::TundraMonkey::LeftHandSocketName);
		const FVector RightHandLocation = MonkeySkelMesh.GetSocketLocation(MovementAudio::TundraMonkey::RightHandSocketName);

		const FVector RelativeLeftHandVelo = (LeftHandLocation - CachedLeftHandLocation) - MonkeyVelo;
		const FVector RelativeRightHandVelo = (RightHandLocation - CachedRightHandLocation) - MonkeyVelo;

		CachedRelativeLeftHandVeloSpeed = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_HAND_VELO), FVector2D(0.0, 1.0), RelativeLeftHandVelo.Size() / DeltaSeconds);
		CachedRelativeRightHandVeloSpeed = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_HAND_VELO), FVector2D(0.0, 1.0), RelativeRightHandVelo.Size() / DeltaSeconds);

		LastMonkeyLocation = MonkeyLocation;
		CachedLeftHandLocation = LeftHandLocation;
		CachedRightHandLocation = RightHandLocation;
	}	

	UFUNCTION(BlueprintPure)
	UHazeAudioEvent GetFootstepEvent(const ETundraMonkeyFootType Foot,  const ETundraMonkeyFootstepType FootstepType, const EHazeAudioPhysicalMaterialHardnessType SurfaceType, const ETundraMonkeyMovementType MovementType)
	{
		UHazeAudioEvent FootstepEvent = nullptr;

		if(FootstepType != ETundraMonkeyFootstepType::Release)
		{
			FTundraMonkeyFootstepDatas FootstepDatas;
			if(FootstepEvents.Find(SurfaceType, FootstepDatas))
			{	
				switch(FootstepType)
				{
					case(ETundraMonkeyFootstepType::Foot):
					{
						switch(MovementType)
						{
							case(ETundraMonkeyMovementType::Idle): FootstepEvent = FootstepDatas.FootWalkEvent; break;
							case(ETundraMonkeyMovementType::Walk): FootstepEvent = FootstepDatas.FootWalkEvent; break;
							case(ETundraMonkeyMovementType::Run): FootstepEvent = FootstepDatas.FootRunEvent; break;
						}		

						break;			
					}
					case(ETundraMonkeyFootstepType::Hand):
					{
						switch(MovementType)
						{
							case(ETundraMonkeyMovementType::Idle): FootstepEvent = FootstepDatas.HandWalkEvent; break;
							case(ETundraMonkeyMovementType::Walk): FootstepEvent = FootstepDatas.HandWalkEvent; break;
							case(ETundraMonkeyMovementType::Run): FootstepEvent = FootstepDatas.HandRunEvent; break;
						}	

						break;				
					}
					default: break;
				}		
			}
		}
		else
		{
			FTundraMonkeyFootstepReleaseDatas RelaseData;
			if(FootstepReleaseEvents.Find(MovementType, RelaseData))
			{
				switch(Foot)
				{
					case(ETundraMonkeyFootType::LeftFoot): FootstepEvent = RelaseData.LeftFootEvent; break;
					case(ETundraMonkeyFootType::RightFoot): FootstepEvent = RelaseData.RightFootEvent; break;
					case(ETundraMonkeyFootType::LeftHand): FootstepEvent = RelaseData.LeftHandEvent; break;
					case(ETundraMonkeyFootType::RightHand): FootstepEvent = RelaseData.RightHandEvent; break;
					default: break;
				}	
			}
		}

		return FootstepEvent;		
	}

	UFUNCTION(BlueprintPure)
	bool IsGrounded()
	{
		return MoveComp.IsOnAnyGround();
	}

	UPhysicalMaterialAudioAsset GetGroundPoundImpactMaterial()
	{
		FHazeTraceSettings TraceSettings = FHazeTraceSettings();
		TraceSettings.TraceWithChannel(ECollisionChannel::AudioTrace);

		TraceSettings.IgnoreActor(Game::Mio);
		TraceSettings.IgnoreActor(Game::Zoe);

		const FVector TraceStart = Player.GetActorLocation();
		const FVector TraceEnd = TraceStart + (FVector::UpVector * - 100);

		auto HitResult = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);

		auto PhysMat = AudioTrace::GetPhysMaterialFromHit(HitResult, TraceSettings);
		if(PhysMat != nullptr)
			return Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset);

		devCheck(false, "SnowMonkey GroundSlam - Failed to trace for physmat!");
		return nullptr;
	}

	UFUNCTION(BlueprintPure)
	void GetGroundSlamEvent(UHazeAudioEvent&out GroundSlamEvent, UHazeAudioEvent&out DebrisEvent, bool&out bHasDebris)
	{	
		auto SlamMaterial = GetGroundPoundImpactMaterial();

		FTundraMonkeyFootstepDatas FootstepDatas;
		FootstepEvents.Find(SlamMaterial.HardnessType, FootstepDatas);
	
		GroundSlamEvent = FootstepDatas.GroundSlamEvent;	

		if(GroundSlamDebrisEvents.Find(SlamMaterial.ForceDebrisData.ForceTag, DebrisEvent))
			bHasDebris = SlamMaterial.ForceDebrisData.bCanCauseDebris;			
	}

	UFUNCTION(BlueprintPure)
	UHazeAudioEvent GetPoleClimbGrabEvent()
	{		
		UHazeAudioEvent PoleClimbEvent = nullptr;
		FTundraMonkeyFootstepDatas FootstepData;
		if(GetPoleClimbFootstepData(FootstepData))
		{
			return FootstepData.PoleClimbGrabEvent;
		}

		return PoleClimbEvent;
	}

	UFUNCTION(BlueprintPure)
	UHazeAudioEvent GetPoleClimbSlideEvent()
	{
		UHazeAudioEvent PoleClimbEvent = nullptr;
		FTundraMonkeyFootstepDatas FootstepData;
		if(GetPoleClimbFootstepData(FootstepData))
		{
			return FootstepData.PoleClimbSlideEvent;
		}

		return PoleClimbEvent;
	}

	UFUNCTION(BlueprintPure)
	UHazeAudioEvent GetPoleClimbEnterEvent()
	{
		UHazeAudioEvent PoleClimbEvent = nullptr;
		FTundraMonkeyFootstepDatas FootstepData;
		if(GetPoleClimbFootstepData(FootstepData))
		{
			return FootstepData.PoleClimbEnterEvent;
		}

		return PoleClimbEvent;
	}

	private bool GetPoleClimbFootstepData(FTundraMonkeyFootstepDatas& OutFootstepData)
	{
		APoleClimbActor CurrentPoleClimb = PoleClimbComp.Data.ActivePole;

		if(CurrentPoleClimb == nullptr)
		{
		#if EDITOR
			devCheck(false, "Missing PhysMat on material for SnowMonkey Pole Climb because ActivePole == nullptr");
		#endif
			return false;
		}

		UPhysicalMaterialAudioAsset AudioPhysMaterial = nullptr;
		bool bFound = false;

		if(CurrentPoleClimb.Pole.Materials.Num() > 0)
		{
			auto PhysMat = CurrentPoleClimb.Pole.Materials[0].PhysicalMaterial;
			if(PhysMat != nullptr)
			{
				AudioPhysMaterial = Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset);
			}
		}

		if(AudioPhysMaterial == nullptr)
		{
		#if EDITOR
			devCheck(false, f"Missing PhysMat on material for SnowMonkey Pole Climb: {CurrentPoleClimb.GetActorLabel()}");
		#endif
		}
		else
		{
			bFound = FootstepEvents.Find(AudioPhysMaterial.HardnessType, OutFootstepData);			
			
		}

		return bFound;
	}	

	UFUNCTION(BlueprintPure)
	float GetAirborneGroundPoundDistanceNormalized()
	{
		// Trace towards ground
		FHazeTraceSettings TraceSettings = FHazeTraceSettings();
		TraceSettings.TraceWithPlayerProfile(Player);

		TraceSettings.IgnoreActor(HazeOwner);
		TraceSettings.IgnoreActor(Game::GetMio());
		TraceSettings.IgnoreActor(Game::GetZoe());

		TraceSettings.UseLine();

		const FVector Start = Player.GetActorLocation();
		const FVector End = Player.GetActorLocation() + (Player.GetMovementWorldUp() * -AIRBORNE_GROUNDPOUND_MAX_DISTANCE);

		FHitResult Hit = TraceSettings.QueryTraceSingle(Start, End);
		if(!Hit.bBlockingHit)
			return 0.0;
		
		return Math::GetMappedRangeValueClamped(FVector2D(AIRBORNE_GROUNDPOUND_MAX_DISTANCE, 0.0), FVector2D(0.0, 1.0), Hit.Distance);
	}

	UFUNCTION(BlueprintPure)
	void GetRelativeHandVelocities(float&out Left, float&out Right)
	{
		Left = CachedRelativeLeftHandVeloSpeed;
		Right = CachedRelativeRightHandVeloSpeed;
	}

	UFUNCTION(BlueprintPure)
	float GetHangClimbSpeedNormalized()
	{
		return Math::GetMappedRangeValueClamped(FVector2D(0.0, HANG_CLIMB_MAX_SPEED), FVector2D(0.0, 1.0), MoveComp.Velocity.Size());
	}

	UFUNCTION(BlueprintPure)
	float GetPoleClimbSlideSpeedNormalized()
	{
		return Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_POLE_SLIDE_SPEED), FVector2D(0.0, 2.0), Math::Abs(MoveComp.GetVerticalSpeed()));
	}

	private void QuerySliding()
	{
		const bool bIsSliding = MoveComp.IsOnAnyGround() && SlideComp.IsSlideActive();
		if(bIsSliding && !bWasSliding)
		{
			FHazeTraceSettings TraceSettings = Trace::InitFromPlayer(Player);
			TraceSettings.IgnoreActor(HazeOwner);
			TraceSettings.IgnoreActor(Player);
			auto PhysMat = AudioTrace::GetPhysMaterialFromHit(MoveComp.GroundContact.ConvertToHitResult(), TraceSettings);		
			
			bool bIsIceSlide = false;
			if(PhysMat != nullptr)
			{
				bIsIceSlide = PhysMat.Name.ToString().Contains("Ice");
			}
			
			OnSlidingStart(bIsIceSlide);
			
		}
		else if(!bIsSliding && bWasSliding)
		{
			OnSlidingStop();
		}

		bWasSliding = bIsSliding;
	}

	UFUNCTION(BlueprintOverride)
	void DebugTick(float DeltaSeconds)
	{
		auto Mesh = USkeletalMeshComponent::Get(HazeOwner);

		const FVector Loc = Mesh.GetSocketLocation(MovementAudio::TundraMonkey::LeftHandSocketName);
		const FRotator Rot = Mesh.GetSocketRotation(MovementAudio::TundraMonkey::LeftHandSocketName);


		//Debug::DrawDebugCylinder(Loc, Loc + (Rot.ForwardVector * 30), 30.0, 5.0, FLinearColor::Red, Duration = 1.0);
	}
}